//
//  Spotify.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/29/22.
//

import Foundation

import UIKit

class Spotify {
    
    static var authCode: String?
    
    static var token: SpotifyToken? {
        didSet {
            print("New token: ", token)
        }
    }
    
    static var refreshTokenUrl: URL {
        get {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsDir.appending(path: "spotify_refresh_token").appendingPathExtension("plist")
        }
    }
    
    static var spotifyUserUrl: URL {
        get {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsDir.appending(path: "spotify_user_profile").appendingPathExtension("plist")
        }
    }
    
    
    static var refreshToken: String? 
    
    static let apiUrl: String = "https://api.spotify.com/v1"
    
    static var appPlaylistId: String?
    
    static var appPlaylistUri: String?
    
    static var spotifyUser: SpotifyUser?
    
    static let APP_PLAYLIST_NAME: String = "Podkast Snippets"
    
    static var iphoneDeviceId: String?
    
    static func getToken() async {
        print("get token!")
        var urlComponents = URLComponents(string: "https://accounts.spotify.com/api/token")
        urlComponents?.queryItems = [
            "grant_type": "authorization_code",
            "code": Spotify.authCode!,
            "redirect_uri": "podkast://home.com",
        ].map { (name: String, value: String) -> URLQueryItem in
            URLQueryItem(name: name, value: value)
        }

        guard let url = urlComponents?.url else {return}

        var request = URLRequest(url: url)
        
        let encoded = "f71867c3c3384668acb38d9a48b1b913:71179be2272944419545c6303d6349fc".data(using: .utf8)?.base64EncodedString()
    
        request.addValue("Basic \(encoded!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let result = try? await URLSession.shared.data(for: request)
        
        guard let (data, response) = result else {
            print("Spotify token request failed")
            return
        }
        
        guard let response = response as? HTTPURLResponse else {
            print("token request response could not be downcasted to HTTPURLResponse")
            return
        }

        guard response.statusCode == 200 else {
            print("Spotify token request was unsuccessful")
            print(String(data: data, encoding: .utf8))
            return
        }
        
        
        let token = try? JSONDecoder().decode(SpotifyToken.self, from: data)
        
        guard var token = token else {
            print("Spotify token couldn't be decoded.")
            return
        }
        
        token.acquisitionDate = Date()
        
        self.token = token
        
        refreshToken = token.refresh_token
        
        
        // save refresh token to memory
        let encodedRefreshToken = try? PropertyListEncoder().encode(RefreshToken(refresh_token: refreshToken!))
        
        if let encodedRefreshToken = encodedRefreshToken {
//            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let refreshTokenUrl = documentsDir.appending(path: "spotify_refresh_token").appendingPathExtension("plist")
            
            print("refreshTokenUrl: ", refreshTokenUrl)
            
            do {
                try encodedRefreshToken.write(to: refreshTokenUrl, options: .noFileProtection)
            } catch {
                print("Spotify refresh token could not be saved to local memory!")
            }
            
        } else {
            print("Refresh token could not be encoded into a plist!")
        }
        
        await retrieveUserProfile()
        
        print("auth code: ", authCode)
        print("access token: ", token)
        
    }
    
    private static func retrieveUserProfile() async {
        guard let userProfileRequest = await createAuthorizedSpotifyRequest(endpoint: "/me") else {return}
        
        let result = try? await URLSession.shared.data(for: userProfileRequest)
        
        guard let (data, response) = result else {
            print("Request to \(userProfileRequest.url!) endpoint failed!")
            return
        }
        
        if (response as! HTTPURLResponse).statusCode != 200 {
            print("Request to \(userProfileRequest.url!) was not successful. Error:")
            print(String(data: data, encoding: .utf8))
        }
        
        let user = try? JSONDecoder().decode(SpotifyUser.self, from: data)
        
        guard let user = user else {
            print("Spotify user couldn't be decoded from response JSON!")
            return
        }
        
        spotifyUser = user
        
        // save Spotify user profile to memory
        let encodedSpotifyUser = try? PropertyListEncoder().encode(spotifyUser)
        
        if let encodedSpotifyUser = encodedSpotifyUser {
//            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let refreshTokenUrl = documentsDir.appending(path: "spotify_refresh_token").appendingPathExtension("plist")
            
            do {
                try encodedSpotifyUser.write(to: spotifyUserUrl, options: .noFileProtection)
            } catch {
                print("Spotify user profile could not be saved to local memory!")
            }
            
        } else {
            print("Spotify user profile could not be encoded into a plist!")
        }
        
        print(spotifyUser)
    }
    
    
    static func refreshAccessToken() async {
        
        guard let refreshToken = refreshToken else {
            print("refresh token was null when trying to refresh token")
            return
        }
        
        var urlComponents = URLComponents(string: "https://accounts.spotify.com/api/token")
        urlComponents?.queryItems = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ].map { (name: String, value: String) -> URLQueryItem in
            URLQueryItem(name: name, value: value)
        }

        guard let url = urlComponents?.url else {return}

        var request = URLRequest(url: url)
        
        let encoded = "f71867c3c3384668acb38d9a48b1b913:71179be2272944419545c6303d6349fc".data(using: .utf8)?.base64EncodedString()
    
        request.addValue("Basic \(encoded!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

       
        
        self.token = await tokenRequest(request: request)
        
    }
    
    private static func tokenRequest(request: URLRequest) async -> SpotifyToken? {
        
        let result = try? await URLSession.shared.data(for: request)
        
        guard let (data, response) = result else {
            print("Spotify token request failed")
            return nil
        }
        
        guard let response = response as? HTTPURLResponse else {
            print("token request response could not be downcasted to HTTPURLResponse")
            return nil
        }

        guard response.statusCode == 200 else {
            print("Spotify token request was unsuccessful")
            print(String(data: data, encoding: .utf8))
            return nil
        }
        
        print(String(data: data, encoding: .utf8))
        
        let token = try? JSONDecoder().decode(SpotifyToken.self, from: data)
        
        guard var token = token else {
            print("Spotify token couldn't be decoded.")
            return nil
        }
        
        token.acquisitionDate = Date()
        
        print("refreshed token:", token)
        
        return token
    }
    
    static func stopPlayback() async {
            
        guard var request = await createAuthorizedSpotifyRequest(endpoint: "/me/player/pause") else { return }
        
        request.httpMethod = "PUT"
    
        let result = try? await URLSession.shared.data(for: request)
        
        guard result != nil else {
            print("PLayback failed")
            return
        }
        
        let (data, response) = result!
        
    }
    
    static func startPlayback(snippet: PodcastSnippet, position: Int, deviceId: String? = nil) async throws {
            
        guard var request = await createAuthorizedSpotifyRequest(endpoint: "/me/player/play") else { return }
        
        request.httpMethod = "PUT"
        
        if deviceId != nil {
            print("Device \(deviceId!) specified for playback")
            request.url?.append(queryItems: [URLQueryItem(name: "device_id", value: deviceId!)])
        }
        
        print("player play request url: ", request.url)
        
        struct Body: Codable {
            let context_uri: String
            let offset: Offset
            let position_ms: Int
            
            struct Offset: Codable {
                let position: Int
            }
        }
        
//        print("context uri:", "spotify:episode:\(episodeId)")
        guard let uri = appPlaylistUri else {
            print("Playlist uri was nil!")
            return
        }
        
        guard let playlistOffset = snippet.playlistOffset else {
            print("Snippet had no offset during playback!")
            return
        }
        let body = Body(context_uri: uri, offset: Body.Offset(position: playlistOffset), position_ms: position)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try? encoder.encode(body)
        request.httpBody = json
    
        let result = try? await URLSession.shared.data(for: request)
        
        guard result != nil else {
            print("PLayback failed")
            return
        }
        
        print("Playback started at offset \(playlistOffset) and position \(position / 1000)s")
        
        let (data, response) = result!
        
        print(String(data: data, encoding: .utf8)!)
        
        struct ErrorReponse: Codable {
            let error: Error?
            
            struct Error: Codable {
                let status: Int?
                let message: String?
                let reason: String?
            }
        }
        
        guard let responseBody = try? JSONDecoder().decode(ErrorReponse.self, from: data) else {
            print("Could not decode error response body during playback!")
            return
        }
        
        if let message = responseBody.error?.message,
           message == "Not found." {
            throw SpotifyError.CouldNotPlayOnSpecifiedAdvice
        }
        
        if let reason = responseBody.error?.reason,
           reason == "NO_ACTIVE_DEVICE" {
            print("There was no active device found!")
            let deviceId = (try await getUserDevice()).id
            try await startPlayback(snippet: snippet, position: position, deviceId: deviceId)
//            throw SpotifyError.NoActiveDevice
//            print("No active device was found during playback!")
        }
    }
    
    /**
     Retrieves user's devices and returns the first one
     */
    static private func getUserDevice() async throws -> Device {
        
        guard let request = await createAuthorizedSpotifyRequest(endpoint: "/me/player/devices") else {
            print("Could not create request for when retrieving user devices!")
            return Device(id: "", name: "")
        }
        
        guard let (data, _) = try? await URLSession.shared.data(for: request) else {
            print("Request to retrieve user devices failed!")
            return Device(id: "", name: "")
        }
        
        struct DevicesResponse: Codable {
            let devices: [Device]
        }
        
        guard let responseBody = try? JSONDecoder().decode(DevicesResponse.self, from: data) else {
            print("Could not decode devices response body!")
            return Device(id: "", name: "")
        }
        
        if responseBody.devices.count == 0 {
            print("Spotify could not find any devices!")
            throw SpotifyError.NoDeviceFound
        }
        
        print("Spotify found the following devices: ", responseBody.devices)
        return responseBody.devices.first!
    }
    
    static func seekPlayer(position: Int) async {
        guard var request = await createAuthorizedSpotifyRequest(endpoint: "/me/player/seek?position_ms=\(position)") else { return }
        request.httpMethod = "PUT"
    
        let result = try? await URLSession.shared.data(for: request)
    }
    
    static func getPlaybackState() async throws -> PlaybackState? {
        
        let startTime = Date.now.timeIntervalSince1970 
        
        guard let request = await createAuthorizedSpotifyRequest(endpoint: "/me/player/currently-playing?additional_types=episode") else { return nil }
    
        let result = try? await URLSession.shared.data(for: request)
        
        guard let (data, response) = result else {
            print("Failed to make request to get currently playing track")
            return nil
        }
        
        guard let response = response as? HTTPURLResponse else {
            print("token request response could not be downcasted to HTTPURLResponse")
            return nil
        }
        
        if response.statusCode == 204 {
            throw SpotifyError.NoActiveDevice
        }
        
//        print("PLAYBACKRESPONSE:", String(data: data, encoding: .utf8)!)
    
        let stateService = try? JSONDecoder().decode(PlaybackStateService.self, from: data)
        
        guard let stateService = stateService else {
            print("Playback state JSON could not be decoded")
            return nil
        }
        
        return await PlaybackState(from: stateService)
        
    }
    
    /**
     Returns offset of the episode played back
     */
    static func playBackSnippet(_ snippet: PodcastSnippet, deviceId: String? = nil) async throws -> Int {
        
        // check if playlist exists and create it if it doesn't exist
        if !(await appPlaylistExists()) {
            await createAppPlaylist()
        }
        
        // Update the offset because episode might have been moved or removed.
        let offset = await getEpisodePlaylistOffset(snippet: snippet)
        
        var snippetCopy = snippet
        snippetCopy.playlistOffset = offset
        
        guard let startTime = snippet.startTime else {
            print("Snippet did not have a start time during playback!")
            return -1
        }
        
        try await startPlayback(snippet: snippetCopy, position: startTime, deviceId: deviceId)
        
        return offset
        
    }
    
    /**
     Returns the episode's actual offset within the app playlist.
     Assumes the app playlist already exists.
     
     Will retrieve the item using the snippet provided's offset. If the item does not match the snippet's episode. if it doesn't match, the playlist's items are searched until the episode is found, which then the snippet's offset is updated to the match's offset. If a match is not found, the episode is added to the playlist and snippet's offset is likewise updated.
     
     */
    static private func getEpisodePlaylistOffset(snippet: PodcastSnippet) async -> Int  {
        // Retrieve the item at snippet's offset and check that it's a match
        var offset: Int
        
        // Check that offset is nil but assign it a value if it is. This is to prevent the function from returning; the function will ultimately add the episode to the playlist nonethless
        if snippet.playlistOffset == nil {
            offset = 0
        } else {
            offset = snippet.playlistOffset!
        }
        
        // If offset is larger than the number of items in the playlist, Spotify will simply return an empty array.
        guard let request = await createAuthorizedSpotifyRequest(endpoint: "/playlists/\(appPlaylistId!)/tracks?limit=1&offset=\(offset)") else {
            print("Unable to create request when retrieving item from app playlist using offset")
            return -1
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            print("Unable to make request when retrieving item from app playlist using offset")
            return -1
        }
        
        guard let playItemResponse = try? JSONDecoder().decode(PlaylistItemsResponse.self, from: data) else {
            print("Could not decoded response data when retrieving playlist item at offset \(offset)")
            return -1
        }
        print("response total: ", playItemResponse.total)
        print("response items: ", playItemResponse.items)
        if playItemResponse.items.count == 0 || playItemResponse.items.first!.track.id != snippet.episode.id {
            // Either offset was larger than number of items in app playlist or selected item did not match the snippet episode
            print("Either offset was larger than number of items in app playlist or selected item did not match the snippet episode")
            
            let actualOffset = await findItemInAppPlaylist(itemId: snippet.episode.id)
            
            if actualOffset < 0 {
                // Snippet's episode was not in app playlist
                offset = await addToAppPlaylist(snippet: snippet)
                print("Snippet's episode was not in app playlist and added to offset \(offset)")
            } else {
                // Snippet's episode was found in app playlist
                print("Snippet's episode was found in app playlist at offset \(actualOffset - 1) instead of \(offset)")
                offset = actualOffset - 1
            }
        }
        
        return offset
    }
    
    /**
     Searches the playlist items until it finds the matching item and returns its offset. If no match is found, offset returned is a negative number who's absolute value is the number of items in the playlist.
     
     OFFSET IS 1 INDEXED
     */
    static private func findItemInAppPlaylist(itemId: String) async -> Int {
        // loop through playlist items until item with snippet's episode id is found
        var areItemsRemaining = true
        var offset = 1
        guard let appPlaylistId = appPlaylistId else {return -1}
        var url = "\(apiUrl)/playlists/\(appPlaylistId)/tracks"
        
        while areItemsRemaining {
            let request = await createAuthorizedSpotifyRequest(url: url)
            guard let request = request else {return -1}
            
            guard let (data, response) = try? await URLSession.shared.data(for: request) else {
                print("request to retrieve playlist items failed!")
                return -1
            }
            
            guard let playlistItemsResponse = try? JSONDecoder().decode(PlaylistItemsResponse.self, from: data) else {
                print("Could not decode playlist items!")
                return -1
            }
            
            // if matching item is found, return item's offset. Nothing else should be done because item was already in playlist!
            for item in playlistItemsResponse.items {
                if item.track.id == itemId {
                    print("Item found in app playlist!")
                    return offset
                }
                offset += 1
            }
            
            if playlistItemsResponse.next == nil { areItemsRemaining = false }
            else {
                url = playlistItemsResponse.next!
            }
            
        }
        
        print("Item was not found in app playlist!")
        
        return offset * -1
    }
    
    
    private static func createAuthorizedSpotifyRequest(url: String) async -> URLRequest? {
        let elapsedTime: Int?
        if let token = token?.acquisitionDate {
            elapsedTime = Int(token.distance(to: Date()))
        } else {
            elapsedTime = nil
        }
        
        // check that token isn't nil or expired
        if elapsedTime == nil || elapsedTime! > (token!.expires_in - 1) {
            // refresh token
            await refreshAccessToken()
            if token == nil {
                print("Failed to build Spotify API request")
                return nil
            }
        }
    
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("Bearer \(token!.access_token)", forHTTPHeaderField: "Authorization")
        return request
    }
    private static func createAuthorizedSpotifyRequest(endpoint: String) async -> URLRequest? {
        return await createAuthorizedSpotifyRequest(url: "\(apiUrl)\(endpoint)")
    }
    
    /**
     Returns the playlist offset for the item added.
     */
    static func addToAppPlaylist(snippet: PodcastSnippet) async -> Int {
        // check that app playlist exists. Create it if it does not
        if !(await appPlaylistExists()) {
            print("playlist doesn't exist!")
            await createAppPlaylist()
        }
        
        
        // check if playlist already contains the episode. Add it if it doesn't
        //  ---
        var offset = await findItemInAppPlaylist(itemId: snippet.episode.id)
        if offset > 0 {
            print("Item was found in app playlist at offset \(offset - 1)!")
            return offset - 1
        }
        
        // if there is no item with the snippet's uri, add the episode and return the offset, which should be equal to the final size of playlist - 1
        offset = abs(offset) - 1
        
        guard let appPlaylistId = appPlaylistId else {return -1}
        guard var request = await createAuthorizedSpotifyRequest(endpoint: "/playlists/\(appPlaylistId)/tracks?uris=\(snippet.episode.uri)") else { return -1}
        
        request.httpMethod = "POST"
        
        guard let (data, response) = try? await URLSession.shared.data(for: request) else { return -1 }
        
        if (response as! HTTPURLResponse).statusCode != 201 {
            print("Snippet episode could not be added to app playlist: ")
            print(data.prettyPrintedJSONString!)
            return -1
        }
        // ---
        
        print("Episode added to app playlist at offset \(offset)!")
        
        return offset
    }
    
    static private func createAppPlaylist() async {
        
        guard let spotifyUser = spotifyUser else {
            print("Spotify user was null when creating app playlist!")
            return
        }
        
        struct CreatePlaylistBody: Codable {
            let name: String
            let isPublic: Bool?
            let collaborative: Bool?
            let description: String?
            
            init(name: String, isPublic: Bool? = nil, collaborative: Bool? = nil, description: String? = nil) {
                self.name = name
                self.isPublic = isPublic
                self.collaborative = collaborative
                self.description = description
            }
            
            enum CodingKeys: String, CodingKey {
                case name
                case isPublic = "public"
                case collaborative
                case description
            }
        }
        
        var request = await createAuthorizedSpotifyRequest(endpoint: "/users/\(spotifyUser.id)/playlists")
        guard var request = request else { return }
        
        request.httpMethod = "POST"
        
        let body = try? JSONEncoder().encode(CreatePlaylistBody(name: APP_PLAYLIST_NAME, isPublic: false, collaborative: false))
        guard let body = body else {return}
        
        request.httpBody = body
        
        let result = try? await URLSession.shared.data(for: request)
        guard let (data, response) = result else {
            print("request failed when creating app playlist")
            return
        }
        
        if (response as! HTTPURLResponse).statusCode != 201 {
            print("app playlist could not be created:")
            print(data.prettyPrintedJSONString!)
        }
        
        struct CreatePlaylistResponse: Codable {
            let id: String
            let uri: String
        }
        
        guard let createPlaylistResponse = try? JSONDecoder().decode(CreatePlaylistResponse.self, from: data) else {
            print("Unable to decode create playlist response")
            return
        }
        
        appPlaylistId = createPlaylistResponse.id
        appPlaylistUri = createPlaylistResponse.uri
        
    }
    
    /**
     Will update appPlaylistId if nil and playlist is found!
     */
    static private func appPlaylistExists() async -> Bool {
        // if playlist id is non-null, retrieve playlist and return true if no error
        if let id = appPlaylistId {
            let request = await createAuthorizedSpotifyRequest(endpoint: "/playlists/\(id)")
            guard let request = request else {
                print("request to /playlists/:playlistId could not be built")
                return false
            }
            
            let result = try? await URLSession.shared.data(for: request)
            guard let (_, response) = result else {
                print("request to /playlists/:playlistId unsuccessful")
                return false
            }
            
            if (response as! HTTPURLResponse).statusCode == 200 {return true}
            
        }
        
        // loop through user's playlist's until app playlist is found. Assign id to variable and return true. If playlist isn't found, create the playlist first.
        
        var arePlaylistsRemaining = true
        
        var url = "\(apiUrl)/me/playlists"
        
        struct PlaylistSearch: Codable {
            let offset: Int
            let next: String?
            let href: String
            let limit: Int
            let previous: String?
            let total: Int
            let items: [PlaylistSearchItems]
            
            struct PlaylistSearchItems: Codable {
                let id: String
                let uri: String
                let name: String
            }
        }
        
        while arePlaylistsRemaining {
            let request = await createAuthorizedSpotifyRequest(url: url)
            guard let request = request else {
                print("request to /me/playlists could not be built")
                return false
            }
            
            let result = try? await URLSession.shared.data(for: request)
            guard let (data, response) = result else {
                print("request to /me/playlists unsuccessful")
                return false
            }
            
            let playlistSearch = try? JSONDecoder().decode(PlaylistSearch.self, from: data)
            guard let playlistSearch = playlistSearch else {
                print("playlist search could not be decoded")
                return false
            }
            
            for playlist in playlistSearch.items {
                if playlist.name == APP_PLAYLIST_NAME {
                    appPlaylistId = playlist.id
                    appPlaylistUri = playlist.uri
                    return true
                }
            }
            
            if playlistSearch.next == nil {arePlaylistsRemaining = false}
            else {
                url = playlistSearch.next!
            }
            
            print(playlistSearch)
            
        }
        
        return false
    }
    
    struct Playlist: Codable {
        
    }
    
    struct SpotifyToken: Codable {
        
        let access_token: String
        let expires_in: Int
        let refresh_token: String?
        var acquisitionDate: Date?
        
    }
    
    struct PlaybackState {
        let dataFetchTimestamp: Date
        let progress: Int
        let isPlaying: Bool
        let currentlyPlayingType: PlaybackType
        let episode: Episode?
        let podcast: Podcast?
        
        init?(from service: PlaybackStateService) async {
            // convert timestamp from Unix ms to Date
            dataFetchTimestamp = Date(timeIntervalSince1970: service.timestamp / 1000)
            
            progress = service.progress_ms
            isPlaying = service.is_playing
            
            switch service.currently_playing_type {
            case "episode":
                currentlyPlayingType = .episode
            case "track":
                currentlyPlayingType = .track
            default:
                currentlyPlayingType = .unknown
            }
            
            guard currentlyPlayingType == .episode, let show = service.item.show else {
                episode = nil
                podcast = nil
                return
            }
            
            let epDuration = service.item.duration_ms
            let epSpotifyUrl = service.item.external_urls.spotify
            let epId = service.item.id
            let epName = service.item.name
            let epUri = service.item.uri
            
            let smallestEpImage = service.item.images!.sorted(by: { a, b in
                a.height < b.height
            })[0]
            
            var result = try? await URLSession.shared.data(from: URL(string: smallestEpImage.url)!)
            guard var (data, _ ) = result else {
                print("Images could not be fetched during PlaybackState initialization.")
                return nil
            }
            
            guard let epImage = UIImage(data: data) else {
                print("UIImage could not be created during PlaybackState initialization.")
                return nil
            }
            
            episode = Episode(duration: epDuration, openSpotifyUrl: epSpotifyUrl, image: epImage, id: epId, name: epName, uri: epUri)
            
            let podId = show.id
            let podName = show.name
            let podUrl = show.external_urls.spotify

            let smallestPodImage = show.images.sorted(by: { a, b in
                a.height < b.height
            })[0]
            
            result = try? await URLSession.shared.data(from: URL(string: smallestPodImage.url)!)
            guard let (data, _ ) = result else {
                print("Images could not be fetched during PlaybackState initialization.")
                return nil
            }
            
            guard let podImage = UIImage(data: data) else {
                print("UIImage could not be created during PlaybackState initialization.")
                return nil
            }

            podcast = Podcast(id: podId, image: podImage, name: podName, openSpotifyUrl: podUrl)
            
        }
        
        struct Podcast {
            let id: String
            let image: UIImage
            let name: String
            let openSpotifyUrl: String
        }
        
        struct Episode {
            let duration: Int
            let openSpotifyUrl: String
            let image: UIImage
            let id: String
            let name: String
            let uri: String
        }
        
    }
    
    struct PlaylistItemsResponse: Codable {
        let next: String?
        let total: Int
        let items: [PlaylistItems]
        
        struct PlaylistItems: Codable {
            let track: Track
            
            struct Track: Codable {
                let id: String
            }
        }
    }
    
    struct Image {
        let height: Int
        let url: String
        let width: Int
    }
    
    struct Device: Codable {
        let id: String
        let name: String
    }
    
    struct PlaybackStateService: Codable {
        let timestamp: Double
        var progress_ms: Int
        let item: Item
        let is_playing: Bool
        let currently_playing_type: String
        
        struct Item: Codable {
            let duration_ms: Int
            let external_urls: ExternalUrl
            let id: String
            let images: [Image]?
            let show: Show?
            let name: String
            let uri: String
            
            struct Show: Codable {
                let external_urls: ExternalUrl
                let id: String
                let images: [Image]
                let name: String
            }
            
            struct Image: Codable {
                let height: Int
                let url: String
                let width: Int
            }
            
            struct ExternalUrl: Codable {
                let spotify: String
            }
        }
    }
}
