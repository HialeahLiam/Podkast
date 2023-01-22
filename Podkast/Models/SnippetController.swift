//
//  SnippetController.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/21/23.
//

import Foundation

class SnippetController {
    
    static private var snippets: [PodcastSnippet] = {
        guard let snippetData = try? Data(contentsOf: dataUrl),
           let snippets = try? PropertyListDecoder().decode([PodcastSnippet].self, from: snippetData) else {
            print("Snippet data could not be loaded!")
            return []
           }
         
         return snippets
    }()
    static var filterText = ""
    static private var filteredSnippets: [PodcastSnippet] {
        if filterText.isEmpty {return self.snippets}
        
        let results = self.fuse.search(self.filterText, in: self.snippets)
        print("RESULTS: ", results)
        results.forEach { item in
            print("snippet: ", snippets[item.index].title, "-", snippets[item.index].podcast.name)
            print("score: ", item.score)
        }
        return results.map { item in
            self.snippets[item.index]
        }
    }
    static let fuse = Fuse(threshold: 1)
    static private var dataUrl: URL {
        get {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsDir.appending(path: "snippets").appendingPathExtension("plist")
        }
    }
   
    static func getAll() -> [PodcastSnippet] {
        return snippets
    }
    
    static func append(_ snippet: PodcastSnippet) {
        self.snippets.insert(snippet, at: 0)
        refreshData()
    }
    
    static func getAt(index: Int) -> PodcastSnippet {
        return filteredSnippets[index]
    }
    
    static func remove(index: Int) {
        snippets.remove(at: index)
        refreshData()
    }
    
    static func count() -> Int {
        return filteredSnippets.count
    }
    /**
     Only edits:
     - title
     */
    static func edit(at index: Int, newSnippet: PodcastSnippet) {
        if newSnippet.title == "" {
            snippets[index].title = snippets[index].episodeName
        } else {
            snippets[index].title = newSnippet.title
        }
        refreshData()
    }
    
    static func unmarkSnippetAsNew(index: Int) {
        self.snippets[index].isNew = false
        refreshData()
    }
    
    static private func refreshData() {
        print("refresh data!: ", self.snippets.count)
 
        let encodedSnippets = try? PropertyListEncoder().encode(self.snippets)

        if let encodedSnippets = encodedSnippets {
//            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let refreshTokenUrl = documentsDir.appending(path: "spotify_refresh_token").appendingPathExtension("plist")

            do {
                try encodedSnippets.write(to: dataUrl, options: .noFileProtection)
            } catch {
                print("Snippets could not be saved to local memory!")
            }

        } else {
            print("Snippets could not be encoded into a plist!")
        }

        print("snippets saved: ", encodedSnippets)
    }
}
