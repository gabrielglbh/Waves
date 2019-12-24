//
//  DisplaySongController.swift
//  Waves
//
//  Created by Gabriel Garcia on 19/11/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class DisplaySongController: UIViewController, AVAudioPlayerDelegate {

    var songToBePlayed: URL?
    var songRawName: String?
    var currentSongFromList: Bool?
    
	// Instancia única para toda la aplicación de la canción que suena
	let ap = AudioPlayer()
	var audioPlayer: AudioPlayer!
    var songParams = AudioPlayer.song()
    
    var cfm = CustomFileManager()
    var key: String!
    
    var songTime = Timer()
    
    var fromPlaylist = false
    var isCarModeActive = false
    
    @IBOutlet var portrait: UIImageView?
    @IBOutlet var songName: UILabel?
    @IBOutlet var songArtist: UILabel?
    @IBOutlet var initialTime: UILabel?
    @IBOutlet var lastTime: UILabel?
    
    @IBOutlet var playPauseButton: UIButton?
    @IBOutlet var repeatSong: UIButton?
    @IBOutlet var shuffleSongs: UIButton?
    @IBOutlet var carMode: UIBarButtonItem?
    
    @IBOutlet var songSlider: UISlider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     * viewWillAppear: Se inicializa el singleton del audioPlayer y los ficheros de musica
     */
    override func viewWillAppear(_ animated: Bool) {
		audioPlayer = ap.getInstance()
        songParams = audioPlayer.getSongParams()
        
        key = songParams.key
        cfm.setCFM(key: songParams.key, isPlaylist: false)
        cfm.reloadData(key: key)
        
		getAndSetDataFromID3(songToBePlayed!)
        setPlayerToNewSong(songToBePlayed!, isOnPause: false, isBeingPlayedOnList: currentSongFromList!)
        
        navigationController!.navigationBar.tintColor = UIColor(named: "TintColor")
        navigationController!.isToolbarHidden = true
        
        setRepeatMode()
        setShuffleMode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        audioPlayer.setSongWithParams(songParams: songParams)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loadLyrics" || segue.identifier == "loadLyricsPlaylist" {
            if (segue.destination.view != nil) {
                let view = (segue.destination as! LyricsViewController)
                
                let p = AVPlayerItem(url: songToBePlayed!)
                if let l = p.asset.lyrics {
                    view.lyrics?.text = l
                } else {
                    view.lyrics?.text = NSLocalizedString("nolyricsfound.displaysongcontroller", comment: "")
                }
            }
        }
    }
    
    @IBAction func goBackToList(_ sender: Any) {
        if fromPlaylist {
            performSegue(withIdentifier: "getPlayedPlaylistSong", sender: self)
        } else {
            performSegue(withIdentifier: "getPlayedSong", sender: self)
        }
    }
   
    // MARK: Funciones de inicialización de la vista
    
    /**
     * setPlayerToNewSong: Se inicializa la variable player con la nueva canción @param songToBePlayed y se reproduce.
     * Además, actualiza los UILabel de tiempo y hace reset del Timer de reproducción.
     * El @param isOnPause sirve para clarificar si empezar o no la reproduccion al cambiar de cancion.
     *
     * La funcionalidad cambia al meterse en esta vista si la cancion que se reproduce es la misma a la que se quiere acceder (@param isBeingPlayedOnList)
     */
    private func setPlayerToNewSong(_ songToBePlayed: URL, isOnPause: Bool, isBeingPlayedOnList: Bool) {
        if isBeingPlayedOnList {
            initialTime?.text = convertDurationToString(duration: audioPlayer.getCurrentTime())
                        
            startTimerOfSong()
        } else {
            audioPlayer.setSong(song: songToBePlayed)
            audioPlayer.setPlay()
            
            initialTime?.text = "0:00"
            
            songSlider?.value = 0
        
            if !isOnPause {
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                startTimerOfSong()
            }
        }
        
        let duration = audioPlayer.getDuration()
        lastTime?.text = convertDurationToString(duration: duration)
        
        songSlider?.minimumValue = 0
        songSlider?.maximumValue = Float(duration)
        
        if isBeingPlayedOnList { songSlider?.value = Float(audioPlayer.getCurrentTime()) }

        songParams.title = songName!.text! + ".mp3"
        audioPlayer.setDelegate(sender: self)
    }
	
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            goNextOrPreviousSong(true, hasEnded: true)
        }
    }
    
    /**
     * remoteControlReceived: Funcion para posible control remoto con cascos o demás para la reproducción
     * de la canción
     */
    override func remoteControlReceived(with event: UIEvent?) {
        if event!.type == UIEvent.EventType.remoteControl{
            switch event!.subtype{
                case UIEventSubtype.remoteControlPlay:
                    playSong()
                case UIEventSubtype.remoteControlPause:
                    playSong()
                case UIEventSubtype.remoteControlNextTrack:
                    goNextOrPreviousSong(true, hasEnded: false)
                case UIEventSubtype.remoteControlPreviousTrack:
                    goNextOrPreviousSong(false, hasEnded: false)
                default:
                    print("Error con el control remoto")
            }
        }
    }
    
    // MARK: Funciones para la administración de la reproducción
    
    /**
     * Nombre explanatorio: actualiza la IU y la canción en función de la pulsación del boton
     * de play/pause
     */
    @IBAction private func playSong() {
        if audioPlayer.getIsPlaying() {
            playPauseButton?.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            audioPlayer.pause()
            songTime.invalidate()
        } else {
            playPauseButton?.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            audioPlayer.play()
            startTimerOfSong()
        }
    }
    
    /**
     * playFromSelectedTime: Al desplazar el slider, la canción se reproduce desde donde el usuario deja el slider
     */
    @IBAction private func playFromSelectedTime() {
        audioPlayer.setCurrentTime(at: Double(songSlider!.value))
        initialTime?.text = convertDurationToString(duration: Double(songSlider!.value))
    }
    
    // Nombre explanatorio
    @IBAction private func setRepeatMode() {
        if songParams.isRepeatModeActive {
            repeatSong?.setImage(UIImage(systemName: "repeat"), for: .normal)
            repeatSong?.tintColor = .lightGray
        } else {
            repeatSong?.setImage(UIImage(systemName: "repeat.1"), for: .normal)
            repeatSong?.tintColor = UIColor(named: "TintColor")
        }
        songParams.isRepeatModeActive = !songParams.isRepeatModeActive
    }
    
    // Nombre explanatorio
    @IBAction private func setShuffleMode() {
        if songParams.isShuffleModeActive {
            shuffleSongs?.tintColor = .lightGray
        } else {
            shuffleSongs?.tintColor = UIColor(named: "TintColor")
        }
        songParams.isShuffleModeActive = !songParams.isShuffleModeActive
    }
    
    // Nombre explanatorio
    @IBAction private func setCarMode() {
        if isCarModeActive {
            carMode?.image = UIImage(systemName: "car.fill")
            songSlider?.isHidden = false
            initialTime?.isHidden = false
            lastTime?.isHidden = false
            
            songName?.font = UIFont.systemFont(ofSize: 23)
            songArtist?.font = UIFont.systemFont(ofSize: 17)
            for constraint in self.view.constraints {
                if constraint.identifier == "bottomSongArtist" {
                    constraint.constant = 8
                } else if constraint.identifier == "alignmentHorizontalPlayButton" {
                    constraint.constant = 0
                } else if constraint.identifier == "alignmentHorizontalPlayButtonAlter" {
                    constraint.constant = 0
                }
            }
        } else {
            carMode?.image = UIImage(systemName: "car")
            songSlider?.isHidden = true
            initialTime?.isHidden = true
            lastTime?.isHidden = true
            
            let conf = UIImage.SymbolConfiguration(scale: .large)
            playPauseButton?.imageView?.preferredSymbolConfiguration = conf
            
            songName?.font = UIFont.systemFont(ofSize: 35)
            songArtist?.font = UIFont.systemFont(ofSize: 29)
            for constraint in self.view.constraints {
                if constraint.identifier == "bottomSongArtist" {
                    constraint.constant = 0
                } else if constraint.identifier == "alignmentHorizontalPlayButton" {
                    constraint.constant = -40
                } else if constraint.identifier == "alignmentHorizontalPlayButtonAlter" {
                    constraint.constant = 40
                }
            }
        }
        isCarModeActive = !isCarModeActive
    }
    
    // Nombre explanatorio
    private func startTimerOfSong() {
         songTime = Timer.scheduledTimer(timeInterval: 1, target: self,
                                         selector: (#selector(DisplaySongController.updateSongTimer)),
                                         userInfo: nil, repeats: true)
    }
    
    /**
     * Nombre explanatorio: Actualiza el UILabel inicial de tiempo y la barra de progreso cada segundo
     * que pasa de la canción
     */
    @objc private func updateSongTimer() {
        songSlider?.value += 1
        initialTime?.text = convertDurationToString(duration: audioPlayer.getCurrentTime())
    }
    
    /**
     * goNextOrPreviousSong: Función que permite reproducir la siguiente o anterior cancion en función de @param mode.
     *      True -> Siguiente cancion
     *      False -> Anterior cancion
     *
     * Por supuesto se verifica si al pasar de canción, en el modo que sea, si la canción está reproduciendose o no, ya que
     * el reproductor se comporta de manera diferente.
     *
     * Se añade la funcionalidad de que si la canción ha sido reproducida más de 5 segundos, al darle a "anterior cancion",
     * se reproduce de nuevo la canción actual. Si no, se reproduce la canción anterior.
     *
     * Se maneja aquí la funcionalidad de la repetición: Si está activo, la canción se vuelve a reproducir independientemente
     * del boton que se pulse ademas de si acaba la canción.
     *
     * Se maneja aquí la funcionalidad del aleatorio.
     */
    private func goNextOrPreviousSong(_ mode: Bool, hasEnded: Bool) {
        songTime.invalidate()
        songSlider?.value = 0
        
        if songParams.isRepeatModeActive {
            if audioPlayer.evaluateOnRepeat() {
                initialTime?.text = "0:00"
                startTimerOfSong()
            } else {
                initialTime?.text = "0:00"
                if hasEnded {
                    audioPlayer.setCurrentTime(at: 0)
                    audioPlayer.prepareToPlay()
                    audioPlayer.play()
                    startTimerOfSong()
                }
            }
        } else {
            let limitFromSkippingSong = secondsToTimeInterval(5)
            if !mode && Int(audioPlayer.getCurrentTime()) > limitFromSkippingSong {
                if audioPlayer.getIsPlaying() {
                    audioPlayer.setCurrentTime(at: 0)
                    initialTime?.text = "0:00"
                    startTimerOfSong()
                } else {
                    audioPlayer.setCurrentTime(at: 0)
                    initialTime?.text = "0:00"
                }
            } else {
                let prev = songParams.actualSongIndex
				if mode {
					songParams.actualSongIndex = audioPlayer.nextSong(currentIndex: prev,
                                                            hasShuffle: songParams.isShuffleModeActive)
				} else {
					songParams.actualSongIndex = audioPlayer.prevSong(currentIndex: prev,
                                                            hasShuffle: songParams.isShuffleModeActive)
                }
                
                let newSong = cfm.getNextSong(from: songParams.actualSongIndex)
                songToBePlayed = newSong
                getAndSetDataFromID3(newSong)
                
                if hasEnded {
                    setPlayerToNewSong(newSong, isOnPause: false, isBeingPlayedOnList: false)
                } else {
                    setPlayerToNewSong(newSong, isOnPause: !audioPlayer.getIsPlaying(), isBeingPlayedOnList: false)
                }
    
                songName?.font = UIFont.boldSystemFont(ofSize: 23)
            }
        }
    }
    
    // Nombre explanatorio
    @IBAction private func nextSong() { goNextOrPreviousSong(true, hasEnded: false) }
    
    // Nombre explanatorio
    @IBAction private func previousSong() { goNextOrPreviousSong(false, hasEnded: false) }
    
    // MARK: Funciones auxiliares
    
    /**
     * convertDurationToString: Convierte la duración de la canción actual a un string formateado tal que mm:ss
     */
    private func convertDurationToString(duration: Double) -> String {
        let interval = Int(duration)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%2d:%02d", minutes, seconds)
    }
        
    private func secondsToTimeInterval (_ seconds : Int) -> Int {
        return (seconds % 3600) % 60
    }
    
    /**
     * getAndSetDataFromID3: Recoge los metadatos de los archivos .mp3 y popula la vista
     */
    private func getAndSetDataFromID3(_ song: URL) {
        let p = AVPlayerItem(url: song)
        let metadataList = p.asset.commonMetadata
        var count = 1
   
        for item in metadataList {
            switch item.commonKey!.rawValue {
                case "title":
                    songName?.text = item.value as? String
                    break
                case "artist":
                    songArtist?.text = item.value as? String
                    break
                case "artwork":
                    count -= 1
                    portrait?.image = UIImage(data: item.value as! Data)
                    break
                default:
                    break
            }
        }
        
        if count != 0 {
            portrait?.image = UIImage(named: "album")
        }
    }
}
