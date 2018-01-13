//
//  ChatsInfoCell.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/13/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

final class ChatsInfoCell: UITableViewCell, Reusable {
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private func setup() {
        self.selectionStyle = .none

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.lightGray
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        contentView.addSubview(stackView)
        contentView.addConstraints([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, message: String) {
        self.titleLabel.text = title
        self.messageLabel.text = message
    }
}
