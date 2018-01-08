//
//  ChatViewController.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import UIKit

final class ChatViewController: UIViewController {
    lazy var chatView: ChatView = {
        let nib = UINib(nibName: "ChatView", bundle: Bundle(for: ChatView.self))
        return nib.instantiate(withOwner: self, options: nil).first as! ChatView
    }()

    override func loadView() {
        self.view = chatView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
