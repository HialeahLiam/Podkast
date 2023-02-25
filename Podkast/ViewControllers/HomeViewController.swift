//
//  HomeViewController.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/29/22.
//

import UIKit

class HomeViewController: UIViewController, SPTAppRemotePlayerStateDelegate {
    
    
    // in seconds
    var dateOnTapDown: Double?
    var snippet: PodcastSnippet?
    // in seconds
    let START_TOLERANCE: Double = 5.0
    private var subscribedToPlayerState: Bool = false
    private let playURI = ""
    private var playerState: SPTAppRemotePlayerState?
    var defaultCallback: SPTAppRemoteCallback {
       get {
           return {[weak self] _, error in
               if let error = error {
                   print("e: ", error)
               }
           }
       }
    }
    
    var appRemote: SPTAppRemote? {
        get {
            return (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appRemote
        }
    }
    var captureButton: CaptureSnippetView!
    var alertHiddenConstraint: NSLayoutConstraint!
    var alertDisplayedConstraint: NSLayoutConstraint!
    var timestampTimer = Timer()
    
    
    @IBOutlet var playbackControls: UIStackView!
    @IBOutlet var trackCard: UIStackView!
    @IBOutlet var trackNameLabel: UILabel!
    @IBOutlet var albumNameLabel: UILabel!
    @IBOutlet var captureAlertLabel: UILabel!
    @IBOutlet var albumImageView: UIImageView!
    @IBOutlet var topAlertLabel: UILabel!
    @IBOutlet var back15Button: UIButton!
//    @IBOutlet var initialInfo: UIStackView!
    @IBOutlet var nothingPlayingLabel: UILabel!
    @IBOutlet var connectSpotifyButton: UIButton!
    @IBOutlet var nowPlayingLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        initialInfo.isHidden = true
        connectSpotifyButton.isHidden = true
        
        nothingPlayingLabel.isHidden = true
        nowPlayingLabel.isHidden = true
        
        trackCard.isHidden = true
        
        captureButton = CaptureSnippetView(frame: CGRect())
        captureButton.pressDownHandler = {
            self.captureStart()
        }
        captureButton.pressStopHandler = {
            self.captureStop()
        }
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(captureButton)
        
        captureButton.isHidden = true
        captureButton.widthAnchor.constraint(equalToConstant: 150).isActive = true
        captureButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        captureButton.bottomAnchor.constraint(equalTo: self.playbackControls.topAnchor, constant: -10).isActive = true
        
        captureButton.center = self.view.center
        
        captureAlertLabel.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -30).isActive = true
        captureAlertLabel.isHidden = true
        
        alertHiddenConstraint = topAlertLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: -200)
        alertDisplayedConstraint = topAlertLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5)
        
        alertHiddenConstraint.isActive = true
        alertDisplayedConstraint.isActive = false
        
        trackNameLabel.isHidden = true
        albumNameLabel.isHidden = true
        
        trackCard.layer.cornerRadius = 10
        
        playbackControls.layer.cornerRadius = 20
    }
    override func viewDidAppear(_ animated: Bool) {
        print("APPEAR")
        
        appRemote?.playerAPI?.getPlayerState { (result, error) in
            guard error == nil else {return}
            
            let playerState = result as! SPTAppRemotePlayerState
            self.playerState = playerState
            self.updateViewWithPlayerState(playerState)
        }
        
        if appRemote?.isConnected == false {
            connectSpotifyButton.isHidden = false
            
        }
        
    }
    
    @IBAction func connectToSpotify(_ sender: Any) {
        if appRemote?.authorizeAndPlayURI(playURI) == false {
            showAppStoreInstall()
        }
    }
    @IBAction func unwindToHome(unwindSegue: UIStoryboardSegue) {}
    
    @IBAction func back15Pressed(_ sender: Any) {
        if appRemote?.isConnected == false {
            // Call stopPress function because Spotify will make user leave app and CaptureButton will remain in pressed state.
            captureButton.pressStop(handler: nil)
            if appRemote?.authorizeAndPlayURI(playURI) == nil {
                self.showAppStoreInstall()
            }
        } else {
            guard let isPodcast = playerState?.track.isPodcast,
                  isPodcast else {
                print("You can only skip on podcasts!")
                let alertController = UIAlertController(title: "You can only skip on podcasts!", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(alertAction)
                self.present(alertController, animated: true)
                
                return
            }
            appRemote?.playerAPI?.seekBackward15Seconds() {(result, error) -> Void in
                guard error == nil else {
                    print("Error seeking back 15 seconds: ", error!)
                    return
                }
            }
        }
    }
    
    @IBAction func forward15Pressed(_ sender: Any) {
        if appRemote?.isConnected == false {
            // Call stopPress function because Spotify will make user leave app and CaptureButton will remain in pressed state.
            captureButton.pressStop(handler: nil)
            if appRemote?.authorizeAndPlayURI(playURI) == false {
                showAppStoreInstall()
            }
        } else {
            guard let isPodcast = playerState?.track.isPodcast,
                  isPodcast else {
                print("You can only skip on podcasts!")
                let alertController = UIAlertController(title: "You can only skip on podcasts!", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(alertAction)
                self.present(alertController, animated: true)
                
                return
            }
            appRemote?.playerAPI?.seekForward15Seconds() {(result, error) -> Void in
                guard error == nil else {
                    print("Error seeking forward 15 seconds: ", error!)
                    return
                }
            }
        }
    }
    
    func captureStart() {
        print("CAPTURE START")
        
        if appRemote?.isConnected == false {
            // Call stopPress function because Spotify will make user leave app and CaptureButton will remain in pressed state.
            captureButton.pressStop(handler: nil)
            if appRemote?.authorizeAndPlayURI(playURI) == false {
                showAppStoreInstall()
            }
        } else {
            appRemote?.playerAPI?.getPlayerState {(result, error) -> Void in
                guard error == nil else {
                    print("Error getting playback state: ", error!)
                    return
                }
                
                let playerState = result as! SPTAppRemotePlayerState
                let track = playerState.track
                guard !playerState.isPaused else {
                    self.appRemote?.playerAPI?.resume() { (result, error) -> Void in
                        guard error == nil else {
                            print("Error getting resuming playback: ", error!)
                            return
                        }
                        self.captureStart()}
                    return
                }
                
                guard track.isPodcast else {
                    print("You can only record a podcast!")
                    let alertController = UIAlertController(title: "You can only record podcasts!", message: nil, preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(alertAction)
                    self.present(alertController, animated: true)
                    
                    return
                }
                
                
                self.beginCapture(playerState)
                
            }
        }
    }
    
    func beginCapture(_ playerState: SPTAppRemotePlayerState) {
        let track = playerState.track
        self.captureAlertLabel.isHidden = false

        self.dateOnTapDown = Date.now.timeIntervalSince1970
        let toleranceInMS = Int(self.START_TOLERANCE * 1000)
        var startTime: Int
        
        if playerState.playbackPosition < toleranceInMS {
            startTime = 0
        } else {
            startTime = playerState.playbackPosition - toleranceInMS
        }
        
        self.snippet = PodcastSnippet(startTime: startTime, episodeName: track.name, episodeUri: track.uri, episodeDuration: track.duration, episodeArtist: track.artist, podcast: track.album)
        self.fetchAlbumArtForTrack(track: track, width: 500, height: 500) { (image) -> Void in
            guard let imageData = image.pngData() else {
                print("Could get image data!")
                return
            }
            self.snippet!.imageData = imageData
        }
    }
    
    func presentNothingPlayingMessage() {
        print("Either no active device or nothing's playing!")
        let alertController = UIAlertController(title: "Nothing's playing!", message: "We can't record a snippet if there is no podcast playing in your Spotify app.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let openSpotifyAction = UIAlertAction(title: "Open Spotify", style: .default) { action in
            self.openSpotifyApp()
        }

        alertController.addAction(cancelAction)
        alertController.addAction(openSpotifyAction)

        self.present(alertController, animated: true)
        return
    }
    
    func captureStop() {
        print("CAPTURE STOP")
        captureAlertLabel.isHidden = true
        
        addSnippetToLibrary()
    }
    
    private func fetchAlbumArtForTrack(track: SPTAppRemoteTrack, width: Int, height: Int, callback: @escaping (UIImage) -> Void ) {
        appRemote?.imageAPI?.fetchImage(forItem: track, with:CGSize(width: width, height: height), callback: { (image, error) -> Void in
            guard error == nil else {
                print("image error: ", error)
                return }

            let image = image as! UIImage
            callback(image)
        })
    }
    
    private func startPlayback() {
           appRemote?.playerAPI?.resume(defaultCallback)
       }

   private func pausePlayback() {
       appRemote?.playerAPI?.pause(defaultCallback)
   }
    
    func openSpotifyApp() {
        print("Opening Spotify!")
        UIApplication.shared.open(URL(string: "spotify:home")!)
    }
    
    func addSnippetToLibrary() {
        guard let dateOnTapDown = dateOnTapDown,
              var snippet = self.snippet else { return }
        
        let dateOnTapUp = Date.now.timeIntervalSince1970
        snippet.duration = dateOnTapUp - dateOnTapDown + START_TOLERANCE
        
        print(snippet)
        
//        // Passing snippet to LibraryTableViewController
//        let navController: UINavigationController = self.tabBarController!.viewControllers![1] as! UINavigationController
//        let libraryController = navController.viewControllers[0] as! LibraryTableViewController
//
//        libraryController.snippets.append(snippet)
        
        SnippetController.append(snippet)
        topAlertLabel.text = "Snippet saved to library!"
        
        UIView.animate(withDuration: 0.5, delay: .zero, options: []) {
            self.alertHiddenConstraint.isActive = false
            self.alertDisplayedConstraint.isActive = true
            
            self.view.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 1, delay: 2, options: []) {
            self.alertHiddenConstraint.isActive = true
            self.alertDisplayedConstraint.isActive = false
            
            self.view.layoutIfNeeded()
        }

        self.snippet = nil
//        }
    }
    
    func updateViewWithPlayerState(_ playerState: SPTAppRemotePlayerState) {
        var initialPosition = playerState.playbackPosition
        
        
        fetchAlbumArtForTrack(track: playerState.track, width: 250, height: 250) { image in
            self.albumImageView.image = image
            // Placing everything in closure because I don't want image to render after everything else has rendered.
            if self.trackNameLabel.isHidden { self.trackNameLabel.isHidden = false}
            if self.albumNameLabel.isHidden { self.albumNameLabel.isHidden = false}
            
            self.trackNameLabel.text = playerState.track.name
            self.albumNameLabel.text = playerState.track.album.name
            
            self.nowPlayingLabel.isHidden = false
        }
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("CHANGED")
        print("CHANGED")
        
        
//        initialInfo.isHidden = true
        self.playerState = playerState
        updateViewWithPlayerState(playerState)
    }
    
    func spotifyConnected() {
        
        connectSpotifyButton.isHidden = true
        self.captureButton.isHidden=false
        trackCard.isHidden = false
    }
    
    func spotifyDisconnected(){
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
