//
//  ViewController.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/24/22.
//

//import UIKit
import AuthenticationServices

class LoginViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    
    
    @IBOutlet var myStack: UIStackView!
    
    @IBOutlet var authButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func authorize(_ sender: Any) {
        getAuthCode()
    }
    
    func getAuthCode() {
        
        // deactivate login button until authentication is finished
        authButton.isEnabled = false
        
        var urlComponents = URLComponents(string: "https://accounts.spotify.com/authorize")
        urlComponents?.queryItems = [
            "client_id": "f71867c3c3384668acb38d9a48b1b913",
            "response_type": "code",
            "redirect_uri": "podkast://home.com",
            "scope": "user-read-playback-state user-modify-playback-state user-read-playback-position playlist-read-private playlist-modify-private playlist-modify-public user-read-private user-read-email"
        ].map { (name: String, value: String) -> URLQueryItem in
            URLQueryItem(name: name, value: value)
        }
        
        if let url = urlComponents?.url {
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "podkast")
            { callbackUrl, error in
                guard error == nil else {
                    print(error!)
                    return
                }
                guard let callbackUrl = callbackUrl else { return }
                guard let spotifyAuthCode = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false)?
                    .queryItems!.first(where: { item -> Bool in
                        return item.name == "code"
                        
                    })?
                    .value else {return}
                
                Spotify.authCode = spotifyAuthCode
                
                Task {
                    await Spotify.getToken()
                    if Spotify.token != nil {
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
                        (
                            UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
                        )?.changeRootViewController(mainTabBarController)
                        
                    } else {
                        // reactivate log in button
                        self.authButton.isEnabled = true
                    }
                }
                
            }
            
            session.presentationContextProvider = self
            
            session.start()
        }
        
    }
    
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
    




}

