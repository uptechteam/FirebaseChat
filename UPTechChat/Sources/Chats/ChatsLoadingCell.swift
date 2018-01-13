//
//  ChatsLoadingCell.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/13/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

final class ChatsLoadingCell: UITableViewCell, Reusable {
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private func setup() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicator)
        self.addConstraints([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func startAnimating() {
        activityIndicator.startAnimating()
    }
}
