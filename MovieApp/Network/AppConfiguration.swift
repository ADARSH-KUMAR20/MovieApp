//
//  AppConfiguration.swift
//  MovieApp
//

import Foundation

enum AppConfiguration {
    /// OMDb API Key retrieved from Info.plist (referenced from Build Settings)
    static var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty else {
            fatalError("API_KEY not configured in Info.plist / Build Settings")
        }
        return key
    }
}

extension Bundle {
    /// Convenient accessor for API_KEY from Info.plist
    var apiKey: String? {
        object(forInfoDictionaryKey: "API_KEY") as? String
    }
}
