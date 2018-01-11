//
//  ChatViewController.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

final class ChatViewController: UIViewController {
    lazy var chatView: ChatView = {
        let nib = UINib(nibName: "ChatView", bundle: Bundle(for: ChatView.self))
        return nib.instantiate(withOwner: self, options: nil).first as! ChatView
    }()

    private let viewModel: ChatViewModel

    override func loadView() {
        self.view = chatView
    }

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatView.endEditing(false)
    }

    private func bindViewModel() {
        chatView.reactive.loadItems(viewModel.items)

        chatView.reactive.clearInputText <~ viewModel.clearInputText

        chatView.reactive.inputTextChanges
            .logEvents()
            .observe(viewModel.inputTextChangesObserver)

        chatView.reactive.sendButtonTap
            .observe(viewModel.sendButtonTapObserver)
    }
}
