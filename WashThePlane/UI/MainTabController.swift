//
//  MainTabController.swift
//  WashThePlane
//
//  Таб-бар приложения. Чёрный стиль, красный акцент.
//

import UIKit

final class MainTabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let home = wrap(HomeViewController(), title: "Services", icon: "bubbles.and.sparkles.fill")
        let orders = wrap(UINavigationController(rootViewController: OrdersViewController()), title: "Orders", icon: "list.bullet.clipboard.fill")
        let qr = wrap(QRViewController(), title: "WashPass", icon: "qrcode")
        let countries = wrap(UINavigationController(rootViewController: CountriesViewController()), title: "Europe", icon: "globe.europe.africa.fill")
        let profile = wrap(ProfileViewController(), title: "Profile", icon: "person.fill")

        viewControllers = [home, orders, qr, countries, profile]
    }

    private func wrap(_ vc: UIViewController, title: String, icon: String) -> UIViewController {
        vc.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), selectedImage: UIImage(systemName: "\(icon).fill"))
        return vc
    }

    private func setupAppearance() {
        let bar = UITabBarAppearance()
        bar.configureWithOpaqueBackground()
        bar.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        bar.shadowColor = .clear

        let normal: UITabBarItemAppearance = {
            let a = UITabBarItemAppearance()
            a.normal.iconColor = Theme.textTertiary
            a.normal.titleTextAttributes = [.foregroundColor: Theme.textTertiary]
            a.selected.iconColor = Theme.accent
            a.selected.titleTextAttributes = [.foregroundColor: Theme.accent]
            return a
        }()

        bar.stackedLayoutAppearance = normal
        bar.inlineLayoutAppearance = normal
        bar.compactInlineLayoutAppearance = normal

        tabBar.standardAppearance = bar
        tabBar.scrollEdgeAppearance = bar
        tabBar.isTranslucent = false

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = Theme.background
        nav.titleTextAttributes = [.foregroundColor: Theme.textPrimary]
        nav.largeTitleTextAttributes = [.foregroundColor: Theme.textPrimary]
        nav.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = Theme.accent
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}
