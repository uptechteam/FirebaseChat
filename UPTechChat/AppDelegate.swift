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
import ReactiveSwift
import Result

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        let chatsViewModel = ChatsViewModel(chatsProvider: ChatsProvider())
        let chatsViewController = ChatsViewController(viewModel: chatsViewModel)
        let navigationController = UINavigationController(rootViewController: chatsViewController)

        let window = UIWindow()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
}

