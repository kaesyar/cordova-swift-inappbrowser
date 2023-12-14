import Foundation
import WebKit

class CDVWKInAppBrowserUIDelegate: NSObject, WKUIDelegate {
    var viewController: UIViewController?

    private var title: String

    init(title: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "") {
        self.title = title
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let ok = UIAlertAction(
            title: NSLocalizedString("OK", comment: "OK"),
            style: .default,
            handler: { action in
                completionHandler()
                alert.dismiss(animated: true)
            })

        alert.addAction(ok)

        viewController?.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let ok = UIAlertAction(
            title: NSLocalizedString("OK", comment: "OK"),
            style: .default,
            handler: { action in
                completionHandler(true)
                alert.dismiss(animated: true)
            })

        alert.addAction(ok)

        let cancel = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel"),
            style: .default,
            handler: { action in
                completionHandler(false)
                alert.dismiss(animated: true)
            })
        alert.addAction(cancel)

        viewController?.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = UIAlertController(
            title: title,
            message: prompt,
            preferredStyle: .alert
        )

        let ok = UIAlertAction(
            title: NSLocalizedString("OK", comment: "OK"),
            style: .default,
            handler: { action in
                completionHandler((alert.textFields?[0])?.text ?? "")
                alert.dismiss(animated: true)
            })

        alert.addAction(ok)

        let cancel = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel"),
            style: .default,
            handler: { action in
                completionHandler(nil)
                alert.dismiss(animated: true)
            })
        alert.addAction(cancel)

        alert.addTextField(configurationHandler: { textField in
            textField.text = defaultText
        })

        viewController?.present(alert, animated: true)
    }
}
