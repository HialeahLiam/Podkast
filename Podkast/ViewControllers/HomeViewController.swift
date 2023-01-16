//
//  HomeViewController.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/29/22.
//

import UIKit

class HomeViewController: UIViewController {
    
    // in seconds
    var dateOnTapDown: Double?
    
    var snippet: PodcastSnippet?
    
    // in seconds
    let START_TOLERANCE: Double = 5.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    @IBAction func unwindToHome(unwindSegue: UIStoryboardSegue) {}
    
    @IBAction func recordDown(_ sender: Any) {
        Task {
//            await Spotify.stopPlayback()
            do {
                let state = try await Spotify.getPlaybackState()
                guard let state = state else {return}
                
                guard state.currentlyPlayingType == .episode else {
                    throw SpotifyError.NotAPodcast
                }
                
                guard state.isPlaying else {
                    throw SpotifyError.NothingPlaying
                }
                
                dateOnTapDown = Date.now.timeIntervalSince1970
                snippet = PodcastSnippet(playbackState: state)
                
                let toleranceInMS = Int(START_TOLERANCE * 1000)
                
                if state.progress < toleranceInMS {
                    snippet!.startTime = 0
                } else {
                    snippet!.startTime = state.progress - toleranceInMS
                }
                
            } catch SpotifyError.NoActiveDevice, SpotifyError.NothingPlaying {
                print("Either no active device or nothing's playing!")
                let alertController = UIAlertController(title: "Nothing's playing!", message: "We can't record a snippet if there is no podcast playing in your Spotify app.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                let openSpotifyAction = UIAlertAction(title: "Open Spotify", style: .default) { action in
                    self.openSpotifyApp()
                }
                
                alertController.addAction(cancelAction)
                alertController.addAction(openSpotifyAction)
                
                present(alertController, animated: true)
                
            } catch SpotifyError.NotAPodcast {
                print("You can only record a podcast!")
                let alertController = UIAlertController(title: "You can only record podcasts!", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default)
                
                alertController.addAction(alertAction)
                
                present(alertController, animated: true)
            }
            
        }
    }
    
    func openSpotifyApp() {
        print("Opening Spotify!")
        UIApplication.shared.open(URL(string: "spotify:home")!)
    }
    
    @IBAction func recordUp(_ sender: Any) {
       
        
        addSnippetToLibrary()
        
    }
    
    func addSnippetToLibrary() {
        guard let dateOnTapDown = dateOnTapDown,
              var snippet = snippet else { return }
        
        let dateOnTapUp = Date.now.timeIntervalSince1970
        snippet.duration = dateOnTapUp - dateOnTapDown + START_TOLERANCE
        
        print(snippet)
        Task {
            // Add playlist offset to snippet instance. Offset will be used to tell which playlist item to playback
            snippet.playlistOffset = await Spotify.addToAppPlaylist(snippet: snippet)
            
            // Passing snippet to LibraryTableViewController
            let navController: UINavigationController = self.tabBarController!.viewControllers![1] as! UINavigationController
            let libraryController = navController.viewControllers[0] as! LibraryTableViewController
            
            libraryController.snippets.append(snippet)
            
            self.snippet = nil
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
