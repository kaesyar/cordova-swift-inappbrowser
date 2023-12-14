import Foundation

struct CDVInAppBrowserOptions: Codable {
    var beforeLoad: Bool = true
    var beforeBlank: Bool = false
    var hidden: Bool = false
    var bottomOffset: CGFloat = 44.0
    
    enum CodingKeys: String, CodingKey {
        case beforeLoad = "beforeload"
        case beforeBlank = "beforeblank"
        case hidden = "hidden"
        case bottomOffset = "bottomoffset"
    }
}
