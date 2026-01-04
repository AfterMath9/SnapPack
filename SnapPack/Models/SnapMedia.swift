import Foundation

struct SnapMedia: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mediaType: String
    let location: String
    let downloadUrl: String
    var localPath: String? // Relative path to saved file
    var isLocked: Bool
    
    enum MediaType: String {
        case image = "Image"
        case video = "Video"
    }
    
    var type: MediaType {
        MediaType(rawValue: mediaType) ?? .image
    }

    init(id: UUID = UUID(), date: Date, mediaType: String, location: String, downloadUrl: String, localPath: String? = nil, isLocked: Bool = false) {
        self.id = id
        self.date = date
        self.mediaType = mediaType
        self.location = location
        self.downloadUrl = downloadUrl
        self.localPath = localPath
        self.isLocked = isLocked
    }
}

struct SnapchatExport: Codable {
    let savedMedia: [SnapMediaEntry]
    
    enum CodingKeys: String, CodingKey {
        case savedMedia = "Saved Media"
    }
}

struct SnapMediaEntry: Codable {
    let date: String
    let mediaType: String
    let location: String
    let downloadUrl: String
    let mediaDownloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case mediaType = "Media Type"
        case location = "Location"
        case downloadUrl = "Download Link"
        case mediaDownloadUrl = "Media Download Url"
    }
}
