//
//  CountriesViewController.swift
//  WashThePlane
//
//  Список европейских стран. При клике — детальный экран с адресами.
//

import UIKit

final class CountriesViewController: UIViewController {

    private let countries = Country.europe
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        title = "Europe"

        let header = UILabel()
        header.text = "Available Countries"
        header.font = Theme.titleLarge()
        header.textColor = Theme.textPrimary
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 60)

        tableView.backgroundColor = .clear
        tableView.separatorColor = Theme.separator
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CountryCell.self, forCellReuseIdentifier: "CountryCell")
        tableView.tableHeaderView = header
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension CountriesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { countries.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath) as! CountryCell
        cell.configure(country: countries[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = CountryDetailViewController(country: countries[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Country Cell

final class CountryCell: UITableViewCell {

    private let card = WTPCard()
    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let countLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear

        let selectedBg = UIView()
        selectedBg.backgroundColor = Theme.accentDim
        selectedBackgroundView = selectedBg

        card.translatesAutoresizingMaskIntoConstraints = false; contentView.addSubview(card)

        flagLabel.font = .systemFont(ofSize: 28)
        nameLabel.font = Theme.bodyBold(); nameLabel.textColor = Theme.textPrimary
        countLabel.font = Theme.caption(); countLabel.textColor = Theme.textTertiary

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = Theme.textTertiary
        chevron.translatesAutoresizingMaskIntoConstraints = false

        [flagLabel, nameLabel, countLabel, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false; card.addSubview($0)
        }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            flagLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            flagLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            flagLabel.widthAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -8),

            countLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 8),
            chevron.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(country: Country) {
        flagLabel.text = country.flag
        nameLabel.text = country.name
        let n = country.airports.count
        countLabel.text = n == 1 ? "1 location" : "\(n) locations"
    }
}

// MARK: - Country Detail

final class CountryDetailViewController: UIViewController {

    private let country: Country

    init(country: Country) {
        self.country = country
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        title = "\(country.flag) \(country.name)"

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
        stack.axis = .vertical; stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        let subtitle = UILabel()
        subtitle.text = "WashThePlane service locations in \(country.name):"
        subtitle.font = Theme.body()
        subtitle.textColor = Theme.textSecondary
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)

        for (i, airport) in country.airports.enumerated() {
            let card = WTPCard()

            let num = UILabel()
            num.text = "\(i + 1)"
            let d = UIFont.systemFont(ofSize: 14, weight: .bold).fontDescriptor.withDesign(.monospaced)
                ?? UIFont.systemFont(ofSize: 14, weight: .bold).fontDescriptor
            num.font = UIFont(descriptor: d, size: 14)
            num.textColor = Theme.accent
            num.translatesAutoresizingMaskIntoConstraints = false

            let addr = UILabel()
            addr.text = airport
            addr.font = Theme.body()
            addr.textColor = Theme.textPrimary
            addr.numberOfLines = 0
            addr.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(num); card.addSubview(addr)

            NSLayoutConstraint.activate([
                num.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                num.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                num.widthAnchor.constraint(equalToConstant: 24),

                addr.leadingAnchor.constraint(equalTo: num.trailingAnchor, constant: 12),
                addr.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                addr.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                addr.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
            ])

            stack.addArrangedSubview(card)
        }

        if country.washingSurchargePct > 0 {
            let spacer = UIView(); spacer.heightAnchor.constraint(equalToConstant: 10).isActive = true
            stack.addArrangedSubview(spacer)

            let note = UILabel()
            note.text = "🌍 Service surcharge in \(country.name): +\(Int(country.washingSurchargePct))%"
            note.font = Theme.caption()
            note.textColor = Theme.textAccent
            note.textAlignment = .center
            stack.addArrangedSubview(note)
        }
    }
}
