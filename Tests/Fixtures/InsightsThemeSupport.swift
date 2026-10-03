import SwiftUI

// The standalone macOS data tests do not load the UIKit app theme or user
// preferences. Supply only the presentation dependency needed by InsightsMetric.
extension Color {
    static var pitcheeAccent: Color { .accentColor }
}
