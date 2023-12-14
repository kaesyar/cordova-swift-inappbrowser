//
//  BrowserConstants.swift
//  NostrSecond
//
//  Created by Shakhzod Omonbayev on 26/10/23.
//

import Foundation

enum BrowserConstants {
    static let kInAppBrowserTargetSelf = "_self"
    static let kInAppBrowserTargetSystem = "_system"
    static let kInAppBrowserTargetBlank = "_blank"

    static let kInAppBrowserToolbarBarPositionBottom = "bottom"
    static let kInAppBrowserToolbarBarPositionTop = "top"

    static let IAB_BRIDGE_NAME = "cordova_iab"

    static let TOOLBAR_HEIGHT = 44.0
    static let LOCATIONBAR_HEIGHT: Double = 21.0
//    21.0
    static let FOOTER_HEIGHT = LOCATIONBAR_HEIGHT + TOOLBAR_HEIGHT
}
