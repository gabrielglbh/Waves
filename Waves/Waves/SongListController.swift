//
//  SongListController.swift
//  Waves
//
//  Created by Gabriel Garcia on 19/11/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

class SongListController: UITableViewController {

    var docs: URL!
    var files: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Mis Canciones"
        
        docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(docs.path)
        
        let fm = FileManager.default
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let song_name = files![indexPath.row]
        let parted = song_name.components(separatedBy: "-")
        let artist = parted[0]
        var name = parted[1].components(separatedBy: ".mp3")[0]
        name.remove(at: name.startIndex)
        
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = artist
        cell.imageView?.image = UIImage(named: "album")

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPlaySong" {
            if (segue.destination.view != nil) {
                let song = files![tableView.indexPathForSelectedRow!.row]
                let songToBePlayed = docs.appendingPathComponent(song)
                
                let parted = song.components(separatedBy: "-")
                let artist = parted[0]
                let title = parted[1].components(separatedBy: ".mp3")[0]
                
                let view = segue.destination as! DisplaySongController
                view.title = ""
        
                view.songName?.text = title
                view.songArtist?.text = artist
                
                view.song = songToBePlayed
            }
        }
    }
}
