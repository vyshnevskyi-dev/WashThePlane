//
//  OrdersViewController.swift
//  WashThePlane
//
//  Список заказов + статус-трекер.
//

import UIKit

final class OrdersViewController: UIViewController {

    private var orders: [Order] = Order.samples
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        title = "My Orders"

        tableView.backgroundColor = .clear
        tableView.separatorColor = Theme.separator
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OrderCell.self, forCellReuseIdentifier: "OrderCell")
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

extension OrdersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderCell", for: indexPath) as! OrderCell
        cell.configure(with: orders[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 130 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = OrderDetailViewController(order: orders[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Order Cell

final class OrderCell: UITableViewCell {
    private let card = WTPCard()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let regLabel = UILabel()
    private let badge: WTPBadge

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        badge = WTPBadge(text: "", kind: .confirmed)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        iconView.tintColor = Theme.accent
        iconView.contentMode = .scaleAspectFit

        nameLabel.font = Theme.bodyBold()
        nameLabel.textColor = Theme.textPrimary

        regLabel.font = Theme.caption()
        regLabel.textColor = Theme.textSecondary

        let stack = UIStackView(arrangedSubviews: [nameLabel, regLabel])
        stack.axis = .vertical; stack.spacing = 4

        [iconView, stack, badge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            stack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: badge.leadingAnchor, constant: -8),

            badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            badge.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with order: Order) {
        iconView.image = UIImage(systemName: order.package.icon)
        nameLabel.text = order.package.name
        regLabel.text = "\(order.aircraftRegistration) • \(order.airport)"
    }
}

// MARK: - Order Detail

final class OrderDetailViewController: UIViewController {

    private let order: Order

    init(order: Order) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        title = "Order \(order.id.uuidString.prefix(8))"

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
        stack.axis = .vertical; stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // Package info card
        let infoCard = WTPCard()
        let infoStack = UIStackView(); infoStack.axis = .vertical; infoStack.spacing = 10
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)

        func row(_ k: String, _ v: String) -> UIStackView {
            let r = UIStackView(); r.axis = .horizontal; r.distribution = .equalSpacing
            let kl = UILabel(); kl.text = k; kl.font = Theme.body(); kl.textColor = Theme.textSecondary
            let vl = UILabel(); vl.text = v; vl.font = Theme.bodyBold(); vl.textColor = Theme.textPrimary
            r.addArrangedSubview(kl); r.addArrangedSubview(vl)
            return r
        }

        infoStack.addArrangedSubview(row("Package", order.package.name))
        infoStack.addArrangedSubview(row("Aircraft", order.aircraftRegistration))
        infoStack.addArrangedSubview(row("Airport", order.airport))
        infoStack.addArrangedSubview(row("Country", order.country))
        infoStack.addArrangedSubview(row("Date", DateFormatter.localizedString(from: order.date, dateStyle: .medium, timeStyle: .short)))
        infoStack.addArrangedSubview(row("Price", "€\(Int(order.package.price))"))

        NSLayoutConstraint.activate([
            infoCard.heightAnchor.constraint(equalToConstant: 220),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            infoStack.centerYAnchor.constraint(equalTo: infoCard.centerYAnchor)
        ])
        stack.addArrangedSubview(infoCard)

        // Status timeline
        let statusTitle = UILabel()
        statusTitle.text = "Status"
        statusTitle.font = Theme.titleMedium()
        statusTitle.textColor = Theme.textPrimary
        stack.addArrangedSubview(statusTitle)

        let timelineCard = WTPCard()
        let timelineStack = UIStackView(); timelineStack.axis = .vertical; timelineStack.spacing = 0
        timelineStack.translatesAutoresizingMaskIntoConstraints = false
        timelineCard.addSubview(timelineStack)

        for (i, st) in Order.OrderStatus.allCases.enumerated() {
            guard st != .cancelled else { continue }
            let row = UIStackView(); row.axis = .horizontal; row.spacing = 14; row.alignment = .top

            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 8
            dot.backgroundColor = i <= order.status.step ? order.status.color : Theme.separator

            let label = UILabel()
            label.text = st.rawValue
            label.font = i <= order.status.step ? Theme.bodyBold() : Theme.body()
            label.textColor = i <= order.status.step ? Theme.textPrimary : Theme.textTertiary

            row.addArrangedSubview(dot)
            row.addArrangedSubview(label)
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 16),
                dot.heightAnchor.constraint(equalToConstant: 16),
                row.heightAnchor.constraint(equalToConstant: 40)
            ])

            timelineStack.addArrangedSubview(row)

            if i < 3 {
                let line = UIView()
                line.backgroundColor = i < order.status.step ? order.status.color : Theme.separator
                line.translatesAutoresizingMaskIntoConstraints = false
                timelineStack.addArrangedSubview(line)
                line.heightAnchor.constraint(equalToConstant: 2).isActive = true
                line.leadingAnchor.constraint(equalTo: timelineStack.leadingAnchor, constant: 22).isActive = true
            }
        }

        NSLayoutConstraint.activate([
            timelineCard.heightAnchor.constraint(equalToConstant: 260),
            timelineStack.leadingAnchor.constraint(equalTo: timelineCard.leadingAnchor, constant: 16),
            timelineStack.trailingAnchor.constraint(equalTo: timelineCard.trailingAnchor, constant: -16),
            timelineStack.centerYAnchor.constraint(equalTo: timelineCard.centerYAnchor)
        ])
        stack.addArrangedSubview(timelineCard)
    }
}

// MARK: - Sample Orders

extension Order {
    static var samples: [Order] {
        [
            Order(package: WashPackage.all[3], aircraftRegistration: "N456WB", date: Date().addingTimeInterval(-86400), airport: "Paris Le Bourget (LBG)", country: "France", status: .completed),
            Order(package: WashPackage.all[0], aircraftRegistration: "G-ABCD", date: Date(), airport: "London Luton (LTN)", country: "United Kingdom", status: .inProgress),
            Order(package: WashPackage.all[4], aircraftRegistration: "D-AIRX", date: Date().addingTimeInterval(3600), airport: "Munich (OBF)", country: "Germany", status: .confirmed),
        ]
    }
}
