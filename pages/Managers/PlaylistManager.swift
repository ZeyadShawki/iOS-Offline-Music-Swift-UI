
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
                    let relativePath = entity.path ?? ""
                    let url = fileManager.getFullPath(from: relativePath)

                    guard FileManager.default.fileExists(atPath: url.path) else {
                        return nil
                    }

                    let songCount = fileManager.getSongCount(from: url.path)
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
                // Error fetching playlists
            }
        }
        completionHandler(playlists)
    }
    
    func createPlaylist(name: String) -> Playlist? {
        let playlistId = UUID()
        guard let fullPath = fileManager.createPlaylistFolder(named: name) else {
            return nil
        }

        let relativePath = fileManager.getRelativePath(for: name)
        let entity = PlaylistEntity(context: context)
        entity.id = playlistId
        entity.name = name
        entity.icon = "heart.fill"
        entity.overlayColor = Color.blue.description
        entity.path = relativePath

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
                folderPath: fullPath
            )
        } catch {
            return nil
        }
    }
    
    func deletePlaylist(playlist: Playlist) {
        guard let folderPath = playlist.folderPath else { return }
        fileManager.deletePlaylistFolder(from: folderPath)
        let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", playlist.id as CVarArg)

        do {
            let results = try context.fetch(request)
            for entity in results {
                context.delete(entity)
            }
            try context.save()
        } catch {
            // Error deleting playlist
        }
    }
    
    
}
