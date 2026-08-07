//
//  OrderCreateViewController.swift
//  WashThePlane
//
//  Экран создания заказа: выбор страны → аэропорта → регистрация самолёта → подтверждение.
//

import UIKit

final class OrderCreateViewController: UIViewController {

    private let package: WashPackage
    private var selectedCountry: Country?
    private var selectedAirport: String?
    private var registration: String = ""

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let regField = UITextField()

    init(package: WashPackage) {
        self.package = package
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        setupUI()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        // Package header
        let pkgCard = WTPCard()
        let pkgStack = UIStackView()
        pkgStack.axis = .horizontal
        pkgStack.spacing = 14
        pkgStack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: package.icon))
        icon.tintColor = Theme.accent
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let info = UIStackView()
        info.axis = .vertical
        info.spacing = 4

        let nameL = UILabel()
        nameL.text = package.name; nameL.font = Theme.titleMedium(); nameL.textColor = Theme.textPrimary
        let priceL = UILabel()
        priceL.text = "€\(Int(package.price))"; priceL.font = Theme.priceLarge(); priceL.textColor = Theme.textAccent

        info.addArrangedSubview(nameL)
        info.addArrangedSubview(priceL)

        pkgStack.addArrangedSubview(icon)
        pkgStack.addArrangedSubview(info)
        pkgCard.addSubview(pkgStack)

        NSLayoutConstraint.activate([
            pkgCard.heightAnchor.constraint(equalToConstant: 80),
            icon.widthAnchor.constraint(equalToConstant: 36), icon.heightAnchor.constraint(equalToConstant: 36),
            pkgStack.leadingAnchor.constraint(equalTo: pkgCard.leadingAnchor, constant: 16),
            pkgStack.centerYAnchor.constraint(equalTo: pkgCard.centerYAnchor)
        ])
        contentStack.addArrangedSubview(pkgCard)

        // Country picker
        sectionTitle("Select Country")
        let countryCard = WTPCard()
        let countryBtn = buildPickerButton(placeholder: "Choose country...", tag: 1)
        countryCard.addSubview(countryBtn)
        NSLayoutConstraint.activate([
            countryCard.heightAnchor.constraint(equalToConstant: 52),
            countryBtn.leadingAnchor.constraint(equalTo: countryCard.leadingAnchor, constant: 16),
            countryBtn.trailingAnchor.constraint(equalTo: countryCard.trailingAnchor, constant: -16),
            countryBtn.centerYAnchor.constraint(equalTo: countryCard.centerYAnchor)
        ])
        contentStack.addArrangedSubview(countryCard)

        // Airport picker (disabled until country selected)
        sectionTitle("Select Airport")
        let airportCard = WTPCard()
        let airportBtn = buildPickerButton(placeholder: "Select country first...", tag: 2)
        airportBtn.isEnabled = false
        airportBtn.tag = 2
        airportCard.addSubview(airportBtn)
        NSLayoutConstraint.activate([
            airportCard.heightAnchor.constraint(equalToConstant: 52),
            airportBtn.leadingAnchor.constraint(equalTo: airportCard.leadingAnchor, constant: 16),
            airportBtn.trailingAnchor.constraint(equalTo: airportCard.trailingAnchor, constant: -16),
            airportBtn.centerYAnchor.constraint(equalTo: airportCard.centerYAnchor)
        ])
        contentStack.addArrangedSubview(airportCard)

        // Registration
        sectionTitle("Aircraft Registration")
        let regCard = WTPCard()
        regField.placeholder = "e.g. N123AB"
        regField.font = Theme.body()
        regField.textColor = Theme.textPrimary
        regField.attributedPlaceholder = NSAttributedString(
            string: "e.g. N123AB",
            attributes: [.foregroundColor: Theme.textTertiary]
        )
        regField.translatesAutoresizingMaskIntoConstraints = false
        regField.addTarget(self, action: #selector(regChanged), for: .editingChanged)
        regCard.addSubview(regField)
        NSLayoutConstraint.activate([
            regCard.heightAnchor.constraint(equalToConstant: 52),
            regField.leadingAnchor.constraint(equalTo: regCard.leadingAnchor, constant: 16),
            regField.trailingAnchor.constraint(equalTo: regCard.trailingAnchor, constant: -16),
            regField.centerYAnchor.constraint(equalTo: regCard.centerYAnchor)
        ])
        contentStack.addArrangedSubview(regCard)

        // Price summary
        let spacer = UIView(); spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        contentStack.addArrangedSubview(spacer)

        let summaryCard = WTPCard()
        let sumStack = UIStackView(); sumStack.axis = .vertical; sumStack.spacing = 8
        sumStack.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(sumStack)

        func sumRow(_ key: String, _ val: String) -> UIStackView {
            let r = UIStackView(); r.axis = .horizontal; r.distribution = .equalSpacing
            let k = UILabel(); k.text = key; k.font = Theme.body(); k.textColor = Theme.textSecondary
            let v = UILabel(); v.text = val; v.font = Theme.bodyBold(); v.textColor = Theme.textPrimary
            r.addArrangedSubview(k); r.addArrangedSubview(v)
            return r
        }
        sumStack.addArrangedSubview(sumRow("Package", "€\(Int(package.price))"))
        sumStack.addArrangedSubview(sumRow("Est. duration", package.durationMinutes > 0 ? "\(package.durationMinutes) min" : "Monthly"))
        sumStack.addArrangedSubview(sumRow("Country surcharge", selectedCountry.map { "\(Int($0.washingSurchargePct))%" } ?? "—"))

        let sep = UIView(); sep.backgroundColor = Theme.separator; sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        sumStack.addArrangedSubview(sep)

        let total = selectedCountry.map { Double(package.price) * (1 + $0.washingSurchargePct/100) } ?? package.price
        sumStack.addArrangedSubview(sumRow("TOTAL", "€\(Int(total))"))

        NSLayoutConstraint.activate([
            summaryCard.heightAnchor.constraint(equalToConstant: 180),
            sumStack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            sumStack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -16),
            sumStack.centerYAnchor.constraint(equalTo: summaryCard.centerYAnchor)
        ])
        contentStack.addArrangedSubview(summaryCard)

        // Place Order button
        let btn = WTPButton(title: "Place Order", style: .primary)
        btn.addTarget(self, action: #selector(placeOrder), for: .touchUpInside)
        contentStack.addArrangedSubview(btn)
    }

    private func sectionTitle(_ text: String) {
        let l = UILabel()
        l.text = text; l.font = Theme.caption(); l.textColor = Theme.textSecondary
        contentStack.addArrangedSubview(l)
    }

    private func buildPickerButton(placeholder: String, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(placeholder, for: .normal)
        btn.titleLabel?.font = Theme.body()
        btn.contentHorizontalAlignment = .leading
        btn.setTitleColor(Theme.textTertiary, for: .normal)
        btn.tag = tag
        btn.addTarget(self, action: #selector(pickerTapped(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    @objc private func pickerTapped(_ sender: UIButton) {
        if sender.tag == 1 {
            showCountryPicker(sender)
        } else if sender.tag == 2, let country = selectedCountry {
            showAirportPicker(sender, country: country)
        }
    }

    private func showCountryPicker(_ sender: UIButton) {
        let alert = UIAlertController(title: "Select Country", message: nil, preferredStyle: .actionSheet)
        for country in Country.europe {
            alert.addAction(UIAlertAction(title: "\(country.flag) \(country.name)", style: .default) { [weak self] _ in
                self?.selectedCountry = country
                sender.setTitle("\(country.flag) \(country.name)", for: .normal)
                sender.setTitleColor(Theme.textPrimary, for: .normal)

                // Enable airport picker
                if let airportBtn = self?.view.viewWithTag(2) as? UIButton {
                    airportBtn.isEnabled = true
                    airportBtn.setTitle("Select airport...", for: .normal)
                }
                self?.selectedAirport = nil
                self?.rebuildSummaryIfNeeded()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showAirportPicker(_ sender: UIButton, country: Country) {
        let alert = UIAlertController(title: "\(country.flag) \(country.name)", message: "Select Airport", preferredStyle: .actionSheet)
        for airport in country.airports {
            alert.addAction(UIAlertAction(title: airport, style: .default) { [weak self] _ in
                self?.selectedAirport = airport
                sender.setTitle(airport, for: .normal)
                sender.setTitleColor(Theme.textPrimary, for: .normal)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func regChanged() {
        registration = regField.text ?? ""
    }

    private func rebuildSummaryIfNeeded() {
        contentStack.arrangedSubviews.forEach { if $0 is WTPCard { $0.removeFromSuperview() } }
        // In a real app we'd update the summary inline; for now just rebuild
    }

    @objc private func placeOrder() {
        guard let country = selectedCountry, let airport = selectedAirport, !registration.isEmpty else {
            let alert = UIAlertController(title: "Missing Info", message: "Please fill in country, airport, and registration.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Success
        let alert = UIAlertController(title: "✅ Order Placed", message: "\(package.name) for \(registration) at \(airport). Crew will be dispatched shortly.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Track Order", style: .default) { [weak self] _ in
            self?.dismiss(animated: true) {
                // Switch to Orders tab
                if let tabBar = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
                    tabBar.selectedIndex = 1
                }
            }
        })
        present(alert, animated: true)
    }
}
