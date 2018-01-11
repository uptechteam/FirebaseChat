//
//  ChatViewMessageCell.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

final class ChatViewMessageCell: ChatViewCell, Reusable {
    static let textAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: Constants.FontSize)
    ]
    static let titleAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: Constants.TitleFontSize, weight: .medium)
    ]

    private let bubbleView = UIImageView()
    private let titleLabel = UILabel()
    private let textLabel = UILabel()
    private let stackView = UIStackView()
    private var pinToLeadingConstraint: NSLayoutConstraint?
    private var pinToTrailingConstraint: NSLayoutConstraint?
    private let crookView = CrookView()
    private var crookViewPinToLeadingConstraint: NSLayoutConstraint?
    private var crookViewPinToTrailingConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        let pinToLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.BubbleSideOffset)
        pinToLeadingConstraint.priority = UILayoutPriority.defaultLow
        self.pinToLeadingConstraint = pinToLeadingConstraint
        let pinToTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.BubbleSideOffset)
        pinToTrailingConstraint.priority = UILayoutPriority.defaultHigh
        self.pinToTrailingConstraint = pinToTrailingConstraint
        self.addConstraints([
            pinToLeadingConstraint,
            pinToTrailingConstraint,
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.BubbleTopOffset),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: Constants.MaxBubbleWidthRatio)
        ])

        titleLabel.textColor = UIColor(red: 21 / 255, green: 152 / 255, blue: 133 / 255, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.attributedText = NSAttributedString(string: "Evgeny Matviyenko", attributes: ChatViewMessageCell.titleAttributes)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        bubbleView.addSubview(stackView)
        self.addConstraints([
            stackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Constants.BubbleInsets.left),
            stackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Constants.BubbleInsets.right),
            stackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: Constants.BubbleInsets.top),
            stackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -Constants.BubbleInsets.bottom)
        ])

        crookView.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(crookView, at: 0)
        let crookViewPinToLeadingConstraint = crookView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -9)
        crookViewPinToLeadingConstraint.priority = UILayoutPriority.defaultLow
        self.crookViewPinToLeadingConstraint = crookViewPinToLeadingConstraint
        let crookViewPinToTrailingConstraint = crookView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 9)
        crookViewPinToTrailingConstraint.priority = UILayoutPriority.defaultHigh
        self.crookViewPinToTrailingConstraint = crookViewPinToTrailingConstraint
        self.addConstraints([
            crookView.widthAnchor.constraint(equalToConstant: 20),
            crookView.heightAnchor.constraint(equalToConstant: 16),
            crookViewPinToLeadingConstraint,
            crookViewPinToTrailingConstraint,
            crookView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0)
        ])
    }

    private func set(backgroundColor: UIColor) {
        let cornerRadius = (Constants.FontSize + Constants.BubbleInsets.top + Constants.BubbleInsets.bottom) / 2
        bubbleView.image = UIImage.cornerRoundedImage(color: backgroundColor, cornerRadius: cornerRadius)
        crookView.color = backgroundColor
    }

    func configure(with content: ChatViewMessageContent) {
        set(backgroundColor: content.isCurrentSender ? UIColor(red: 12 / 255, green: 110 / 255, blue: 97 / 255, alpha: 1) : UIColor(white: 0.95, alpha: 1))

        textLabel.attributedText = NSAttributedString(string: content.body, attributes: ChatViewMessageCell.textAttributes)
        textLabel.textColor = content.isCurrentSender ? UIColor.white : UIColor.black

        crookView.isHidden = !content.isCrooked
        crookView.pointsToRight = content.isCurrentSender

        let pinToLeadingConstraintPriority = content.isCurrentSender ? UILayoutPriority.defaultLow : .defaultHigh
        pinToLeadingConstraint?.priority = pinToLeadingConstraintPriority
        crookViewPinToLeadingConstraint?.priority = pinToLeadingConstraintPriority
        let pinToTrailingConstraintPriority = content.isCurrentSender ? UILayoutPriority.defaultHigh : .defaultLow
        pinToTrailingConstraint?.priority = pinToTrailingConstraintPriority
        crookViewPinToTrailingConstraint?.priority = pinToTrailingConstraintPriority
        self.setNeedsLayout()
        self.layoutIfNeeded()

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let title = content.title {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: ChatViewMessageCell.titleAttributes)
            stackView.addArrangedSubview(titleLabel)
        }
        stackView.addArrangedSubview(textLabel)
    }
}

extension ChatViewMessageCell {
    static func preferredHeight(content: ChatViewMessageContent, collectionViewFrame: CGRect) -> CGFloat {
        let availableWidth = collectionViewFrame.width * Constants.MaxBubbleWidthRatio - 28

        let titleHeight: CGFloat = {
            guard let title = content.title else { return 0 }
            let textBoundingRect = (title as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude), options: [], attributes: titleAttributes, context: nil)
            return CGFloat(ceilf(Float(textBoundingRect.height)))
        }()

        let textHeight: CGFloat = {
            let textBoundingRect = (content.body as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: textAttributes, context: nil)
            return CGFloat(ceilf(Float(textBoundingRect.height)))
        }()

        return titleHeight + textHeight + Constants.BubbleTopOffset + Constants.BubbleInsets.top + Constants.BubbleInsets.bottom
    }
}

private enum Constants {
    static let FontSize: CGFloat = 17
    static let TitleFontSize: CGFloat = 14
    static let BubbleInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
    static let MaxBubbleWidthRatio: CGFloat = 0.7
    static let BubbleTopOffset: CGFloat = 1
    static let BubbleSideOffset: CGFloat = 12
}

private class CrookView: UIView {
    var color = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }

    var pointsToRight = true {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func draw(_ rect: CGRect) {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 0))
        bezierPath.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height), controlPoint: CGPoint(x: 0, y: rect.height))
        bezierPath.addQuadCurve(to: CGPoint(x: rect.width / 2, y: 0), controlPoint: CGPoint(x: rect.width / 2, y: rect.height))
        bezierPath.close()

        if !pointsToRight {
            bezierPath.apply(CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -rect.width, y: 0))
        }

        color.setFill()
        bezierPath.fill()
    }
}
