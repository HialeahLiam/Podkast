//
//  SnippetTableViewCell.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/2/23.
//

import UIKit

class SnippetTableViewCell: UITableViewCell {
    
    @IBOutlet var myImage: UIImageView!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var showLabel: UILabel!
    
    @IBOutlet var timestampLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
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
        myImage.image = snippet.episode.image
        
    }

}
