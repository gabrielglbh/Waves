//
//  DisplayContentPlaylistController.swift
//  Waves
//
//  Created by Gabriel Garcia on 16/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation

class DisplayContentPlaylistController: UITableViewController, AVAudioPlayerDelegate {

    // Instancia para la administración de ficheros
    var cfm = CustomFileManager()
    var newPlaylist = [String]()
    
    // Instancia única para toda la aplicación de la canción que suena
    let ap = AudioPlayer()
    var audioPlayer: AudioPlayer!
    
    let af = AuxiliarFunctions()
    
    var actualSongIndex: Int?
    var isShuffleModeActive = false
    var isRepeatModeActive = false
    var isPlaying = false
    var fromToolbarToDisplay = false
    
    var playButton: UIBarButtonItem!
    var songToolbarText: UIBarButtonItem!
    var cellOfPlayingSong: UITableViewCell?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.editButtonItem.tintColor = UIColor.systemYellow

        cfm.reloadData()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        audioPlayer = ap.getInstance()
        
        navigationController!.navigationBar.tintColor = UIColor.systemYellow
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
        
        cfm.setCFM(key: title!)
        newPlaylist = cfm.getFiles()
        
        setToolbarManagement()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isPlaying == true { setToolbarButtonsForPlayingSong(playButton: "pause.circle") }
    }
    
    @IBAction func unwindToDisplayPlaylist(_ unwind: UIStoryboardSegue) {
        let view = unwind.source as! SelectSongsController
        
        for ind in view.selectedSongs {
            newPlaylist.append(cfm.getFileFrom(at: ind, from: "music"))
        }
    
        cfm.setUserDefaults(files: newPlaylist)
        tableView.reloadData()
    }

    // MARK: Funciones del UITableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newPlaylist.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songPlaylist", for: indexPath)

        let songs = cfm.getFiles()
        af.getAndSetDataFromID3(song: cfm.getURLFromDoc(of: songs[indexPath.row]), cell: cell)
       
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        return cell
    }
    
    /**
     * editingStyle: Elimina de Documents la cancion, al igual que de la lista.
     */
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.row == actualSongIndex {
                audioPlayer.stop()
                af.resetUIList(tableView, files: cfm.getCountFiles())
                navigationController!.toolbar.isHidden = true
            }
            
            let songToBeRemoved = cfm.getFile(at: indexPath.row)
            cfm.removeInstance(songToBeRemoved: songToBeRemoved)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    /**
     * moveRowAt: Al mover una cancion se actualizan los indices
     */
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        cfm.updateInstance(from: fromIndexPath.row, to: to.row)
        actualSongIndex = to.row
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
    
    // MARK: Observadores
    
    /**
     * audioPlayerDidFinishPlaying: Cuando la canción ha terminado de reproducirse, se pasa y reproduce la siguiente canción
     */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            goNextOrPreviousSong(mode: true, isOnPause: false)
        }
    }
    
    /**
     * unwindToPlaylist: Dos caminos posibles:
     *          1. Al volver de la preview de la cancion, recoge si hay alguna cancion reproduciendose. Si la hay,
     *              se actualizará la IU y se hace set del nuevo delegado de la vista.
     *          2. Al volver de la selección de canciones a añadir a la playlist, añade esas canciones al
 *                                      UserDeafults de la playlist y se popula la tabla.
     */
    @IBAction func unwindToPlaylist(_ unwind: UIStoryboardSegue) {
        if let view = unwind.source as? DisplaySongController {
            hidesBottomBarWhenPushed = false
            af.resetUIList(tableView, files: cfm.getCountFiles())
            
            if view.isPlaying {
                self.actualSongIndex = view.actualSongIndex!
                self.isShuffleModeActive = view.isShuffleModeActive
                self.isRepeatModeActive = view.isRepeatModeActive
                self.isPlaying = view.isPlaying
                navigationController!.isToolbarHidden = false
                
                audioPlayer.setDelegate(sender: self)
                cellOfPlayingSong = af.setCurrentSongUI(tableView, at: actualSongIndex!)
            } else {
                navigationController!.isToolbarHidden = true
            }
        } else if let view = unwind.source as? SelectSongsController {
            for ind in view.selectedSongs {
                newPlaylist.append(cfm.getFileFrom(at: ind, from: "music"))
            }
        
            cfm.setUserDefaults(files: newPlaylist)
            tableView.reloadData()
        }
    }
    
    /**
     * Prepara las variables para entrar a la preview de la cancion.
     * @var songRawName: nombre del fichero de la cancion
     * @var actualSongIndex: indice que representa la posicion de la cancion abierta dentro de la lista de las canciones
     * @var songToBePlayed: URL de la cancion que se debe reproducir
     * @hideBottomBarWhenPushed: Esconde la NavBar al ir a la preview de la canción
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goDisplayFromPlaylist" {
            if (segue.destination.view != nil) {
                hidesBottomBarWhenPushed = true
                var selectedRow: Int?
                if fromToolbarToDisplay {
                    selectedRow = actualSongIndex
                } else {
                    selectedRow = tableView.indexPathForSelectedRow!.row
                }
                
                let view = segue.destination as! DisplaySongController
                
                if isPlaying && actualSongIndex == selectedRow {
                    view.currentSongFromList = true
                } else {
                    if isPlaying { audioPlayer.stop() }
                    view.currentSongFromList = false
                }
                
                let song = cfm.getFile(at: selectedRow!)
                view.songRawName = song
                view.actualSongIndex = selectedRow!
                view.key = title!
                view.fromPlaylist = true
                
                let songToBePlayed = cfm.getURLFromDoc(of: song)
                view.songToBePlayed = songToBePlayed
                
                view.isShuffleModeActive = !self.isShuffleModeActive
                view.isRepeatModeActive = !self.isRepeatModeActive
            }
        }
        
        fromToolbarToDisplay = false
    }
    
    // MARK: Funciones de manejo de reproducción
    
    /**
    * didSelect: Delegado de UITabBar. Actualiza la IU y la canción en función de la pulsación del boton
    * de play/pause, y siguiente/anterior cancion
    */
    @objc private func managePlayAction() {
        if isPlaying {
            setToolbarButtonsForPlayingSong(playButton: "play.circle")
            audioPlayer.pause()
        } else {
            setToolbarButtonsForPlayingSong(playButton: "pause.circle")
            audioPlayer.play()
        }
        isPlaying = !isPlaying
    }
    
    private func goNextOrPreviousSong(mode: Bool, isOnPause: Bool) {
        if !isRepeatModeActive {
            let prev = actualSongIndex!
            if mode {
                actualSongIndex = audioPlayer.nextSong(currentIndex: prev,
                                                        hasShuffle: isShuffleModeActive,
                                                        totalSongs: cfm.getCountFiles())
            } else {
                actualSongIndex = audioPlayer.prevSong(currentIndex: prev,
                                                        hasShuffle: isShuffleModeActive,
                                                        totalSongs: cfm.getCountFiles())
            }
            af.resetUIList(tableView, files: cfm.getCountFiles())
            cellOfPlayingSong = af.setCurrentSongUI(tableView, at: actualSongIndex!)
        }
        
        let next = cfm.getFile(at: actualSongIndex!)
        let newSong = cfm.getURLFromDoc(of: next)
        
        audioPlayer.setSong(song: newSong)
        audioPlayer.setDelegate(sender: self)
        audioPlayer.setPlay()
        
        if !isOnPause {
            setToolbarButtonsForPlayingSong(playButton: "pause.circle")
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } else {
            setToolbarButtonsForPlayingSong(playButton: "play.circle")
        }
    }
    
    @objc private func previousSong() { goNextOrPreviousSong(mode: false, isOnPause: !audioPlayer.getIsPlaying()) }
    
    @objc private func nextSong() { goNextOrPreviousSong(mode: true, isOnPause: !audioPlayer.getIsPlaying()) }
    
    @objc private func displaySong() {
        fromToolbarToDisplay = true
        performSegue(withIdentifier: "goDisplayFromPlaylist", sender: nil)
    }
    
    // MARK: Funciones auxiliares
    
    /**
    * setToolbarManagement: Añade GestureRecognizers a la toolbar cuando una canción se está reproduciendo.
    * Swipe a la izquierda: NextSong
    * Swipe a la derecha: PreviousSong
    * Tap -> Lleva a la canción que está sonando
    */
    private func setToolbarManagement() {
        navigationController!.toolbar.barTintColor = UIColor.darkGray
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(previousSong))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextSong))
        swipeLeft.direction = .left
        let tap = UITapGestureRecognizer(target: self, action: #selector(displaySong))
        tap.numberOfTapsRequired = 1
        
        navigationController!.toolbar.addGestureRecognizer(swipeLeft)
        navigationController!.toolbar.addGestureRecognizer(swipeRight)
        navigationController!.toolbar.addGestureRecognizer(tap)
    }
    
    /**
     * createCustomButton: Crea un boton o un label personalizado para la UIToolbar
     */
    private func createCustomButton(_ image: String?, _ title: String?, _ detail: String?) -> UIBarButtonItem {
        if let img = image {
            let button = UIButton(type: .custom)
            
            button.setBackgroundImage(UIImage(systemName: img), for: .normal)
            button.tintColor = UIColor.white
            
            button.addTarget(self, action: #selector(managePlayAction), for: .touchUpInside)
            return UIBarButtonItem.init(customView: button)
        } else {
            let label = UILabel()
            
            if title != nil {
                label.text = title
                label.textColor = UIColor.white
                label.font = UIFont.boldSystemFont(ofSize: 18)
            } else {
                label.text = detail
                label.textColor = UIColor(named: "Detail")
            }
            label.numberOfLines = 1
            return UIBarButtonItem.init(customView: label)
        }
    }
    
    /**
     * setToolbarButtonsForPlayingSong: Crea una customToolbar para la reproduccion de una cancion
     */
    private func setToolbarButtonsForPlayingSong(playButton: String) {
        let playButton = createCustomButton(playButton, nil, nil)
        let songToolbarText = createCustomButton(nil, cellOfPlayingSong!.textLabel!.text! + " \u{00B7} ", nil)
        let artistToolbarText = createCustomButton(nil, nil, cellOfPlayingSong!.detailTextLabel!.text!)
        let blank = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolbarItems = [songToolbarText, artistToolbarText, blank, playButton]
    }
}