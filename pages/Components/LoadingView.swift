//
//  LoadingView.swift
//  aboutme
//
//  Created by zeyad Shawki on 11/01/2026.
//

import SwiftUI

struct LoadingView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    var content: () -> Content
    var loadingText: String? = nil
    
    var body: some View {
        ZStack {
            content().disabled(isShowing).blur(radius: isShowing ? 3: 0)
            if isShowing {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    if let text = loadingText {
                        Text(text).foregroundColor(.white).font(.headline)
                    }
                }.padding(24).background(.primary.opacity(0.6))
                    .cornerRadius(12)
            }
        }.animation(.easeInOut(duration: 0.2),value: isShowing)
    }
}

#Preview {
    LoadingView(isShowing:.constant(true), content: {
        Text("ssss")
    }, loadingText: "loadinggg")
}
