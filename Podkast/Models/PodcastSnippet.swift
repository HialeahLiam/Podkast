//
//  Snippet.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/31/22.
//

import Foundation

class PodcastSnippet: Codable, Fuseable {
    
    // ms
    var startTime: Int?
    // s
    var duration: Double?
    let episodeName: String
    let episodeUri: String
    let episodeDuration: Int
    let episodeArtist: Artist
    let podcast: Podcast
    var imageData: Data?
    var isNew = true
    dynamic var title: String
    var properties: [FuseProperty] {
        print("snippet title: ", self.title)
            return [
                FuseProperty(name: title, weight: 0.7),
                FuseProperty(name: podcast.name, weight: 0.3),
            ]
        }
//    let image: UIImage?
    
    struct Podcast: Codable {
        let name: String
        let uri: String
        let description: String
    }
    
    struct Artist: Codable {
        let name: String
        let uri: String
        let description: String
    }
    
    init(startTime: Int? = nil, duration: Double? = nil, episodeName: String, episodeUri: String, episodeDuration: UInt, episodeArtist: SPTAppRemoteArtist, podcast: SPTAppRemoteAlbum, image: UIImage? = nil) {
        self.startTime = startTime
        self.duration = duration
        self.episodeName = episodeName
        self.episodeUri = episodeUri
        self.episodeDuration = Int(episodeDuration)
        self.title = episodeName
//        self.image = image
        
        self.podcast = Podcast(name: podcast.name, uri: podcast.uri, description: podcast.description)
        self.episodeArtist = Artist(name: episodeArtist.name, uri: episodeArtist.uri, description: episodeArtist.description)
    }
    
//    let podcast: Podcast
//    let episode: Episode
//    var playlistOffset: Int?
//    var uri: String?
    
//    init?(playbackState: Spotify.PlaybackState) {
//        guard let podcast = playbackState.podcast else {return nil}
//        guard let episode = playbackState.episode else {return nil}
//        
//        self.podcast = Podcast(id: podcast.id, image: podcast.image, name: podcast.name, openSpotifyUrl: podcast.openSpotifyUrl)
//        self.episode = Episode(duration: episode.duration, openSpotifyUrl: episode.openSpotifyUrl, image: episode.image, id: episode.id, name: episode.name, uri: episode.uri)
//        
//        title = episode.name
//    }
    
    static func convertToMinandSec(timeInSeconds: Int) -> String {
        let minutes = timeInSeconds / 60
        var seconds = timeInSeconds % 60
        
        if seconds < 10 {
            return "\(minutes):0\(seconds)"
        }
        return "\(minutes):\(seconds)"
    }
}
