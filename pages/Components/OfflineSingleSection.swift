import SwiftUI

struct OfflineSongsSection: View {
    let songs: [OfflineSong]
    let onMoreTap: () -> Void
    let onSongTap: (OfflineSong) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Offline Songs")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: onMoreTap) {
                    Text("More")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
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
        OfflineSong(
              title: "كليب صادفت الحب وقولت اجرب ( البت عرفت بعد...",
              artistNameEnglish: "Magdy ElZahar",
              artistNameArabic: "مجدي الزهار",
              duration: "03:41",
              fileSize: "14.8 MB",
              thumbnailImageName: "youtube-logo" // Replace with your image asset name
          )
    ], onMoreTap: {}, onSongTap: { music in
        
    })
}
