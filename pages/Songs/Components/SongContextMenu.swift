//
//  SongContextMenu.swift
//  aboutme
//
//  Created by zeyad Shawki on 28/12/2025.
//

import Foundation
import SwiftUI

struct SongContextMenu: View {
    let onAddNextPlay: () -> Void
    let onAddToList: () -> Void
    let onDelete: () -> Void
    @State private var showMenu = false

    var body: some View {
        Button(action: {
            showMenu = true
        },) {
            Image(systemName: "ellipsis.circle")
                          .font(.title)
        }.confirmationDialog("Options", isPresented: $showMenu) {
            Button("Add to Next Play", action: onAddNextPlay)
            Button("Add to List", action: onAddToList)
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel, action: {
                showMenu = false
            })

        }
    }
}

struct SongContextMenu_Previews: PreviewProvider {
    static var previews: some View {
        SongContextMenu(
            onAddNextPlay: { print("Add to Next Play") },
            onAddToList: { print("Add to List") },
            onDelete: { print("Delete") }
        )
    }
}
