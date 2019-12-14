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
    var docs: URL!
    var songs: [String]?
    var songRawName: String?
    var actualSongIndex: Int?
    var currentSongFromList: Bool?
    
	// Instancia única para toda la aplicación de la canción que suena
	let ap = AudioPlayer()
	var audioPlayer: AudioPlayer!
    var songTime = Timer()
    
    var isPlaying = true
    var isRepeatModeActive = false
    var isShuffleModeActive = false
    
    @IBOutlet var portrait: UIImageView?
    @IBOutlet var songName: UILabel?
    @IBOutlet var songArtist: UILabel?
    @IBOutlet var initialTime: UILabel?
    @IBOutlet var lastTime: UILabel?
    
    @IBOutlet var playPauseButton: UIButton?
    @IBOutlet var repeatSong: UIButton?
    @IBOutlet var shuffleSongs: UIButton?
    
    @IBOutlet var songDurationSlider: UISlider?
    
    /**
     * viewDidLoad: Se crea la URL para acceder a las canciones y se agranda en altura la progress bar.
     * Se crean los manejadores para la LockScreen y el Control Center de iOS para la cancion
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        title = "Waves"
    }
    
    /**
     * viewWillAppear: Se inicializa la variable player para reproducir la canción pasada por segue dse la anterior
     * vista de la aplicación
     */
    override func viewWillAppear(_ animated: Bool) {
		audioPlayer = ap.getInstance()
		getAndSetDataFromID3(songToBePlayed!)
        
        setPlayerToNewSong(songToBePlayed!, isOnPause: false, isBeingPlayedOnList: currentSongFromList!)
        
        navigationController!.navigationBar.tintColor = UIColor.systemYellow
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
        navigationController!.isToolbarHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loadLyrics" {
            if (segue.destination.view != nil) {
                let view = (segue.destination as! LyricsViewController)
                
                let p = AVPlayerItem(url: songToBePlayed!)
                if let l = p.asset.lyrics {
                    view.lyrics?.text = l
                } else {
                    view.lyrics?.text = "No se han encontrado lyrics ;("
                }
            }
        }
    }
    
    @IBAction func goBackToList(_ sender: Any) {
        performSegue(withIdentifier: "getPlayedSong", sender: self)
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
            
            songDurationSlider?.value = Float(audioPlayer.getCurrentTime())
            
            startTimerOfSong()
        } else {
            audioPlayer.setSong(song: songToBePlayed)
            audioPlayer.setPlay()
            
            initialTime?.text = "0:00"
            
            songDurationSlider?.value = 0
        
            if !isOnPause {
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                startTimerOfSong()
            }
        }
        
        audioPlayer.setDelegate(sender: self)
        let duration = audioPlayer.getDuration()
        lastTime?.text = convertDurationToString(duration: duration)
        
        songDurationSlider?.minimumValue = 0
        songDurationSlider?.maximumValue = Float(duration)
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
        if isPlaying {
            playPauseButton?.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            audioPlayer.pause()
            songTime.invalidate()
        } else {
            playPauseButton?.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            audioPlayer.play()
            startTimerOfSong()
        }
        isPlaying = !isPlaying
    }
    
    /**
     * playFromSelectedTime: Al desplazar el slider, la canción se reproduce desde donde el usuario deja el slider
     */
    @IBAction private func playFromSelectedTime() {
        audioPlayer.setCurrentTime(at: Double(songDurationSlider!.value))
        initialTime?.text = convertDurationToString(duration: Double(songDurationSlider!.value))
    }
    
    // Nombre explanatorio
    @IBAction private func setRepeatMode() {
        if isRepeatModeActive {
            repeatSong?.setImage(UIImage(systemName: "repeat"), for: .normal)
            repeatSong?.tintColor = .lightGray
        } else {
            repeatSong?.setImage(UIImage(systemName: "repeat.1"), for: .normal)
            repeatSong?.tintColor = .systemYellow
        }
        isRepeatModeActive = !isRepeatModeActive
    }
    
    // Nombre explanatorio
    @IBAction private func setShuffleMode() {
        if isShuffleModeActive {
            shuffleSongs?.tintColor = .lightGray
        } else {
            shuffleSongs?.tintColor = .systemYellow
        }
        isShuffleModeActive = !isShuffleModeActive
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
        songDurationSlider?.value += 1
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
        songDurationSlider?.value = 0
        
        if isRepeatModeActive {
            if audioPlayer.evaluateOnRepeat() {
                initialTime?.text = "0:00"
                startTimerOfSong()
            } else {
                initialTime?.text = "0:00"
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
                let prev = actualSongIndex!
				if mode {
					actualSongIndex = audioPlayer.nextSong(currentIndex: prev,
                                                            hasShuffle: isShuffleModeActive,
                                                            totalSongs: songs!.count)
				} else {
					actualSongIndex = audioPlayer.prevSong(currentIndex: prev,
                                                            hasShuffle: isShuffleModeActive,
                                                            totalSongs: songs!.count)
                }
                
                let next = songs![actualSongIndex!]
                let newSong = docs.appendingPathComponent(next)
                songToBePlayed = newSong
                
                if hasEnded {
                    setPlayerToNewSong(newSong, isOnPause: false, isBeingPlayedOnList: false)
                } else {
                    setPlayerToNewSong(newSong, isOnPause: !audioPlayer.getIsPlaying(), isBeingPlayedOnList: false)
                }
                getAndSetDataFromID3(newSong)
                
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
