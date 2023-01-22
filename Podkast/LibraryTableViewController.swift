//
//  LibraryTableViewController.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/1/23.
//

import UIKit

class LibraryTableViewController: UITableViewController, UISearchBarDelegate {
    
    
    var playbackTimer: Timer?
    var openSpotifyPingTimer: Timer?
    var isSpotifyOpen = false
    var editingRow: Int = -1
    private let playURI = ""
    var appRemote: SPTAppRemote? {
        get {
            return (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appRemote
        }
    }
    var snippetToBePlayed: PodcastSnippet?

    @IBOutlet var podcastSelectionButton: UIButton!
    
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
        
        // Podcast filter button - here instead of view did load so it will contain newly recorded podcasts
        let podcastSelectionButton = UIButton(type: .custom)
        podcastSelectionButton.configuration = UIButton.Configuration.borderless()
        podcastSelectionButton.configuration!.baseForegroundColor = .systemRed
//        podcastSelectionButton.configuration!.baseBackgroundColor = .systemRed
        
        let podcastFilterSelectionHandler = {(action: UIAction) in
            SnippetController.podcastNameFilter = action.title
            self.tableView.reloadData()
        }
        var actions = SnippetController.getPodcasts().map { title in
            return UIAction(title: title, handler: podcastFilterSelectionHandler)
        }
        actions.insert(UIAction(title: SnippetController.DEFAULT_PODCAST_FILTER_TEXT, handler: podcastFilterSelectionHandler), at: 0)
        podcastSelectionButton.menu = UIMenu(children: actions)
        
        podcastSelectionButton.showsMenuAsPrimaryAction = true
        podcastSelectionButton.changesSelectionAsPrimaryAction = true
        
        navigationItem.titleView = podcastSelectionButton
        // This line let's button expand to its full potential width. I do not know why
        navigationItem.titleView?.translatesAutoresizingMaskIntoConstraints = false

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

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print("CONTROLLER COUNT: ", SnippetController.count())
        return SnippetController.count()
    }
    
    func finishSnippetEdit() {
        let cell = tableView.cellForRow(at: IndexPath(row: editingRow, section: 0)) as! EditSnippetTableViewCell
        
        let newTitle = cell.titleField.text
        var snippet = SnippetController.getAt(index: editingRow)
        if newTitle != nil {
            snippet.title = newTitle!
        }
        SnippetController.edit(at: editingRow, newSnippet: snippet)
        
        editingRow = -1
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if editingRow == indexPath.row {
            let cell = tableView.dequeueReusableCell(withIdentifier: "snippetEdit", for: indexPath) as! EditSnippetTableViewCell
            
            // Configure the cell...
            let snippet = SnippetController.getAt(index: indexPath.row)
            
            fetchAlbumArtForSnippet(snippet: snippet, width: 64, height: 64) { image in
                print("fetch")
            }
            
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
            let snippet = SnippetController.getAt(index: indexPath.row)
            
            fetchAlbumArtForSnippet(snippet: snippet, width: 64, height: 64) { image in
                print("fetch")
            }
            
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedSnippet = SnippetController.getAt(index: indexPath.row)
        print("selected snippet", selectedSnippet.isNew)
        
        playbackSnippet(selectedSnippet)
        SnippetController.unmarkSnippetAsNew(index: indexPath.row)
        Task {
            tableView.reloadData()
        }
    }
    
    func playbackSnippet(_ snippet: PodcastSnippet) {
        guard let duration = snippet.duration else {
            print("Podcast snippet did not have startTime or duration properties at time of table cell selection.")
            return
        }

        if playbackTimer != nil { playbackTimer!.invalidate()}
        
        if appRemote?.isConnected == false {
            // We keep the selected snippet in order to play it as soon as we return to our app.
            self.snippetToBePlayed = snippet
            if appRemote?.authorizeAndPlayURI(playURI) == false {
                showAppStoreInstall()
                return
            }
            print("NOW AUTHORIZED")
        } else {
            appRemote?.playerAPI?.play(snippet.episodeUri, asRadio: false, callback: { reslt, error in
                guard error == nil else {
                    print("Error when playing back episode: ", error!)
                    return
                }
                
                // set playback to correct position once it starts playing
                
                guard let startTime = snippet.startTime else {
                    print("Could not seek because there was no start time!")
                    return
                }
                self.appRemote?.playerAPI?.seek(toPosition: startTime, callback: { result, error in
                    guard error == nil else {
                        print("Error when seeking to episode: ", error!)
                        return
                    }
                })
                
            })
            
            playbackTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                self.appRemote?.playerAPI?.pause { result, error in
                    guard error == nil else {
                        print("Error when pausing episode playback: ", error!)
                        return
                    }
                }
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
            SnippetController.remove(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // MARK UISearchBarDelegate functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        SnippetController.filterText = searchText
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("submit clicked!")
        searchBar.searchTextField.resignFirstResponder()
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
    
    // TODO: Use web api to fetch images. Do image fetching on app startup and save them to snippets array in SnippetController
    private func fetchAlbumArtForSnippet(snippet: PodcastSnippet, width: Int, height: Int, callback: @escaping (UIImage) -> Void ) {
//        appRemote?.contentAPI?.fetchContentItem(forURI: snippet.episodeUri) { (result: SPTAppRemoteContentType, error) in
//            guard error == nil else {
//                return
//            }
//            print("RESULT: ", result)
////            let track = result as! SPTAppRemoteTrack
//
//
//            appRemote?.imageAPI?.fetchImage(forItem: snippet, with:CGSize(width: width, height: height), callback: { (image, error) -> Void in
//                guard error == nil else {
//                    print("image error: ", error)
//                    return }
//
//                let image = image as! UIImage
//                callback(image)
//            })
//        }
        
    }

}
