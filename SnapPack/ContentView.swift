import SwiftUI

struct ContentView: View {
    @StateObject var session = UserSession()
    @StateObject var downloadManager: DownloadManager
    
    init() {
        let session = UserSession()
        _session = StateObject(wrappedValue: session)
        _downloadManager = StateObject(wrappedValue: DownloadManager(session: session))
    }
    
    var body: some View {
        TabView {
            DownloaderView(downloadManager: downloadManager)
                .tabItem {
                    Label("downloader".localized(session.language), systemImage: "square.and.arrow.down")
                }
            
            GalleryView()
                .tabItem {
                    Label("gallery".localized(session.language), systemImage: "photo.on.rectangle")
                }
            
            SettingsView()
                .tabItem {
                    Label("settings".localized(session.language), systemImage: "gearshape")
                }
        }
        .environment(\.layoutDirection, session.language == "ar" ? .rightToLeft : .leftToRight)
        .environmentObject(session)
        .fullScreenCover(isPresented: Binding(
            get: { !session.hasCompletedOnboarding },
            set: { session.hasCompletedOnboarding = !$0 }
        )) {
            OnboardingView()
                .environmentObject(session)
        }
    }
}

#Preview {
    ContentView()
}
