//
//  JavaScriptInjector.swift
//  NostrSecond
//
//  Created by Shakhzod Omonbayev on 26/10/23.
//

import Foundation

extension CDVWKInAppBrowser {
    
    func injectDeferredObject(_ source: String?, withWrapper jsWrapper: String?) {
        // Ensure a message handler bridge is created to communicate with the CDVWKInAppBrowserViewController
        evaluateJavaScript(String(format: "(function(w){if(!w._cdvMessageHandler) {w._cdvMessageHandler = function(id,d){w.webkit.messageHandlers.%@.postMessage({d:d, id:id});}}})(window)", BrowserConstants.IAB_BRIDGE_NAME))
        
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: [source], options: [])
        } catch {
        }
        
        var sourceArrayString: String?
        if let jsonData {
            sourceArrayString = String(data: jsonData, encoding: .utf8)
        }
        if let sourceArrayString {
            let sourceString = (sourceArrayString as NSString).substring(with: NSRange(location: 1, length: sourceArrayString.count - 2))
            let jsToInject = String(format: jsWrapper ?? "", sourceString)
            evaluateJavaScript(jsToInject)
        }
    }
    
    func evaluateJavaScript(_ script: String?) {
        let _script = script
        DispatchQueue.main.async { [weak self] in
            self?.inAppBrowserViewController?.webView?.evaluateJavaScript(script ?? "") { result, error in
                if error == nil {
                    if let result {
                        print("\(result)")
                    }
                } else {
                    print("evaluateJavaScript error : \(error?.localizedDescription ?? "") : \(_script ?? "")")
                }
            }
        }
    }
}
