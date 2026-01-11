//
//  AddFolderAlert.swift
//  aboutme
//
//  Created by zeyad Shawki on 27/12/2025.
//

import Foundation
import SwiftUI
import Combine

struct AddFolderAlert : ViewModifier {
    
    @Binding var isPresented: Bool
    @State var folderName: String
    
    var onCreate: (String)->Void
    
    func body(content: Content) -> some View {
        content.alert("New Playlist", isPresented: $isPresented) {
            TextField("Playlist name", text: $folderName)
            Button("Cancel", role: .cancel) {
                folderName = ""
            }
            
            Button("Create") {
                onCreate(folderName)
            }
            
        } message: {
            Text("Enter a name for your new playlist")
        }
    }
}

extension View {
    func addFolderAlert(
        isPresented: Binding<Bool>,
        onCreate: @escaping (String) -> Void
    ) -> some View {
        modifier(AddFolderAlert(
            isPresented: isPresented,
            folderName: "",
            onCreate: onCreate,
        ))
    }
}


#Preview {
    Text("Preview")
        .addFolderAlert(
            isPresented: .constant(true),
            onCreate: { _ in }
        )
}
