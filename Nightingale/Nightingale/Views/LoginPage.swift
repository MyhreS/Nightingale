import SwiftUI

struct LoginPage: View {
    let onLogin: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient (
                    colors: [.orange.opacity(0.8), .orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)
                    
                    Text("Nightingale")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Text("Connect a SoundCloud account to be able to play music in this app.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: onLogin) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text("Log in with SoundCloud")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding()                
            }
        }
        
    }
}
