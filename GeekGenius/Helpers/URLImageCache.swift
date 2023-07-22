//
//  URLImageCache.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/5/23.
//

import SwiftUI
import Combine

class URLImageCache: ObservableObject {
    @Published var cache = NSCache<NSURL, UIImage>()

    static let shared = URLImageCache()
}

