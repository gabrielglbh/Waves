//
//  DisplayPlaylistController.swift
//  Waves
//
//  Created by Gabriel Garcia on 12/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation

class DisplayPlaylistController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var cfm = CustomFileManager()
    var newPlaylist = [String]()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addSongs: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSongs.layer.cornerRadius = 20
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController!.navigationBar.tintColor = UIColor.systemYellow
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
        
        cfm.setCFM(key: title!)
        newPlaylist = cfm.getFiles()
    }
    
    @IBAction func unwindToDisplayPlaylist(_ unwind: UIStoryboardSegue) {
        let view = unwind.source as! SelectSongsController
        
        for ind in view.selectedSongs {
            newPlaylist.append(cfm.getFileFrom(at: ind, from: "music", initial: title!))
        }
    
        cfm.setUserDefaults(files: newPlaylist, key: title!)
        tableView.reloadData()
    }
    
    // MARK: Fucniones de UITableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newPlaylist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songPlaylist", for: indexPath)

        getAndSetDataFromID3(cfm.getURLFromDoc(of: newPlaylist[indexPath.row]), cell: cell)
       
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPlaySongFromPlaylist" {
            if (segue.destination.view != nil) {
                hidesBottomBarWhenPushed = true
                /*var selectedRow: Int?
                if fromToolbarToDisplay {
                    selectedRow = actualSongIndex
                } else {
                    selectedRow = tableView.indexPathForSelectedRow!.row
                }*/
                let selectedRow = tableView.indexPathForSelectedRow!.row
                
                let view = segue.destination as! DisplaySongController
                
                /*if isPlaying && actualSongIndex == selectedRow {
                    view.currentSongFromList = true
                } else {
                    if isPlaying { audioPlayer.stop() }
                    view.currentSongFromList = false
                }*/
                
                let song = cfm.getFile(at: selectedRow)
                view.songRawName = song
                view.actualSongIndex = selectedRow
                view.key = title!
                
                let songToBePlayed = cfm.getURLFromDoc(of: song)
                view.songToBePlayed = songToBePlayed
                
                //view.isShuffleModeActive = !self.isShuffleModeActive
                //view.isRepeatModeActive = !self.isRepeatModeActive
            }
        }
    }
    
    // MARK: Funciones auxiliares
    
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
    
    // TODO: Poner la toolbar (igual que en SongListController)
    // TODO: Pasar la información correcta a DisplaySongController
    // TODO: Permitir la edición de la tableView (igual que en SongListController)
}
