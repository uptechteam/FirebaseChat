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
}

extension Reactive where Base: ChatsView {
    var selectedItemIndex: Signal<Int, NoError> {
        return base.selectedItemIndex
    }

    var items: BindingTarget<[ChatsViewItem]> {
        return BindingTarget(on: QueueScheduler.main, lifetime: self.lifetime) { [weak base] items in
            base?.dataSource.load(items: items)
        }
    }
}
