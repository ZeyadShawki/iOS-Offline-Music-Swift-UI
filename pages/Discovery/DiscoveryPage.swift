//
//  DiscoveryPage.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import Foundation
import SwiftUI

struct DiscoveryPage : View {
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var webViewModel = WebViewModel()

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
        NavigationStack(path: $appRouter.discoveryPath) {
            
            VStack {
                ReusableTextField(
                    text: $webViewModel.text,
                    placeHolder: "Search or enter web address",
                    title: nil,
                    buttonOptions: searchEngineOptions,
                    selectedOption: $webViewModel.selectedSearchEngine,
                    onSearch: onSearch
                )
                OfflineSongsSection(songs: [
                    Song(
                        title: "Amr Diab - Ayyam We Ben'eshha",
                        artist: "Rotana",
                        duration: 195,
                        fileSize: 3_670_016,
                        thumbnailImageUrl: nil,
                        audioURL: URL(fileURLWithPath: "")
                    ),
                ], onMoreTap: {}, onSongTap: { music in
                    
                })
            }.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .topLeading).padding(.horizontal,10)
            .navigationDestination(for: DiscoveryRoute.self) { route in
                switch route {
                case .webView(let webViewModel):
                    WebViewPage(webViewModel: webViewModel)
                }
            }
        }
    }
    
    func onSearch() {
        guard let selected = webViewModel.selectedSearchEngine else { return }
        let engine = selected.searchEngine
        webViewModel.searchURL = WebViewSearchHelper.buildSearchURL(query: webViewModel.text, engine: engine)
        // Navigate to WebView page
        if webViewModel.searchURL != nil {
                   appRouter.navigateDiscovery(to: .webView(webViewModel: webViewModel))
        }
    }
    
}

#Preview {
    DiscoveryPage()
}


