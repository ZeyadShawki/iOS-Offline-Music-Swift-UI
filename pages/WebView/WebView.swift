//
//  webView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var url: URL
    @Binding var currentURL: String
    var onURLChange: ((String) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Add KVO observer for URL changes (catches SPA navigation)
        context.coordinator.observeURL(webView)

        context.coordinator.initialURL = url
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only reload if the URL prop changed (not due to user navigation)
        if context.coordinator.initialURL != url {
            // The parent changed the URL prop - load the new URL
            context.coordinator.initialURL = url
            let request = URLRequest(url: url)
            uiView.load(request)
        }
        // Otherwise, don't reload - let user navigate freely within the WebView
    }

     func makeCoordinator() -> Coordinator {
         Coordinator(self)
     }

    // Add the Coordinator class
    @MainActor
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var urlObservation: NSKeyValueObservation?
        private var lastReportedURL: String?
        var initialURL: URL?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func observeURL(_ webView: WKWebView) {
            // KVO to detect URL changes from JavaScript navigation (SPA)
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] _, change in
                guard let newURL = change.newValue?? .absoluteString else { return }
                
                Task { @MainActor in
                    guard let self = self,
                    newURL != self.lastReportedURL else { return }
                    
                    print("👁️ KVO URL Changed: \(newURL)")
                    self.lastReportedURL = newURL
                    self.parent.currentURL = newURL
                    self.parent.onURLChange?(newURL)
                }
            }
        }

        // When webview starts loading, THIS method is called:
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("Page started loading!")
        }

        // When webview finishes loading, THIS method is called:
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("📄 Page finished loading!")
            if let urlString = webView.url?.absoluteString {
                print("📄 didFinish URL: \(urlString)")
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if let urlString = navigationAction.request.url?.absoluteString {
                print("🧭 decidePolicyFor URL: \(urlString)")
            }
            return .allow
        }

        deinit {
            urlObservation?.invalidate()
        }
    }
}
