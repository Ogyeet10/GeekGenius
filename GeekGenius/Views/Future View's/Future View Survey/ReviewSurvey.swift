//
//  ReviewSurvey.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 11/15/23.
//

import SwiftUI
import FirebaseFirestore
import UIKit
import Network

struct ReviewSurvey: View {
    @EnvironmentObject var appState: AppState
    @Binding var questions: [SurveyQuestion]
    @Binding var currentPage: Int
    @State private var isSubmitting = false // State variable to track submission status
    @State private var showAlert = false // State for alert visibility
    
    let colorMapping: [String: Color] = [
        "Red": .red,
        "YouTube Music": .red,
        "Green": .green,
        "Spotify": .green,
        "Blue": .blue,
        "Yellow": .yellow,
        "Pink": .pink,
        "Apple Music": .pink,
        "SoundCloud": .orange,
        "Orange": .orange,
        "Black": .black,
        "White": .white,
        "Purple": .purple,
        "jacksepticeye": .green,
        "styropyro": .purple,
        "Linus Tech Tips": .orange,
        "NileRed": .red,
        "Half as Interesting": .yellow,
        "ELA": .green
    ]
    
    var body: some View {
        ZStack {
            VStack {
                Text("Answer Review")
                    .fontWeight(.bold)
                    .padding(.top)
                Divider()
                Text("Please review your answers carefully before submitting. You can only submit one survey.")
                    .font(.headline)
                    .padding()
                    .multilineTextAlignment(.center)
                    .italic()
                Divider()
                ScrollView {
                    VStack {
                        ForEach(Array(zip(0..., questions)), id: \.0) { index, question in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(question.questionText)
                                        .fontWeight(.semibold)
                                        .font(.title3)
                                    
                                    if question.hasAnswer {
                                        Text(showAnswerTo(question))
                                            .foregroundColor(colorForAnswer(showAnswerTo(question)))
                                    } else {
                                        Text("Not Answered")
                                            .italic()
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .onTapGesture {
                                self.currentPage = index
                            }
                            .padding() // Added padding to each question
                            Divider()
                        }
                    }
                }
                .ignoresSafeArea(edges: .all) // Ignore safe area vertically
            }
            
            VStack {
                Spacer() // Pushes the button to the bottom
                submitButton
            }
            .padding(.horizontal) // Add horizontal padding if needed
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Survey Submitted"),
                message: Text("Thank you for completing the survey. You will receive a notification anywhere from a few minutes to a few days, depending on availability."),
                dismissButton: .default(Text("OK")) {
                    appState.navigateToFutureChatView = false
                }
            )
        }
    }
    
    var submitButton: some View {
        Button(action: submitSurvey) {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                HStack {
                    Image(systemName: "arrow.up.to.line")
                        .font(.title2)
                    Text("Submit")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.blue)
        .cornerRadius(10)
        .disabled(isSubmitting)
    }

    
    func showAnswerTo(_ question: SurveyQuestion) -> String {
        switch question.type {
        case .multipleChoice:
            return question.answer ?? ""
        case .shortAnswer:
            return question.shortAnswer ?? ""
        case .date:
            return question.dateAnswer?.formatted(date: .long, time: .omitted) ?? ""
        }
    }
    
    func colorForAnswer(_ answer: String) -> Color {
        return colorMapping[answer] ?? .primary // Default to black if the answer isn't in the mapping
    }
}

extension SurveyQuestion {
    var hasAnswer: Bool {
        switch type {
        case .multipleChoice:
            return answer != nil
        case .shortAnswer:
            return shortAnswer != nil
        case .date:
            return dateAnswer != nil
        }
    }
}

extension ReviewSurvey {
    func submitSurvey() {
        isSubmitting = true // Start loading indicator
        appState.hasChatIntroductionViewOpened = true // Block the view from opening again after summation
        let db = Firestore.firestore()
        
        // Prepare survey responses
        var surveyData: [String: Any] = [:]
        for question in questions {
            surveyData[question.questionText] = question.getAnswer()
        }
        
        // Additional device information
        surveyData["submissionDate"] = Timestamp(date: Date())
        surveyData["deviceModel"] = UIDevice.current.modelName
        surveyData["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        surveyData["osVersion"] = UIDevice.current.systemVersion
        surveyData["connectionStatus"] = getConnectionStatus()
        // Additional field for APN Device Token
        if let apnDeviceToken = appState.apnDeviceToken {
            surveyData["apnDeviceToken"] = apnDeviceToken
        }

        // Fetch IP address and then submit data
        fetchIPAddress { ip in
            var surveyDataWithIP = surveyData
            surveyDataWithIP["ipAddress"] = ip
            // Send data to Firestore
            
            if let appStateUUID = appState.appInstallUUID {
                db.collection("survey").document(appStateUUID).setData(surveyDataWithIP) { error in
                    if let error = error {
                        isSubmitting = false // Stop loading indicator
                        print("Error writing document: \(error)")
                    } else {
                        // Document successfully written
                        print("Document successfully written!")
                        isSubmitting = false // Stop loading indicator
                        appState.navigateToFutureChatView = false
                        showAlert = true
                    }
                }
            }
        }
    }
    
    func getConnectionStatus() -> String {
        var status = "No Connection"
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    status = "Wi-Fi"
                } else if path.usesInterfaceType(.cellular) {
                    status = "Cellular"
                }
            } else {
                status = "No Connection"
            }
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        semaphore.wait() // Wait for the pathUpdateHandler to be called at least once
        monitor.cancel() // Stop the monitor
        
        return status
    }
    
    func fetchIPAddress(completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api64.ipify.org?format=json") else {
            completion("Unavailable")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion("Unavailable")
                return
            }
            
            if let ipResponse = try? JSONDecoder().decode(IPResponse.self, from: data) {
                completion(ipResponse.ip)
            } else {
                completion("Unavailable")
            }
        }
        task.resume()
    }
}

extension SurveyQuestion {
    func getAnswer() -> Any {
        switch type {
        case .multipleChoice:
            return answer ?? ""
        case .shortAnswer:
            return shortAnswer ?? ""
        case .date:
            return dateAnswer?.formatted(date: .long, time: .omitted) ?? ""
        }
    }
}

struct IPResponse: Codable {
    let ip: String
}

struct ReviewSurvey_Previews: PreviewProvider {
    // Sample survey questions for preview
    static let sampleQuestions: [SurveyQuestion] = [
        SurveyQuestion(questionText: "What's your favorite color?", options: ["Red", "Blue", "Green"], type: .multipleChoice, answer: "Pink", isOptional: false),
        SurveyQuestion(questionText: "What's your birthday?", options: nil, type: .date, dateAnswer: Date(), isOptional: true),
    ]
    
    // Sample current page number
    static let sampleCurrentPage = 0
    
    static var previews: some View {
        ReviewSurvey(questions: .constant(sampleQuestions), currentPage: .constant(sampleCurrentPage))
    }
}
