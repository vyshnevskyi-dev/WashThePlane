//
//  WebContentController.swift
//  AppTemplate
//
//  Прокачанный WKWebView-контроллер, портированный из AppFlowKit.
//
//  Фичи:
//    • LiquidGlassSlider — жестовый back/reload/close
//    • Progress bar (тонкая полоса над Safe Area)
//    • Адаптивный фон — подстраивается под цвет страницы
//    • Обработка target=_blank, window.open() — всё в одном WebView
//    • Внешние схемы: tel, mailto, sms, facetime → системный обработчик
//    • App Store ссылки → открываются в App Store
//    • JS alert/confirm/prompt — нативные диалоги
//    • inline media playback, нет user action для video
//    • Anti-debug: Web Inspector выключен в Release
//    • Безопасное закрытие JS-диалогов при уходе с экрана
//

import UIKit
import WebKit

// MARK: - Web Content Controller

final class WebContentController: UIViewController {

    // MARK: - Properties

    var startURL: URL
    private let allowClose: Bool
    private let onClose: () -> Void

    private var webView: WKWebView!
    private var statusBarStyle: UIStatusBarStyle = .lightContent
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let liquid = LiquidGlassSlider()

    private var progressObserver: NSKeyValueObservation?
    private var canGoBackObserver: NSKeyValueObservation?
    private var canGoForwardObserver: NSKeyValueObservation?

    // MARK: - Init

    init(
        url: URL,
        allowClose: Bool = true,
        onClose: @escaping () -> Void = {}
    ) {
        self.startURL = url
        self.allowClose = allowClose
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(url:allowClose:onClose:)")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupWebView()
        setupProgressView()
        setupLiquidSlider()
        bindObservers()
        loadURL(startURL)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissActiveJSDialogs()
    }

    deinit {
        progressObserver?.invalidate()
        canGoBackObserver?.invalidate()
        canGoForwardObserver?.invalidate()
        dismissActiveJSDialogs()
    }

    private func dismissActiveJSDialogs() {
        guard let alert = presentedViewController as? UIAlertController,
              alert.title == nil else { return }
        if let cancel = alert.actions.first(where: { $0.style == .cancel }) {
            (cancel.value(forKey: "handler") as? (() -> Void))?()
        }
        alert.dismiss(animated: false)
    }

    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Если нужен web→native bridge (Cherry Flow / кастомные события),
        // добавь сюда WKUserContentController + обработчик. Пример:
        //   let ucc = WKUserContentController()
        //   ucc.add(bridge, name: "yourHandler")
        //   config.userContentController = ucc

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self

        #if !DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = false
        }
        #endif

        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(red: 0.922, green: 0.271, blue: 0.353, alpha: 1)
        progressView.trackTintColor = .clear
        progressView.isHidden = true

        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func setupLiquidSlider() {
        liquid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(liquid)

        NSLayoutConstraint.activate([
            liquid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            liquid.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            liquid.heightAnchor.constraint(equalToConstant: 44),
            liquid.widthAnchor.constraint(equalToConstant: 44)
        ])

        liquid.onBack = { [weak self] in
            guard let self else { return }
            if self.webView.canGoBack {
                self.webView.goBack()
            } else if self.allowClose {
                self.closeWebView()
            } else {
                self.liquid.bump()
            }
        }

        liquid.onReload = { [weak self] in
            self?.webView.reload()
        }

        liquid.onClose = { [weak self] in
            guard let self, self.allowClose else { return }
            self.closeWebView()
        }

        liquid.canGoBackProvider = { [weak self] in
            self?.webView.canGoBack ?? false
        }

        liquid.allowCloseProvider = { [weak self] in
            self?.allowClose ?? false
        }
    }

    private func bindObservers() {
        progressObserver = webView.observe(\.estimatedProgress, options: .new) { [weak self] webView, _ in
            guard let self else { return }
            let progress = Float(webView.estimatedProgress)
            self.progressView.setProgress(progress, animated: true)
            self.progressView.isHidden = progress >= 1.0
        }

        canGoBackObserver = webView.observe(\.canGoBack, options: .new) { [weak self] _, _ in
            self?.liquid.updateState()
        }

        canGoForwardObserver = webView.observe(\.canGoForward, options: .new) { [weak self] _, _ in
            self?.liquid.updateState()
        }
    }

    // MARK: - Loading

    private func loadURL(_ url: URL) {
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView.load(request)
    }

    func loadBlankAndNavigate(to url: URL) {
        webView.load(URLRequest(url: URL(string: "about:blank")!))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.loadURL(url)
        }
    }

    private func closeWebView() {
        onClose()
        dismiss(animated: true)
    }

    // MARK: - Adaptive Background

    private func syncBackgroundWithPage() {
        let js = """
        (function() {
            const body = document.body;
            const html = document.documentElement;
            function bg(el) { return window.getComputedStyle(el).backgroundColor; }
            function pick(c) {
                if (!c) return null;
                if (c === "rgba(0, 0, 0, 0)" || c === "transparent") return null;
                return c;
            }
            return pick(body ? bg(body) : null) || pick(html ? bg(html) : null) || null;
        })();
        """

        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self else { return }
            guard let css = result as? String, let color = UIColor(cssRGBA: css) else {
                self.view.backgroundColor = .black
                self.statusBarStyle = .lightContent
                self.setNeedsStatusBarAppearanceUpdate()
                return
            }
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let brightness = (0.299 * r + 0.587 * g + 0.114 * b)
            self.statusBarStyle = brightness > 0.55 ? .darkContent : .lightContent
            self.setNeedsStatusBarAppearanceUpdate()
            UIView.animate(withDuration: 0.2, delay: 0,
                           options: [.curveEaseOut, .allowUserInteraction]) {
                self.view.backgroundColor = color
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebContentController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        syncBackgroundWithPage()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[WebView] Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        print("[WebView] Provisional navigation failed: \(error.localizedDescription)")

        let alert = UIAlertController(
            title: "Loading Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.loadURL(self?.startURL ?? URL(string: "about:blank")!)
        })
        if allowClose {
            alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in
                self?.closeWebView()
            })
        }
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let scheme = (url.scheme ?? "").lowercased()

        // Внешние схемы → системный обработчик
        if ["tel", "mailto", "sms", "facetime"].contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // target=_blank → загружаем в этот же WebView
        if navigationAction.targetFrame == nil {
            webView.load(URLRequest(url: url))
            decisionHandler(.cancel)
            return
        }

        // App Store ссылки → открываем в App Store
        if url.host?.contains("apps.apple.com") == true ||
           url.host?.contains("itunes.apple.com") == true {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension WebContentController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }
}

// MARK: - Liquid Glass Slider

final class LiquidGlassSlider: UIView {

    var onBack: (() -> Void)?
    var onReload: (() -> Void)?
    var onClose: (() -> Void)?
    var canGoBackProvider: (() -> Bool)?
    var allowCloseProvider: (() -> Bool)?

    private let collapsedSize: CGFloat = 44
    private let expandedWidth: CGFloat = 280
    private let thumbDiameter: CGFloat = 28
    private let triggerRatio: CGFloat = 0.75
    private let idleAlpha: CGFloat = 0.55
    private let expandedAlpha: CGFloat = 0.70

    private enum State { case collapsed, expanded, animating }
    private var state: State = .collapsed
    private weak var leadingConstraint: NSLayoutConstraint?
    private weak var widthConstraint: NSLayoutConstraint?
    private var overlayButton: UIButton?

    private let track = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let centerButton = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let centerIcon = UIImageView(image: UIImage(systemName: "circle.grid.2x2.fill"))
    private let leftLabel = UILabel()
    private let rightLabel = UILabel()
    private let leftIcon = UIImageView(image: UIImage(systemName: "chevron.left"))
    private let rightIcon = UIImageView(image: UIImage(systemName: "arrow.clockwise"))
    private let thumb = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let thumbDot = UIView()
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private var leftHints: [UIImageView] = []
    private var rightHints: [UIImageView] = []
    private var hintTimer: Timer?
    private var hintStep = 0
    private var isDragging = false
    private var didTrigger = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        clipsToBounds = false

        // Track
        track.translatesAutoresizingMaskIntoConstraints = false
        track.clipsToBounds = true
        track.alpha = 0
        addSubview(track)

        // Center button
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        centerButton.clipsToBounds = true
        centerButton.alpha = idleAlpha
        addSubview(centerButton)

        centerIcon.translatesAutoresizingMaskIntoConstraints = false
        centerIcon.contentMode = .scaleAspectFit
        centerIcon.tintColor = .white.withAlphaComponent(0.92)
        centerButton.contentView.addSubview(centerIcon)

        // Labels + icons in track
        setupLabel(leftLabel, text: "Back")
        setupIcon(leftIcon)
        setupLabel(rightLabel, text: "Reload")
        setupIcon(rightIcon)
        track.contentView.addSubview(leftIcon)
        track.contentView.addSubview(leftLabel)
        track.contentView.addSubview(rightIcon)
        track.contentView.addSubview(rightLabel)

        // Thumb
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.clipsToBounds = true
        thumb.alpha = 0
        addSubview(thumb)

        thumbDot.translatesAutoresizingMaskIntoConstraints = false
        thumbDot.backgroundColor = .white.withAlphaComponent(0.55)
        thumbDot.layer.cornerRadius = 2
        thumb.contentView.addSubview(thumbDot)

        // Layout
        NSLayoutConstraint.activate([
            track.leadingAnchor.constraint(equalTo: leadingAnchor),
            track.trailingAnchor.constraint(equalTo: trailingAnchor),
            track.topAnchor.constraint(equalTo: topAnchor),
            track.bottomAnchor.constraint(equalTo: bottomAnchor),

            centerButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            centerButton.topAnchor.constraint(equalTo: topAnchor),
            centerButton.widthAnchor.constraint(equalToConstant: collapsedSize),
            centerButton.heightAnchor.constraint(equalToConstant: collapsedSize),

            centerIcon.centerXAnchor.constraint(equalTo: centerButton.contentView.centerXAnchor),
            centerIcon.centerYAnchor.constraint(equalTo: centerButton.contentView.centerYAnchor),
            centerIcon.widthAnchor.constraint(equalToConstant: 18),
            centerIcon.heightAnchor.constraint(equalToConstant: 18),

            leftIcon.leadingAnchor.constraint(equalTo: track.contentView.leadingAnchor, constant: 16),
            leftIcon.centerYAnchor.constraint(equalTo: track.contentView.centerYAnchor),
            leftIcon.widthAnchor.constraint(equalToConstant: 14),
            leftIcon.heightAnchor.constraint(equalToConstant: 14),

            leftLabel.leadingAnchor.constraint(equalTo: leftIcon.trailingAnchor, constant: 6),
            leftLabel.centerYAnchor.constraint(equalTo: track.contentView.centerYAnchor),

            rightIcon.trailingAnchor.constraint(equalTo: track.contentView.trailingAnchor, constant: -16),
            rightIcon.centerYAnchor.constraint(equalTo: track.contentView.centerYAnchor),
            rightIcon.widthAnchor.constraint(equalToConstant: 14),
            rightIcon.heightAnchor.constraint(equalToConstant: 14),

            rightLabel.trailingAnchor.constraint(equalTo: rightIcon.leadingAnchor, constant: -6),
            rightLabel.centerYAnchor.constraint(equalTo: track.contentView.centerYAnchor),

            thumb.centerXAnchor.constraint(equalTo: centerXAnchor),
            thumb.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: thumbDiameter),
            thumb.heightAnchor.constraint(equalToConstant: thumbDiameter),

            thumbDot.centerXAnchor.constraint(equalTo: thumb.contentView.centerXAnchor),
            thumbDot.centerYAnchor.constraint(equalTo: thumb.contentView.centerYAnchor),
            thumbDot.widthAnchor.constraint(equalToConstant: 4),
            thumbDot.heightAnchor.constraint(equalToConstant: 4)
        ])

        buildHintChevrons()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        centerButton.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        thumb.addGestureRecognizer(pan)

        haptic.prepare()
    }

    private func buildHintChevrons() {
        let hintSize: CGFloat = 12, hintGap: CGFloat = 6
        for i in 0..<3 {
            let left = UIImageView(image: UIImage(systemName: "chevron.left"))
            let right = UIImageView(image: UIImage(systemName: "chevron.right"))
            for v in [left, right] {
                v.translatesAutoresizingMaskIntoConstraints = false
                v.contentMode = .scaleAspectFit
                v.tintColor = .white.withAlphaComponent(0.85)
                v.alpha = 0
                addSubview(v)
                NSLayoutConstraint.activate([
                    v.centerYAnchor.constraint(equalTo: centerYAnchor),
                    v.widthAnchor.constraint(equalToConstant: hintSize),
                    v.heightAnchor.constraint(equalToConstant: hintSize)
                ])
            }
            left.trailingAnchor.constraint(
                equalTo: thumb.leadingAnchor,
                constant: -(CGFloat(i + 1) * (hintSize + hintGap))
            ).isActive = true
            right.leadingAnchor.constraint(
                equalTo: thumb.trailingAnchor,
                constant: CGFloat(i + 1) * (hintSize + hintGap)
            ).isActive = true
            leftHints.append(left)
            rightHints.append(right)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        centerButton.layer.cornerRadius = collapsedSize / 2
        track.layer.cornerRadius = bounds.height / 2
        thumb.layer.cornerRadius = thumbDiameter / 2
        track.layer.cornerCurve = .continuous
        centerButton.layer.cornerCurve = .continuous
        thumb.layer.cornerCurve = .continuous
    }

    // MARK: - State

    func updateState() {
        let canGoBack = canGoBackProvider?() ?? false
        let allowClose = allowCloseProvider?() ?? false
        if state == .expanded {
            leftLabel.text = canGoBack ? "Back" : (allowClose ? "Close" : "Back")
            leftIcon.image = UIImage(systemName: canGoBack ? "chevron.left" : (allowClose ? "xmark" : "chevron.left"))
            leftLabel.alpha = (canGoBack || allowClose) ? 1.0 : 0.5
            leftIcon.alpha = (canGoBack || allowClose) ? 1.0 : 0.5
        }
    }

    // MARK: - Expand / Collapse

    @objc private func handleTap() {
        switch state {
        case .collapsed: expand()
        case .expanded: collapse()
        case .animating: break
        }
    }

    private func captureConstraints() {
        guard leadingConstraint == nil else { return }
        for c in constraints {
            if c.firstItem === self, c.firstAttribute == .leading { leadingConstraint = c }
            if c.firstItem === self, c.firstAttribute == .width { widthConstraint = c }
        }
    }

    private func expand() {
        captureConstraints()
        guard state == .collapsed, let superview, let lc = leadingConstraint, let wc = widthConstraint else { return }
        state = .animating

        haptic.impactOccurred(intensity: 0.5)
        addOverlay(in: superview)

        let targetLeading = max(12, (superview.bounds.width - expandedWidth) / 2)
        wc.constant = expandedWidth
        lc.constant = targetLeading

        track.alpha = expandedAlpha
        thumb.alpha = expandedAlpha
        centerButton.alpha = 0
        thumb.center = CGPoint(x: bounds.midX, y: bounds.midY)
        didTrigger = false
        updateState()
        hintStep = 0

        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.88, initialSpringVelocity: 0.6,
                       options: [.allowUserInteraction, .curveEaseOut]) {
            superview.layoutIfNeeded()
        } completion: { _ in
            self.state = .expanded
            self.startHintSequence()
        }
    }

    private func collapse() {
        captureConstraints()
        guard state == .expanded, let superview, let lc = leadingConstraint, let wc = widthConstraint else { return }
        state = .animating

        stopHintSequence()
        removeOverlay()
        snapThumbToCenter(animated: true)

        wc.constant = collapsedSize
        lc.constant = 16

        UIView.animate(withDuration: 0.24, delay: 0,
                       usingSpringWithDamping: 0.92, initialSpringVelocity: 0.7,
                       options: [.allowUserInteraction, .curveEaseOut]) {
            self.track.alpha = 0
            self.thumb.alpha = 0
            self.centerButton.alpha = self.idleAlpha
            superview.layoutIfNeeded()
        } completion: { _ in
            self.state = .collapsed
        }
    }

    // MARK: - Pan

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard state == .expanded else { return }
        let t = gr.translation(in: self)
        gr.setTranslation(.zero, in: self)

        switch gr.state {
        case .began:
            isDragging = true; didTrigger = false
            stopHintSequence(); haptic.prepare()
        case .changed:
            var newX = thumb.center.x + t.x
            let leftLimit = track.frame.minX + 14 + thumbDiameter / 2
            let rightLimit = track.frame.maxX - 14 - thumbDiameter / 2
            newX = min(max(newX, leftLimit), rightLimit)
            thumb.center = CGPoint(x: newX, y: thumb.center.y)
            updateEmphasis()
            if !didTrigger, resolveAction() != .none {
                didTrigger = true
                haptic.impactOccurred(intensity: 0.35)
            }
        case .ended, .cancelled, .failed:
            isDragging = false
            switch resolveAction() {
            case .back:
                haptic.impactOccurred(intensity: 0.85)
                onBack?(); collapse()
            case .reload:
                haptic.impactOccurred(intensity: 0.85)
                onReload?(); collapse()
            case .none:
                snapThumbToCenter(animated: true)
                startHintSequence()
            }
        default: break
        }
    }

    private enum Action { case none, back, reload }

    private func resolveAction() -> Action {
        let dx = thumb.center.x - bounds.midX
        let usable = (expandedWidth / 2) - 20
        if dx < 0 { return abs(dx) / usable >= triggerRatio ? .back : .none }
        if dx > 0 { return dx / usable >= triggerRatio ? .reload : .none }
        return .none
    }

    private func snapThumbToCenter(animated: Bool) {
        let target = CGPoint(x: bounds.midX, y: bounds.midY)
        if animated {
            UIView.animate(withDuration: 0.16, delay: 0,
                           options: [.curveEaseOut, .allowUserInteraction]) {
                self.thumb.center = target
                self.resetEmphasis()
            }
        } else {
            thumb.center = target
            resetEmphasis()
        }
    }

    private func updateEmphasis() {
        let dx = thumb.center.x - bounds.midX
        if dx < 0 {
            leftLabel.alpha = 1; leftIcon.alpha = 1
            rightLabel.alpha = 0.5; rightIcon.alpha = 0.5
        } else if dx > 0 {
            rightLabel.alpha = 1; rightIcon.alpha = 1
            leftLabel.alpha = 0.5; leftIcon.alpha = 0.5
        } else { resetEmphasis() }
    }

    private func resetEmphasis() {
        leftLabel.alpha = 1; leftIcon.alpha = 1
        rightLabel.alpha = 1; rightIcon.alpha = 1
        updateState()
    }

    func bump() {
        haptic.impactOccurred(intensity: 0.45)
        UIView.animate(withDuration: 0.1) { self.thumb.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.12) { self.thumb.transform = .identity }
        }
    }

    // MARK: - Hint Animation

    private func startHintSequence() {
        guard hintTimer == nil else { return }
        for v in leftHints + rightHints { v.alpha = 0.1 }
        hintStep = 0
        hintTimer = Timer.scheduledTimer(timeInterval: 0.45, target: self,
                                         selector: #selector(stepHint), userInfo: nil, repeats: true)
        RunLoop.main.add(hintTimer!, forMode: .common)
        stepHint()
    }

    private func stopHintSequence() {
        hintTimer?.invalidate(); hintTimer = nil
        for v in leftHints + rightHints { v.alpha = 0 }
    }

    @objc private func stepHint() {
        guard state == .expanded, !isDragging else { return }
        UIView.animate(withDuration: 0.1) {
            for v in self.leftHints + self.rightHints { v.alpha = 0.1 }
        }
        let idx = hintStep % 3; hintStep += 1
        let L = leftHints[idx], R = rightHints[idx]
        UIView.animate(withDuration: 0.55, delay: 0,
                       options: [.allowUserInteraction, .curveEaseOut]) {
            L.alpha = 0.72; R.alpha = 0.72
        } completion: { _ in
            UIView.animate(withDuration: 0.18, delay: 0.02, options: [.allowUserInteraction]) {
                L.alpha = 0.1; R.alpha = 0.1
            }
        }
    }

    // MARK: - Helpers

    private func setupLabel(_ label: UILabel, text: String) {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.90)
    }

    private func setupIcon(_ icon: UIImageView) {
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.tintColor = .white.withAlphaComponent(0.92)
    }

    private func addOverlay(in superview: UIView) {
        guard overlayButton == nil else { return }
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .clear
        b.addTarget(self, action: #selector(overlayTapped), for: .touchUpInside)
        superview.insertSubview(b, belowSubview: self)
        NSLayoutConstraint.activate([
            b.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            b.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            b.topAnchor.constraint(equalTo: superview.topAnchor),
            b.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
        overlayButton = b
    }

    private func removeOverlay() {
        overlayButton?.removeFromSuperview()
        overlayButton = nil
    }

    @objc private func overlayTapped() {
        if state == .expanded { collapse() }
    }
}

// MARK: - CSS Color Parser

private extension UIColor {
    convenience init?(cssRGBA: String) {
        let s = cssRGBA
            .replacingOccurrences(of: "rgba(", with: "")
            .replacingOccurrences(of: "rgb(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: " ", with: "")
        let parts = s.split(separator: ",").map { String($0) }
        guard parts.count == 3 || parts.count == 4 else { return nil }
        func f(_ i: Int) -> CGFloat? {
            guard i < parts.count, let v = Double(parts[i]) else { return nil }
            return CGFloat(v)
        }
        guard let r = f(0), let g = f(1), let b = f(2) else { return nil }
        let a: CGFloat = (parts.count == 4 ? (Double(parts[3]).map { CGFloat($0) } ?? 1) : 1)
        self.init(red: r/255, green: g/255, blue: b/255, alpha: a)
    }
}
