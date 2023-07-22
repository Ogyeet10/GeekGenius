//
//  UpdatedSubscriptionInfoView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 6/3/23.
//

//import SwiftUI
//import StoreKit
//import SwiftyStoreKit
//
//struct UpdatedSubscriptionInfoView: View {
//    @EnvironmentObject var productHandler: ProductHandler
//    
//    var body: some View {
//        List(productHandler.products, id: \.productIdentifier) { product in
//            VStack(alignment: .leading) {
//                Text(product.localizedTitle)
//                Text(priceString(for: product))
//                Button(action: {
//                    purchase(product: product)
//                }) {
//                    Text("Purchase")
//                }
//            }
//        }
//    }
//    
//    // Helper function to format the price and currency
//    func priceString(for product: SKProduct) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.locale = product.priceLocale
//        return formatter.string(from: product.price) ?? ""
//    }
//    
//    // Function to initiate a purchase
//    func purchase(product: SKProduct) {
//        let payment = SKPayment(product: product)
//        SKPaymentQueue.default().add(payment)
//    }
//}
//
//
//struct UpdatedSubscriptionInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        UpdatedSubscriptionInfoView()
//    }
//}
