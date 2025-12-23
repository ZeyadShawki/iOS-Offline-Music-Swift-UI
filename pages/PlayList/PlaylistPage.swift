//
//  DiscoveryPage.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import Foundation
import SwiftUI

struct PlaylistPage : View {
    init(playlists: [Playlist], text: String = "") {
        self.playlists = playlists
        self.text = text
    }
    @State private var playlists: [Playlist]
    @State private var isLoading = true
    @State var text = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Playlists").font(.largeTitle).bold()
                    Spacer()
                }.padding(.vertical)
                HStack {
                    TextField("Search on Library", text: $text).padding(10).background(Color(.systemGray6)).cornerRadius(10).cornerRadius(50).frame()
                    Spacer()
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort by Date")
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                AddButton {
                    
                }
                
                List(playlists) { Playlist in
                    PlayistRow(playlist: Playlist)
                        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)) // vertical only
                        .listRowBackground(Color.clear)     .alignmentGuide(.listRowSeparatorLeading) { d in
                            d[.leading]
                        }
                }.listStyle(PlainListStyle())
                
                
            }.padding(.horizontal)
                .background(Color(.systemBackground)).onAppear {
                    
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
#Preview {
    PlaylistPage(
        playlists: [
            Playlist(
                name: "Liked Songs", songCount: 3, iconName: "heart.fill",
                overlayColor: .blue
            ),
            Playlist(
                name: "Liked Songs", songCount: 3, iconName: "heart.fill",
                overlayColor: .blue
            )
        ]
    )
}
