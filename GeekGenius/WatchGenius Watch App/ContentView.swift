//
//  ContentView.swift
//  WatchGenius Watch App
//
//  Created by Aidan Leuenberger on 5/29/23.
//

import SwiftUI

struct ContentView: View {
    @State private var subscriptions: [String: Bool] = [:]

    var body: some View {
        List(subscriptions.keys.sorted(), id: \.self) { key in
            Text("\(key): \(subscriptions[key]! ? "Active" : "Inactive")")
        }
        .onAppear(perform: fetchSubscriptions)
    }

    func fetchSubscriptions() {
        guard let url = URL(string: "http://192.168.50.58:4000/subscriptions") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode([String: Bool].self, from: data) {
                    DispatchQueue.main.async {
                        self.subscriptions = decodedResponse
                    }
                    return
                }
            }

            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
