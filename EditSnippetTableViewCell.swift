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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let handler = onTextFieldReturn {handler()}
        
        return false
    }
    
    func update(with snippet: PodcastSnippet, onTextFieldReturn: @escaping () -> Void) {
        
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
        myImage.image = snippet.episode.image
        
    }

}
