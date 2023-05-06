//
//  RemoteImage.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/16/23.
//

import SwiftUI
import Combine
import Foundation

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    
    func load(url: String) {
        guard let imageURL = URL(string: url) else { return }
        
        cancellable = URLSession.shared.dataTaskPublisher(for: imageURL)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { image in
                self.image = image
            }
    }

    func cancel() {
        cancellable?.cancel()
    }
}

struct RemoteImage: View {
    @StateObject private var loader = ImageLoader()
    @ObservedObject var cache = URLImageCache.shared
    let placeholder: Image
    let url: String

    init(url: String, placeholder: Image = Image(systemName: "photo")) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = cache.cache.object(forKey: NSURL(string: url)!) {
                Image(uiImage: image)
                    .resizable()
            } else if loader.image != nil {
                Image(uiImage: loader.image!)
                    .resizable()
                    .onAppear {
                        cache.cache.setObject(loader.image!, forKey: NSURL(string: self.url)!)
                    }
            } else {
                placeholder
                    .resizable()
                    .onAppear {
                        loader.load(url: url)
                    }
                    .onDisappear {
                        loader.cancel()
                    }
            }
        }
    }
}

struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImage(url: "https://via.placeholder.com/150")
    }
}
