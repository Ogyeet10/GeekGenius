//
//  TipStore.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 7/21/23.
//

import Foundation
import StoreKit
import Firebase


typealias PurchaseResult = Product.PurchaseResult
typealias TransactionLister = Task<Void, Error>

enum TipsError: LocalizedError {
    case failedVerification
    case system(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "User transaction verification failed"
        case .system(let err):
            return err.localizedDescription
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification
    case system(Error)
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "User transaction verification failed"
        case .system(let err):
            return err.localizedDescription
        }
    }
}

enum TipsAction: Equatable {
    case successful
    case failed(TipsError)
    
    static func == (lhs: TipsAction, rhs: TipsAction) -> Bool {
            
        switch (lhs, rhs) {
        case (.successful, .successful):
            return true
        case (let .failed(lhsErr), let .failed(rhsErr)):
            return lhsErr.localizedDescription == rhsErr.localizedDescription
        default:
            return false
        }
    }
}

@MainActor
class TipsStore: ObservableObject {
    let db = Firestore.firestore()
    @Published private(set) var items: [Product]?
    @Published private(set) var action: TipsAction? {
        didSet {
            switch action {
            case .failed:
                hasError = true
            default:
                hasError = false
            }
        }
    }
    @Published var hasError = false
    
    private var transactionListener: TransactionLister?
    
    var error: TipsError? {
        switch action {
        case .failed(let err):
            return err
        default:
            return nil
        }
    }
    
    init() {
        
        transactionListener = configureTransactionListener()
        
        Task {
            await retrieveProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }

    func purchase(_ item: Product) async {
            do {
                let result = try await item.purchase()
                try await handlePurchase(from: result, for: item)
            } catch {
                action = .failed(.system(error))
                print(error)
            }
        }
    
    /// Call to reset the action state within the store
    func reset() {
        action = nil
    }
}

private extension TipsStore {
    
    /// Create a listener for transactions that don't come directly via the purchase function
    func configureTransactionListener() -> TransactionLister {
        
        Task { [weak self] in
            
            do {
                
                for await result in Transaction.updates {
                    
                    let transaction = try self?.checkVerified(result)
                    
                    self?.action = .successful
                    
                    await transaction?.finish()
                }
                
            } catch {
                self?.action = .failed(.system(error))
            }
        }
    }
    
    /// Get all of the products that are on offer
    func retrieveProducts() async {
        do {
            let products = try await Product.products(for: myTipProductIdentifiers)
            items = products.sorted(by: { $0.price < $1.price })
        } catch {
            action = .failed(.system(error))
            print(error)
        }
    }
    
    /// Handle the result when purchasing a product
    func handlePurchase(from result: PurchaseResult, for item: Product) async throws {
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Log the purchase to Firestore
            await logPurchaseToFirestore(for: item)
            action = .successful
            await transaction.finish()
            
        case .pending:
            print("The user needs to complete some action on their account before they can complete purchase")
            
        case .userCancelled:
            print("The user hit cancel before their transaction started")
            
        default:
            print("Unknown error")
            
        }
    }
    
    /// Check if the user is verified with their purchase
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            print("The verification of the user failed")
            throw TipsError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // New function to log the purchase to Firestore using async/await
    func logPurchaseToFirestore(for item: Product) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let userRef = db.collection("users").document(userID)
        var tierPrice = item.displayPrice  // Assuming displayPrice is a String representing the price
        
        // Replace the period with an underscore
        tierPrice = tierPrice.replacingOccurrences(of: ".", with: "_")
        
        do {
            // Atomically increment the tier count for the user
            try await userRef.updateData([
                "tiers.\(tierPrice)": FieldValue.increment(Int64(1))
            ])
            print("Document successfully updated")
        } catch let err {
            print("Error updating document: \(err)")
        }
    }
}

