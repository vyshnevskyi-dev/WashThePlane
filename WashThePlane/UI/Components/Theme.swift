//
//  Theme.swift
//  WashThePlane
//
//  Дизайн-система: черно-красная палитра, авиационная эстетика.
//

import UIKit

enum Theme {

    // MARK: - Colors

    static let background    = UIColor.black
    static let surface       = UIColor(white: 0.08, alpha: 1.0)   // #141414
    static let card          = UIColor(white: 0.12, alpha: 1.0)   // #1E1E1E
    static let cardHighlight = UIColor(white: 0.16, alpha: 1.0)   // #292929

    static let accent        = UIColor(red: 0.92, green: 0.18, blue: 0.18, alpha: 1)  // #EB2E2E
    static let accentDim     = UIColor(red: 0.92, green: 0.18, blue: 0.18, alpha: 0.15)
    static let accentGlow    = UIColor(red: 1.0,  green: 0.25, blue: 0.25, alpha: 0.6)

    static let textPrimary   = UIColor.white
    static let textSecondary = UIColor(white: 0.60, alpha: 1.0)
    static let textTertiary  = UIColor(white: 0.40, alpha: 1.0)
    static let textAccent    = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1)

    static let success       = UIColor(red: 0.20, green: 0.80, blue: 0.40, alpha: 1)
    static let warning        = UIColor(red: 1.0, green: 0.75, blue: 0.10, alpha: 1)

    static let separator     = UIColor(white: 0.20, alpha: 1.0)

    // MARK: - Typography

    static func titleHero() -> UIFont {
        .systemFont(ofSize: 32, weight: .bold)
    }

    static func titleLarge() -> UIFont {
        .systemFont(ofSize: 24, weight: .bold)
    }

    static func titleMedium() -> UIFont {
        .systemFont(ofSize: 18, weight: .semibold)
    }

    static func body() -> UIFont {
        .systemFont(ofSize: 15, weight: .regular)
    }

    static func bodyBold() -> UIFont {
        .systemFont(ofSize: 15, weight: .semibold)
    }

    static func caption() -> UIFont {
        .systemFont(ofSize: 12, weight: .regular)
    }

    static func priceLarge() -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: 28, weight: .bold)
            .fontDescriptor.withDesign(.rounded) ?? UIFont.systemFont(ofSize: 28, weight: .bold).fontDescriptor
        return UIFont(descriptor: descriptor, size: 28)
    }

    // MARK: - Gradients

    static func accentGradient() -> CAGradientLayer {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(red: 0.92, green: 0.18, blue: 0.18, alpha: 1).cgColor,
            UIColor(red: 0.75, green: 0.10, blue: 0.10, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
        return g
    }
}
