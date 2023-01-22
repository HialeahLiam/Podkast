//
//  SceneDelegate.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/24/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SPTAppRemoteDelegate {
    
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("app remote established connection")
        currentViewController?.appRemoteConnected()
//        currentController?.appRemoteConnected()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("disconnected")
//        playerViewController?.appRemoteDisconnect()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("failed app remote connection: ", error)
//        playerViewController?.appRemoteDisconnect()
    }

    var window: UIWindow?
    let SpotifyCientId = "f71867c3c3384668acb38d9a48b1b913"
    let SpotifyRedirectUrl = URL(string: "podkast://")!
    lazy var configuration = SPTConfiguration(clientID: SpotifyCientId, redirectURL: SpotifyRedirectUrl)
    static private let kAccessTokenKey = "access-token-key"
//
//
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self

        return appRemote
    }()
    
    var accessToken = UserDefaults.standard.string(forKey: kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: SceneDelegate.kAccessTokenKey)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("OTHER SCENE!")
        print("open url contexts: ", URLContexts)
        
        guard let url = URLContexts.first?.url else {
            return
        }
        
        
        print("url: ", url)

        let parameters = appRemote.authorizationParameters(from: url)

        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            print("access!")
            appRemote.connectionParameters.accessToken = accessToken
            self.accessToken = accessToken
            print("SPT access token: ", accessToken)
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("Error encountered while obtaining Spotify App Remote access token:")
            print(error_description)
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        print("SCENE!")
       
        
//        print("Scene")
//        guard let _ = (scene as? UIWindowScene) else { return }
//
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//
//        // Retrieve Spotify refresh token from local memory. Make user sign in if token isn't saved.
//        if let refreshTokenData = try? Data(contentsOf: Spotify.refreshTokenUrl),
//           let refreshToken = try? PropertyListDecoder().decode(RefreshToken.self, from: refreshTokenData) {
//
//            Spotify.refreshToken = refreshToken.refresh_token
//
//            // TODO: user profile is only fetched when token is retrieved the very first time. App will not work if spotify user plist file is suddenly deleted. Should refetch user profile.
//            // Retrieve Spotify user profile from local memory
//            if let spotifyUserData = try? Data(contentsOf: Spotify.spotifyUserUrl),
//               let spotifyUser = try? PropertyListDecoder().decode(SpotifyUser.self, from: spotifyUserData) {
//
//                Spotify.spotifyUser = spotifyUser
//            }
//
//            let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
//            window?.rootViewController = mainTabBarController
//
//        } else {
//            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
//            window?.rootViewController = loginViewController
//        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        print("scene did disconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print("scene did become active")
        if let _ = self.appRemote.connectionParameters.accessToken {
            self.appRemote.connect()
          }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        print("scene will resign active")
        if self.appRemote.isConnected {
            self.appRemote.disconnect()
          }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("scene will enter foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print("scene did enter background")
    }
    
    var currentViewController: UIViewController? {
       get {
           print("children: ", self.window?.rootViewController?.children)
           
           guard let rootController = self.window?.rootViewController as? UITabBarController else { return nil }
           
           let currentController = rootController.selectedViewController
           if let homeController = currentController as? HomeViewController { return homeController }
           // NOTE: topViewController might be LibraryTableViewController if it, for example, displays a modal!
           if let navController = currentController as? UINavigationController { return navController.topViewController}
           
           return nil
       }
   }
    
    func changeRootViewController(_ viewController: UIViewController) {
        
        guard let window = window else {return}
        window.rootViewController = viewController
        
        // add animation
        UIView.transition(with: window,
                          duration: 0.5,
                          options: [.transitionFlipFromLeft],
                          animations: nil,
                          completion: nil)
    }


}

