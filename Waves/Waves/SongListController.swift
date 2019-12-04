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
    var fm: FileManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.editButtonItem.tintColor = UIColor.systemYellow
        
        self.title = "Mis Canciones"
        
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(docs.path)
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files!.count
    }

    /**
     * cellForRowAt: Pinta cada celda con una cancion de una lista de canciones guardada previamente
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let song_name = files![indexPath.row]
        let parted = song_name.components(separatedBy: "-")
        let artist = parted[0]
        var name = parted[1].components(separatedBy: ".mp3")[0]
        name.remove(at: name.startIndex)
        
        cell.textLabel?.text = name
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        cell.detailTextLabel?.text = artist
        cell.imageView?.image = UIImage(named: "album")

        return cell
    }
    
    /**
     * editingStyle: Elimina de Documents la cancion, al igual que de la lista.
     */
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let songToBeRemoved = files![indexPath.row]
            let path = docs.appendingPathComponent(songToBeRemoved)
            do {
                try fm.removeItem(at: path)
            } catch { print("Error al eliminar") }
            
            files = try? fm.contentsOfDirectory(atPath: docs.path)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    /**
     * moveRowAt: Al mover una cancion se actualizan los indices
     */
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let song = files!.remove(at: fromIndexPath.row)
        files!.insert(song, at: to.row)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    /**
     * Prepara las variables para entrar a la preview de la cancion.
     * Las canciones deben de tener el siguiente formato para su correcto parseo:
     *
     *      "artista-nombre.mp3"
     *
     * @var songRawName: nombre del fichero de la cancion
     * @var actualSongIndex: indice que representa la posicion de la cancion abierta dentro de la lista de las canciones
     * @var songs: lista de canciones
     * @var songToBePlayed: URL de la cancion que se debe reproducir
     * @var songName: nombre explanatorio
     * @var songArtist: nombre explanatorio
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPlaySong" {
            if (segue.destination.view != nil) {
                let view = segue.destination as! DisplaySongController
                
                let song = files![tableView.indexPathForSelectedRow!.row]
                view.songRawName = song
                view.actualSongIndex = tableView.indexPathForSelectedRow!.row
                view.songs = files!
                
                let songToBePlayed = docs.appendingPathComponent(song)
                view.songToBePlayed = songToBePlayed
                
                let parted = song.components(separatedBy: "-")
                let artist = parted[0]
                let title = parted[1].components(separatedBy: ".mp3")[0]
                
                view.title = ""
        
                view.songName?.text = title
                view.songArtist?.text = artist
            }
        }
    }
}
