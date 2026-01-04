import SwiftUI
import UniformTypeIdentifiers

struct DownloaderView: View {
    @EnvironmentObject var session: UserSession
    @StateObject var downloadManager: DownloadManager
    @State private var showFilePicker = false
    @State private var selectedFile: URL?
    @State private var entries: [SnapMediaEntry] = []
    @State private var downloadListTab: Int = 0 // 0: Pending, 1: Success
    @State private var showTutorial = false
    @State private var selectedMedia: SnapMedia?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if let file = selectedFile {
                        // Header info - show only if not active
                        if !downloadManager.isDownloading && downloadManager.pendingEntries.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text(file.lastPathComponent)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("\(entries.count) " + "memories_ready".localized(session.language))
                                    .foregroundColor(.gray)
                                
                                Button(action: startDownload) {
                                    Text("start_download".localized(session.language))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 40)
                                
                                Button("choose_another".localized(session.language)) {
                                    selectedFile = nil
                                    entries = []
                                }
                                .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                        }
                        
                        // Download Progress & Controls
                        if downloadManager.isDownloading || !downloadManager.successfulMedia.isEmpty || !downloadManager.pendingEntries.isEmpty {
                            VStack(spacing: 20) {
                                if downloadManager.isDownloading {
                                    VStack(spacing: 15) {
                                        ProgressView(value: downloadManager.progress)
                                            .progressViewStyle(.linear)
                                            .tint(.blue)
                                        
                                        HStack(spacing: 40) {
                                            Button(action: {
                                                if downloadManager.isPaused {
                                                    downloadManager.resume { results in
                                                        session.addMedia(results)
                                                    }
                                                } else {
                                                    downloadManager.pause()
                                                }
                                            }) {
                                                Image(systemName: downloadManager.isPaused ? "play.fill" : "pause.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.white)
                                                    .frame(width: 50, height: 50)
                                                    .background(Circle().fill(Color.blue))
                                            }
                                            
                                            Button(action: {
                                                downloadManager.stop()
                                            }) {
                                                Image(systemName: "stop.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.white)
                                                    .frame(width: 50, height: 50)
                                                    .background(Circle().fill(Color.red))
                                            }
                                        }
                                        
                                        Text("\(Int(downloadManager.progress * 100))% ・ \(downloadManager.downloadedCount)/\(downloadManager.totalCount)")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                // Tabbed List (Side-by-side)
                                VStack(spacing: 0) {
                                    Picker("", selection: $downloadListTab) {
                                        Text("\("pending".localized(session.language)) (\(downloadManager.pendingEntries.count))").tag(0)
                                        Text("\("success".localized(session.language)) (\(downloadManager.successfulMedia.count))").tag(1)
                                        Text("\("failed".localized(session.language)) (\(downloadManager.failedEntries.count))").tag(2)
                                    }
                                    .pickerStyle(.segmented)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                    
                                    List {
                                        if downloadListTab == 0 {
                                            ForEach(downloadManager.pendingEntries.prefix(50), id: \.mediaDownloadUrl) { entry in
                                                HStack {
                                                    Image(systemName: entry.mediaType == "Video" ? "video" : "photo")
                                                        .foregroundColor(.gray)
                                                    Text(entry.date)
                                                        .font(.caption2)
                                                        .foregroundColor(.white)
                                                    Spacer()
                                                    Text("pending".localized(session.language))
                                                        .font(.system(size: 8, weight: .bold))
                                                        .padding(4)
                                                        .background(Color.gray.opacity(0.3))
                                                        .cornerRadius(4)
                                                }
                                                .listRowBackground(Color.white.opacity(0.05))
                                            }
                                        } else if downloadListTab == 1 {
                                            if !downloadManager.successfulMedia.isEmpty {
                                                Button(action: {
                                                    session.cleanBrokenMedia()
                                                }) {
                                                    HStack {
                                                        Image(systemName: "sparkles")
                                                        Text("clean_up".localized(session.language))
                                                    }
                                                    .font(.caption.bold())
                                                    .foregroundColor(.blue)
                                                    .padding(.vertical, 8)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(8)
                                                }
                                                .padding(.horizontal)
                                                .padding(.top, 8)
                                            }
                                            
                                            ForEach(downloadManager.successfulMedia.reversed()) { media in
                                                Button(action: { selectedMedia = media }) {
                                                    HStack(spacing: 12) {
                                                        if let path = media.localPath {
                                                            let url = session.getDocumentsDirectory().appendingPathComponent(path)
                                                            if let uiImage = UIImage(contentsOfFile: url.path) {
                                                                Image(uiImage: uiImage)
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fill)
                                                                    .frame(width: 40, height: 40)
                                                                    .cornerRadius(6)
                                                            } else {
                                                                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 40).cornerRadius(6)
                                                            }
                                                        }
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(media.date.formatted(date: .abbreviated, time: .shortened))
                                                                .font(.caption.bold())
                                                                .foregroundColor(.white)
                                                            Text(media.type == .image ? "Photo".localized(session.language) : "Video".localized(session.language))
                                                                .font(.system(size: 10))
                                                                .foregroundColor(.gray)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.green)
                                                            .font(.system(size: 14))
                                                    }
                                                }
                                                .listRowBackground(Color.white.opacity(0.05))
                                            }
                                        } else {
                                            ForEach(downloadManager.failedEntries.reversed(), id: \.mediaDownloadUrl) { entry in
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text(entry.date)
                                                            .font(.caption2)
                                                            .foregroundColor(.white)
                                                        Text("expired_link".localized(session.language))
                                                            .font(.system(size: 8))
                                                            .foregroundColor(.red)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 14))
                                                }
                                                .listRowBackground(Color.white.opacity(0.05))
                                            }
                                        }
                                    }
                                    .listStyle(.plain)
                                    .frame(minHeight: 300)
                                }
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "bolt.horizontal.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                            
                            Text("ready_sync".localized(session.language))
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("pick_json".localized(session.language))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.horizontal, 40)
                            
                            Button(action: { showFilePicker = true }) {
                                Text("select_file".localized(session.language))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Capsule().fill(Color.blue))
                            }
                            .padding(.horizontal, 40)
                            
                            // Storage overview
                            VStack(spacing: 5) {
                                let freeSpace = session.getAvailableDiskSpace()
                                Text("\("storage_available".localized(session.language)) \(ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                }
                .padding(.top, 40)
            }
            .navigationTitle("downloader".localized(session.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showTutorial = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showTutorial) {
                OnboardingView()
            }
            .fullScreenCover(item: $selectedMedia) { media in
                MediaDetailView(media: media)
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        handleFileSelection(url: url)
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func handleFileSelection(url: URL) {
        // Gain access to the file
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        selectedFile = url
        entries = downloadManager.parseJSON(at: url)
    }
    
    private func startDownload() {
        downloadManager.startDownload(entries: entries) { results in
            session.addMedia(results)
            print("Downloaded \(results.count) items")
        }
    }
}
