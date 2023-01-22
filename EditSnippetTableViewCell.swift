//
//  SnippetTableViewCell.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/2/23.
//

import UIKit

class EditSnippetTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet var myImage: UIImageView!

    @IBOutlet var titleField: UITextField!

    @IBOutlet var showLabel: UILabel!

    @IBOutlet var timestampLabel: UILabel!
    
    var onTextFieldReturn: (() -> Void)?
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let handler = onTextFieldReturn {handler()}
        
        return false
    }
    
    func update(with snippet: PodcastSnippet, image: UIImageView? = nil, onTextFieldReturn: @escaping () -> Void) {
        
        self.onTextFieldReturn = onTextFieldReturn
        
        titleField.text = snippet.title
        titleField.returnKeyType = .done
        titleField.delegate = self
        
        showLabel.text = snippet.podcast.name
        
        guard var startTime = snippet.startTime,
              let duration = snippet.duration else {
            print("Podcast snippet did not have startTime or duration properties at time of table cell creation.")
            return
        }
        
        startTime /= 1000
        
        let start = PodcastSnippet.convertToMinandSec(timeInSeconds: startTime)
        let end = PodcastSnippet.convertToMinandSec(timeInSeconds: startTime + Int(duration))

        timestampLabel.text = "\(start)-\(end)"
        
        if let imageData = snippet.imageData {
            myImage.image = UIImage(data: imageData)
        } else {
            myImage.image = UIImage(named: "empty-image")
        } 
        
    }

}
