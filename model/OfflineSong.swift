//
//  OfflineSong.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//
import SwiftUI

struct OfflineSong: Identifiable {
    let id = UUID()
    let title: String
    let artistNameEnglish: String
    let artistNameArabic: String?
    let duration: String // Format: "03:41"
    let fileSize: String // Format: "14.8 MB"
    let thumbnailImageName: String?
    
    init(
        title: String,
        artistNameEnglish: String,
        artistNameArabic: String? = nil,
        duration: String,
        fileSize: String,
        thumbnailImageName: String? = nil,
        thumbnailImage: Image? = nil
    ) {
        self.title = title
        self.artistNameEnglish = artistNameEnglish
        self.artistNameArabic = artistNameArabic
        self.duration = duration
        self.fileSize = fileSize
        self.thumbnailImageName = thumbnailImageName
    }
}
