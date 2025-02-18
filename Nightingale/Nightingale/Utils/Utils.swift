import UIKit
import Foundation
import SwiftUI

/// Provides haptic feedback when the button is tapped
func provideHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare() // ✅ Prepares the haptic feedback to avoid delay
    generator.impactOccurred()
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
