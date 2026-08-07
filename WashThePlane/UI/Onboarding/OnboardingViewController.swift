//
//  OnboardingViewController.swift
//  WashThePlane
//
//  Онбординг — 3 слайда, показывается при первом запуске.
//

import UIKit

final class OnboardingViewController: UIPageViewController {

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "airplane.circle.fill",
            title: "Welcome to\nWash the Plane",
            subtitle: "Premium aircraft detailing across Europe's finest private airports."
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Six Wash Packages",
            subtitle: "From Quick Rinse to Black Jet Elite — we handle everything from Cessnas to Gulfstreams."
        ),
        OnboardingPage(
            icon: "globe.europe.africa.fill",
            title: "15 European Countries",
            subtitle: "France, UK, Monaco, Switzerland, and more. Your jet, washed wherever you land."
        )
    ]

    private let getStartedButton = WTPButton(title: "Get Started", style: .primary)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        dataSource = self

        if let first = pageController(for: 0) {
            setViewControllers([first], direction: .forward, animated: false)
        }

        view.addSubview(getStartedButton)
        getStartedButton.addTarget(self, action: #selector(dismissOnboarding), for: .touchUpInside)
        getStartedButton.alpha = 0

        NSLayoutConstraint.activate([
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func dismissOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding_done")
        dismiss(animated: true)
    }

    private func pageController(for index: Int) -> OnboardingPageController? {
        guard index >= 0, index < pages.count else { return nil }
        let vc = OnboardingPageController()
        vc.page = pages[index]
        vc.pageIndex = index
        vc.isLastPage = index == pages.count - 1
        vc.onLastPageRevealed = { [weak self] in
            UIView.animate(withDuration: 0.4) { self?.getStartedButton.alpha = 1 }
        }
        return vc
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
        guard let vc = vc as? OnboardingPageController else { return nil }
        return pageController(for: vc.pageIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
        guard let vc = vc as? OnboardingPageController else { return nil }
        return pageController(for: vc.pageIndex + 1)
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int { pages.count }
    func presentationIndex(for pageViewController: UIPageViewController) -> Int { 0 }
}

// MARK: - Page

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

final class OnboardingPageController: UIViewController {
    var page: OnboardingPage!
    var pageIndex = 0
    var isLastPage = false
    var onLastPageRevealed: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let icon = UIImageView(image: UIImage(systemName: page.icon))
        icon.tintColor = Theme.accent
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = page.title
        title.font = Theme.titleHero()
        title.textColor = Theme.textPrimary
        title.textAlignment = .center
        title.numberOfLines = 0

        let sub = UILabel()
        sub.text = page.subtitle
        sub.font = Theme.body()
        sub.textColor = Theme.textSecondary
        sub.textAlignment = .center
        sub.numberOfLines = 0

        stack.addArrangedSubview(UIView()) // spacer
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(sub)
        stack.addArrangedSubview(UIView()) // spacer

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            icon.widthAnchor.constraint(equalToConstant: 100),
            icon.heightAnchor.constraint(equalToConstant: 100)
        ])

        if isLastPage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.onLastPageRevealed?()
            }
        }
    }
}
