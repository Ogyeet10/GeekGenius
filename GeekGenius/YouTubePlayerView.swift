//
//  YouTubePlayerView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/6/23.
//

import SwiftUI
import YouTubeiOSPlayerHelper

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        playerView.load(withVideoId: videoID, playerVars: ["playsinline": 1, "autoplay": 1, "rel": 0])
        return playerView
    }

    func updateUIView(_ uiView: YTPlayerView, context: Context) {}
}


struct YouTubePlayerView_Previews: PreviewProvider {
    static var previews: some View {
        YouTubePlayerView(videoID: "1jsEsnC8BC")
    }
}
