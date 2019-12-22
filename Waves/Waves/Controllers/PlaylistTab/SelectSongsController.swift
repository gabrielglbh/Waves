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
        
        self.title = NSLocalizedString("selectsongs.selecsongscontroller", comment: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        cfm.setAllFiles()
        cfm.checkUserDefaults(key: "music")
        
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectSongCell", for: indexPath)
        
        let song_name = cfm.getFile(at: indexPath.row)
        af.getAndSetDataFromID3(song: cfm.getURLFromDoc(of: song_name), cell: cell)
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell?.contentView.backgroundColor = UIColor.darkGray
        selectedSongs.append(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell?.contentView.backgroundColor = UIColor.init(red: 111, green: 113, blue: 121, alpha: 0)
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
