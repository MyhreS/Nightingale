import UIKit

/// Provides haptic feedback when the button is tapped
func provideHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare() // ✅ Prepares the haptic feedback to avoid delay
    generator.impactOccurred()
}
