//
//  ViewController.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let database = Database.database().reference()
        let provider = Provider<Chat>(reference: database.child("chats"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

