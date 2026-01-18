
import Foundation
import CoreData
import SwiftUI

class PlaylistManager {
    
    private let context = PersistenceController.shared.container.viewContext
    private let fileManager = FileManagerHelper()
    
    private let defaultLikedSong = "Liked Songs"
    
    init() {}
    
    func fetchPlaylists() async -> [Playlist] {
        var playlists: [Playlist] = []
        await context.perform { [weak self] in
            guard let self = self else { return }
            let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            do {
                let entities = try self.context.fetch(request)
                
                playlists = entities.compactMap { entity -> Playlist? in
                    return self.mapPlaylist(entity: entity)
                }
            } catch {
                // Error fetching playlists
                print("Error Fetching playlis \(error.localizedDescription)")
            }
        }
        return playlists
    }
    
    func mapPlaylist(entity: PlaylistEntity) -> Playlist? {
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
    
    @discardableResult
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
    
    @discardableResult
    func createDefaultPlaylist() async -> [Playlist]? {
        let playlists = await fetchPlaylists()
     
        if !playlists.contains(where: { playlist in
            return playlist.name == self.defaultLikedSong
        }) {
            self.createPlaylist(name: self.defaultLikedSong)
            return playlists
        }
        return nil
    }

    func getPlaylist(byPath path: String) async throws -> Playlist? {
        try await context.perform {
            let request: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            request.predicate = NSPredicate(format: "path == %@", path)
            request.fetchLimit = 1
            if let entity = try self.context.fetch(request).first {
                return self.mapPlaylist(entity: entity)
            }
            return nil
        }
    }
    
}
