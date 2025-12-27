//
//  DiscoveryPage.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import Foundation
import SwiftUI

struct PlaylistPage : View {
    init(playlists: [Playlist]) {
        self.playlists = playlists
    }
    private let playlistManager = PlaylistManager()
    @State private var playlists: [Playlist]
    @State private var isLoading = true
    @State var text = ""
    @State var folderName = ""
    @State var isPresented = false

    var body: some View {
        NavigationView {
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
                                selectedOption:  .constant(nil),
                                onSearch: {

                                }
                            )
                        }

                        AddButton {
                            isPresented = true
                        }

                        List(playlists) { Playlist in
                            PlayistRow(playlist: Playlist)
                                .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                                .listRowBackground(Color.clear)
                                .alignmentGuide(.listRowSeparatorLeading) { d in
                                    d[.leading]
                                }
                        }.listStyle(PlainListStyle())
                    }.padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $isPresented, onDismiss: {
            if folderName.isEmpty {
                return
            }
            guard let playlist = playlistManager.createPlaylist(name: folderName) else { return }
            playlists.append(playlist)
            folderName = ""
        }) {
            AddFolderSheet(folderName: $folderName, isPresented: $isPresented)
        }
        .task {
            isLoading = true
            
            self.playlistManager.fetchPlaylists(){ fetched in
                DispatchQueue.main.async{
                    playlists = fetched
                    isLoading = false
                }
            }
        }
    }
    
    struct AddButton : View {
        var onTap : () -> Void
        var body: some View {
            Button(action: onTap) {
                VStack (alignment: .leading){
                    HStack(alignment: .top, spacing: 16){
                        RoundedRectangle(cornerRadius: 12).fill(Color(.gray)).frame(width: 50,height: 50).overlay(Image(
                            systemName: "folder.fill.badge.plus"
                        ).font(.system(size: 30)).foregroundStyle(.yellow))
                        VStack{
                            Spacer()
                            Text("Add new playlist").foregroundColor(.yellow).bold()
                            Spacer()
                            
                        }.frame(maxHeight: 50)
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                }
            }
        }
    }
}
    #Preview {
        PlaylistPage(
            playlists: [
                Playlist(
                    name: "Liked Songs", songCount: 3, iconName: "heart.fill",
                    overlayColor: .blue,
                    folderPath: URL(fileURLWithPath: "")
                ),
                Playlist(
                    name: "Liked Songs", songCount: 3, iconName: "heart.fill",
                    overlayColor: .blue,
                    folderPath: URL(fileURLWithPath: "")
                )
            ]
        )
}
