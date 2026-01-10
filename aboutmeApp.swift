//
//  aboutmeApp.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI

@main
struct aboutmeApp: App {
    let audioManager = AudioManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(audioManager)
        }
    }
}
