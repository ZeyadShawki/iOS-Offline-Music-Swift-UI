//
//  DownloadOverlayButton.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import SwiftUI

struct DownloadOverlayButton:
    View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle().fill(.blue).frame(width: 56,height: 56).shadow(color: .black.opacity(0.3), radius: 4,x:0,y: 2)
                
                Image(systemName: "arrow.down.to.line.alt").font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
            }.padding(.trailing, 20)
             .padding(.bottom, 30)
        }
    }
}

#Preview {
    DownloadOverlayButton(onTap: {})
}
