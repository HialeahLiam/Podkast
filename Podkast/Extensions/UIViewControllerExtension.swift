//
//  UIViewControllerExtension.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/17/23.
//

import Foundation

extension UIViewController {
    
    
    // The reason I made the extension is so that both HomeView and LibraryView can share this function.
    func appRemoteConnected() {
        if let controller = self as? LibraryTableViewController,
           let snippet = controller.snippetToBePlayed {
            
            controller.playbackSnippet(snippet)
            controller.snippetToBePlayed = nil
            
            
        } else if let controller = self as? HomeViewController {
            // subscribe to player state
            controller.appRemote?.playerAPI!.delegate = controller.self
            controller.appRemote?.playerAPI?.subscribe { (_, error) -> Void in
                guard error == nil else {
                    print("Unable to subscribe to player API!")
                    return
                }
            }
        }
    }
}
