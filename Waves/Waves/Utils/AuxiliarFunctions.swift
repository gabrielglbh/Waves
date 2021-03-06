//
//  AuxiliarFunctions.swift
//  Waves
//
//  Created by Gabriel Garcia on 16/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation

class AuxiliarFunctions {
    
    let cfm = CustomFileManager()
    
    func resetUIList(_ tableView: UITableView, files: Int) {
        for song in 0...files {
            let cell = tableView.cellForRow(at: IndexPath(row: song, section: 0))
            cell?.textLabel?.textColor = UIColor(named: "TextColor")
            cell?.detailTextLabel?.textColor = UIColor(named: "Detail")
        }
    }
    
    /**
     * Actualiza la celda elegida de la cancion que está sonando y la pinta de amarillo
     */
    /*func setCurrentSongUI(_ tableView: UITableView, song: AudioPlayer.song) {
        var realInd = 0
        for (ind, cell) in tableView.visibleCells.enumerated() {
            if cell.textLabel!.text! + ".mp3" == song.title {
                realInd = ind
            }
        }
        
        let cellOfPlayingSong = tableView.cellForRow(at: IndexPath(row: realInd, section: 0))
        cellOfPlayingSong?.textLabel?.textColor = UIColor.systemYellow
        cellOfPlayingSong?.detailTextLabel?.textColor = UIColor.systemYellow
    }*/

    /**
    * Recoge la información de metadatos ID3 de cada canción y popula la celda
    */
    func getAndSetDataFromID3(song: URL, cell: UITableViewCell?) {
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
    
    /**
     * Recoge la información de metadatos ID3 de la canción que está sonando para poner los campos de la toolbar
     */
    func getAndSetDataFromID3ForToolbar(song: URL) -> [String] {
        let p = AVPlayerItem(url: song)
        let metadataList = p.asset.commonMetadata
        var id3_fields = [String]()
        
        for item in metadataList {
            switch item.commonKey!.rawValue {
                case "title":
                    id3_fields.append((item.value as? String)!)
                    break
                case "artist":
                    id3_fields.append((item.value as? String)!)
                    break
                default:
                    break
            }
        }
        return id3_fields
    }
}
