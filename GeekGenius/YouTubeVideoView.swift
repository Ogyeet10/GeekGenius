//
//  YouTubeVideoView.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 4/18/23.
//

import SwiftUI
import WebKit

struct YouTubeVideoView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin: 0; background-color: #000; }
                iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
            </style>
            <script>
                document.addEventListener('DOMContentLoaded', function () {
                    document.body.style.webkitTouchCallout='none';
                    document.body.style.webkitUserSelect='none';
                }, false);
            </script>
        </head>
        <body>
            <iframe src="https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=1&rel=0&modestbranding=1" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        </body>
        </html>
        """

        
        
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, WKNavigationDelegate {
            var parent: YouTubeVideoView

            init(_ parent: YouTubeVideoView) {
                self.parent = parent
            }
        }
    }


struct YouTubeVideoView_Previews: PreviewProvider {
    static var previews: some View {
        YouTubeVideoView(videoID: "1jsEsnC8BCU") // Replace with a valid YouTube video ID
            .overlay(OverlayView())
    }
}




