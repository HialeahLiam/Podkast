//
//  UIViewControllerExtension.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/17/23.
//

import Foundation
import StoreKit

extension UIViewController: SKStoreProductViewControllerDelegate {
    func showAppStoreInstall() {
        if TARGET_OS_SIMULATOR != 0 {
            presentAlert(title: "Simulator In Use", message: "The App Store is not available in the iOS simulator, please test this feature on a physical device.")
        } else {
            let loadingView = UIActivityIndicatorView(frame: view.bounds)
            view.addSubview(loadingView)
            loadingView.startAnimating()
            loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            let storeProductViewController = SKStoreProductViewController()
            storeProductViewController.delegate = self
            storeProductViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: SPTAppRemote.spotifyItunesItemIdentifier()], completionBlock: { (success, error) in
                loadingView.removeFromSuperview()
                if let error = error {
                    self.presentAlert(
                        title: "Error accessing App Store",
                        message: error.localizedDescription)
                } else {
                    self.present(storeProductViewController, animated: true, completion: nil)
                }
            })
        }
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
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
