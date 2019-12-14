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
	
    // Instancia única para toda la aplicación de la canción que suena
	let ap = AudioPlayer()
	var audioPlayer: AudioPlayer!
    
	var actualSongIndex: Int?
    var isShuffleModeActive = false
    var isRepeatModeActive = false
    var isPlaying = false
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
        
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(docs.path)
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
        
        if UserDefaults.standard.object(forKey: "music") == nil {
            UserDefaults.standard.set(files!, forKey: "music")
        } else {
            files = UserDefaults.standard.object(forKey: "music")! as? [String]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
		audioPlayer = ap.getInstance()
	
        navigationController!.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
        
        setToolbarManagement()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isPlaying == true { setToolbarButtonsForPlayingSong(playButton: "pause.circle") }
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
        getAndSetDataFromID3(docs.appendingPathComponent(song_name), cell: cell)
        
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
                resetUIList()
                navigationController!.toolbar.isHidden = true
            }
            
            let songToBeRemoved = files![indexPath.row]
            let path = docs.appendingPathComponent(songToBeRemoved)
            do {
                try fm.removeItem(at: path)
            } catch { print("Error al eliminar") }
            
            files = try? fm.contentsOfDirectory(atPath: docs.path)
            UserDefaults.standard.set(files!, forKey: "music")
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    /**
     * moveRowAt: Al mover una cancion se actualizan los indices
     */
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let song = files!.remove(at: fromIndexPath.row)
        files!.insert(song, at: to.row)
        UserDefaults.standard.set(files!, forKey: "music")
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
     * unwindToController: Al ir de la preview de la cancion a la lista, recoge si hay alguna cancion reproduciendose.
     * Si la hay, se actualizará la IU y se hace set del nuevo delegado de la vista.
     */
    @IBAction func unwindToSongList(_ unwind: UIStoryboardSegue) {
        let view = unwind.source as! DisplaySongController
        hidesBottomBarWhenPushed = false
        resetUIList()
        
        if view.isPlaying {
			self.actualSongIndex = view.actualSongIndex!
            self.isShuffleModeActive = view.isShuffleModeActive
            self.isRepeatModeActive = view.isRepeatModeActive
			self.isPlaying = view.isPlaying
            navigationController!.isToolbarHidden = false
			
            audioPlayer.setDelegate(sender: self)
			setCurrentSongUI()
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
                
                let song = files![selectedRow!]
                view.songRawName = song
                view.actualSongIndex = selectedRow!
                view.songs = files!
                
                let songToBePlayed = docs.appendingPathComponent(song)
                view.songToBePlayed = songToBePlayed
                
                view.isShuffleModeActive = !self.isShuffleModeActive
                view.isRepeatModeActive = !self.isRepeatModeActive
            }
        }
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
                                                        totalSongs: files!.count)
            } else {
                actualSongIndex = audioPlayer.prevSong(currentIndex: prev,
                                                        hasShuffle: isShuffleModeActive,
                                                        totalSongs: files!.count)
            }
            resetUIList()
            setCurrentSongUI()
        }
        
        let next = files![actualSongIndex!]
        let newSong = docs.appendingPathComponent(next)
        
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
        performSegue(withIdentifier: "goToPlaySong", sender: nil)
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
    
    // MARK: Funciones Auxiliares
    
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
	
    /**
     * setCurrentSongUI: Actualiza la interfaz para pintar de amarillo la cancion que está sonando en la lista
     */
	private func setCurrentSongUI() {
        cellOfPlayingSong = tableView.cellForRow(at: IndexPath(row: actualSongIndex!, section: 0))
		cellOfPlayingSong?.textLabel?.textColor = UIColor.systemYellow
		cellOfPlayingSong?.detailTextLabel?.textColor = UIColor.systemYellow
	}
    
    private func resetUIList() {
        for song in 0...files!.count {
            let cell = tableView.cellForRow(at: IndexPath(row: song, section: 0))
            cell?.textLabel?.textColor = UIColor.white
            cell?.detailTextLabel?.textColor = UIColor.white
        }
    }
    
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
