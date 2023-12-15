//
//  CDVWKInAppBrowserViewController.swift
//  NostrSecond
//
//  Created by Shakhzod Omonbayev on 24/10/23.
//

import Foundation

class CDVWKInAppBrowserViewController: UIViewController {
    
    private var browserOptions: CDVInAppBrowserOptions
    private var settings: [AnyHashable : Any]?
    
    @IBOutlet var webView: WKWebView!
    @IBOutlet var configuration: WKWebViewConfiguration!
    @IBOutlet var closeButton: UIBarButtonItem!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var webViewUIDelegate: CDVWKInAppBrowserUIDelegate!
    
    weak var orientationDelegate: CDVScreenOrientationDelegate?
    weak var navigationDelegate: CDVWKInAppBrowser?
    
    var currentURL: URL?
    var lastReducedStatusBarHeight: CGFloat = 0.0
    var isExiting = false
    
//    var toolbarIsAtBottom: Bool {
//        browserOptions.toolbarPosition == BrowserConstants.kInAppBrowserToolbarBarPositionBottom
//    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        guard let statusBarStylePreference = setting(forKey: "InAppBrowserStatusBarStyle") as? String else {
            return .default
        }
        return statusBarStylePreference == "lightContent" ? .lightContent : .darkContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var shouldAutorotate: Bool {
        orientationDelegate?.shouldAutorotate() ?? true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        orientationDelegate?.supportedInterfaceOrientations() ?? [.portrait]
    }
    
    // MARK: - Initializers
    
    init(browserOptions: CDVInAppBrowserOptions, settings: [AnyHashable : Any]?) {
        self.browserOptions = browserOptions
        self.settings = settings
        
        super.init(nibName: nil, bundle: nil)
        
        webViewUIDelegate = CDVWKInAppBrowserUIDelegate()
        webViewUIDelegate.viewController = self
        
        setupConfiguration()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        rePositionViews()
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isExiting {
            navigationDelegate?.browserExit()
            isExiting = false
        }
    }
    
    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        
        coordinator.animate { context in
            self.rePositionViews()
        }
        super.viewWillTransition(to: size, with: coordinator)
    }
}

// MARK: - Actions
    
extension CDVWKInAppBrowserViewController {
    
    @objc func close() {
        currentURL = nil
        //         Run later to avoid the "took a long time" log message.
        DispatchQueue.main.async { [ weak self] in
            self?.isExiting = true
            self?.lastReducedStatusBarHeight = 0.0
            self?.presentingViewController?.dismiss(animated: true)
            self?.parent?.dismiss(animated: true)
        }
    }
    
    @IBAction func goBack(_ sender: Any?) {
        webView?.goBack()
    }
    
    @IBAction func goForward(_ sender: Any?) {
        webView?.goForward()
    }
    
}
    // MARK: - WKNavigationDelegate
extension CDVWKInAppBrowserViewController: WKNavigationDelegate {
    func webView(_ theWebView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // loading url, start spinner, update back/forward
//        addressLabel.text = NSLocalizedString("Loading...", comment: "")
//        backButton?.isEnabled = theWebView.canGoBack
//        forwardButton.isEnabled = theWebView.canGoForward
        
//        print(browserOptions.isSpinnerHidden ? "Yes" : "No")
//        if browserOptions.isSpinnerHidden {
//            spinner.startAnimating()
//        }
        
        navigationDelegate?.didStartProvisionalNavigation(theWebView)
    }
    
    func webView(
        _ theWebView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let url = navigationAction.request.url
        let mainDocumentURL = navigationAction.request.mainDocumentURL
        let isTopLevelNavigation = url == mainDocumentURL
        
        if isTopLevelNavigation {
            currentURL = url
        }
        
        navigationDelegate?.webView(theWebView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
    
    func webView(_ theWebView: WKWebView, didFinish navigation: WKNavigation!) {
        // update url, stop spinner, update back/forward
//        addressLabel.text = currentURL?.absoluteString
//        backButton?.isEnabled = theWebView.canGoBack
//        forwardButton.isEnabled = theWebView.canGoForward
        theWebView.scrollView.contentInset = .zero
        
//        spinner.stopAnimating()
        
        navigationDelegate?.didFinishNavigation(theWebView)
    }
    
    func webView(_ theWebView: WKWebView, failedNavigation delegateName: String?, withError error: Error) {
        // log fail message, stop spinner, update back/forward
        print(String(format: "webView:%@ - %ld: %@", delegateName ?? "", (error as NSError).code, error.localizedDescription))
        
//        backButton?.isEnabled = theWebView.canGoBack
//        forwardButton.isEnabled = theWebView.canGoForward
//        spinner.stopAnimating()
        
//        addressLabel.text = NSLocalizedString("Load Error", comment: "")
        
        navigationDelegate?.webView(theWebView, didFailNavigation: error)
    }
    
    func webView(_ theWebView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView(theWebView, failedNavigation: "didFailNavigation", withError: error)
    }
    
    func webView(_ theWebView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView(theWebView, failedNavigation: "didFailProvisionalNavigation", withError: error)
    }
}

// MARK: -  WKScriptMessageHandler delegate

extension CDVWKInAppBrowserViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == BrowserConstants.IAB_BRIDGE_NAME else {
            return
        }
        navigationDelegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: -  UIAdaptivePresentationControllerDelegate
 
extension CDVWKInAppBrowserViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        isExiting = true
    }
}

// MARK: - Configuration

private extension CDVWKInAppBrowserViewController {
    func setupConfiguration() {
        configuration = WKWebViewConfiguration()
        
        var userAgent = configuration.applicationNameForUserAgent
        if setting(forKey: "OverrideUserAgent") == nil && setting(forKey: "AppendUserAgent") != nil {
            userAgent = "\(userAgent ?? "") \(String(describing: setting(forKey: "AppendUserAgent")))"
        }
        
        configuration.applicationNameForUserAgent = userAgent
        configuration.userContentController = WKUserContentController()
        // MARK: - Stub Pool
        configuration.processPool = WKProcessPool()
        // MARK: - Stub Pool
        configuration.userContentController.add(self, name: BrowserConstants.IAB_BRIDGE_NAME)
        
        //WKWebView options
//        configuration.allowsInlineMediaPlayback = browserOptions.isInlineMediaPlaybackAllowed
//        configuration.ignoresViewportScaleLimits = browserOptions.isViewPortScaleEnabled
//        configuration.mediaTypesRequiringUserActionForPlayback = browserOptions.isUserActionRequiredForMediaPlayback ?  .all : []
        
        let contentMode = setting(forKey: "PreferredContentMode") as? String
        if contentMode == "mobile" {
            configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        } else if contentMode == "desktop" {
            configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        }
    }
}

// MARK: - UI Setup

extension CDVWKInAppBrowserViewController {
    
    func setupUI() {
        setupWebView()
//        setupSpinner()
//        setupAddressLabel()
//        setupCloseButton()
//        setupBackButton()
//        setupForwardButton()
//        setupToolbar()
        
        view.backgroundColor = UIColor.clear
//        view.addSubview(toolbar)
//        view.addSubview(addressLabel)
//        view.addSubview(spinner)
    }
    
    func setupWebView() {
        var webViewBounds = view.bounds
        webViewBounds.size.height -= browserOptions.bottomOffset
//        browserOptions.location ? BrowserConstants.FOOTER_HEIGHT : BrowserConstants.TOOLBAR_HEIGHT
        
        webView = WKWebView(frame: webViewBounds, configuration: configuration)
        
        view.addSubview(webView)
        view.sendSubviewToBack(webView)
        
        webView.navigationDelegate = self
        webView.uiDelegate = webViewUIDelegate
        webView.backgroundColor = .white
        if setting(forKey: "OverrideUserAgent") != nil {
            webView.customUserAgent = setting(forKey: "OverrideUserAgent") as? String
        }
        
        webView.clearsContextBeforeDrawing = true
        webView.clipsToBounds = true
        webView.contentMode = .scaleToFill
        webView.isMultipleTouchEnabled = true
        webView.isOpaque = true
        webView.isUserInteractionEnabled = true
        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = true
        webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    func setupSpinner() {
        spinner = UIActivityIndicatorView(style: .medium)
        spinner.alpha = 1.000
        spinner.autoresizesSubviews = true
        spinner.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        spinner.clearsContextBeforeDrawing = false
        spinner.clipsToBounds = false
        spinner.contentMode = .scaleToFill
        spinner.frame = CGRect(x: webView?.frame.midX ?? 0.0, y: webView?.frame.midY ?? 0.0, width: 20.0, height: 20.0)
        spinner.isHidden = false
        spinner.hidesWhenStopped = true
        spinner.isMultipleTouchEnabled = false
        spinner.isOpaque = false
        spinner.isUserInteractionEnabled = false
        spinner.stopAnimating()
    }
    
    func setupCloseButton() {
        closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.close))
        closeButton.isEnabled = true
    }
    
//    func setupToolbar() {
//        let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        let fixedSpaceButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
//        fixedSpaceButton.width = 20
//
//        let toolbarY: CGFloat = toolbarIsAtBottom ? view.bounds.size.height - BrowserConstants.TOOLBAR_HEIGHT : 0.0
//        let toolbarFrame = CGRect(
//            x: 0.0,
//            y: toolbarY,
//            width: view.bounds.size.width,
//            height: BrowserConstants.TOOLBAR_HEIGHT
//        )
//
//        toolbar = UIToolbar(frame: toolbarFrame)
//        toolbar.alpha = 1.000
//        toolbar.autoresizesSubviews = true
//        toolbar.autoresizingMask = toolbarIsAtBottom ? ([.flexibleWidth, .flexibleTopMargin]) : .flexibleWidth
//        toolbar.barStyle = .black
//        toolbar.clearsContextBeforeDrawing = false
//        toolbar.clipsToBounds = false
//        toolbar.contentMode = .scaleToFill
//        toolbar.isHidden = false
//        toolbar.isMultipleTouchEnabled = false
//        toolbar.isOpaque = false
//        toolbar.isUserInteractionEnabled = true
//        toolbar.barTintColor = UIColor(hex: browserOptions.toolbarColor ?? "")
//        toolbar.isTranslucent = browserOptions.isToolbarTranslucent
//
//        if browserOptions.isNavigationButtonsHidden {
//            toolbar.items = [flexibleSpaceButton, closeButton]
//        } else {
//            toolbar.items = [backButton, fixedSpaceButton, forwardButton, flexibleSpaceButton, closeButton]
//        }
//
//        if !browserOptions.isLeftToRight {
//            toolbar.items = toolbarItems?.reversed()
//        }
//    }
    
//    func setupAddressLabel() {
//        let labelInset: CGFloat = 5.0
//        let locationBarY: CGFloat = toolbarIsAtBottom ? view.bounds.size.height - BrowserConstants.FOOTER_HEIGHT : view.bounds.size.height - BrowserConstants.LOCATIONBAR_HEIGHT
//
//        addressLabel = UILabel(
//            frame: CGRect(
//                x: labelInset,
//                y: locationBarY,
//                width: view.bounds.size.width - labelInset,
//                height: BrowserConstants.LOCATIONBAR_HEIGHT
//            )
//        )
//        addressLabel.adjustsFontSizeToFitWidth = false
//        addressLabel.alpha = 1.000
//        addressLabel.autoresizesSubviews = true
//        addressLabel.autoresizingMask = [.flexibleWidth, .flexibleRightMargin, .flexibleTopMargin]
//        addressLabel.backgroundColor = UIColor.clear
//        addressLabel.baselineAdjustment = .alignCenters
//        addressLabel.clearsContextBeforeDrawing = true
//        addressLabel.clipsToBounds = true
//        addressLabel.contentMode = .scaleToFill
//        addressLabel.isEnabled = true
//        addressLabel.isHidden = false
//        addressLabel.lineBreakMode = .byTruncatingTail
//        addressLabel.minimumScaleFactor = 10.0 / UIFont.labelFontSize
//        addressLabel.isMultipleTouchEnabled = false
//        addressLabel.numberOfLines = 1
//        addressLabel.isOpaque = false
//        addressLabel.shadowOffset = CGSize(width: 0.0, height: -1.0)
//        addressLabel.text = NSLocalizedString("Loading...", comment: "")
//        addressLabel.textAlignment = .left
//        addressLabel.textColor = UIColor(white: 1.000, alpha: 1.000)
//        addressLabel.isUserInteractionEnabled = false
//    }
    
//    func setupForwardButton() {
//        let frontArrowString = NSLocalizedString("►", comment: "") // create arrow from Unicode char
//        forwardButton = UIBarButtonItem(title: frontArrowString, style: .plain, target: self, action: #selector(goForward))
//        forwardButton.isEnabled = true
//        forwardButton.imageInsets = .zero
//        if let color = browserOptions.navigationButtonColor {
//            forwardButton.tintColor = UIColor(hex: color)
//        }
//    }
    
//    func setupBackButton() {
//        let backArrowString = NSLocalizedString("◄", comment: "") // create arrow from Unicode char
//        backButton = UIBarButtonItem(title: backArrowString, style: .plain, target: self, action: #selector(goBack))
//        backButton.isEnabled = true
//        backButton.imageInsets = UIEdgeInsets.zero
//        if let color = browserOptions.navigationButtonColor {
//            backButton.tintColor = UIColor(hex: color)
//        }
//    }
    
//    func setCloseButtonTitle(_ title: String?, _ colorString: String?, _ buttonIndex: Int) {
//        let color = UIColor(hex: colorString ?? "") ?? .defaultButtonColor
//        if let title {
//            closeButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(close))
//        } else {
//            closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
//        }
//        closeButton = nil
//        closeButton.isEnabled = true
//        closeButton.tintColor = color
//        toolbar.items?[buttonIndex] = closeButton
//    }
    
//    func showLocationBar(_ show: Bool) {
//        var locationbarFrame = addressLabel.frame
//        var webViewBounds = view.bounds
//
//        // prevent double show/hide
//        guard show == addressLabel.isHidden else {
//            return
//        }
//
//        addressLabel.isHidden = !show
//
//        if show {
//            webViewBounds.size.height -= toolbar.isHidden ? BrowserConstants.LOCATIONBAR_HEIGHT : BrowserConstants.FOOTER_HEIGHT
//            locationbarFrame.origin.y = webViewBounds.size.height
//            addressLabel.frame = locationbarFrame
//        } else {
//            webViewBounds.size.height -= toolbar.isHidden ? .zero : BrowserConstants.TOOLBAR_HEIGHT
//        }
//
//        self.webView.frame = webViewBounds
//    }
    
//    func showToolBar(_ show: Bool, _ toolbarPosition: String?) {
//        var toolbarFrame = toolbar.frame
//        var webViewBounds = view.bounds
////        let isLocationBarHidden = true
//
//        let isOnTop = toolbarPosition == BrowserConstants.kInAppBrowserToolbarBarPositionTop
//        // prevent double show/hide
////        guard show == toolbar.isHidden else {
////            return
////        }
//
////        toolbar.isHidden = !show
//
////        if !isLocationBarHidden {
//            // move locationBar down
////            var locationbarFrame = addressLabel.frame
////            locationbarFrame.origin.y = webViewBounds.size.height
////            addressLabel.frame = locationbarFrame
////        }
//
////        if show {
//            toolbarFrame.origin.y = isOnTop ? .zero : webViewBounds.size.height + BrowserConstants.LOCATIONBAR_HEIGHT
//            toolbar.frame = toolbarFrame
//
//            webViewBounds.size.height -= BrowserConstants.TOOLBAR_HEIGHT
//            webViewBounds.origin.y += isOnTop ? toolbarFrame.size.height : .zero
////        }
////        else {
//            // locationBar is on top of toolBar, hide toolBar
//            // put locationBar at the bottom
////            webViewBounds.size.height -= isLocationBarHidden ? .zero : BrowserConstants.LOCATIONBAR_HEIGHT
////        }
//        self.webView.frame = webViewBounds
//    }
    
    // MARK: - Refactor
    
    func rePositionViews() {
        var viewBounds = webView.bounds
        let statusBarHeight = UIApplication.statusBarHeight
        
        // orientation portrait or portraitUpsideDown: status bar is on the top and web view is to be aligned to the bottom of the status bar
        // orientation landscapeLeft or landscapeRight: status bar height is 0 in but lets account for it in case things ever change in the future
        viewBounds.origin.y = statusBarHeight
        
        // account for web view height portion that may have been reduced by a previous call to this method
        viewBounds.size.height = viewBounds.size.height - statusBarHeight + lastReducedStatusBarHeight
        lastReducedStatusBarHeight = statusBarHeight
        
//        if browserOptions.toolbar && browserOptions.toolbarPosition == BrowserConstants.kInAppBrowserToolbarBarPositionTop {
//            // if we have to display the toolbar on top of the web view, we need to account for its height
//            viewBounds.origin.y += BrowserConstants.TOOLBAR_HEIGHT
//            toolbar.frame = CGRect(
//                x: toolbar.frame.origin.x,
//                y: statusBarHeight,
//                width: toolbar.frame.size.width,
//                height: toolbar.frame.size.height
//            )
//        }
        
        webView.frame = viewBounds
    }
}

// MARK: - Utils

extension CDVWKInAppBrowserViewController {
    func navigate(to url: URL?) {
        guard let url else { return }
        
        if url.scheme == "file" {
            webView?.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func setting(forKey key: String?) -> Any? {
        return settings?[key?.lowercased() ?? ""]
    }
}
