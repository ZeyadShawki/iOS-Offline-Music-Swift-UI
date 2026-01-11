//
//  WebViewModel.swift
//  aboutme
//
//  Created by zeyad Shawki on 11/01/2026.
//

import Foundation
import SwiftUI
import Combine

class WebViewModel: ObservableObject, Hashable {
    @Published  var text: String = ""
    @Published  var selectedSearchEngine: IconButtonOption?
    @Published  var searchURL: URL?
    
    init(text: String = "", selectedSearchEngine: IconButtonOption? = nil, searchURL: URL? = nil) {
        self.text = text
        self.selectedSearchEngine = selectedSearchEngine
        self.searchURL = searchURL
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(searchURL)
    }
    
    static func == (lhs: WebViewModel, rhs: WebViewModel) -> Bool {
        return lhs.searchURL == rhs.searchURL
    }
}
