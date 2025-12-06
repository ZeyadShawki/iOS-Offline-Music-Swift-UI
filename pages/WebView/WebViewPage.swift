//
//  webView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI

struct WebViewPage: View {

    let url: URL?
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @Binding var selectedSearchEngine : IconButtonOption?
    @Binding var searchURL: URL?

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

    var body: some View {
        VStack(alignment: .leading){
            HStack {
                navigationBar
                ReusableTextField(
                    text: $text,
                    placeHolder: "Search or enter web address",
                    title: nil,
                    buttonOptions: searchEngineOptions,
                    selectedOption: $selectedSearchEngine,
                    onSearch: onSearch
                )
                Spacer().frame(width: 30)
            }
            ZStack(alignment: .topLeading) {
                if let url = url {
                    WebView(url: url).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptyStateView
                }
                
                
            }
            .navigationBarHidden(true)
        }
    }
    
    func onSearch() {
        guard let selected = selectedSearchEngine else { return }
        let engine = selected.searchEngine
        searchURL = WebViewSearchHelper.buildSearchURL(query: text, engine: engine)
        // Navigate to WebView page
        
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: {
                dismiss()
            },){
                HStack(alignment: .firstTextBaseline,) {
                    Image(systemName: "chevron.left").font(.system(size: 18,weight: .bold))
                
                }
            }
           
        } .scaledToFit()   .foregroundColor(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
           
    
    }
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.primary)
            Text("Invalid URL")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}

#Preview {
    NavigationStack {
        WebViewPage(
            url: URL(string: "https://www.google.com"),
            text: .constant(""),
            selectedSearchEngine: .constant(nil),
            searchURL: .constant(nil)
        )
    }
}

