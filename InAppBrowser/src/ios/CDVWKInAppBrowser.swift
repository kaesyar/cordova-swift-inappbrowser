@objc(CDVWKInAppBrowser)
final class CDVWKInAppBrowser: CDVPlugin {
    var tmpWindow: UIWindow?
    
//    private var beforeLoad: String?
    private var fromOpen: Bool = false
    private var waitBeforeLoad = false
    
    var inAppBrowserViewController: CDVWKInAppBrowserViewController?
    var currentCallbackId = String()
    
    @objc(open:)
    func open(_ command: CDVInvokedUrlCommand) {
        currentCallbackId = command.callbackId
        
        let url = command.arguments[0] as? String
        let target = command.arguments[1] as? String  ?? BrowserConstants.kInAppBrowserTargetSelf
        let options = command.arguments[2] as? String ?? ""
        
        guard let url else {
            failureCallback(msg: "incorrect number of arguments")
            return
        }
        
        let baseUrl = webViewEngine.url()
        let absoluteUrl = URL(string: url, relativeTo: baseUrl)?.absoluteURL
        
        if target == BrowserConstants.kInAppBrowserTargetSelf {
            open(inCordovaWebView: absoluteUrl!, withOptions: options)
        } else if isSystemUrl(absoluteUrl) {
            open(inSystem: absoluteUrl)
        } else {
            open(inAppBrowser: absoluteUrl!, withOptions: options)
        }
        successCallback()
    }
    
    @objc(show:)
    func show(_ command: CDVInvokedUrlCommand?) {
        guard let inAppBrowserViewController else {
            print("Tried to show IAB after it was closed.")
            return
        }
        
        guard !inAppBrowserViewController.isBeingPresented else {
            print("Tried to show IAB while already shown")
            return
        }
        
        let nav = CDVInAppBrowserNavigationController(rootViewController: inAppBrowserViewController)
        nav.orientationDelegate = inAppBrowserViewController as? CDVScreenOrientationDelegate
        nav.navigationBar.isHidden = true
        nav.modalPresentationStyle = inAppBrowserViewController.modalPresentationStyle
        nav.presentationController?.delegate = inAppBrowserViewController
        self.viewController.present(nav, animated: true)
    }
    
    @objc(hide:)
    func hide(_ command: CDVInvokedUrlCommand) {
        guard let inAppBrowserViewController else {
            print("Tried to hide IAB after it was closed.")
            return
        }
        
        guard !inAppBrowserViewController.view.isHidden else {
            print("Tried to hide IAB while already hidden")
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.inAppBrowserViewController?.presentingViewController?.dismiss(animated: true)
        }
    }
    
    @objc(load:)
    func load(command: CDVInvokedUrlCommand) {
        
        guard let urlStr = command.argument(at: 0) as? String else {
            print("loadAfterBeforeload called with nil argument, ignoring.")
            return
        }
        
        guard waitBeforeLoad else {
            print("unexpected loadAfterBeforeload called without feature beforeload=get|post")
            return
        }
        
        guard let inAppBrowserViewController else {
            print("Tried to invoke loadAfterBeforeload on IAB after it was closed.")
            return
        }
        
        let url = URL(string: urlStr)
        
        waitBeforeLoad = false
        inAppBrowserViewController.navigate(to: url)
    }
    
    @objc(injectScriptCode:)
    func injectScriptCode(_ command: CDVInvokedUrlCommand?) {
        guard let stringArgument = command?.arguments[0] as? String else {
            return
        }
        
        guard let callbackId = command?.callbackId, callbackId != "INVALID" else {
            return
        }

        let jsWrapper = String(format: "_cdvMessageHandler('%@',JSON.stringify([eval(%%@)]));", callbackId)
        
        injectDeferredObject(stringArgument, withWrapper: jsWrapper)
    }
    
    @objc(injectStyleCode:)
    func injectStyleCode(_ command: CDVInvokedUrlCommand?) {
        guard let stringArgument = command?.arguments[0] as? String else {
            return
        }
        
        let jsWrapper: String
        
        if let callbackId = command?.callbackId, callbackId != "INVALID" {
            jsWrapper = String(format: "(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", callbackId)
        } else {
            jsWrapper = "(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)"
        }
        
        injectDeferredObject(stringArgument, withWrapper: jsWrapper)
    }
    
    @objc(close:)
    func close(_ command: CDVInvokedUrlCommand?) {
        
        guard let inAppBrowserViewController else {
            print("IAB.close() called but it was already closed.")
            return
        }
        
        inAppBrowserViewController.close()
    }
}

// MARK: - Web View Manager

extension CDVWKInAppBrowser {
    func webView(
        _ theWebView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        
        let url = navigationAction.request.url
        let mainDocumentURL = navigationAction.request.mainDocumentURL
        let isTopLevelNavigation = url == mainDocumentURL
        var shouldStart = true
        let useBeforeLoad = false
//        let httpMethod = navigationAction.request.httpMethod
//        var errorMessage: String?
        
//        if beforeLoad == "post" {
//            //TODO handle POST requests by preserving POST data then remove this condition
//            errorMessage = "beforeload doesn't yet support POST requests"
//        } else if isTopLevelNavigation && ((beforeLoad == "yes") || ((beforeLoad == "get") && (httpMethod == "GET"))) {
//            useBeforeLoad = true
//        }
        
        // When beforeload, on first URL change, initiate JS callback. Only after the beforeload event, continue.
        if waitBeforeLoad && useBeforeLoad {
            let msg = ["type": "beforeload", "url": url?.absoluteString ?? ""]
            successCallback(msg: msg)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        
//        if let errorMessage {
//            let msg = ["type": "loaderror", "url": url?.absoluteString ?? "", "code": "-1", "message": errorMessage]
//            failureCallback(msg: msg)
//        }
        
        //if is an app store, tel, sms, mailto or geo link, let the system handle it, otherwise it fails to load it
        let allowedSchemes = ["itms-appss", "itms-apps", "tel", "sms", "mailto", "geo"]
        
        if allowedSchemes.contains(url?.scheme ?? "") {
            theWebView.stopLoading()
            open(inSystem: url)
            shouldStart = false
        } else if !currentCallbackId.isEmpty && isTopLevelNavigation {
//            print("^", navigationAction.request.)
            if fromOpen {
                // Send a loadstart event for each top-level navigation (includes redirects).
                let msg = ["type": "loadstart", "url": url?.absoluteString ?? ""]
                successCallback(msg: msg)
            }
        }
        fromOpen = false
        
        waitBeforeLoad = useBeforeLoad
        if shouldStart {
            // Fix GH-417 & GH-424: Handle non-default target attribute
            // Based on https://stackoverflow.com/a/25713070/777265
            if navigationAction.targetFrame == nil {
                theWebView.load(navigationAction.request)
                decisionHandler(WKNavigationActionPolicy.cancel)
            } else {
                decisionHandler(WKNavigationActionPolicy.allow)
            }
        } else {
            decisionHandler(WKNavigationActionPolicy.cancel)
        }
    }
    
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if let messageContent = message.body as? [AnyHashable : Any] {
            
            guard let scriptCallbackId = messageContent["id"] as? String else {
                failureCallback()
                return
            }
            
            guard let scriptResult = messageContent["d"] as? String else {
                successCallback()
                return
            }

            guard
                let data = scriptResult.data(using: .utf8),
                let serializedData = try? JSONSerialization.jsonObject(with: data),
                let decodedResult = serializedData as? [AnyHashable] else  {
                exceptionCallback()
                return
            }
            
            successCallback(msg: decodedResult, callbackId: scriptCallbackId)
        } else if !currentCallbackId.isEmpty {
            // Send a message event
            guard let messageContent = message.body as? String else {
                return
            }
            
            guard let data = messageContent.data(using: .utf8) else {
                return
            }
                
            guard let decodedResult = try? JSONSerialization.jsonObject(with: data) else {
                return
            }
            
            let msg: [AnyHashable : Any] = ["type": "message", "data": decodedResult]
            
            successCallback(msg: msg, callbackId: currentCallbackId)
        }
    }
    
    func didStartProvisionalNavigation(_ theWebView: WKWebView?) {
        print("didStartProvisionalNavigation")
//        self.inAppBrowserViewController?.currentURL = theWebView?.url
    }
    
    func didFinishNavigation(_ theWebView: WKWebView?) {
        print("didFinishProvisionalNavigation")
        guard !currentCallbackId.isEmpty else { return }
        
        let url = theWebView?.url?.absoluteString ?? (inAppBrowserViewController?.currentURL?.absoluteString ?? "")
        let msg = ["type": "loadstop", "url": url]
        
        successCallback(msg: msg, callbackId: currentCallbackId)
    }
    
    func webView(_ theWebView: WKWebView?, didFailNavigation error: Error?) {
        
        guard !currentCallbackId.isEmpty else {
            return
        }
        
        guard let error else {
            failureCallback()
            return
        }

        let url = theWebView?.url?.absoluteString ?? (inAppBrowserViewController?.currentURL?.absoluteString ?? "")
        
        let msg = [
            "type": "loaderror",
            "url": url,
            "code": (error as NSError).code,
            "message": error.localizedDescription
        ] as [String : Any]
        
        failureCallback(msg: msg)
    }
    
    func browserExit() {
        
        if !currentCallbackId.isEmpty {
            guard let msg = [
                "type": "exit"
            ].json else {
                failureCallback()
                return
            }
            successCallback(msg: msg)
            currentCallbackId = ""
        }
        
        inAppBrowserViewController?.configuration.userContentController.removeScriptMessageHandler(forName: BrowserConstants.IAB_BRIDGE_NAME)
        inAppBrowserViewController?.configuration = nil
        
        inAppBrowserViewController?.webView?.stopLoading()
        inAppBrowserViewController?.webView?.removeFromSuperview()
        inAppBrowserViewController?.webView?.uiDelegate = nil
        inAppBrowserViewController?.webView?.navigationDelegate = nil
        inAppBrowserViewController?.webView = nil
        
        // Set navigationDelegate to nil to ensure no callbacks are received from it.
        inAppBrowserViewController?.navigationDelegate = nil
        inAppBrowserViewController = nil
        
        // Set tmpWindow to hidden to make main webview responsive to touch again
        // Based on https://stackoverflow.com/questions/4544489/how-to-remove-a-uiwindow
        tmpWindow?.isHidden = true
        tmpWindow = nil
    }

}

// MARK: - Callback Functions
extension CDVWKInAppBrowser {
    func failureCallback(msg: String = "") {
        
        let result = msg.isEmpty
        ? CDVPluginResult(status: CDVCommandStatus_ERROR)
        : CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg)
        
        result?.setKeepCallbackAs(true)
        commandDelegate!.send(result, callbackId: currentCallbackId)
    }
    
    func failureCallback(msg: [AnyHashable: Any], callbackId: String = "") {
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg)
        let id = callbackId.isEmpty ? currentCallbackId : callbackId
        
        result?.setKeepCallbackAs(true)
        commandDelegate!.send(result, callbackId: id)
    }
    
    func successCallback(msg: String = "", callbackId: String = "") {
        
        let result = msg.isEmpty
        ? CDVPluginResult(status: CDVCommandStatus_OK)
        : CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg)
        
        let id = callbackId.isEmpty ? currentCallbackId : callbackId
        
        result?.setKeepCallbackAs(true)
        commandDelegate!.send(result, callbackId: id)
    }
    
    func successCallback(msg: [AnyHashable], callbackId: String = "") {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg)
        let id = callbackId.isEmpty ? currentCallbackId : callbackId
        
        result?.setKeepCallbackAs(true)
        commandDelegate!.send(result, callbackId: id)
    }
    
    func successCallback(msg: [AnyHashable: Any], callbackId: String = "") {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg)
        let id = callbackId.isEmpty ? currentCallbackId : callbackId
        
        result?.setKeepCallbackAs(true)
        commandDelegate!.send(result, callbackId: id)
    }

    func exceptionCallback() {
        let result = CDVPluginResult(status: CDVCommandStatus_JSON_EXCEPTION)
        
        result?.setKeepCallbackAs(true)
        commandDelegate!.send(result,callbackId: currentCallbackId)
    }
}

// MARK: - Utils
extension CDVWKInAppBrowser {
    override func pluginInitialize() {
//        beforeLoad = ""
        waitBeforeLoad = false
    }
    
    override func onReset() {
        close(nil)
    }
    
    func isSystemUrl(_ url: URL?) -> Bool {
        url?.host == "itunes.apple.com"
    }
}

// MARK: - Open

private extension CDVWKInAppBrowser {
    private func open(inCordovaWebView url: URL?, withOptions options: String?) {
        
        guard let url else { return }
        
        let request = URLRequest(url: url)
        webViewEngine.load(request)
    }
    
    private func open(inSystem url: URL?) {
        
        guard let url else { return }
        
        guard UIApplication.shared.canOpenURL(url) else { return }
        
        let notification = Notification(name: Notification.Name.CDVPluginHandleOpenURL, object: url)
        
        NotificationCenter.default.post(notification)
        UIApplication.shared.open(url)
    }
    
    private func open(inAppBrowser url: URL, withOptions options: String) {
//        let browserOptions = CDVInAppBrowserOptions.parseOptions(options)
        let browserOptions = CDVInAppBrowserOptions(beforeLoad: true, beforeBlank: false, hidden: false)
        let dataStore = WKWebsiteDataStore.default()
        let cookieStore = dataStore.httpCookieStore
        
//        if browserOptions.isDataCleared {
//
            dataStore.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: .distantPast
            ) {
                self.inAppBrowserViewController?.webView?.configuration.processPool = WKProcessPool()
                // create new process pool to flush all data
            }
//        }
//
//        if browserOptions.isCacheCleaned {
            cookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    cookieStore.delete(cookie)
                }
            }
//        }
//
//        if browserOptions.isSessionCacheCleared {
            cookieStore.getAllCookies { cookies in
                for cookie in cookies where cookie.isSessionOnly {
                    cookieStore.delete(cookie)
                }
            }
//        }
        
        if inAppBrowserViewController == nil {
            inAppBrowserViewController = CDVWKInAppBrowserViewController(
                browserOptions: browserOptions,
                settings: commandDelegate.settings
            )
            inAppBrowserViewController?.navigationDelegate = self
            
            if let orientationDelegate = viewController as? CDVScreenOrientationDelegate {
                inAppBrowserViewController?.orientationDelegate = orientationDelegate
            }
        }
        
//        inAppBrowserViewController?.showLocationBar(browserOptions.location)
//        inAppBrowserViewController?.showToolBar(browserOptions.toolbar, browserOptions.toolbarPosition)
        
//        if browserOptions.closeButtonCaption != nil || browserOptions.closeButtonColor != nil {
//            let closeButtonIndex = browserOptions.isLeftToRight ? (browserOptions.isNavigationButtonsHidden ? 1 : 4) : 0
//            inAppBrowserViewController?.setCloseButtonTitle(browserOptions.closeButtonCaption, browserOptions.closeButtonColor, closeButtonIndex)
//        }
        
        // Set Presentation Style
        let presentationStyle: UIModalPresentationStyle = .fullScreen // default
//        if browserOptions.presentationStyle != nil {
//            if browserOptions.presentationStyle?.lowercased() == "pagesheet" {
//                presentationStyle = .pageSheet
//            } else if browserOptions.presentationStyle?.lowercased() == "formsheet" {
//                presentationStyle = .formSheet
//            }
//        }
        inAppBrowserViewController?.modalPresentationStyle = presentationStyle
        
        // Set Transition Style
        let transitionStyle: UIModalTransitionStyle = .coverVertical // default
//        if browserOptions.transitionStyle != nil {
//            if browserOptions.transitionStyle?.lowercased() == "fliphorizontal" {
//                transitionStyle = .flipHorizontal
//            } else if browserOptions.transitionStyle?.lowercased() == "crossdissolve" {
//                transitionStyle = .crossDissolve
//            }
//        }
        inAppBrowserViewController?.modalTransitionStyle = transitionStyle
        
        //prevent webView from bouncing
//        inAppBrowserViewController?.webView.scrollView.bounces = !browserOptions.isOverScrollDisabled
        
        // use of beforeload event
//        beforeLoad = browserOptions.beforeLoad ?? true
        waitBeforeLoad = browserOptions.beforeLoad
//        !(beforeLoad == "")
        
        inAppBrowserViewController?.navigate(to: url)
        if !browserOptions.hidden {
            fromOpen = true
            show(nil)
        }
    }
}
