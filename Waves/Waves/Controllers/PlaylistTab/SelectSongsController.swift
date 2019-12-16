//
//  SelectSongsController.swift
//  Waves
//
//  Created by Gabriel Garcia on 14/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation

class SelectSongsController: UITableViewController {

    var cfm = CustomFileManager()
    var selectedSongs = [Int]()
    
    var af = AuxiliarFunctions()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Elige Canciones"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        cfm.setFiles()
        
        navigationController!.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
    }

    // MARK: Funciones de UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cfm.getCountFiles()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectSongCell", for: indexPath)
        
        let song_name = cfm.getFile(at: indexPath.row)
        af.getAndSetDataFromID3(song: cfm.getURLFromDoc(of: song_name), cell: cell)
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedSongs.append(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        for (ind, row) in selectedSongs.enumerated() {
            if row == indexPath.row {
                selectedSongs.remove(at: ind)
            }
        }
    }
    
    // MARK: Funciones auxiliares
    
    @IBAction private func backToPlaylist(_ sender: Any) {
        performSegue(withIdentifier: "getSongsForPlaylist", sender: self)
    }
}
