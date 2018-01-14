//
//  ChatViewMessageCell.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

final class ChatViewMessageCell: ChatViewCell, Reusable {
    static let textAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: Constants.FontSize)
    ]
    static let titleAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: Constants.TitleFontSize, weight: .medium)
    ]
    static let statusAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.systemFont(ofSize: Constants.StatusFontSize, weight: .medium)
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
    private let hiddenLabel = UILabel()
    private let statusLabel = UILabel()
    fileprivate let retryButton = UIButton(type: UIButtonType.infoLight)
    private var retryButtonPinToTrailingConstraint: NSLayoutConstraint?
    private var retryButtonPinToLeadingConstraint: NSLayoutConstraint?

    private let content = MutableProperty<ChatViewMessageContent?>(nil)
    private let horizontalPanGestureState = MutableProperty<UIPanGestureRecognizer?>(nil)

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

        titleLabel.textColor = UIColor(red: 253 / 255, green: 145 / 255, blue: 80 / 255, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(textLabel)
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

        hiddenLabel.translatesAutoresizingMaskIntoConstraints = false
        hiddenLabel.textColor = UIColor.lightGray
        hiddenLabel.textAlignment = .left
        hiddenLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(hiddenLabel)
        self.addConstraints([
            hiddenLabel.widthAnchor.constraint(equalToConstant: Constants.HiddenLabelWidth),
            hiddenLabel.leadingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hiddenLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textColor = UIColor.red
        statusLabel.textAlignment = .right
        contentView.addSubview(statusLabel)
        self.addConstraints([
            statusLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.BubbleSideOffset),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.BubbleSideOffset)
        ])

        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.tintColor = UIColor.red
        contentView.addSubview(retryButton)
        let retryButtonPinToTrailingConstraint = retryButton.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 0)
        retryButtonPinToTrailingConstraint.priority = UILayoutPriority.defaultHigh
        self.retryButtonPinToTrailingConstraint = retryButtonPinToTrailingConstraint
        let retryButtonPinToLeadingConstraint = retryButton.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 0)
        retryButtonPinToLeadingConstraint.priority = UILayoutPriority.defaultLow
        self.retryButtonPinToLeadingConstraint = retryButtonPinToLeadingConstraint
        self.addConstraints([
            retryButtonPinToTrailingConstraint,
            retryButtonPinToLeadingConstraint,
            retryButton.widthAnchor.constraint(equalToConstant: 44),
            retryButton.heightAnchor.constraint(equalToConstant: 40),
            retryButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor)
        ])

        content.producer
            .filterMap { $0 }
            .take(duringLifetimeOf: self)
            .startWithValues { [weak self] content in
                guard let `self` = self else { return }

                self.bubbleView.image = content.isCurrentSender ? Constants.CurrentSenderBubbleBackgroundImage : Constants.OtherSenderBubbleBackgroundImage
                self.crookView.color = content.isCurrentSender ? Constants.CurrentSenderBubbleColor : Constants.OtherSenderBubbleColor

                self.textLabel.attributedText = NSAttributedString(string: content.body, attributes: ChatViewMessageCell.textAttributes)
                self.textLabel.textColor = content.isCurrentSender ? UIColor.white : UIColor.black

                self.titleLabel.attributedText = NSAttributedString(string: content.title ?? "", attributes: ChatViewMessageCell.titleAttributes)

                self.crookView.isHidden = !content.isCrooked
                self.crookView.pointsToRight = content.isCurrentSender

                let pinToLeadingConstraintPriority = content.isCurrentSender ? UILayoutPriority.defaultLow : .defaultHigh
                self.pinToLeadingConstraint?.priority = pinToLeadingConstraintPriority
                self.crookViewPinToLeadingConstraint?.priority = pinToLeadingConstraintPriority
                self.retryButtonPinToLeadingConstraint?.priority = pinToLeadingConstraintPriority
                let pinToTrailingConstraintPriority = content.isCurrentSender ? UILayoutPriority.defaultHigh : .defaultLow
                self.pinToTrailingConstraint?.priority = pinToTrailingConstraintPriority
                self.crookViewPinToTrailingConstraint?.priority = pinToTrailingConstraintPriority
                self.retryButtonPinToTrailingConstraint?.priority = pinToTrailingConstraintPriority
                self.setNeedsLayout()
                self.layoutIfNeeded()

                self.hiddenLabel.text = content.hiddenText

                self.statusLabel.attributedText = NSAttributedString(string: content.statusText ?? "", attributes: ChatViewMessageCell.statusAttributes)
                self.statusLabel.textAlignment = content.isCurrentSender ? .right : .left

                self.retryButton.isHidden = !content.isRetryShown
        }

        Signal.combineLatest(
            horizontalPanGestureState.signal.filterMap { $0 },
            content.signal.filterMap { $0 }
            )
            .take(duringLifetimeOf: self)
            .observeValues { [weak self] (panGestureRecognizer, content) in
                guard let `self` = self else { return }

                switch panGestureRecognizer.state {
                case .changed:
                    let translation = panGestureRecognizer.translation(in: self)
                    let hiddenLabelXTranslation = max(0, min(Constants.HiddenLabelWidth, translation.x / 3))
                    let transform = CGAffineTransform(translationX: -hiddenLabelXTranslation, y: 0)

                    self.hiddenLabel.transform = transform
                    self.bubbleView.transform = content.isCurrentSender ? transform : .identity
                    self.crookView.transform = content.isCurrentSender ? transform : .identity
                    self.retryButton.transform = content.isCurrentSender ? transform : .identity
                case .ended:
                    UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
                        self.hiddenLabel.transform = .identity
                        self.bubbleView.transform = .identity
                        self.crookView.transform = .identity
                        self.retryButton.transform = .identity
                    }, completion: nil)
                default:
                    break
                }
        }
    }

    func configure(content: ChatViewMessageContent, horizontalPanGestureState: Signal<UIPanGestureRecognizer, NoError>) {
        self.content.value = content

        self.horizontalPanGestureState <~ horizontalPanGestureState
            .take(until: reactive.prepareForReuse)
    }
}

extension Reactive where Base: ChatViewMessageCell {
    var retryButtonTap: Signal<Void, NoError> {
        return base.retryButton.reactive.controlEvents(.touchUpInside)
            .map { _ in () }
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

        let statusHeight: CGFloat = {
            guard let statusText = content.statusText else { return 0 }
            let textBoundingRect = (statusText as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude), options: [], attributes: statusAttributes, context: nil)
            return CGFloat(ceilf(Float(textBoundingRect.height))) + 4
        }()

        return titleHeight + textHeight + statusHeight + Constants.BubbleTopOffset + Constants.BubbleInsets.top + Constants.BubbleInsets.bottom
    }
}

private enum Constants {
    static let CurrentSenderBubbleColor: UIColor = .init(red: 12 / 255, green: 110 / 255, blue: 97 / 255, alpha: 1)
    static let OtherSenderBubbleColor: UIColor = .init(white: 0.94, alpha: 1)
    static let CurrentSenderBubbleBackgroundImage: UIImage = UIImage.cornerRoundedImage(color: Constants.CurrentSenderBubbleColor, cornerRadius: Constants.BubbleCornerRadius)!
    static let OtherSenderBubbleBackgroundImage: UIImage = UIImage.cornerRoundedImage(color: Constants.OtherSenderBubbleColor, cornerRadius: Constants.BubbleCornerRadius)!
    static let FontSize: CGFloat = 17
    static let TitleFontSize: CGFloat = 14
    static let StatusFontSize: CGFloat = 11
    static let BubbleInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
    static let MaxBubbleWidthRatio: CGFloat = 0.7
    static let BubbleTopOffset: CGFloat = 1
    static let BubbleSideOffset: CGFloat = 12
    static let BubbleCornerRadius: CGFloat = (FontSize + BubbleInsets.top + BubbleInsets.bottom) / 2
    static let HiddenLabelWidth: CGFloat = 60
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
