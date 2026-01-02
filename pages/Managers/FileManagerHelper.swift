
import Foundation

class FileManagerHelper {
    private var fileManager : FileManager
    private let documentsDir: URL
    private let playlistDir : URL

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
        self.documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.playlistDir = documentsDir.appendingPathComponent("playlists")
    }

    /// Returns the relative path (relative to Documents directory) for storage in Core Data
    func getRelativePath(for name: String) -> String {
        return "playlists/\(name)"
    }

    /// Returns the full URL from a relative path (relative to Documents directory)
    func getFullPath(from relativePath: String) -> URL {
        return documentsDir.appendingPathComponent(relativePath)
    }
    
    func getSongCount(from folderPath: String)-> Int {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folderPath)
            return contents.count
        } catch {
            print("Error getting song count: \(error)")
            return 0
        }
    }
    
    func createFile(at url: URL, contents: Data? = nil) -> Bool {
        do {
            try contents?.write(to: url)
            return true
        } catch {
            print("Error creating file: \(error)")
            return false
        }
    }
    
    func createPlaylistFolder(named name: String) -> URL? {
        let playlistFolder = playlistDir.appendingPathComponent(name)
        if fileManager.fileExists(atPath: playlistFolder.path) {
            return playlistFolder
        }
        do {
            try fileManager.createDirectory(at: playlistFolder, withIntermediateDirectories: true)
            return playlistFolder
        } catch {
            print("Failed to create playlist folder \(error)")
            return nil
        }
    }
    
    func deletePlaylistFolder(from folderPath:  URL) {
        do {
            try fileManager.removeItem(at: folderPath)
        } catch {
            print("error while removing item \(error)")
        }
    }
    
    func sanitizeFilename(_ filename: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return filename.components(separatedBy: invalidChars).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generateUniqueFilename(_ base: String, ext: String, in folder: URL) -> String {
        var filename = "\(base).\(ext)"
        var counter = 1
        while FileManager.default.fileExists(atPath: folder.appendingPathComponent(filename).path) {
            filename = "\(base) (\(counter)).\(ext)"
            counter += 1
        }
        return filename
    }
    
    
    func getURLsFromFolder(from folderURL: URL, supportedFormats: [String]) -> [URL] {
        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey],
                                                      options: [.skipsHiddenFiles]
        ) else { return [] }
        
        var audioFiles: [URL] = []
        for case let fileURL as URL in enumerator {
            let fileExtension = fileURL.pathExtension.lowercased()
            if supportedFormats.contains(fileExtension) {
                audioFiles.append(fileURL)
            }
        }
        return audioFiles.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
    }
   static func getFileSize(from fileURL: URL) -> Int {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path())
            if let size = attributes[.size] as? Int64 {
                 return Int(size / (1024 * 1024))
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return 0
    }
    
}
