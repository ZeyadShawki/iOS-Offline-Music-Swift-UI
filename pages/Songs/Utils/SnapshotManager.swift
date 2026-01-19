//
//  SnapshotManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 18/01/2026.
//

import Foundation
import CoreData

class SnapshotManager {

    private let context = PersistenceController.shared.container.viewContext
    private let entityName = "LastSongEntity"
    private let fileManager = FileManagerHelper()

    func saveLastPlayedSong(song: Song, playlist: Playlist) async throws {
        let entity = LastSongEntity(context: context)
        entity.id = UUID()
        entity.createdAt = Date()
        entity.songPath = song.audioURL?.path()
        entity.songName = song.title
        entity.playlistPath = fileManager.getRelativePath(for: playlist.name)
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    func deleteLastRecords() async throws {
       try await context.perform { [weak self] in
            guard let self = self else { return }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs
            if let result = try? self.context.execute(deleteRequest) as? NSBatchDeleteResult, let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
            try context.save()
        }
    }
    
    func getLastPlayedSong() async throws -> LastSongEntity? {
        try await context.perform {
            let request: NSFetchRequest<LastSongEntity> = LastSongEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 1
            let res = try self.context.fetch(request)
            return res.first
        }
    }
}
