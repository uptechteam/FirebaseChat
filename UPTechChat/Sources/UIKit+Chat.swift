//
//  UIKit+Chat.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(for error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIImage {
    static func cornerRoundedImage(color: UIColor, cornerRadius: CGFloat) -> UIImage? {
        let diameter = cornerRadius * 2

        // Setup context.
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.saveGState()

        // Draw circle.
        let circleRect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: circleRect)

        context.restoreGState()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        let capInsets = UIEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius)
        let resizableImage = image?.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
        return resizableImage
    }
}
