//
//  WebViewSearchHelper.swift
//  aboutme
//
//  Created by zeyad Shawki on 07/12/2025.
//


import Foundation


struct WebViewSearchHelper {
    
    static func buildSearchURL(query: String, engine: SearchEngine) -> URL? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return nil }
        
        let url = parseAsURL(trimmedQuery)
        
        let urlLast = buildSearchQueryURL(query: query, engine: engine)
        print("urlll \( urlLast)")
        return urlLast
    }
    
    
    private static func parseAsURL(_ input: String) -> URL? {
        if input.hasPrefix("https://") || input.hasPrefix("http://"){
            return URL(string: input)
        }
        
        return URL(string: "https://\(input)")
    }
    
    private static func buildSearchQueryURL(query: String, engine: SearchEngine) -> URL? {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        switch engine {
        case .youtube:
            return buildYouTubeSearchURL(query: encodedQuery)
        case .google:
            return buildGoogleSearchURL(query: encodedQuery)
        }
    }
    
    /// Builds YouTube search URL
    private static func buildYouTubeSearchURL(query: String) -> URL? {
        // Check if it's a YouTube URL
        if query.contains("youtube.com") || query.contains("youtu.be") {
            let urlString = query.hasPrefix("http") ? query : "https://\(query)"
            return URL(string: urlString)
        }
        
        // Build YouTube search URL
        let searchURL = "https://www.youtube.com/results?search_query=\(query)"
        return URL(string: searchURL)
    }
    
    private static func buildGoogleSearchURL(query: String) -> URL? {
        let searchURL = "https://www.google.com/search?q=\(query)"
        return URL(string: searchURL)
    }
    
    
    
}
