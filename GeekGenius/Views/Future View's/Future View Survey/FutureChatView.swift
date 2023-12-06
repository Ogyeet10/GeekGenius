//
//  FutureChatView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 11/1/23.
//

import SwiftUI

// A simple model to represent a survey question
struct SurveyQuestion: Identifiable, Codable, Equatable {
    var id = UUID() // unique identifier for each question
    let questionText: String
    let options: [String]?
    let type: QuestionType
    var shortAnswer: String? // Only used for short answer questions
    var dateAnswer: Date? // Only used for date questions
    var answer: String?
    var isOptional: Bool // Flag for optional questions
    var isAnswered: Bool = false
}

struct AlertItem: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var dismissButton: String
}

enum QuestionType: Codable {
    case multipleChoice
    case shortAnswer
    case date
}


struct QuestionView: View {
    @State private var selectedOption: String?
    @State private var shortAnswer: String = ""
    @State private var dateAnswer: Date = Date()
    @State private var showingOptional: Bool = false
    @Binding var question: SurveyQuestion
    @Binding var currentPage: Int
    
    
    var body: some View {
        VStack {
            Spacer()
            
            // Question Text
            Text(question.questionText)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .minimumScaleFactor(0.2) 
            
            Spacer()
            
            switch question.type {
            case .multipleChoice:
                ForEach(question.options!, id: \.self) { option in
                    OptionButton(
                        option: option,
                        isSelected: selectedOption == option,
                        action: {
                            selectedOption = option
                            question.isAnswered = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                }
            case .shortAnswer:
                // Short answer UI
                TextField("Your answer", text: $shortAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: shortAnswer) { newValue in
                        question.isAnswered = !newValue.isEmpty
                    }
            case .date:
                // Date question UI
                DatePicker(
                    "Select Date",
                    selection: $dateAnswer,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .onChange(of: dateAnswer) { _ in
                    question.isAnswered = true
                    
                }
            }
            Spacer()
            
            // Continue button
            Button(action: {
                withAnimation {
                    currentPage += 1
                }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            ) {
                HStack {
                    Text("Continue")
                        .font(.headline)
                    
                    Image(systemName: "arrow.right.circle")
                        .font(Font.system(size: 20, weight: .semibold))
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(self.buttonColor())
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            .disabled(!question.isOptional && !question.isAnswered)
            
            //back
            Button(action: {
                // Action to go back to the previous question
                if currentPage > 0 {
                    withAnimation {
                        currentPage -= 1
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.left.circle")
                        .font(Font.system(size: 20, weight: .semibold))
                    Text("Back")
                        .font(.headline)
                }
                .font(.headline)
                .foregroundColor(currentPage == 0 ? .gray : .blue)
                .padding()
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .disabled(currentPage == 0)
            Spacer()
        }
        .padding(.bottom)
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: currentPage) { _ in
            switch question.type {
            case .multipleChoice:
                question.answer = selectedOption
            case .shortAnswer:
                question.shortAnswer = !shortAnswer.isEmpty ? shortAnswer : nil
            case .date:
                question.dateAnswer = dateAnswer
            }
        }
        .onAppear {
            // Set the isOptional flag for the question
            showingOptional = question.isOptional
            if let mq = question.answer {
                selectedOption = mq
            }
            if let sq = question.shortAnswer {
                shortAnswer = sq
            }
            if let dq = question.dateAnswer {
                dateAnswer = dq
            }
        }
    }

    func buttonColor() -> Color {
        if question.isAnswered {
            return Color.blue
        } else if question.isOptional {
            return Color.green
        } else {
            return Color.gray
        }
    }
}


struct OptionButton: View {
    var option: String
    var isSelected: Bool
    var action: () -> Void
    let colors: [String: Color] = [
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
        Button(action: action) {
            HStack {
                Text(option)
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.white)
                }
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(isSelected ? colors[option, default: Color.blue] : Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FutureChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var alertIndex = 0 // Current index in the alert sequence
    @State private var showingGradient = true
    @State private var isAlertPresented = false // New state to track if an alert is presented
    @State private var showAlert = false // State to control alert presentation
    
    // Define your alerts here
    var alerts: [AlertItem] = [
        AlertItem(title: "Welcome", message: "GeekGenius has detected that you might be eligible for access to the special easter egg.", dismissButton: "OK"),
        AlertItem(title: "Verification Required", message: "GeekGenius need to verify your identity to continue.", dismissButton: "Got it"),
        AlertItem(title: "How do I get verified", message: "GeekGenius will now ask you a series of unintrusive personal questions to verify your identity.", dismissButton: "Got it"),
        AlertItem(title: "WARNING", message: "After 1 failed attempt to fill out the survey correctly GeekGenius won't open the survey ever again.", dismissButton: "I Understand"),
        AlertItem(title: "Your submission may take time to get approved.", message: "I need to manually verify each form submission so we don't get any false positives.", dismissButton: "Understood"),
        AlertItem(title: "Optional questions", message: "This survey has a few optional questions. The Continue button will be green if the question is optional.", dismissButton: "Yep, I understand"),
        AlertItem(title: "Reminder", message: "Please ALWAYS answer truthfully for ALL questions as you may eligible and get a false negative.", dismissButton: "I will"),
        AlertItem(title: "You ready?", message: "The survey will begin when you tap the I am button", dismissButton: "I am!")
    ]
    
    var body: some View {
        VStack {
            // Only show this when showingGradient is true
            if showingGradient {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.pink]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                // Other content when gradient is showing
            }
            
            // When showingGradient is false, make sure that the above views are not affecting the layout
            if !showingGradient {
                SurveyView()
                    .transition(.opacity) // Adjust this if it's causing layout issues
            }
        }
        .onAppear {
            // Start the alert sequence when the view appears
            self.showAlertSequence()
        }
        .alert(isPresented: $showAlert) {
            // Configure the alert based on the current alert index
            let currentAlert = alerts[alertIndex]
            return Alert(
                title: Text(currentAlert.title),
                message: Text(currentAlert.message),
                dismissButton: .default(Text(currentAlert.dismissButton)) {
                    // Handle the dismissal of the alert
                    self.handleAlertDismissal()
                }
            )
        }
    }
    
    private func showAlertSequence() {
        if alertIndex < alerts.count {
            showAlert = true // Trigger the alert
        } else {
            withAnimation {
                showingGradient = false
            }
        }
    }
    
    private func handleAlertDismissal() {
        // Ensure that there's a delay before showing the next alert to avoid conflicts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Increment the alert index to show the next alert
            alertIndex += 1
            showAlertSequence() // Call the sequence function again
        }
    }
}


#Preview {
    FutureChatView()
}
