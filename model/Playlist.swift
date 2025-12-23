//
//  PlaylistModel.swift
//  aboutme
//
//  Created by zeyad Shawki on 23/12/2025.
//

import Foundation
import SwiftUI

struct Playlist: Identifiable  {
    let id = UUID()
    let name: String
    let songCount: Int
    let iconName: String
    let overlayColor: Color
}
