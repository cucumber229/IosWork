//
//  SceneDelegate.swift
//  IosControl
//
//  Created by Артур Мавликаев on 21.11.2024.
//

// SceneDelegate.swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let galleryVC = GalleryViewController()
        window?.rootViewController = galleryVC
        window?.makeKeyAndVisible()
    }
}

