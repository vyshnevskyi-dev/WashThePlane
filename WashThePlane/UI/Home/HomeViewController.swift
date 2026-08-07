//
//  HomeViewController.swift
//  WashThePlane
//
//  Главный экран: категории + сетка пакетов мойки.
//

import UIKit

final class HomeViewController: UIViewController {

    private var packages = WashPackage.all
    private var selectedCategory: WashPackage.PackageCategory?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // MARK: - Header
    private let greetingLabel: UILabel = {
        let l = UILabel()
        l.text = "Wash the Plane"
        l.font = Theme.titleHero()
        l.textColor = Theme.textPrimary
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Premium aircraft detailing across Europe"
        l.font = Theme.body()
        l.textColor = Theme.textSecondary
        return l
    }()

    private let categoryScroll = UIScrollView()
    private let categoryStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        setupScrollView()
        buildHeader()
        buildCategoryChips()
        buildPackageGrid()
        buildMockOrdersPreview()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .always
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 24
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Header

    private func buildHeader() {
        let headerStack = UIStackView(arrangedSubviews: [greetingLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        let heroCard = UIView()
        heroCard.translatesAutoresizingMaskIntoConstraints = false
        heroCard.backgroundColor = Theme.card
        heroCard.layer.cornerRadius = 24
        heroCard.layer.cornerCurve = .continuous
        heroCard.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Status dots
        let statusDot = UIView()
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.backgroundColor = Theme.success
        statusDot.layer.cornerRadius = 5
        heroCard.addSubview(statusDot)

        let statusLabel = UILabel()
        statusLabel.text = "Crews active now"
        statusLabel.font = Theme.caption()
        statusLabel.textColor = Theme.textSecondary
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        heroCard.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            heroCard.heightAnchor.constraint(equalToConstant: 120),
            headerStack.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 20),
            headerStack.centerYAnchor.constraint(equalTo: heroCard.centerYAnchor, constant: -8),

            statusDot.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 20),
            statusDot.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -16),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),

            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 6),
            statusLabel.centerYAnchor.constraint(equalTo: statusDot.centerYAnchor)
        ])

        contentStack.addArrangedSubview(heroCard)
    }

    // MARK: - Category Chips

    private func buildCategoryChips() {
        let title = UILabel()
        title.text = "Service Categories"
        title.font = Theme.titleMedium()
        title.textColor = Theme.textPrimary
        contentStack.addArrangedSubview(title)

        categoryScroll.translatesAutoresizingMaskIntoConstraints = false
        categoryScroll.showsHorizontalScrollIndicator = false
        categoryStack.axis = .horizontal
        categoryStack.spacing = 10
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryScroll.addSubview(categoryStack)

        NSLayoutConstraint.activate([
            categoryScroll.heightAnchor.constraint(equalToConstant: 40),
            categoryStack.leadingAnchor.constraint(equalTo: categoryScroll.leadingAnchor),
            categoryStack.trailingAnchor.constraint(equalTo: categoryScroll.trailingAnchor),
            categoryStack.topAnchor.constraint(equalTo: categoryScroll.topAnchor),
            categoryStack.bottomAnchor.constraint(equalTo: categoryScroll.bottomAnchor)
        ])

        // "All" chip
        addCategoryChip(name: "All", isSelected: selectedCategory == nil) { [weak self] in
            self?.selectedCategory = nil
            self?.refreshChipsAndPackages()
        }

        for cat in WashPackage.PackageCategory.allCases {
            addCategoryChip(name: cat.rawValue, isSelected: selectedCategory == cat) { [weak self] in
                self?.selectedCategory = cat
                self?.refreshChipsAndPackages()
            }
        }

        contentStack.addArrangedSubview(categoryScroll)
    }

    private func addCategoryChip(name: String, isSelected: Bool, action: @escaping () -> Void) {
        let chip = UIButton(type: .system)
        chip.setTitle(name, for: .normal)
        chip.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        chip.backgroundColor = isSelected ? Theme.accent : Theme.card
        chip.setTitleColor(isSelected ? .white : Theme.textSecondary, for: .normal)
        chip.layer.cornerRadius = 18
        chip.layer.cornerCurve = .continuous
        chip.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        chip.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)
        chip.tag = isSelected ? 1 : 0
        categoryStack.addArrangedSubview(chip)
    }

    private func refreshChipsAndPackages() {
        for case let chip as UIButton in categoryStack.arrangedSubviews {
            let selected = (selectedCategory == nil && chip.title(for: .normal) == "All") ||
                           (selectedCategory?.rawValue == chip.title(for: .normal))
            chip.backgroundColor = selected ? Theme.accent : Theme.card
            chip.setTitleColor(selected ? .white : Theme.textSecondary, for: .normal)
        }
        rebuildPackageGrid()
    }

    // MARK: - Package Grid

    private func buildPackageGrid() {
        let title = UILabel()
        title.text = "Available Packages"
        title.font = Theme.titleMedium()
        title.textColor = Theme.textPrimary
        title.tag = 999  // to find and remove
        contentStack.addArrangedSubview(title)

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 14
        grid.tag = 1000
        contentStack.addArrangedSubview(grid)

        renderPackages(into: grid)
    }

    private func rebuildPackageGrid() {
        if let old = contentStack.viewWithTag(1000) as? UIStackView {
            old.arrangedSubviews.forEach { $0.removeFromSuperview() }
            renderPackages(into: old)
        }
    }

    private func renderPackages(into grid: UIStackView) {
        let filtered = selectedCategory.map { cat in
            packages.filter { $0.category == cat }
        } ?? packages

        for pkg in filtered {
            let card = WTPCard()

            let icon = UIImageView(image: UIImage(systemName: pkg.icon))
            icon.tintColor = Theme.accent
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false

            let nameLabel = UILabel()
            nameLabel.text = pkg.name
            nameLabel.font = Theme.titleMedium()
            nameLabel.textColor = Theme.textPrimary
            nameLabel.translatesAutoresizingMaskIntoConstraints = false

            let descLabel = UILabel()
            descLabel.text = pkg.description
            descLabel.font = Theme.caption()
            descLabel.textColor = Theme.textSecondary
            descLabel.numberOfLines = 2
            descLabel.translatesAutoresizingMaskIntoConstraints = false

            let priceLabel = UILabel()
            priceLabel.text = "€\(Int(pkg.price))"
            priceLabel.font = Theme.priceLarge()
            priceLabel.textColor = Theme.textAccent
            priceLabel.translatesAutoresizingMaskIntoConstraints = false

            let durationLabel = UILabel()
            if pkg.durationMinutes > 0 {
                durationLabel.text = "⏱ \(pkg.durationMinutes) min"
            } else {
                durationLabel.text = "⏱ Monthly"
            }
            durationLabel.font = Theme.caption()
            durationLabel.textColor = Theme.textTertiary
            durationLabel.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(icon)
            card.addSubview(nameLabel)
            card.addSubview(descLabel)
            card.addSubview(priceLabel)
            card.addSubview(durationLabel)

            // Popular badge
            if pkg.isPopular {
                let badge = WTPBadge(text: "MOST POPULAR", kind: .done)
                card.addSubview(badge)
                NSLayoutConstraint.activate([
                    badge.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
                    badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
                ])
            }

            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(equalToConstant: 100),

                icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 32),
                icon.heightAnchor.constraint(equalToConstant: 32),

                nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
                nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),

                descLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                descLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

                durationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                durationLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

                priceLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                priceLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor)
            ])

            // Tap → order flow
            let tap = UITapGestureRecognizer(target: self, action: #selector(packageTapped(_:)))
            card.addGestureRecognizer(tap)
            card.accessibilityValue = pkg.name

            grid.addArrangedSubview(card)
        }
    }

    @objc private func packageTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view, let name = card.accessibilityValue,
              let pkg = packages.first(where: { $0.name == name }) else { return }
        let vc = OrderCreateViewController(package: pkg)
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    // MARK: - Recent Orders Preview

    private func buildMockOrdersPreview() {
        let title = UILabel()
        title.text = "Recent Activity"
        title.font = Theme.titleMedium()
        title.textColor = Theme.textPrimary
        contentStack.addArrangedSubview(title)

        let card = WTPCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing

        let left = UILabel()
        left.text = "No active orders yet"
        left.font = Theme.body()
        left.textColor = Theme.textSecondary

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = Theme.textTertiary

        row.addArrangedSubview(left)
        row.addArrangedSubview(arrow)
        stack.addArrangedSubview(row)

        let tap = UITapGestureRecognizer(target: self, action: #selector(openOrders))
        card.addGestureRecognizer(tap)

        contentStack.addArrangedSubview(card)
    }

    @objc private func openOrders() {
        tabBarController?.selectedIndex = 1
    }
}
