import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: UserSession
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("features".localized(session.language))) {
                    Button(action: { showingOnboarding = true }) {
                        Label("Show Tutorial", systemImage: "info.circle")
                    }
                }
                
                Section(header: Text("Contact & Links")) {
                    Link(destination: URL(string: "https://x.com/iBadDroid")!) {
                        Label("Follow on X (@iBadDroid)", systemImage: "link")
                    }
                    
                    Link(destination: URL(string: "https://github.com/aftermath9")!) {
                        Label("GitHub (aftermath9)", systemImage: "link")
                    }
                }
                
                Section {
                    footerContent()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("settings".localized(session.language))
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    private func footerContent() -> some View {
        VStack(spacing: 5) {
            Text("made with ❤️ by aftermath9")
                .font(.footnote)
                .foregroundColor(.gray)
            Text("Version 1.0.0")
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.5))
        }
    }
}
