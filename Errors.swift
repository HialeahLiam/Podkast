//
//  Errors.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/30/22.
//

import Foundation

//enum SpotifyError: Error {
//    case NothingPlayingError
//}

enum SpotifyAuthenticationError: Error {
    case tokenRefreshFailed
    case tokenAcquisitionFailed
}

enum SpotifyError: Error {
    case NothingPlaying
    case NoActiveDevice
    case NotAPodcast
    case NoDeviceFound
    case CouldNotPlayOnSpecifiedAdvice
}

