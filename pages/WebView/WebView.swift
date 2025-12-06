//
//  webView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
     func makeCoordinator() -> Coordinator {
         Coordinator()
     }
    // Add the Coordinator class
    class Coordinator: NSObject, WKNavigationDelegate {
        // When webview starts loading, THIS method is called:
           func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
               print("Page started loading!")
           }
           
           // When webview finishes loading, THIS method is called:
           func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
               print("Page finished loading!")
           }
    }
}
