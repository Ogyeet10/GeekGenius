//
//  SurveyView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 11/15/23.
//

import SwiftUI

// Main view that coordinates the survey
struct SurveyView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage(hasCurrentSessionKey) var hasCurrentSession = false
    @State private var currentPage: Int = 0

    
    // Arey to hold the questions
    @State private var questions: [SurveyQuestion] = [
        SurveyQuestion(questionText: "What's your favorite color?", options: ["Red", "Orange", "Yellow", "Green", "Blue",  "Pink"], type: .multipleChoice, isOptional: false),
        SurveyQuestion(questionText: "What's your favorite food?", options: ["Pizza 🍕",
                                                                             "Sushi 🍣",
                                                                             "Pasta 🍝",
                                                                             "Burgers 🍔"], type: .multipleChoice, isOptional: false),
        SurveyQuestion(
            questionText: "What's your go-to music app?",
            options: ["Spotify", "Apple Music", "YouTube Music", "SoundCloud"], type: .multipleChoice, isOptional: false
        ),
        SurveyQuestion(
            questionText: "What's your daily listening device of choice?",
            options: ["AirPods Pro 🎧", "Wired Earphones", "Over-Ear Headphones", "Car Speakers"], type: .multipleChoice, isOptional: false
        ),
        SurveyQuestion(questionText: "What's your birthday?", options: nil, type: .date, isOptional: true),
        SurveyQuestion(questionText: "What's your favorite TV show?", options: nil, type: .shortAnswer, isOptional: true),
        SurveyQuestion(
            questionText: "What color is your phone case?",
            options: ["Black", "White", "Pink", "Rainbow", "Blue"], type: .multipleChoice, isOptional: false
        ),
        SurveyQuestion(
            questionText: "What was your favorite subject in 7TH GRADE?",
            options: ["Mathematics", "Science", "History", "ELA", "Art", "Physical Education"], type: .multipleChoice, isOptional: false
        ),
        SurveyQuestion(questionText: "What's MY favorite color?", options: ["Red", "Orange", "Yellow", "Green", "Blue", "Purple"], type: .multipleChoice, isOptional: false),
        SurveyQuestion(questionText: "What's MY birthday?", options: nil, type: .date, isOptional: false),
        SurveyQuestion(questionText: "Who is my favorite Youtuber? (Hint, it has not changed in years.)", options: ["jacksepticeye", "Linus Tech Tips", "NileRed", "Half as Interesting", "Mark Rober"], type: .multipleChoice, isOptional: false),
        SurveyQuestion(questionText: "What color was my backpack last year?", options: ["Black", "Orange", "Green", "Blue", "Red"], type: .multipleChoice, isOptional: false),
        SurveyQuestion(questionText: "Name a class where we were partners for a project.", options: nil, type: .shortAnswer, isOptional: true),
        SurveyQuestion(questionText: "What was your favorite moment from the last school year?", options: nil, type: .shortAnswer, isOptional: false),
        SurveyQuestion(questionText: "Create a list of teachers in order by the grades you had them, starting from 4th grade and ending in 8th.", options: nil, type: .shortAnswer, isOptional: false)
        
    ]
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(zip(0..., $questions)), id: \.1.id) { count, $question in
                VStack {
                    Text("GeekGenius Survey")
                        .fontWeight(.bold)
                        .padding(.top)
                    Divider()
                    QuestionView(question: $question, currentPage: $currentPage)
                }
                .tag(count)
                .background {
                     Color.white
                }
                .highPriorityGesture(DragGesture())
            }
            
            ReviewSurvey(questions: $questions, currentPage: $currentPage)
                .tag(questions.count )
            Text("thank you for completing the survey!")
                .font(.title)
                .tag(questions.count + 1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}


