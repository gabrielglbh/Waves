//
//  PlayListListController.swift
//  Waves
//
//  Created by Gabriel Garcia on 12/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation

class PlayListListController: UITableViewController, AVAudioPlayerDelegate {
    
    var playlists = [String]()
    
    // Instancia única para toda la aplicación de la canción que suena
    let ap = AudioPlayer()
    var audioPlayer: AudioPlayer!
    var songParams = AudioPlayer.song()
    
    // Instancia para la administración de ficheros
    let cfm = CustomFileManager()
    
    let af = AuxiliarFunctions()
    
    var playButton: UIBarButtonItem!
    var songToolbarText: UIBarButtonItem!

    /**
    * viewDidLoad: Se añaden los botones de Edit y + en la esquina superior derecha y se inicializan el UserDefaults de la playlists.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPlaylist))
        self.editButtonItem.tintColor = UIColor(named: "TintColor")
        self.editButtonItem.title = NSLocalizedString("editButtontitle", comment: "")
        add.tintColor = UIColor(named: "TintColor")
        self.navigationItem.rightBarButtonItems = [self.editButtonItem, add]
        
        title = NSLocalizedString("title.playlistlistcontroller", comment: "")
        
        if UserDefaults.standard.object(forKey: "playlists") == nil {
            UserDefaults.standard.set(playlists, forKey: "playlists")
        } else {
            playlists = (UserDefaults.standard.object(forKey: "playlists")! as? [String])!
        }
    }
    
    /**
    * viewWillAppear: Se inicializa el singleton del audioPlayer y los ficheros de musica. Se checkea si hay toolbar o no.
    */
    override func viewWillAppear(_ animated: Bool) {
        audioPlayer = ap.getInstance()
        songParams = audioPlayer.getSongParams()
        cfm.setCFM(key: songParams.key, isPlaylist: false)
        
        navigationController!.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor(named: "TintColor") as Any]
        
        setToolbarManagement()
        
        if audioPlayer.getIsPlaying() {
            audioPlayer.setDelegate(sender: self)
            navigationController!.isToolbarHidden = false
        } else {
            navigationController!.isToolbarHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if audioPlayer.getIsPlaying() == true { setToolbarButtonsForPlayingSong(playButton: "pause.circle") }
    }
    
    // MARK: Funciones de UITableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    /**
     * Se añade un gestureRecognizer a cada celda para poder modificar su contenido
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellPlaylist", for: indexPath)

        cell.textLabel?.text = playlists[indexPath.row]
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(modifyPlaylist))
        longPress.minimumPressDuration = 1
        cell.addGestureRecognizer(longPress)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            UserDefaults.standard.removeObject(forKey: playlists[indexPath.row])
            playlists.remove(at: indexPath.row)
            UserDefaults.standard.set(playlists, forKey: "playlists")
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let playlist = playlists.remove(at: fromIndexPath.row)
        playlists.insert(playlist, at: to.row)
        UserDefaults.standard.set(playlists, forKey: "playlists")
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
    
    // MARK: Manejo de botones
    
    @objc private func modifyPlaylist(l: UILongPressGestureRecognizer) {
        let p = l.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: p)
        
        createAlert(isModificationMode: true, indexPath!.row)
    }
    
    @IBAction private func addPlaylist() {
        createAlert(isModificationMode: false, nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getPlaylist" {
            if (segue.destination.view != nil) {
                let view = segue.destination as! DisplayContentPlaylistController
                view.title = playlists[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    /**
     * audioPlayerDidFinishPlaying: Cuando la canción ha terminado de reproducirse, se pasa y reproduce la siguiente canción
     */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            goNextOrPreviousSong(mode: true, isOnPause: false)
        }
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
                                                        hasShuffle: songParams.isShuffleModeActive)
            } else {
                songParams.actualSongIndex = audioPlayer.prevSong(currentIndex: prev,
                                                        hasShuffle: songParams.isShuffleModeActive)
            }
            af.resetUIList(tableView, files: cfm.getCountFiles())
        }
        
        let next = cfm.getFile(at: songParams.actualSongIndex)
        let newSong = cfm.getURLFromDoc(of: next)
        
        songParams.title = next
        audioPlayer.setSong(song: newSong)
        audioPlayer.setDelegate(sender: self)
        audioPlayer.setPlay()
        audioPlayer.setSongWithParams(songParams: songParams)
        
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
    
    // MARK: Funciones Auxiliares
    
    /**
    * setToolbarManagement: Añade GestureRecognizers a la toolbar cuando una canción se está reproduciendo.
    * Swipe a la izquierda: NextSong
    * Swipe a la derecha: PreviousSong
    * Tap -> Lleva a la canción que está sonando
    */
    private func setToolbarManagement() {        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(previousSong))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextSong))
        swipeLeft.direction = .left
        
        navigationController!.toolbar.addGestureRecognizer(swipeLeft)
        navigationController!.toolbar.addGestureRecognizer(swipeRight)
    }
    
    /**
     * createCustomButton: Crea un boton o un label personalizado para la UIToolbar
     */
    private func createCustomButton(_ image: String?, _ title: String?, _ detail: String?) -> UIBarButtonItem {
        if let img = image {
            let button = UIButton(type: .custom)
            
            button.setBackgroundImage(UIImage(systemName: img), for: .normal)
            button.tintColor = UIColor(named: "TextColor")
            
            button.addTarget(self, action: #selector(managePlayAction), for: .touchUpInside)
            return UIBarButtonItem.init(customView: button)
        } else {
            let label = UILabel()
            
            if title != nil {
                label.text = title
                label.textColor = UIColor(named: "TextColor")
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
    
    private func createAlert(isModificationMode: Bool, _ index: Int?) {
        var alert: UIAlertController!
        if isModificationMode {
            alert = UIAlertController(title: NSLocalizedString("titlealert.modify", comment: ""), message: nil, preferredStyle: .alert)
        } else {
            alert = UIAlertController(title: NSLocalizedString("titlealert.add", comment: ""), message: nil, preferredStyle: .alert)
        }
        
        alert.addTextField(configurationHandler: {
            textField in
            if isModificationMode {
                textField.text = self.playlists[index!]
            }
            textField.isSecureTextEntry = false
            textField.placeholder = NSLocalizedString("placeholder.alert", comment: "")
        })
        
        let add = UIAlertAction(title: "Ok", style: .default, handler: {
            action in
            let playlist = alert.textFields![0].text!
            if playlist != "" {
                if isModificationMode {
                    self.playlists.remove(at: index!)
                    self.playlists.insert(playlist, at: index!)
                    // MARK: TODO Meter las canciones de dicha lista en la nueva key
                } else {
                    self.playlists.insert(playlist, at: 0)
                }
                
                UserDefaults.standard.set(self.playlists, forKey: "playlists")
                self.tableView.reloadData()
            }
        })
        
        let dismiss = UIAlertAction(title: NSLocalizedString("backbutton.alert", comment: ""), style: .default, handler: {
            action in
            self.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(dismiss)
        alert.addAction(add)
        present(alert, animated: true)
    }
}
