//
//  ChatViewMessageCell.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

final class ChatViewMessageCell: UICollectionViewCell, Reusable {
    static let textAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: Constants.FontSize)
    ]

    private let bubbleView = UIImageView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let cornerRadius = (Constants.FontSize + Constants.TextInsets.top + Constants.TextInsets.bottom) / 2
        bubbleView.image = UIImage.cornerRoundedImage(color: UIColor(white: 0.9, alpha: 1), cornerRadius: cornerRadius)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        self.addConstraints([
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.BubbleSideOffset),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.BubbleTopOffset),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: Constants.MaxBubbleWidthRatio)
        ])

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0
        bubbleView.addSubview(textLabel)
        self.addConstraints([
            textLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Constants.TextInsets.left),
            textLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Constants.TextInsets.right),
            textLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: Constants.TextInsets.top),
            textLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -Constants.TextInsets.bottom)
        ])
    }

    func configure(with content: ChatViewMessageContent) {
        textLabel.attributedText = NSAttributedString(string: content.body, attributes: ChatViewMessageCell.textAttributes)
    }
}

extension ChatViewMessageCell {
    static func preferredHeight(content: ChatViewMessageContent, collectionViewFrame: CGRect) -> CGFloat {
        let availableWidth = collectionViewFrame.width * Constants.MaxBubbleWidthRatio - 28
        let textBoundingRect = (content.body as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        return textBoundingRect.height + Constants.BubbleTopOffset + Constants.TextInsets.top + Constants.TextInsets.bottom
    }
}

private enum Constants {
    static let FontSize: CGFloat = 18
    static let TextInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
    static let MaxBubbleWidthRatio: CGFloat = 0.7
    static let BubbleTopOffset: CGFloat = 1
    static let BubbleSideOffset: CGFloat = 8
}
