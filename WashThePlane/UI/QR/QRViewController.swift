//
//  QRViewController.swift
//  WashThePlane
//
//  Персональный QR-код пользователя для быстрого чекина.
//

import UIKit
import CoreImage.CIFilterBuiltins

final class QRViewController: UIViewController {

    private let userID = "WTP-\(UUID().uuidString.prefix(8).uppercased())"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 24; stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 40),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        let title = UILabel()
        title.text = "Your WashPass™"
        title.font = Theme.titleHero()
        title.textColor = Theme.textPrimary
        stack.addArrangedSubview(title)

        let sub = UILabel()
        sub.text = "Show this QR at the hangar for express check-in"
        sub.font = Theme.body()
        sub.textColor = Theme.textSecondary
        sub.textAlignment = .center
        sub.numberOfLines = 2
        stack.addArrangedSubview(sub)

        // QR Card
        let qrCard = WTPCard()
        qrCard.backgroundColor = .white

        let qrImage = generateQR(from: userID)
        let qrView = UIImageView(image: qrImage)
        qrView.translatesAutoresizingMaskIntoConstraints = false
        qrView.contentMode = .scaleAspectFit
        qrCard.addSubview(qrView)

        NSLayoutConstraint.activate([
            qrCard.widthAnchor.constraint(equalToConstant: 260),
            qrCard.heightAnchor.constraint(equalToConstant: 260),
            qrView.centerXAnchor.constraint(equalTo: qrCard.centerXAnchor),
            qrView.centerYAnchor.constraint(equalTo: qrCard.centerYAnchor),
            qrView.widthAnchor.constraint(equalToConstant: 210),
            qrView.heightAnchor.constraint(equalToConstant: 210)
        ])
        stack.addArrangedSubview(qrCard)

        let idLabel = UILabel()
        idLabel.text = userID
        let monoDesc = UIFont.systemFont(ofSize: 20, weight: .bold).fontDescriptor.withDesign(.monospaced)
            ?? UIFont.systemFont(ofSize: 20, weight: .bold).fontDescriptor
        idLabel.font = UIFont(descriptor: monoDesc, size: 20)
        idLabel.textColor = Theme.textAccent
        stack.addArrangedSubview(idLabel)

        // Info card
        let info = WTPCard()
        let iStack = UIStackView(); iStack.axis = .vertical; iStack.spacing = 10
        iStack.translatesAutoresizingMaskIntoConstraints = false
        info.addSubview(iStack)

        func infoRow(_ icon: String, _ text: String) -> UIStackView {
            let r = UIStackView(); r.axis = .horizontal; r.spacing = 12
            let img = UIImageView(image: UIImage(systemName: icon))
            img.tintColor = Theme.accent; img.contentMode = .scaleAspectFit
            img.translatesAutoresizingMaskIntoConstraints = false
            img.widthAnchor.constraint(equalToConstant: 20).isActive = true

            let l = UILabel(); l.text = text; l.font = Theme.body(); l.textColor = Theme.textSecondary
            r.addArrangedSubview(img); r.addArrangedSubview(l)
            return r
        }

        iStack.addArrangedSubview(infoRow("checkmark.shield.fill", "Priority service"))
        iStack.addArrangedSubview(infoRow("clock.fill", "Skip the queue"))
        iStack.addArrangedSubview(infoRow("creditcard.fill", "Auto-billing enabled"))
        iStack.addArrangedSubview(infoRow("airplane", "Valid at all European locations"))

        NSLayoutConstraint.activate([
            info.heightAnchor.constraint(equalToConstant: 180),
            iStack.leadingAnchor.constraint(equalTo: info.leadingAnchor, constant: 16),
            iStack.trailingAnchor.constraint(equalTo: info.trailingAnchor, constant: -16),
            iStack.centerYAnchor.constraint(equalTo: info.centerYAnchor)
        ])
        stack.addArrangedSubview(info)
    }

    private func generateQR(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let output = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaled = output.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
