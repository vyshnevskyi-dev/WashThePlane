//
//  WTPButton.swift
//  WashThePlane
//
//  Кастомные кнопки в стиле Wash the Plane.
//

import UIKit

final class WTPButton: UIButton {

    enum Style {
        case primary    // красная заливка
        case secondary  // красная обводка
        case ghost      // прозрачная с текстом
    }

    private let buttonStyle: Style
    private var gradientLayer: CAGradientLayer?

    init(title: String, style: Style = .primary) {
        self.buttonStyle = style
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.font = Theme.bodyBold()
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        heightAnchor.constraint(equalToConstant: 52).isActive = true

        switch buttonStyle {
        case .primary:
            backgroundColor = Theme.accent
            setTitleColor(.white, for: .normal)
            layer.shadowColor = Theme.accentGlow.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 12
            layer.shadowOpacity = 0.4

        case .secondary:
            backgroundColor = .clear
            layer.borderWidth = 1.5
            layer.borderColor = Theme.accent.cgColor
            setTitleColor(Theme.accent, for: .normal)

        case .ghost:
            backgroundColor = .clear
            setTitleColor(Theme.textSecondary, for: .normal)
        }

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if buttonStyle == .primary {
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 14).cgPath
        }
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) { self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97) }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            self.transform = .identity
        }
    }
}

// MARK: - Card View

final class WTPCard: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Theme.card
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 0.5
        layer.borderColor = Theme.separator.cgColor
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Status Badge

final class WTPBadge: UIView {
    enum Kind { case confirmed, progress, done, cancelled }

    init(text: String, kind: Kind) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous

        let label = UILabel()
        label.text = text.uppercased()
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        switch kind {
        case .confirmed:
            backgroundColor = Theme.warning.withAlphaComponent(0.2)
            label.textColor = Theme.warning
        case .progress:
            backgroundColor = Theme.accent.withAlphaComponent(0.2)
            label.textColor = Theme.textAccent
        case .done:
            backgroundColor = Theme.success.withAlphaComponent(0.2)
            label.textColor = Theme.success
        case .cancelled:
            backgroundColor = Theme.textTertiary.withAlphaComponent(0.2)
            label.textColor = Theme.textTertiary
        }

        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
