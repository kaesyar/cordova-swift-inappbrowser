//
//  UIApplication+.swift
//  NostrSecond
//
//  Created by Shakhzod Omonbayev on 23/10/23.
//

import UIKit

extension UIApplication {
    static var interfaceOrientation: UIInterfaceOrientation {
        UIApplication
            .shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first!
            .interfaceOrientation
    }
    
    static var keyWindow: UIWindow? {
      let allScenes = UIApplication.shared.connectedScenes
      for scene in allScenes {
        guard let windowScene = scene as? UIWindowScene else { continue }
        for window in windowScene.windows where window.isKeyWindow {
           return window
         }
       }
        return nil
    }
    
    static var statusBarStyle: Int {
        UIApplication.keyWindow?.windowScene?.statusBarManager?.statusBarStyle.rawValue ?? 0
    }
    
    static var statusBarHeight: CGFloat {
        UIApplication.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.size.height ?? 0
    }
}
