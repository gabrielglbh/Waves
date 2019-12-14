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

    var docs: URL!
    var files: [String]?
    var fm: FileManager!
    
    var selectedSongs: [Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Elige Canciones"
        
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController!.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
    }

    // MARK: Funciones de UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectSongCell", for: indexPath)
        
        let song_name = files![indexPath.row]
        getAndSetDataFromID3(docs.appendingPathComponent(song_name), cell: cell)
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
    // MARK: Funciones auxiliares
    
    @IBAction private func backToPlaylist(_ sender: Any) {
        let indexPaths = tableView.indexPathsForSelectedRows!
        for ind in 0..<indexPaths.count {
            let v = indexPaths[ind] as IndexPath
            print(v.row)
            selectedSongs?.append(v.row)
        }
        performSegue(withIdentifier: "getSongsForPlaylist", sender: self)
    }
    
    /**
     * getAndSetDataFromID3: Recoge los metadatos de los archivos .mp3 y popula la celda de la lista
     */
    private func getAndSetDataFromID3(_ song: URL, cell: UITableViewCell?) {
        let p = AVPlayerItem(url: song)
        let metadataList = p.asset.commonMetadata
        var count = 1
        
        for item in metadataList {
            switch item.commonKey!.rawValue {
                case "title":
                    cell!.textLabel?.text = item.value as? String
                    break
                case "artist":
                    cell!.detailTextLabel?.text = item.value as? String
                    break
                case "artwork":
                    count -= 1
                    cell!.imageView?.image = UIImage(data: item.value as! Data)
                    break
                default:
                    break
            }
        }
        
        if count != 0 {
            cell!.imageView?.image = UIImage(named: "album")
        }
    }
}
