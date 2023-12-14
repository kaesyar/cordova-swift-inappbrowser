import UIKit

class CDVInAppBrowserNavigationController: UINavigationController {
    weak var orientationDelegate: CDVScreenOrientationDelegate?

    //MARK: - Check if this methods are needed
    
    override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        guard presentedViewController != nil else { return }
        
        super.dismiss(animated: animated, completion: completion)
    }
    
    func invertFrameIfNeeded(_ rect: CGRect) -> CGRect {
        var rect = rect
        rect.origin = .zero
        
        if UIApplication.interfaceOrientation.isLandscape {
            swap(&rect.size.width, &rect.size.height)
        }
        
        return rect
    }
}
