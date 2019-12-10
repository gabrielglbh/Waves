//
//  SongListController.swift
//  Waves
//
//  Created by Gabriel Garcia on 19/11/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation

class SongListController: UITableViewController, AVAudioPlayerDelegate {

    var docs: URL!
    var files: [String]?
    var fm: FileManager!
    
    var player: AVAudioPlayer!
    var isPlaying = false
    var currentSongPlaying: UITableViewCell?
    
    var playButton: UIBarButtonItem!
    var songToolbarText: UIBarButtonItem!
    
    var cellOfPlayingSong: UITableViewCell?
        
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
        navigationController!.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
        
        navigationController!.toolbar.barTintColor = UIColor.darkGray
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isPlaying == true { setToolbarButtonsForPlayingSong("pause.fill") }
    }
    
    // MARK: Funciones de tableView

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
        getAndSetDataFromID3(docs.appendingPathComponent(song_name), cell: cell, view: nil)
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)

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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
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
    
    // MARK: IBActions y observadores
    
    /**
     * audioPlayerDidFinishPlaying: Cuando la canción ha terminado de reproducirse, se pasa y reproduce la siguiente canción
     */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // TODO: Siguiente cancion
        if flag {
            player.stop()
        } else {
            print("Hola")
        }
        // ERROR: Cuando la cancion termina en la lista, se sigue reproduciendo la siguiente.
        //  Se para el player de esta vista, pero el player de la vista de cancion sigue su curso
    }
    
    /**
     * unwindToController: Al ir de la preview de la cancion a la lista, recoge si hay alguna cancion reproduciendose.
     * Si la hay, se actualizará la IU.
     */
    @IBAction func unwindToSongList(_ unwind: UIStoryboardSegue) {
        let view = unwind.source as! DisplaySongController
        resetUIList()
        
        if view.isPlaying {
            cellOfPlayingSong = tableView.cellForRow(at: IndexPath(row: view.actualSongIndex!,
                                                                                  section: 0))
            cellOfPlayingSong?.textLabel?.textColor = UIColor.systemYellow
            cellOfPlayingSong?.detailTextLabel?.textColor = UIColor.systemYellow
            
            self.player = view.player
            self.isPlaying = view.isPlaying
            
            navigationController!.isToolbarHidden = false
        } else {
            navigationController!.isToolbarHidden = true
        }
    }
    
    /**
    * didSelect: Delegado de UITabBar. Actualiza la IU y la canción en función de la pulsación del boton
    * de play/pause, y siguiente/anterior cancion
    */
    @objc private func managePlayAction() {
        if isPlaying {
            setToolbarButtonsForPlayingSong("play.fill")
            player.pause()
        } else {
            setToolbarButtonsForPlayingSong("pause.fill")
            player.play()
        }
        isPlaying = !isPlaying
    }
    
    /**
     * refreshLibrary: Actualiza la biblioteca de música por si se ha añadido alguna canción nueva
     * mientras la aplicación se está ejecutando
     */
    private func refreshLibrary() {
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
        tableView.reloadData()
    }

    /**
     * Prepara las variables para entrar a la preview de la cancion.
     * Las canciones deben de tener el siguiente formato para su correcto parseo:
     *
     *      "artista - nombre.mp3"
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
                if isPlaying { player.stop() }
                
                // TODO: Si song == songPlaying, entrar a la view con los parametros
                //  del timer puestos con self.player
                
                let view = segue.destination as! DisplaySongController
                
                let song = files![tableView.indexPathForSelectedRow!.row]
                view.songRawName = song
                view.actualSongIndex = tableView.indexPathForSelectedRow!.row
                view.songs = files!
                
                let songToBePlayed = docs.appendingPathComponent(song)
                view.songToBePlayed = songToBePlayed
                
                getAndSetDataFromID3(songToBePlayed, cell: nil, view: view)
            }
        }
    }
    
    // MARK: Funciones Auxiliares
    
    /**
     * getAndSetDataFromID3: Recoge los metadatos de los archivos .mp3 y popula la lista/vista
     */
    private func getAndSetDataFromID3(_ song: URL, cell: UITableViewCell?, view: DisplaySongController?) {
        let p = AVPlayerItem(url: song)
        let metadataList = p.asset.commonMetadata
        
        for item in metadataList {
            switch item.commonKey!.rawValue {
                case "title":
                    if cell != nil {
                        cell!.textLabel?.text = item.value as? String
                    } else {
                        view!.songName?.text = item.value as? String
                    }
                    break
                case "artist":
                    if cell != nil {
                        cell!.detailTextLabel?.text = item.value as? String
                    } else {
                        view!.songArtist?.text = item.value as? String
                    }
                    break
                case "artwork":
                    print(item.value as! Data)
                        if cell != nil {
                            cell!.imageView?.image = UIImage(data: item.value as! Data)
                        } else {
                            view!.portrait?.image = UIImage(data: item.value as! Data)!
                        }
                    /*
                    
                    TODO: Si no hay imagen de album
                 
                    if cell != nil {
                       cell!.imageView?.image = UIImage(named: "album")
                    } else {
                       view!.portrait?.image = UIImage(named: "album2")
                    }*/
                default:
                    break
            }
        }
    }
    
    private func resetUIList() {
        for song in 0...files!.count {
            let cell = tableView.cellForRow(at: IndexPath(row: song, section: 0))
            cell?.textLabel?.textColor = UIColor.white
            cell?.detailTextLabel?.textColor = UIColor.white
        }
    }
    
    /**
     * createCustomButton: Crea un boton personalizado para la UIToolbar
     */
    private func createCustomButton(_ image: String?, _ title: String?) -> UIBarButtonItem {
        let button = UIButton(type: .custom)

        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        
        if let img = image {
            button.setBackgroundImage(UIImage(systemName: img), for: .normal)
            button.tintColor = UIColor.white
        }
        
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        
        if title == nil {
            button.addTarget(self, action: #selector(managePlayAction), for: .touchUpInside)
        }
        
        return UIBarButtonItem.init(customView: button);
    }
    
    /**
     * setToolbarButtonsForPlayingSong: Crea una customToolbar para la reproduccion de una cancion
     */
    private func setToolbarButtonsForPlayingSong(_ button: String) {
        let playButton = createCustomButton(button, nil)
        let songToolbarText = createCustomButton(nil, "     " + cellOfPlayingSong!.textLabel!.text!)
        let blank = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolbarItems = [playButton, songToolbarText, blank]
    }
}
