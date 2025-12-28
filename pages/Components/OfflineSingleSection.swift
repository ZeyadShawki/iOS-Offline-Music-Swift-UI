import SwiftUI

struct OfflineSongsSection: View {
    let songs: [Song]
    let onMoreTap: () -> Void
    let onSongTap: (Song) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Offline Songs")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onMoreTap) {
                    Text("More")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Songs List
            if songs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No offline songs")
                        .font(.system(size: 16))
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(songs) { song in
                        OfflineSongItem(song: song) {
                            onSongTap(song)
                        }
                        
                        // Divider (except for last item)
                        if song.id != songs.last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.leading, 72) // Align with text, not thumbnail
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

#Preview {
    OfflineSongsSection(songs: [
        
        Song( id: UUID(),
              title: "كليب صادفت الحب وقولت اجرب ( البت عرفت بعد...",
              artist: "SSS",
              duration: 30,
              fileSize: 40,
              thumbnailImageUrl: URL(filePath: "ss"),
              audioURL:  URL(filePath: "ss"),
          )
    ], onMoreTap: {}, onSongTap: { music in
        
    })
}
