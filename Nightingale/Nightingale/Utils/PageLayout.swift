import SwiftUI

struct PageLayout<Content: View, Trailing: View>: View {
    let title: String
    let trailing: Trailing?
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) where Trailing == EmptyView {
        self.title = title
        self.trailing = nil
        self.content = content()
    }

    init(title: String, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing()
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if let trailing = trailing {
                    trailing
                }
            }
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
    }
}
