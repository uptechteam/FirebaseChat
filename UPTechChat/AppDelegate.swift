//
//  AppDelegate.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import ReactiveSwift
import Result

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var chatsViewModel: ChatsViewModel?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        let chatsViewModel = ChatsViewModel()
        self.chatsViewModel = chatsViewModel

        let chatsViewController = ChatsViewController(viewModel: chatsViewModel)
        let navigationController = UINavigationController(rootViewController: chatsViewController)
        navigationController.navigationBar.tintColor = UIColor(red: 12 / 255, green: 110 / 255, blue: 97 / 255, alpha: 1)

        let window = UIWindow()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let pathComponents = url.pathComponents
        if pathComponents.count == 2 {
            chatsViewModel?.joinChatIdentifierObserver.send(value: pathComponents[1])
        }

        return true
    }
}

