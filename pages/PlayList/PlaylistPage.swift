//
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import Foundation
import SwiftUI

struct PlaylistPage: View {
    init(playlists: [Playlist]) {
        self.playlists = playlists
    }
    @EnvironmentObject var appRouter: AppRouter
    private let playlistManager = PlaylistManager()
    @State private var playlists: [Playlist]
    @State private var isLoading = true
    @State var text = ""
    @State var folderName = ""
    @State var isPresented = false

    var body: some View {
        NavigationStack(path: $appRouter.playlistPath) {
            Group {
                if isLoading {
                    ProgressView("Loading playlists...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        HStack {
                            Text("Playlists").font(.largeTitle).bold()
                            Spacer()
                        }.padding(.vertical)
                        HStack {
                            ReusableTextField(
                                text: $text,
                                placeHolder: "Search on Library",
                                title: nil,
                                buttonOptions: [],
                                selectedOption: .constant(nil),
                                onSearch: {

                                }
                            )
                        }

                        AddButton {
                            isPresented = true
                        }

                        List(playlists) { playlist in
                       
                           Button(action: {
                                appRouter.navigatePlaylist(to: .songs(playlist: playlist))
                            }){
                                PlayistRow(playlist: playlist)
                            }
                            .listRowInsets(
                                EdgeInsets(
                                    top: 20,
                                    leading: 0,
                                    bottom: 20,
                                    trailing: 0
                                )
                            )
                            .listRowBackground(Color.clear)
                            .alignmentGuide(.listRowSeparatorLeading) { d in
                                d[.leading]
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    .background(Color(.systemBackground))
                }
            }
            .padding(.horizontal)
            .addFolderAlert(
                isPresented: $isPresented, onCreate: { folderName in
                    if let playlist = playlistManager.createPlaylist(name: folderName){
                        playlists.append(playlist)
                    }
                }
            )
            .task {
                isLoading = true
                playlists = await playlistManager.fetchPlaylists()
                isLoading = false
            }
            .navigationDestination(for: PlaylistRoute.self) { route in
                switch route {
                case .songDetail(let song):
                    SongDetailView(song: song)
                case .songs(let playlist):
                    SongsPage(playlist: playlist)
                }
            }
        }
    }

    struct AddButton: View {
        var onTap: () -> Void
        var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: 16) {
                        RoundedRectangle(cornerRadius: 12).fill(Color(.gray))
                            .frame(width: 50, height: 50).overlay(
                                Image(
                                    systemName: "folder.fill.badge.plus"
                                ).font(.system(size: 30)).foregroundStyle(
                                    .yellow
                                )
                            )
                        VStack {
                            Spacer()
                            Text("Add new playlist").foregroundColor(.yellow)
                                .bold()
                            Spacer()

                        }.frame(maxHeight: 50)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
#Preview {
    PlaylistPage(
        playlists: [
            Playlist(
                name: "Liked Songs",
                songCount: 3,
                iconName: "heart.fill",
                overlayColor: .blue,
                folderPath: URL(fileURLWithPath: "")
            ),
            Playlist(
                name: "Liked Songs",
                songCount: 3,
                iconName: "heart.fill",
                overlayColor: .blue,
                folderPath: URL(fileURLWithPath: "")
            ),
        ]
    )
}
