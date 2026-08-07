//
//  AppDelegate.swift
//  WashThePlane
//
//  ATT — самый первый диалог. Только после ответа пользователя:
//  SDK → push-регистрация → кэш/API → WebView / Native UI.
//

import UIKit
import AppTrackingTransparency
import FacebookCore
import AppsFlyerLib
import UserNotifications

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let cache = CacheManager.shared
    private let network = NetworkService.shared
    private var pendingPushToken: String?
    private var attRequested = false
    private var pushRequested = false

    // MARK: - Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Facebook SDK — базовый init
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        Settings.shared.appID = AppConfig.facebookAppID
        Settings.shared.clientToken = AppConfig.facebookClientToken
        Settings.shared.displayName = AppConfig.facebookDisplayName

        // Loading на фоне — ATT появится поверх него
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = LoadingViewController()
        window?.makeKeyAndVisible()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard !attRequested else { return }
        attRequested = true
        requestATTThenInitialize(application: application, launchOptions: nil)
    }

    // MARK: - ATT → SDK → Routing

    private func log(_ msg: String) { print("[WTP] \(msg)") }

    private func requestATTThenInitialize(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            let trackingAllowed = (status == .authorized)
            self?.log("ATT status: \(status.rawValue), authorized=\(trackingAllowed)")

            // FacebookCore
            DispatchQueue.main.async {
                ApplicationDelegate.shared.initializeSDK()
                Settings.shared.isAdvertiserTrackingEnabled = trackingAllowed
            }

            // AppsFlyer
            AppsFlyerLib.shared().appsFlyerDevKey = AppConfig.appsFlyerDevKey
            AppsFlyerLib.shared().appleAppID = AppConfig.appleAppID
            AppsFlyerLib.shared().start()
            if trackingAllowed {
                AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 0)
            }

            // UID готов сразу после start(), атрибуция приходит асинхронно в фоне
            DispatchQueue.main.async { [weak self] in
                self?.performRouting()
            }
        }
    }

    // MARK: - Push

    private func registerForPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            self.log("Push authorization: \(granted)")
            DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        pendingPushToken = token
        log("Push token received: \(token.prefix(16))...")
        let clientID = AppsFlyerLib.shared().getAppsFlyerUID() ?? ""
        let appID = "id\(AppConfig.appleAppID)"
        network.registerPushToken(clientID: clientID, appID: appID, pushToken: token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] Failed: \(error.localizedDescription)")
    }

    // MARK: - Routing

    private func performRouting() {
        if let cachedLink = cache.getTargetLink(), let url = URL(string: cachedLink) {
            log("Route: cache hit → WebView")
            showWebView(with: url)
            return
        }

        let clientID = AppsFlyerLib.shared().getAppsFlyerUID() ?? ""
        let appID = "id\(AppConfig.appleAppID)"

        Task {
            // Даём AF секунду на сбор атрибуции перед запросом к хосту
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let link = await network.checkRoute(clientID: clientID, appID: appID)
            await MainActor.run {
                if let link, let url = URL(string: link) {
                    log("Route: API returned link → WebView")
                    cache.saveTargetLink(link)
                    self.showWebView(with: url)
                } else {
                    log("Route: no link → Native UI")
                    self.showNative()
                }
            }
        }
    }

    private func showWebView(with url: URL) {
        let webVC = WebContentController(url: url, allowClose: false)
        let nav = UINavigationController(rootViewController: webVC)
        nav.setNavigationBarHidden(true, animated: false)
        setRoot(nav, showOnboarding: false)
        requestPushAfterDelay()
    }

    private func showNative() {
        setRoot(MainTabController(), showOnboarding: true)
        requestPushAfterDelay()
    }

    /// Пуши — через 2 сек после открытия экрана, один раз
    private func requestPushAfterDelay() {
        guard !pushRequested else { return }
        pushRequested = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.registerForPushNotifications()
        }
    }

    private func setRoot(_ vc: UIViewController, showOnboarding: Bool) {
        guard let window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = vc
        } completion: { _ in
            if showOnboarding, !UserDefaults.standard.bool(forKey: "onboarding_done") {
                let onboarding = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
                onboarding.modalPresentationStyle = .fullScreen
                vc.present(onboarding, animated: true)
            }
        }
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}

// MARK: - Push Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                  withCompletionHandler completionHandler: @escaping () -> Void) {
        let pushID = (response.notification.request.content.userInfo["pushID"] as? String) ?? ""
        log("Push clicked, pushID: \(pushID)")
        NetworkService.shared.trackPushClick(
            clientID: AppsFlyerLib.shared().getAppsFlyerUID() ?? "",
            pushID: pushID
        )
        completionHandler()
    }
}

// MARK: - Loading

private final class LoadingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = Theme.accent
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
