import SwiftUI

struct OfflineSongItem: View {
    let song: Song
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap){
            HStack(spacing: 12) {
                // Thumbnail
                Group {
                    if let image = song.thumbnailImageUrl {
                        AsyncImage(url: image) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure(_), .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle().fill(Color.gray.opacity(0.3))
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4){
                    Text(song.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                        
                        Text(song.artist ?? "Unknown Artist")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("|")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(song.duration.formatted())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

