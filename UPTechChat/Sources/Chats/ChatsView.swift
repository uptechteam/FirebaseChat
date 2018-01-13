//
//  ChatsView.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/12/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

final class ChatsView: UIView {
    @IBOutlet weak var tableView: UITableView!
    fileprivate let dataSource = ChatsDataSource()
    fileprivate let (selectedItemIndex, selectedItemIndexObserver) = Signal<Int, NoError>.pipe()
    fileprivate let (leaveItemIndex, leaveItemIndexObserver) = Signal<Int, NoError>.pipe()

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        dataSource.set(tableView: tableView)
    }
}

extension ChatsView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedItemIndexObserver.send(value: indexPath.row)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = dataSource.items[indexPath.row]
        guard case .chat = item else {
            return nil
        }

        let leaveAction = UIContextualAction(style: .normal, title: "Leave") { (_, _, completionHandler) in
            self.leaveItemIndexObserver.send(value: indexPath.row)
            completionHandler(true)
        }

        leaveAction.backgroundColor = UIColor(red: 12 / 255, green: 110 / 255, blue: 97 / 255, alpha: 1)

        return UISwipeActionsConfiguration(actions: [leaveAction])
    }
}

extension Reactive where Base: ChatsView {
    var selectedItemIndex: Signal<Int, NoError> {
        return base.selectedItemIndex
    }

    var leaveItemIndex: Signal<Int, NoError> {
        return base.leaveItemIndex
    }

    var items: BindingTarget<[ChatsViewItem]> {
        return BindingTarget(on: QueueScheduler.main, lifetime: self.lifetime) { [weak base] items in
            base?.dataSource.load(items: items)
        }
    }
}
