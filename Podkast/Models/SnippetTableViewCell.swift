//
//  SnippetTableViewCell.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/2/23.
//

import UIKit

class SnippetTableViewCell: SnippetCell {
    
    @IBOutlet var myImage: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var showLabel: UILabel!
    
    @IBOutlet var timestampLabel: UILabel!
    
    @IBOutlet var isNewLabel: UILabel!
    
    func update(with snippet: PodcastSnippet) {
    
        titleLabel.text = snippet.title
        
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
        
        if !snippet.isNew {
            isNewLabel.isHidden = true
        } else {
            isNewLabel.isHidden = false
        }
    }

}
