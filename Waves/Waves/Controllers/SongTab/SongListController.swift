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
	
    // Instancia única para toda la aplicación de la canción que suena
	let ap = AudioPlayer()
	var audioPlayer: AudioPlayer!
    var songParams = AudioPlayer.song()
    
    // Instancia para la administración de ficheros
    let cfm = CustomFileManager(key: "music")
    let key = "music"
    
    let af = AuxiliarFunctions()
    
    var fromToolbarToDisplay = false
    
    var playButton: UIBarButtonItem!
    var songToolbarText: UIBarButtonItem!
    var cellOfPlayingSong: UITableViewCell?
        
    /**
     * viewDidLoad: Crea un fichero en UsersDefault para mantener el orden de la lista en caso de que haya cambiado
     * Obtiene el path a los ficheros de música.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.editButtonItem.tintColor = UIColor.systemYellow
        
        self.title = "Mis Canciones"
        
        cfm.reloadData()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
		audioPlayer = ap.getInstance()
        songParams = audioPlayer.getSongParams()
	
        navigationController!.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
        
        hidesBottomBarWhenPushed = false
        af.resetUIList(tableView, files: cfm.getCountFiles())
        
        if audioPlayer.getIsPlaying() {
            navigationController!.isToolbarHidden = false
            
            audioPlayer.setDelegate(sender: self)
            cellOfPlayingSong = af.setCurrentSongUI(tableView, at: songParams.actualSongIndex)
        } else {
            navigationController!.isToolbarHidden = true
        }
        
        setToolbarManagement()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if audioPlayer.getIsPlaying() == true { setToolbarButtonsForPlayingSong(playButton: "pause.circle") }
    }
    
    // MARK: Funciones de UITableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cfm.getCountFiles()
    }

    /**
     * cellForRowAt: Pinta cada celda con una cancion de una lista de canciones guardada previamente
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let song_name = cfm.getFile(at: indexPath.row)
        af.getAndSetDataFromID3(song: cfm.getURLFromDoc(of: song_name), cell: cell)
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)

        return cell
    }
    
    /**
     * editingStyle: Elimina de Documents la cancion, al igual que de la lista.
     */
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.row == songParams.actualSongIndex && audioPlayer.getIsPlaying() {
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
        songParams.actualSongIndex = to.row
        audioPlayer.setSongWithParams(songParams: songParams)
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
    
    @IBAction private func resetDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        cfm.reloadData()
        tableView.reloadData()
    }
    
    /**
     * unwindToController: Al ir de la preview de la cancion a la lista, recoge si hay alguna cancion reproduciendose.
     * Si la hay, se actualizará la IU y se hace set del nuevo delegado de la vista.
     */
    @IBAction func unwindToSongList(_ unwind: UIStoryboardSegue) {
        hidesBottomBarWhenPushed = false
        songParams = audioPlayer.getSongParams()
        af.resetUIList(tableView, files: cfm.getCountFiles())
        
        if audioPlayer.getIsPlaying() {
            navigationController!.isToolbarHidden = false
			
            audioPlayer.setDelegate(sender: self)
            cellOfPlayingSong = af.setCurrentSongUI(tableView, at: songParams.actualSongIndex)
        } else {
            navigationController!.isToolbarHidden = true
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
        if segue.identifier == "goToPlaySong" {
            if (segue.destination.view != nil) {
                hidesBottomBarWhenPushed = true
                var selectedRow: Int?
                if fromToolbarToDisplay {
                    selectedRow = songParams.actualSongIndex
                } else {
                    selectedRow = tableView.indexPathForSelectedRow!.row
                }
                
                let view = segue.destination as! DisplaySongController
                
                if audioPlayer.getIsPlaying() && songParams.actualSongIndex == selectedRow {
                    view.currentSongFromList = true
                } else {
                    if audioPlayer.getIsPlaying() { audioPlayer.stop() }
                    view.currentSongFromList = false
                }
                
                let song = cfm.getFile(at: selectedRow!)
                view.songRawName = song
                view.fromPlaylist = false
                
                let songToBePlayed = cfm.getURLFromDoc(of: song)
                view.songToBePlayed = songToBePlayed
                
                songParams.key = key
                songParams.isShuffleModeActive = !songParams.isShuffleModeActive
                songParams.isRepeatModeActive = !songParams.isRepeatModeActive
                songParams.actualSongIndex = selectedRow!
            }
        }
        audioPlayer.setSongWithParams(songParams: songParams)
        
        fromToolbarToDisplay = false
    }
    
    // MARK: Funciones de manejo de reproducción
    
    /**
    * didSelect: Delegado de UITabBar. Actualiza la IU y la canción en función de la pulsación del boton
    * de play/pause
    */
    @objc private func managePlayAction() {
        if audioPlayer.getIsPlaying() {
            setToolbarButtonsForPlayingSong(playButton: "play.circle")
            audioPlayer.pause()
        } else {
            setToolbarButtonsForPlayingSong(playButton: "pause.circle")
            audioPlayer.play()
        }
    }
    
    private func goNextOrPreviousSong(mode: Bool, isOnPause: Bool) {
        if !songParams.isRepeatModeActive {
            let prev = songParams.actualSongIndex
            if mode {
                songParams.actualSongIndex = audioPlayer.nextSong(currentIndex: prev,
                                                        hasShuffle: songParams.isShuffleModeActive,
                                                        totalSongs: cfm.getCountFiles())
            } else {
                songParams.actualSongIndex = audioPlayer.prevSong(currentIndex: prev,
                                                        hasShuffle: songParams.isShuffleModeActive,
                                                        totalSongs: cfm.getCountFiles())
            }
            af.resetUIList(tableView, files: cfm.getCountFiles())
            cellOfPlayingSong = af.setCurrentSongUI(tableView, at: songParams.actualSongIndex)
        }
        
        let next = cfm.getFile(at: songParams.actualSongIndex)
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
        
        audioPlayer.setSongWithParams(songParams: songParams)
    }
    
    @objc private func previousSong() { goNextOrPreviousSong(mode: false, isOnPause: !audioPlayer.getIsPlaying()) }
    
    @objc private func nextSong() { goNextOrPreviousSong(mode: true, isOnPause: !audioPlayer.getIsPlaying()) }
    
    @objc private func displaySong() {
        fromToolbarToDisplay = true
        performSegue(withIdentifier: "goToPlaySong", sender: nil)
    }
    
    // MARK: Funciones Auxiliares
    
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
        let actualSong = cfm.getFile(at: songParams.actualSongIndex)
        let id3 = af.getAndSetDataFromID3ForToolbar(song: cfm.getURLFromDoc(of: actualSong))
        
        let playButton = createCustomButton(playButton, nil, nil)
        let songToolbarText = createCustomButton(nil, id3[0] + " \u{00B7} ", nil)
        let artistToolbarText = createCustomButton(nil, nil, id3[1])
        let blank = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        toolbarItems = [songToolbarText, artistToolbarText, blank, playButton]
    }
}
