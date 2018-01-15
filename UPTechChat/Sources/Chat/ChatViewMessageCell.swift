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
import Kingfisher

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

    private let containerView = UIView()
    private let bubbleContainerView = UIView()
    private let bubbleView = UIImageView()
    private let titleLabel = UILabel()
    private let textLabel = UILabel()
    private let stackView = UIStackView()
    private let crookView = CrookView()
    private let imageView = UIImageView()
    private var imageViewWidthConstraint: NSLayoutConstraint?
    private var imageViewHeightConstraint: NSLayoutConstraint?
    private let hiddenLabel = UILabel()
    private let statusLabel = UILabel()
    fileprivate let retryButton = UIButton(type: UIButtonType.infoLight)

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
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        self.addConstraints([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        bubbleContainerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bubbleContainerView)
        self.addConstraints([
            bubbleContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bubbleContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.BubbleTopOffset)
        ])

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleContainerView.addSubview(bubbleView)
        self.addConstraints([
            bubbleView.trailingAnchor.constraint(equalTo: bubbleContainerView.trailingAnchor, constant: -Constants.BubbleSideOffset),
            bubbleView.topAnchor.constraint(equalTo: bubbleContainerView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: bubbleContainerView.bottomAnchor),
            bubbleView.leadingAnchor.constraint(equalTo: bubbleContainerView.leadingAnchor),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, multiplier: Constants.MaxBubbleWidthRatio)
        ])

        titleLabel.textColor = UIColor(red: 253 / 255, green: 145 / 255, blue: 80 / 255, alpha: 1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.numberOfLines = 0

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        let imageViewWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 200)
        imageViewWidthConstraint.priority = .defaultHigh
        imageView.addConstraints([imageView.heightAnchor.constraint(equalToConstant: 200), imageViewWidthConstraint])

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(imageView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .trailing
        bubbleView.addSubview(stackView)
        self.addConstraints([
            stackView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: Constants.BubbleInsets.left),
            stackView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -Constants.BubbleInsets.right),
            stackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: Constants.BubbleInsets.top),
            stackView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -Constants.BubbleInsets.bottom)
        ])

        crookView.translatesAutoresizingMaskIntoConstraints = false
        containerView.insertSubview(crookView, at: 0)
        self.addConstraints([
            crookView.widthAnchor.constraint(equalToConstant: 20),
            crookView.heightAnchor.constraint(equalToConstant: 16),
            crookView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 9),
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
        containerView.addSubview(statusLabel)
        self.addConstraints([
            statusLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.BubbleSideOffset),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.BubbleSideOffset)
        ])

        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.tintColor = UIColor.red
        containerView.addSubview(retryButton)
        self.addConstraints([
            retryButton.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 0),
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

                switch content.type {
                case .text(let text):
                    self.textLabel.isHidden = false
                    self.imageView.isHidden = true
                    self.textLabel.attributedText = NSAttributedString(string: text, attributes: ChatViewMessageCell.textAttributes)
                case .image(let image):
                    self.textLabel.isHidden = true
                    self.imageView.isHidden = false
                    switch image {
                    case .raw(let data, _):
                        self.imageView.image = UIImage(data: data)
                    case .url(let url):
                        self.imageView.kf.setImage(with: url, options: [.processor(ResizingImageProcessor(referenceSize: CGSize(width: 200, height: 200), mode: .aspectFill))])
                    }
                }

                self.textLabel.textColor = content.isCurrentSender ? UIColor.white : UIColor.black

                self.titleLabel.attributedText = NSAttributedString(string: content.title ?? "", attributes: ChatViewMessageCell.titleAttributes)

                self.crookView.isHidden = !content.isCrooked

                self.hiddenLabel.text = content.hiddenText

                self.statusLabel.attributedText = NSAttributedString(string: content.statusText ?? "", attributes: ChatViewMessageCell.statusAttributes)

                self.retryButton.isHidden = !content.isRetryShown

                let mirrorTransform = CGAffineTransform(scaleX: content.isCurrentSender ? 1 : -1, y: 1)
                self.containerView.transform = mirrorTransform
                self.statusLabel.transform = mirrorTransform
                self.titleLabel.transform = mirrorTransform
                self.textLabel.transform = mirrorTransform
                self.retryButton.transform = mirrorTransform
                self.imageView.transform = mirrorTransform
                self.statusLabel.textAlignment = content.isCurrentSender ? .right : .left
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
            guard let title = content.title else {
                return 0
            }

            let textBoundingRect = (title as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude), options: [], attributes: titleAttributes, context: nil)
            return CGFloat(ceilf(Float(textBoundingRect.height)))
        }()

        let textHeight: CGFloat = {
            guard case .text(let text) = content.type else {
                return 0
            }

            let textBoundingRect = (text as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: textAttributes, context: nil)
            return CGFloat(ceilf(Float(textBoundingRect.height)))
        }()

        let imageHeight: CGFloat = {
            guard case .image = content.type else {
                return 0
            }

            return 200
        }()

        let statusHeight: CGFloat = {
            guard let statusText = content.statusText else { return 0 }
            let textBoundingRect = (statusText as NSString).boundingRect(with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude), options: [], attributes: statusAttributes, context: nil)
            return CGFloat(ceilf(Float(textBoundingRect.height))) + 4
        }()

        return titleHeight + textHeight + imageHeight + statusHeight + Constants.BubbleTopOffset + Constants.BubbleInsets.top + Constants.BubbleInsets.bottom
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

        color.setFill()
        bezierPath.fill()
    }
}
