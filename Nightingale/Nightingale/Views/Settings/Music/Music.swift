import SwiftUI

extension Color {
    func darker(by percentage: Double = 20.0) -> Color {
        let uiColor = UIColor(self) // Convert SwiftUI Color to UIColor
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0

        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return Color(
                red: max(red - percentage / 100, 0),
                green: max(green - percentage / 100, 0),
                blue: max(blue - percentage / 100, 0),
                opacity: Double(alpha)
            )
        }

        return self // Return original color if conversion fails
    }
}

struct Music: View {
    var body: some View {
        CustomCard {
            VStack(alignment: .center, spacing: 10) {
                Text("Music")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack(spacing: 10) {
                    AddMusicButton()
                    RemoveMusicButton()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
