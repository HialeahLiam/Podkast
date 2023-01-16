//
//  SpotifyUser.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/5/23.
//

import Foundation

struct SpotifyUser: Codable {
    let country: String
    // Spotify docs: "null if not available"
    let display_name: String?
    let email: String
    let explicit_content: ExplicitContent
    let external_urls: ExternalUrls
    let followers: Followers
    let href: String
    let id: String
    let images: [Image]
    let product: String
    let type: String
    let uri: String
    
    struct ExplicitContent: Codable {
        let filter_enabled: Bool
        let filter_locked: Bool
    }
    
    struct ExternalUrls: Codable {
        let spotify: String
    }
    
    struct Followers: Codable {
        // Spotify docs: This will always be set to null, as the Web API does not support it at the moment.
        let href: String?
        let total: Int
    }
    
    struct Image: Codable {
        let url: String
        let height: Int
        let width: Int
    }
}
