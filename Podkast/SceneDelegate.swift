//
//  SceneDelegate.swift
//  Podkast
//
//  Created by Liam Idrovo on 12/24/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        print("Scene")
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Retrieve Spotify refresh token from local memory. Make user sign in if token isn't saved.
        if let refreshTokenData = try? Data(contentsOf: Spotify.refreshTokenUrl),
           let refreshToken = try? PropertyListDecoder().decode(RefreshToken.self, from: refreshTokenData) {
            
            Spotify.refreshToken = refreshToken.refresh_token
            
            // TODO: user profile is only fetched when token is retrieved the very first time. App will not work if spotify user plist file is suddenly deleted. Should refetch user profile.
            // Retrieve Spotify user profile from local memory
            if let spotifyUserData = try? Data(contentsOf: Spotify.spotifyUserUrl),
               let spotifyUser = try? PropertyListDecoder().decode(SpotifyUser.self, from: spotifyUserData) {
                
                Spotify.spotifyUser = spotifyUser
            }
            
            let mainTabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController")
            window?.rootViewController = mainTabBarController
            
        } else {
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            window?.rootViewController = loginViewController
        }
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
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        print("scene will resign active")
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

