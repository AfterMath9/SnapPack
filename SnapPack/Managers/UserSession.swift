import SwiftUI
import Combine

class UserSession: ObservableObject {
    let isPro: Bool = true
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("usedStorage") var usedStorage: Int = 0 // in bytes
    @AppStorage("passcode") var passcode: String = ""
    @AppStorage("isLocked") var isAppLocked: Bool = false
    @AppStorage("language") var language: String = "en"
    @AppStorage("hasSelectedLanguage") var hasSelectedLanguage: Bool = false
    
    @Published var downloadedMedia: [SnapMedia] = []
    
    init() {
        loadMedia()
    }
    
    var canDownloadMore: Bool {
        true
    }
    
    func addMedia(_ items: [SnapMedia]) {
        downloadedMedia.append(contentsOf: items)
        saveMedia()
        calculateUsedStorage()
    }
    
    func deleteMedia(_ items: [SnapMedia]) {
        let idsToDelete = Set(items.map { $0.id })
        // Delete files from disk first
        for item in items {
            if let path = item.localPath {
                let url = getDocumentsDirectory().appendingPathComponent(path)
                try? FileManager.default.removeItem(at: url)
            }
        }
        downloadedMedia.removeAll { idsToDelete.contains($0.id) }
        saveMedia()
        calculateUsedStorage()
    }
    
    func moveMediaToVault(_ items: [SnapMedia], locked: Bool) {
        let ids = Set(items.map { $0.id })
        for i in 0..<downloadedMedia.count {
            if ids.contains(downloadedMedia[i].id) {
                downloadedMedia[i].isLocked = locked
            }
        }
        saveMedia()
    }
    
    var hasPasscode: Bool {
        !passcode.isEmpty
    }
    
    func setPasscode(_ code: String) {
        passcode = code
    }
    
    private func saveMedia() {
        if let encoded = try? JSONEncoder().encode(downloadedMedia) {
            UserDefaults.standard.set(encoded, forKey: "saved_snap_media")
        }
    }
    
    private func loadMedia() {
        if let data = UserDefaults.standard.data(forKey: "saved_snap_media"),
           let decoded = try? JSONDecoder().decode([SnapMedia].self, from: data) {
            downloadedMedia = decoded
        }
    }
    
    func calculateUsedStorage() {
        let total = downloadedMedia.reduce(0) { (result, media) -> Int in
            guard let path = media.localPath else { return result }
            let url = getDocumentsDirectory().appendingPathComponent(path)
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            return result + (attributes?[.size] as? Int ?? 0)
        }
        usedStorage = total
    }
    
    func getAvailableDiskSpace() -> Int64 {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            return freeSize
        }
        return 0
    }
    
    func cleanBrokenMedia() {
        var brokenIds = Set<UUID>()
        
        for item in downloadedMedia {
            guard let path = item.localPath else {
                brokenIds.insert(item.id)
                continue
            }
            
            let url = getDocumentsDirectory().appendingPathComponent(path)
            
            // Check if file exists
            if !FileManager.default.fileExists(atPath: url.path) {
                brokenIds.insert(item.id)
                continue
            }
            
            // Check if file is a valid image or video
            if item.type == .image {
                if UIImage(contentsOfFile: url.path) == nil {
                    brokenIds.insert(item.id)
                }
            } else if item.type == .video {
                // Simplified video check: size > 4KB (most broken ones are < 1KB)
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attributes[.size] as? Int, size < 4096 {
                    brokenIds.insert(item.id)
                }
            }
        }
        
        if !brokenIds.isEmpty {
            // Delete broken files from disk (if they weren't nil but just invalid)
            for id in brokenIds {
                if let item = downloadedMedia.first(where: { $0.id == id }), let path = item.localPath {
                    let url = getDocumentsDirectory().appendingPathComponent(path)
                    try? FileManager.default.removeItem(at: url)
                }
            }
            
            downloadedMedia.removeAll { brokenIds.contains($0.id) }
            saveMedia()
            calculateUsedStorage()
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
