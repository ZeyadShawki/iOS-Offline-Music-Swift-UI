//
//  DiscoveryPage.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import Foundation
import SwiftUI

struct DiscoveryPage : View {
    @State var text: String = ""
    var buttons : [IconButtonOption] = {
         (0..<6).map  { index in
            IconButtonOption(
               title: "YouTube",
               color: .red,
               imageName: "youtube-logo",
               action: {
                   print("YouTube \(index) selected")
               }
            )
        }
    }()
    var body: some View {
        VStack {
            ReusableTextField(
                text: $text,
                placeHolder: "Search or enter web address",
                title: nil,
                buttonOptions: [
                    IconButtonOption(
                        title: "YouTube",
                        color: .red,
                        imageName: "youtube-logo",
                        action: {
                            print("YouTube option selected")
                        }
                    ),
                    IconButtonOption(
                        title: "Google",
                        color: nil,
                        imageName: "google-logo",
                        action: {
                            print("Google option selected")
                        }
                    )
                ]
            )
            AppIconGrid(options: buttons)
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
        }.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .topLeading).padding(.horizontal,10)
    }
}

#Preview {
    DiscoveryPage(
        text:("")  )
}


