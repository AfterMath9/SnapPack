import SwiftUI
import AVKit

struct GalleryView: View {
    @EnvironmentObject var session: UserSession
    @State private var sortOption: SortOption = .year
    @State private var showingLocked = false
    @State private var isUnlocked = false
    @State private var selectedMedia: SnapMedia?
    
    // Select Mode
    @State private var isSelectMode = false
    @State private var selectedItems = Set<UUID>()
    
    // Passcode
    @State private var showingPasscodeSetup = false
    @State private var showingPasscodeEntry = false
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case year = "By Year"
    }
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var columns: [GridItem] {
        let count = sizeClass == .regular ? 6 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }
    
    var groupedMedias: [(String, [SnapMedia])] {
        let items = session.downloadedMedia.filter { $0.isLocked == showingLocked }
        
        switch sortOption {
        case .newest:
            return [("All", items.sorted { $0.date > $1.date })]
        case .oldest:
            return [("All", items.sorted { $0.date < $1.date })]
        case .year:
            let grouped = Dictionary(grouping: items) { media in
                Calendar.current.component(.year, from: media.date).description
            }
            return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if showingLocked && !isUnlocked {
                        VStack(spacing: 24) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 80))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                            
                            Text("safe_private".localized(session.language))
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("vault_secured".localized(session.language))
                                .foregroundColor(.gray)
                            
                            Button(session.hasPasscode ? "enter_passcode".localized(session.language) : "create_passcode".localized(session.language)) {
                                if session.hasPasscode {
                                    showingPasscodeEntry = true
                                } else {
                                    showingPasscodeSetup = true
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    } else {
                        if session.downloadedMedia.filter({ $0.isLocked == showingLocked }).isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("no_media".localized(session.language))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) { // Removed pinnedViews to ensure absolute stability
                                    ForEach(groupedMedias, id: \.0) { group in
                                        Section(header: GroupHeader(title: group.0)) {
                                            LazyVGrid(columns: columns, spacing: 2) {
                                                ForEach(group.1) { item in
                                                    MediaThumbnail(
                                                        item: item, 
                                                        isSelectMode: isSelectMode, 
                                                        isSelected: selectedItems.contains(item.id)
                                                    )
                                                    .id(item.id) // Ensure unique identity to prevent jumping
                                                    .onTapGesture {
                                                        if isSelectMode {
                                                            if selectedItems.contains(item.id) {
                                                                selectedItems.remove(item.id)
                                                            } else {
                                                                selectedItems.insert(item.id)
                                                            }
                                                        } else {
                                                            selectedMedia = item
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .id(group.0)
                                    }
                                }
                            }
                            .transaction { transaction in
                                transaction.animation = nil // Disable all layout animations for the scroll content
                            }
                        }
                    }
                    
                }
            }
            .overlay(alignment: .bottom) {
                if isSelectMode {
                    HStack(spacing: 30) {
                        Button(action: deleteSelected) {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("delete".localized(session.language)).font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundColor(.red)
                        
                        Button(action: shareSelected) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("share".localized(session.language)).font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        
                        Button(action: toggleLockSelected) {
                            VStack(spacing: 4) {
                                Image(systemName: showingLocked ? "lock.open" : "lock")
                                Text("locker".localized(session.language)).font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.95))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: isSelectMode)
                }
            }
            .navigationTitle(showingLocked ? "locker".localized(session.language) : "gallery".localized(session.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectMode {
                        Button("cancel".localized(session.language)) {
                            isSelectMode = false
                            selectedItems.removeAll()
                        }
                    } else {
                        Menu {
                            Picker("sort_by".localized(session.language), selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue.lowercased().localized(session.language)).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !isSelectMode {
                        Button(action: {
                            withAnimation {
                                showingLocked.toggle()
                                if !showingLocked { isUnlocked = false }
                            }
                        }) {
                            Image(systemName: showingLocked ? "photo.on.rectangle" : "lock.shield")
                                .foregroundColor(showingLocked ? .blue : .gray)
                        }
                    }
                    
                    if !showingLocked || isUnlocked {
                        Button(action: {
                            isSelectMode.toggle()
                            if !isSelectMode { selectedItems.removeAll() }
                        }) {
                            Text(isSelectMode ? "done".localized(session.language) : "select".localized(session.language))
                                .frame(width: 80, alignment: .trailing) // Fixed width to prevent toolbar shifting
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedMedia) { media in
                MediaDetailView(media: media)
            }
            .sheet(isPresented: $showingPasscodeSetup) {
                PasscodeSetupView().environmentObject(session)
            }
            .fullScreenCover(isPresented: $showingPasscodeEntry) {
                PasscodeEntryView(onSuccess: { isUnlocked = true }).environmentObject(session)
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func deleteSelected() {
        let itemsToDelete = session.downloadedMedia.filter { selectedItems.contains($0.id) }
        session.deleteMedia(itemsToDelete)
        isSelectMode = false
        selectedItems.removeAll()
    }
    
    private func shareSelected() {
        let urls = session.downloadedMedia
            .filter { selectedItems.contains($0.id) }
            .compactMap { item -> URL? in
                guard let path = item.localPath else { return nil }
                return session.getDocumentsDirectory().appendingPathComponent(path)
            }
        
        if !urls.isEmpty {
            shareSheet(items: urls)
        }
    }
    
    private func shareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    private func toggleLockSelected() {
        let itemsToMove = session.downloadedMedia.filter { selectedItems.contains($0.id) }
        session.moveMediaToVault(itemsToMove, locked: !showingLocked)
        isSelectMode = false
        selectedItems.removeAll()
    }
}

struct MediaDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    let media: SnapMedia
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(media.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.bold())
                        Text(media.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        if let path = media.localPath {
                            let url = session.getDocumentsDirectory().appendingPathComponent(path)
                            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                
                                if let popover = activityVC.popoverPresentationController {
                                    let bounds = rootViewController.view.bounds
                                    popover.sourceView = rootViewController.view
                                    popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
                                    popover.permittedArrowDirections = []
                                }
                                
                                rootViewController.present(activityVC, animated: true)
                            }
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                if let path = media.localPath {
                    let url = session.getDocumentsDirectory().appendingPathComponent(path)
                    if media.type == .video {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        if let uiImage = UIImage(contentsOfFile: url.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct GroupHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold)) // Uniform font
            .foregroundColor(.white)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .frame(height: 44) // Locked height
            .background(Color.black)
    }
}

struct MediaThumbnail: View {
    @EnvironmentObject var session: UserSession
    let item: SnapMedia
    let isSelectMode: Bool
    let isSelected: Bool
    
    @State private var duration: String?
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            mainThumbnailView
            
            if item.type == .video {
                videoDurationOverlay
            }
            
            if isSelectMode {
                selectionOverlay
            }
        }
    }

    @ViewBuilder
    private var mainThumbnailView: some View {
        if let path = item.localPath {
            thumbnailOrPhotoView(path: path)
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
        } else {
            PlaceholderBox()
        }
    }

    @ViewBuilder
    private var videoDurationOverlay: some View {
        HStack(spacing: 2) {
            Image(systemName: "play.fill")
                .font(.system(size: 8))
            if let dur = duration {
                Text(dur)
                    .font(.system(size: 8, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .padding(4)
        .background(Color.black.opacity(0.5))
        .cornerRadius(4)
        .padding(4)
        .onAppear {
            fetchDuration()
        }
    }
    
    @ViewBuilder
    private func thumbnailOrPhotoView(path: String) -> some View {
        if let thumb = thumbnail {
            Image(uiImage: thumb)
                .resizable()
                .scaledToFill()
        } else {
            fallbackImageView(path: path)
        }
    }

    @ViewBuilder
    private func fallbackImageView(path: String) -> some View {
        let url = session.getDocumentsDirectory().appendingPathComponent(path)
        if item.type == .image, let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            PlaceholderBox()
                .task { // Using .task instead of .onAppear for better side effect handling
                    if item.type == .video && thumbnail == nil {
                        generateThumbnail(url: url)
                    }
                }
        }
    }
    
    private var selectionOverlay: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color.black.opacity(0.3))
                .frame(width: 24, height: 24)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    private func fetchDuration() {
        guard let path = item.localPath else { return }
        let url = session.getDocumentsDirectory().appendingPathComponent(path)
        let asset = AVURLAsset(url: url)
        Task {
            if let duration = try? await asset.load(.duration) {
                let seconds = CMTimeGetSeconds(duration)
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.minute, .second]
                formatter.unitsStyle = .positional
                formatter.zeroFormattingBehavior = .pad
                DispatchQueue.main.async {
                    self.duration = formatter.string(from: seconds)
                }
            }
        }
    }

    private func generateThumbnail(url: URL) {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 300, height: 300)
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.thumbnail = UIImage(cgImage: image)
                }
            }
        }
    }
    
    private func PlaceholderBox() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(1, contentMode: .fit)
    }
}

struct PasscodeSetupView: View {
    @EnvironmentObject var session: UserSession
    @Environment(\.dismiss) var dismiss
    @State private var code = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Set Vault Passcode")
                    .font(.title2.bold())
                
                SecureField("Enter Passcode", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal, 40)
                
                Button("Save Passcode") {
                    session.setPasscode(code)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.isEmpty)
            }
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct PasscodeEntryView: View {
    @EnvironmentObject var session: UserSession
    @Environment(\.dismiss) var dismiss
    @State private var code = ""
    var onSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Enter Passcode")
                .font(.title2.bold())
            
            SecureField("****", text: $code)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 80)
            
            Button("Unlock") {
                if code == session.passcode {
                    onSuccess()
                    dismiss()
                } else {
                    code = ""
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
        }
        .padding()
    }
}
