
import Foundation

class FileManagerHelper {
    private var fileManager : FileManager
    private let playlistDir : URL
    
    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.playlistDir = docs.appendingPathComponent("playlists")
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
    
}
