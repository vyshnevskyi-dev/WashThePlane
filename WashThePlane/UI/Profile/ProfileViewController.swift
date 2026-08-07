//
//  ProfileViewController.swift
//  WashThePlane
//
//  Профиль пользователя + настройки + информация.
//  Поля кликабельны — открывают редактирование.
//

import UIKit
import StoreKit

final class ProfileViewController: UIViewController {

    private var userName = "John Pilot"
    private var userEmail = "john@washtheplane.com"
    private var userAircraft = "N456WB, G-ABCD"

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private lazy var sections: [ProfileSection] = [
        ProfileSection(title: "Account", items: [
            .init(icon: "person.fill", title: "Name", subtitle: userName),
            .init(icon: "envelope.fill", title: "Email", subtitle: userEmail),
            .init(icon: "airplane", title: "My Aircraft", subtitle: userAircraft),
        ]),
        ProfileSection(title: "Preferences", items: [
            .init(icon: "bell.fill", title: "Push Notifications", subtitle: "Order updates, promotions"),
            .init(icon: "location.fill", title: "Default Airport", subtitle: "Paris Le Bourget (LBG)"),
            .init(icon: "globe", title: "Language", subtitle: "English"),
        ]),
        ProfileSection(title: "About", items: [
            .init(icon: "info.circle.fill", title: "Version", subtitle: "1.0.0 (2026)"),
            .init(icon: "doc.text.fill", title: "Privacy Policy", subtitle: ""),
            .init(icon: "star.fill", title: "Rate Wash the Plane", subtitle: ""),
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background

        let header = buildHeader()
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 160)

        tableView.backgroundColor = .clear
        tableView.separatorColor = Theme.separator
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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

    private func buildHeader() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let avatar = UIView()
        avatar.backgroundColor = Theme.accent
        avatar.layer.cornerRadius = 40
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let initials = UILabel()
        initials.text = "JP"
        initials.font = .systemFont(ofSize: 32, weight: .bold)
        initials.textColor = .white
        initials.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initials)

        container.addSubview(avatar)

        NSLayoutConstraint.activate([
            avatar.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 80),
            avatar.heightAnchor.constraint(equalToConstant: 80),

            initials.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            initials.centerYAnchor.constraint(equalTo: avatar.centerYAnchor)
        ])
        return container
    }

    // MARK: - Edit helpers

    private func showEditAlert(title: String, current: String, key: String, text: String? = nil) {
        let alert = UIAlertController(title: "Edit \(title)", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = current
            tf.autocapitalizationType = (key == "email") ? .none : .words
            tf.keyboardType = (key == "email") ? .emailAddress : .default
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            switch key {
            case "name":     self?.userName = text
            case "email":    self?.userEmail = text
            case "aircraft": self?.userAircraft = text
            default: break
            }
            self?.reloadSections()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func reloadSections() {
        sections = [
            ProfileSection(title: "Account", items: [
                .init(icon: "person.fill", title: "Name", subtitle: userName),
                .init(icon: "envelope.fill", title: "Email", subtitle: userEmail),
                .init(icon: "airplane", title: "My Aircraft", subtitle: userAircraft),
            ]),
            ProfileSection(title: "Preferences", items: [
                .init(icon: "bell.fill", title: "Push Notifications", subtitle: "Order updates, promotions"),
                .init(icon: "location.fill", title: "Default Airport", subtitle: "Paris Le Bourget (LBG)"),
                .init(icon: "globe", title: "Language", subtitle: "English"),
            ]),
            ProfileSection(title: "About", items: [
                .init(icon: "info.circle.fill", title: "Version", subtitle: "1.0.0 (2026)"),
                .init(icon: "doc.text.fill", title: "Privacy Policy", subtitle: ""),
                .init(icon: "star.fill", title: "Rate Wash the Plane", subtitle: ""),
            ]),
        ]
        tableView.reloadData()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]

        let selectedBg = UIView()
        selectedBg.backgroundColor = Theme.accentDim
        cell.selectedBackgroundView = selectedBg
        cell.backgroundColor = Theme.card

        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.secondaryText = item.subtitle.isEmpty ? " " : item.subtitle
        config.image = UIImage(systemName: item.icon)
        config.imageProperties.tintColor = Theme.accent
        config.textProperties.color = Theme.textPrimary
        config.secondaryTextProperties.color = Theme.textSecondary
        config.textProperties.font = Theme.body()
        config.secondaryTextProperties.font = Theme.caption()
        cell.contentConfiguration = config

        let isEditable = (indexPath.section == 0)
        cell.accessoryType = isEditable ? .disclosureIndicator : (item.subtitle.isEmpty ? .disclosureIndicator : .none)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]

        switch (indexPath.section, item.title) {
        case (0, "Name"):     showEditAlert(title: "Name", current: userName, key: "name")
        case (0, "Email"):    showEditAlert(title: "Email", current: userEmail, key: "email")
        case (0, "My Aircraft"): showEditAlert(title: "Aircraft", current: userAircraft, key: "aircraft")
        case (2, "Privacy Policy"):
            if let url = URL(string: "https://washtheplane.com/privacy") {
                UIApplication.shared.open(url)
            }
        case (2, "Rate Wash the Plane"):
            SKStoreReviewController.requestReview()
        default: break
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = Theme.textSecondary
    }
}

private struct ProfileSection {
    let title: String
    let items: [ProfileItem]
}

private struct ProfileItem {
    let icon: String
    let title: String
    let subtitle: String
}
