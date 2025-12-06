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
    @State var selectedSearchEngine : IconButtonOption?
    @State var searchURL: URL? = nil
    @State var showWebView = false

    var searchEngineOptions = [
        IconButtonOption(
            title: "YouTube",
            color: .red,
            imageName: "youtube-logo",
            action: {
                print("YouTube option selected")
            },
            searchEngine: .youtube
        ),
        IconButtonOption(
            title: "Google",
            color: nil,
            imageName: "google-logo",
            action: {
                print("Google option selected")
            },
            searchEngine: .google
        )
    ]
    
    var buttons : [IconButtonOption] = {
         (0..<6).map  { index in
            IconButtonOption(
               title: "YouTube",
               color: .red,
               imageName: "youtube-logo",
               action: {
                   print("YouTube \(index) selected")
               },
               searchEngine: .youtube
            )
        }
    }()
    
    
    var body: some View {
        NavigationStack {
            
            VStack {
                ReusableTextField(
                    text: $text,
                    placeHolder: "Search or enter web address",
                    title: nil,
                    buttonOptions: searchEngineOptions,
                    selectedOption: $selectedSearchEngine,
                    onSearch: onSearch
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
            }.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .topLeading).padding(.horizontal,10).navigationDestination(isPresented: $showWebView, ){
                if let url = searchURL {
                    WebViewPage(url: url,text: $text,selectedSearchEngine: $selectedSearchEngine,searchURL: $searchURL)
                }
            }
        }
    }
    
    func onSearch() {
        guard let selected = selectedSearchEngine else { return }
        let engine = selected.searchEngine
        searchURL = WebViewSearchHelper.buildSearchURL(query: text, engine: engine)
        // Navigate to WebView page
               if searchURL != nil {
                   showWebView = true
               }
    }
    
}

#Preview {
    DiscoveryPage(
        text:("")  )
}


