//
//  ChatsViewController.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/12/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import ReactiveSwift

final class ChatsViewController: UIViewController {
    private lazy var chatsView: ChatsView = {
        let nib = UINib(nibName: "ChatsView", bundle: Bundle(for: ChatsView.self))
        return nib.instantiate(withOwner: self, options: nil).first as! ChatsView
    }()

    private let viewModel: ChatsViewModel

    override func loadView() {
        self.view = chatsView
    }

    init(viewModel: ChatsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Chats"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(ChatsViewController.newChatBarButtonItemPressed(_:)))

        bindViewModel()
    }

    private func bindViewModel() {
        chatsView.reactive.selectedItemIndex
            .observe(viewModel.selectedItemIndexObserver)

        chatsView.reactive.items <~ viewModel.items

        viewModel.showErrorAlert
            .take(duringLifetimeOf: self)
            .observeValues { [weak self] in self?.showAlert(title: $0, message: $1) }

        viewModel.showChat
            .take(duringLifetimeOf: self)
            .observeValues { [weak self] chatEntity in
                let chatViewController = ChatViewController(chatEntity: chatEntity)
                self?.navigationController?.pushViewController(chatViewController, animated: true)
            }
    }

    @objc private func newChatBarButtonItemPressed(_ barButtonItem: UIBarButtonItem) {
        let alertController = UIAlertController(title: "New chat", message: "Please enter the name of new chat", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Chat Name"
        }
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action) in
            let chatName = alertController.textFields?.first?.text ?? ""
            self.viewModel.createChatObserver.send(value: chatName)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
