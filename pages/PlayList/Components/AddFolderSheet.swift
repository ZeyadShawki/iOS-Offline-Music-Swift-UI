//
//  FolderSheet.swift
//  aboutme
//
//  Created by zeyad Shawki on 27/12/2025.
//

import Foundation
import SwiftUI
internal import Combine

struct AddFolderSheet : View {
    
    @Binding var folderName: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Enter Folder Name").font(.title).bold()
            
            ReusableTextField(
                text: $folderName,
                placeHolder: "Search or enter web address",
                title: nil,
                buttonOptions: [],
                selectedOption:  .constant(nil),
                onSearch: {
                    
                }
            )
            HStack {
                Button("Cancel") {
                    folderName = ""
                    isPresented = false
                }.foregroundColor(.red)
                Spacer()
                Button("Create") {
                    isPresented = false
                }
            }.padding(.top,20)
            Spacer()

        }.frame(alignment: .leading) .padding()
    }
}

#Preview {
    AddFolderSheet(folderName: .constant("sss"),isPresented: .constant(false))
}
