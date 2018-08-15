import UIKit

extension UIColor {

    // Global

    static let accent = UIColor(red:0.19, green:0.62, blue:0.89, alpha:1.00)//UIColor(red: 0.09, green: 0.82, blue: 0.39, alpha: 1.00) // UIColor(red:0.34, green:0.45, blue:0.98, alpha:1.00)
    static let mainBackground = UIColor.white

    // Video Library

    static let videoLibraryCellGradient = [UIColor.black.withAlphaComponent(0),
                                           UIColor.black.withAlphaComponent(0.6)]

    // Player

    static let timeSliderValueIndicator = UIColor.accent
    static let timeSliderTrack = UIColor(white: 0.65, alpha: 1)
    static let disabledTimeSliderTrack = UIColor.timeSliderTrack.withAlphaComponent(0.4)

    static let playerOverlayNavigationGradient = [UIColor.black.withAlphaComponent(0.4),
                                                  UIColor.black.withAlphaComponent(0)]

    static let playerOverlayControlsGradient = [UIColor.black.withAlphaComponent(0),
                                                UIColor.black.withAlphaComponent(0.4)]
}
