//
//  SubscriptionInfoView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/6/23.
//

import SwiftUI
import FirebaseAuth
import UIKit

struct SubscriptionInfoView: View {
    @State private var showAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Get a Subscription")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(height: 0, alignment: .bottom)
                )
            
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.green)
                    .font(.system(size: 35))
                Text("Price: $2/month or $24/year")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "list.bullet")
                        .imageScale(.large)
                    
                    Text("To set up a subscription, please follow these steps:")
                        .font(.headline)
                }
                .padding(.vertical)
                
                HStack(alignment: .top) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                    Text("Send $2 via Apple Pay to aidanml05@gmail.com. You can also pay me in cash if you prefer.")
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text("Include your registered email address in the payment notes.")
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("Your subscription will be activated shortly. If it's not activated within 24 hours, please contact me.")
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.red)
                    Text("Remember to pay $2 each month to keep your subscription active, or pay $24 for a yearly subscription.")
                }
                
                HStack {
                       Image(systemName: "person.fill.questionmark")
                           .foregroundColor(.purple)
                       Text("Teachers get free access! Contact me with a photo of you holding a paper with a check mark next to your head. Don't forget to include your registered email! (Check mark lol)")
                   }
            }
            .font(.body)

            
        Button(action: {
                            let haptic = UIImpactFeedbackGenerator(style: .medium)
                            UIPasteboard.general.string = Auth.auth().currentUser?.email
                            haptic.impactOccurred()
                            showAlert = true
                        }) {
                            Text("Copy email")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                                    .padding(.horizontal, 130) // Add horizontal padding to reduce width
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Copied!"), message: Text("Your email has been copied to the clipboard."), dismissButton: .default(Text("OK")))
                        }
            
            Spacer()
            
            Menu {
                Button(action: {
                    openURL(URL(string: "sms:17735519899")!)
                }) {
                    Label("iMessage: 1-773-551-9899", systemImage: "message.fill")
                }
                
                Button(action: {
                    openURL(URL(string: "mailto:aidanml05@gmail.com")!)
                }) {
                    Label("Email: aidanml05@gmail.com", systemImage: "mail.fill")
                }
                
                Button(action: {
                    openURL(URL(string: "https://t.me/Ogyeet10")!)
                }) {
                    Label("Telegram: @Ogyeet10", systemImage: "paperplane.fill")
                }
            } label: {
                Text("Contact Aidan")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Subscription Info")
    }
    
    // Helper function to open a URL
    func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

struct SubscriptionInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionInfoView()
    }
}
