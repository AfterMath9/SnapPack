import Foundation
import Combine
import UIKit
import AVFoundation

class DownloadManager: ObservableObject {
    @Published var progress: Float = 0
    @Published var isDownloading: Bool = false
    @Published var isPaused: Bool = false
    @Published var downloadedCount: Int = 0
    @Published var totalCount: Int = 0
    
    @Published var pendingEntries: [SnapMediaEntry] = []
    @Published var successfulMedia: [SnapMedia] = []
    @Published var failedEntries: [SnapMediaEntry] = []
    
    private var session: UserSession
    private var downloadQueue: [SnapMediaEntry] = []
    private var stopRequested = false
    private var currentTask: URLSessionDataTask?
    
    init(session: UserSession) {
        self.session = session
    }
    
    func parseJSON(at url: URL) -> [SnapMediaEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        do {
            let export = try decoder.decode(SnapchatExport.self, from: data)
            return export.savedMedia
        } catch {
            print("Decoding error: \(error)")
            return []
        }
    }
    
    func startDownload(entries: [SnapMediaEntry], completion: @escaping ([SnapMedia]) -> Void) {
        self.downloadQueue = entries
        self.pendingEntries = entries
        self.successfulMedia = []
        self.failedEntries = []
        self.totalCount = entries.count
        self.downloadedCount = 0
        self.isDownloading = true
        self.isPaused = false
        self.stopRequested = false
        self.progress = 0
        
        processNextInQueue(completion: completion)
    }
    
    private func processNextInQueue(completion: @escaping ([SnapMedia]) -> Void) {
        guard !stopRequested else {
            finishDownload(completion: completion)
            return
        }
        
        guard !isPaused else { return }
        
        guard !downloadQueue.isEmpty else {
            finishDownload(completion: completion)
            return
        }
        
        let entry = downloadQueue.removeFirst()
        let primaryUrlString = entry.mediaDownloadUrl.isEmpty ? entry.downloadUrl : entry.mediaDownloadUrl
        guard let url = URL(string: primaryUrlString) else {
            failedEntries.append(entry)
            updateProgress()
            processNextInQueue(completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            
            if let data = data, error == nil, (200...299).contains(statusCode), data.count > 1000 {
                self.validateAndSave(data: data, entry: entry, primaryUrlString: primaryUrlString, completion: completion)
            } else {
                if primaryUrlString == entry.mediaDownloadUrl && !entry.downloadUrl.isEmpty && entry.downloadUrl != entry.mediaDownloadUrl {
                    print("Retrying with fallback URL for date: \(entry.date)")
                    self.retryWithFallback(entry: entry, completion: completion)
                } else {
                    self.handleFailure(entry: entry, completion: completion)
                }
            }
        }
        currentTask?.resume()
    }
    
    private func validateAndSave(data: Data, entry: SnapMediaEntry, primaryUrlString: String, completion: @escaping ([SnapMedia]) -> Void) {
        let isVideo = entry.mediaType.lowercased() == "video"
        
        // Deep Validation: Ensure data is actually what it claims to be
        if isVideo {
            // For videos, we check if we can create a timed asset or have enough data
            // (Real validation for video stream requires writing to temp file first)
            let tempURL = session.getDocumentsDirectory().appendingPathComponent("temp_validating.mp4")
            try? data.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            // Try to generate a single frame to verify the stream is valid
            let time = CMTime(seconds: 0, preferredTimescale: 1)
            let result = try? generator.copyCGImage(at: time, actualTime: nil)
            
            if result != nil {
                saveFinalMedia(data: data, entry: entry, url: primaryUrlString, isVideo: true, completion: completion)
            } else {
                handleFailure(entry: entry, completion: completion)
            }
            try? FileManager.default.removeItem(at: tempURL)
        } else {
            // For images, check if UIImage can parse the data
            if let _ = UIImage(data: data) {
                saveFinalMedia(data: data, entry: entry, url: primaryUrlString, isVideo: false, completion: completion)
            } else {
                handleFailure(entry: entry, completion: completion)
            }
        }
    }
    
    private func saveFinalMedia(data: Data, entry: SnapMediaEntry, url: String, isVideo: Bool, completion: @escaping ([SnapMedia]) -> Void) {
        let extensionStr = isVideo ? "mp4" : "jpg"
        let filename = UUID().uuidString + ".\(extensionStr)"
        let fileURL = self.session.getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            let media = SnapMedia(
                date: self.parseDate(entry.date) ?? Date(),
                mediaType: entry.mediaType,
                location: entry.location,
                downloadUrl: url,
                localPath: filename
            )
            DispatchQueue.main.async {
                self.successfulMedia.append(media)
                self.pendingEntries.removeAll(where: { $0.mediaDownloadUrl == entry.mediaDownloadUrl || $0.downloadUrl == entry.downloadUrl })
                self.updateProgress()
                self.processNextInQueue(completion: completion)
            }
        } catch {
            self.handleFailure(entry: entry, completion: completion)
        }
    }
    
    private func retryWithFallback(entry: SnapMediaEntry, completion: @escaping ([SnapMedia]) -> Void) {
        guard let url = URL(string: entry.downloadUrl) else {
            handleFailure(entry: entry, completion: completion)
            return
        }
        
        currentTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            
            if let data = data, error == nil, (200...299).contains(statusCode), data.count > 1000 {
                self.validateAndSave(data: data, entry: entry, primaryUrlString: entry.downloadUrl, completion: completion)
            } else {
                self.handleFailure(entry: entry, completion: completion)
            }
        }
        currentTask?.resume()
    }
    
    private func handleFailure(entry: SnapMediaEntry, completion: @escaping ([SnapMedia]) -> Void) {
        DispatchQueue.main.async {
            self.failedEntries.append(entry)
            self.updateProgress()
            self.processNextInQueue(completion: completion)
        }
    }
    
    private func updateProgress() {
        downloadedCount = successfulMedia.count + failedEntries.count
        progress = Float(downloadedCount) / Float(totalCount)
    }
    
    private func finishDownload(completion: @escaping ([SnapMedia]) -> Void) {
        DispatchQueue.main.async {
            self.isDownloading = false
            completion(self.successfulMedia)
        }
    }
    
    func pause() {
        isPaused = true
        currentTask?.suspend()
    }
    
    func resume(completion: @escaping ([SnapMedia]) -> Void) {
        isPaused = false
        if let task = currentTask, task.state == .suspended {
            task.resume()
        } else {
            processNextInQueue(completion: completion)
        }
    }
    
    func stop() {
        stopRequested = true
        currentTask?.cancel()
        downloadQueue.removeAll()
        pendingEntries.removeAll()
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: dateString)
    }
}

extension UserSession {
    var isFastDownloadEnabled: Bool {
        isPro
    }
}
