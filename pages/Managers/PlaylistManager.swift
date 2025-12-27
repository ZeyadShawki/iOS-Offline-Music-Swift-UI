
import Foundation
import CoreData
import SwiftUI

class PlaylistManager {
    private let context = PersistenceController.shared.container.viewContext
    private let fileManager = FileManagerHelper()
    init() {}
    
    func fetchPlaylists(completionHandler: @escaping ([Playlist])->Void ) {
        var playlists: [Playlist] = []
        context.performAndWait {
            let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            do {
                let entities = try context.fetch(request)
                playlists = entities.compactMap { entity -> Playlist? in
                    let folderPath = entity.path ?? ""
                    let url = URL(fileURLWithPath: folderPath)
                    guard FileManager.default.fileExists(atPath: url.path) else {
                        return nil
                    }

                    let songCount = fileManager.getSongCount(from: folderPath)
                    return Playlist(
                        id: entity.id ?? UUID(),
                        name: entity.name ?? "",
                        songCount: songCount,
                        iconName: "heart.fill",
                        overlayColor: .blue,
                        folderPath: url
                    )
                }
            } catch {
                print("Error fetching playlists: \(error)")
            }
        }
        completionHandler(playlists)
    }
    
    func createPlaylist(name: String) -> Playlist? {
        let playlistId = UUID()
        guard let path = fileManager.createPlaylistFolder(named: name) else {
            print("Error saving folder")
            return nil
        }

        // 1. Create a new PlaylistEntity in the Core Data context
        let entity = PlaylistEntity(context: context)

        // 2. Map Playlist properties to PlaylistEntity attributes
        entity.id = playlistId
        entity.name = name
        entity.icon = "heart.fill"
        entity.overlayColor = Color.blue.description
        entity.path = path.path()

        // 3. Save the context to persist to Core Data
        do {
            if context.hasChanges {
                try context.save()
            }
            return Playlist(
                id: playlistId,
                name: name,
                songCount: 0,
                iconName: "heart.fill",
                overlayColor: .blue,
                folderPath: path
            )
        } catch {
            print("Error saving playlist: \(error)")
        }
        return nil
    }
    
    func deletePlaylist(playlist: Playlist) {
        guard (playlist.folderPath != nil) else { return }
        fileManager.deletePlaylistFolder(from: playlist.folderPath!)
        let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", playlist.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            for playlist in results {
                context.delete(playlist)
            }
            try context.save()
        } catch {
            print("Error deleting playlist: \(error)")
        }
        
    }
    
    
}
