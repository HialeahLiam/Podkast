//
//  Snippet.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/31/22.
//

import Foundation

struct PodcastSnippet {
    
    // ms
    var startTime: Int?
    // s
    var duration: Double?
    let podcast: Podcast
    let episode: Episode
    var title: String
    var playlistOffset: Int?
//    var uri: String?
    
    init(startTime: Int, duration: Double, podcast: Podcast, episode: Episode, title: String) {
        self.startTime = startTime
        self.duration = duration
        self.podcast = podcast
        self.episode = episode
        self.title = title
    }
    
    init?(playbackState: Spotify.PlaybackState) {
        guard let podcast = playbackState.podcast else {return nil}
        guard let episode = playbackState.episode else {return nil}
        
        self.podcast = Podcast(id: podcast.id, image: podcast.image, name: podcast.name, openSpotifyUrl: podcast.openSpotifyUrl)
        self.episode = Episode(duration: episode.duration, openSpotifyUrl: episode.openSpotifyUrl, image: episode.image, id: episode.id, name: episode.name, uri: episode.uri)
        
        title = episode.name
    }
    
    static func convertToMinandSec(timeInSeconds: Int) -> String {
        let minutes = timeInSeconds / 60
        var seconds = timeInSeconds % 60
        
        if seconds < 10 {
            return "\(minutes):0\(seconds)"
        }
        return "\(minutes):\(seconds)"
    }
}
