//
//  LandscapeViewController.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/6/23.
//

import SwiftUI
import UIKit

struct LandscapeViewController<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> LandscapeVC {
        let viewController = LandscapeVC()
        viewController.hostingController.rootView = AnyView(content)
        return viewController
    }

    func updateUIViewController(_ uiViewController: LandscapeVC, context: Context) {}

    class LandscapeVC: UIViewController {
        var hostingController: UIHostingController<AnyView> = UIHostingController(rootView: AnyView(EmptyView()))

        override func viewDidLoad() {
            super.viewDidLoad()
            self.view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            hostingController.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            hostingController.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .landscape
        }

        override var shouldAutorotate: Bool {
            return true
        }
    }
}

