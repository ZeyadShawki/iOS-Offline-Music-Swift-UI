@preconcurrency import CoreData
import Foundation
import SwiftUI

class PlaylistManager {

    private let context = PersistenceController.shared.container.viewContext
    private let fileManager = FileManagerHelper()

    let defaultLikedSong = "Liked Songs"

    init() {}

    func fetchPlaylists() async -> [Playlist] {
        let request: NSFetchRequest<PlaylistEntity> =
            PlaylistEntity.fetchRequest()
        let entities: [PlaylistEntity] = await context.perform { [weak self] in
            guard let self = self else { return [] }
            do {
                return try self.context.fetch(request)

            } catch {
                // Error fetching playlists
                print("Error Fetching playlis \(error.localizedDescription)")
                return []
            }
        }
        return entities.compactMap { entity -> Playlist? in
            return self.mapPlaylist(entity: entity)
        }
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
        guard let fullPath = fileManager.createPlaylistFolder(named: name)
        else {
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
        let request: NSFetchRequest<PlaylistEntity> =
            PlaylistEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "id == %@",
            playlist.id as CVarArg
        )

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
            // Fetch again to include the newly created playlist
            return await fetchPlaylists()
        }
        return playlists
    }

    func getPlaylist(byPath path: String) async throws -> Playlist? {
        let request: NSFetchRequest<PlaylistEntity> =
            PlaylistEntity.fetchRequest()
        let entity: PlaylistEntity? =  try await context.perform {
            request.predicate = NSPredicate(format: "path == %@", path)
            request.fetchLimit = 1
            return try self.context.fetch(request).first
        }
        guard let entity = entity else { return nil }
        return self.mapPlaylist(entity: entity)
    }

}
