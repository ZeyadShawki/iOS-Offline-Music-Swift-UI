import SwiftUI

struct OfflineSongItem: View {
    let song: OfflineSong
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap,){
            HStack(spacing: 12) {
                Group {
                    if let image = song.thumbnailImageName {
                        Image(image).resizable().scaledToFit()
                    }
                }.frame(width: 60,height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4){
                    Text(song.title).font(.system(size: 16,weight: .medium)).foregroundColor(.black).multilineTextAlignment(.trailing).lineLimit(1)
                    HStack(spacing: 6,) {
                        Image(systemName: "music.note").foregroundColor(.orange)
                            .font(.system(size: 10))
                        
                        // Artist Name (English)
                                              Text(song.artistNameEnglish)
                                                  .font(.system(size: 12))
                                                  .foregroundColor(.gray)
                                              
                                              // Separator
                                              Text("|")
                                                  .font(.system(size: 12))
                                                  .foregroundColor(.gray)
                                              
                                              // Duration
                                              Text(song.duration)
                                                  .font(.system(size: 12))
                                                  .foregroundColor(.gray)
                                              
                    }
                }
                
                
            }
        }
    }
}

