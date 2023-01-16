//
//  LibraryTableViewController.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/1/23.
//

import UIKit

class LibraryTableViewController: UITableViewController {
    
    var snippets: [PodcastSnippet] = []
    var playbackTimer: Timer?
    var openSpotifyPingTimer: Timer?
    
    var isSpotifyOpen = false
    
    var editingRow: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return snippets.count
    }
    
    func finishSnippetEdit() {
        let cell = tableView.cellForRow(at: IndexPath(row: editingRow, section: 0)) as! EditSnippetTableViewCell
        
        let newTitle = cell.titleField.text
        if newTitle != nil {
            if newTitle == "" {
                snippets[editingRow].title = snippets[editingRow].episode.name
            } else {
                snippets[editingRow].title = newTitle!
            }
        }
        
        editingRow = -1
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if editingRow == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: "snippetEdit", for: indexPath) as! EditSnippetTableViewCell
            
            // Configure the cell...
            let snippet = snippets[indexPath.row]
            
            cell.update(with: snippet) {
                self.finishSnippetEdit()
            }
            
            cell.showsReorderControl = true
            
            let button = UIButton()
            button.setImage(UIImage(systemName: "checkmark"), for: .normal)
            button.tag = indexPath.row
            button.addTarget(self, action: #selector(self.finishEditTouchUp), for: .touchUpInside)
            button.sizeToFit()
            
            cell.accessoryView = button
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "snippet", for: indexPath) as! SnippetTableViewCell

            // Configure the cell...
            let snippet = snippets[indexPath.row]
            
            cell.update(with: snippet)
            cell.showsReorderControl = true
            
            // Add accessory view button
            let button = UIButton()
            button.setImage(UIImage(systemName: "pencil"), for: .normal)
            button.tag = indexPath.row
            button.addTarget(self, action: #selector(self.editSnippet), for: .touchUpInside)
            button.sizeToFit()

            cell.accessoryView = button

            return cell
        }
    }
    
    @IBAction func finishEditTouchUp() { finishSnippetEdit() }
    @IBAction func editSnippet(sender: UIButton) {
        print(sender.tag)
        let indexPath = IndexPath(row: sender.tag, section: 0)
        editingRow = sender.tag
        tableView.reloadData()
        
        let cell = tableView.cellForRow(at: indexPath) as! EditSnippetTableViewCell
        cell.titleField.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedSnippet = snippets[indexPath.row]
        
        guard let startTime = selectedSnippet.startTime,
              let duration = selectedSnippet.duration else {
            print("Podcast snippet did not have startTime or duration properties at time of table cell selection.")
            return
        }

        if playbackTimer != nil { playbackTimer!.invalidate()}
        
        Task {
            do {
                print("Offset before playback: \(selectedSnippet.playlistOffset)")
                selectedSnippet.playlistOffset = try await Spotify.playBackSnippet(selectedSnippet)
                print("Offset after playback: \(selectedSnippet.playlistOffset)")
                // Replace item in snippets after setting playlist offset because structs are pass by value!
                snippets[indexPath.row] = selectedSnippet
                
    //            await Spotify.startPlayback(episodeId: selectedSnippet.episode.id, position: startTime)
                playbackTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                    Task {
                        await Spotify.stopPlayback()
                    }
                }
            } catch SpotifyError.CouldNotPlayOnSpecifiedAdvice{
                print("Device not found! Opening Spotify with uri: \(selectedSnippet.episode.uri)")
                await UIApplication.shared.open(URL(string: selectedSnippet.episode.uri)!)
            } catch SpotifyError.NoDeviceFound {
                let alertController = UIAlertController(title: "Spotify found no devices", message: "Make sure Spotify is open on at least one of your devices.", preferredStyle: .alert)
                
//                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
//                let openSpotifyAction = UIAlertAction(title: "Open Spotify", style: .default) { action in
//                    self.openSpotifyApp()
//                }
                let alertAction = UIAlertAction(title: "OK", style: .default)
                
//                alertController.addAction(cancelAction)
//                alertController.addAction(openSpotifyAction)
                alertController.addAction(alertAction)
                
                present(alertController, animated: true)
            }
            
        }
    }
    
    func openSpotifyApp() {
        print("Opening Spotify!")
        UIApplication.shared.open(URL(string: "spotify:home")!)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            snippets.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
