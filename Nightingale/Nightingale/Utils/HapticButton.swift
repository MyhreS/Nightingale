import SwiftUI
import UIKit

struct HapticButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            label()
        }
    }
}

enum Haptics {
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
