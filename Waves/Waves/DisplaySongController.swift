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

    // Variables para la reproducción de la cancion
    var player: AVAudioPlayer!
    var songToBePlayed: URL?
    var docs: URL!
    var songs: [String]?
    var songRawName: String?
    var actualSongIndex: Int?
    
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
        setPlayerToNewSong(songToBePlayed!)
        
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
    
    /**
     * audioPlayerDidFinishPlaying: Cuando la canción ha terminado de reproducirse, se pasa y reproduce la siguiente canción
     */
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            goNextOrPreviousSong(true)
        }
    }
    
    // MARK: Funciones de inicialización de la vista
    
    /**
     * setPlayerToNewSong: Se inicializa la variable player con la nueva canción @param songToBePlayed y se reproduce.
     * Además, actualiza los UILabel de tiempo y hace reset del Timer de reproducción
     */
    private func setPlayerToNewSong(_ songToBePlayed: URL) {
        player = try! AVAudioPlayer(contentsOf: songToBePlayed)
        player.delegate = self
        player.prepareToPlay()
        player.play()
        
        initialTime?.text = "0:00"
        lastTime?.text = convertDurationToString(duration: player.duration)
        
        songDurationSlider?.minimumValue = 0
        songDurationSlider?.maximumValue = Float(player.duration)
        songDurationSlider?.value = 0
    
        startTimerOfSong()
    }
    
    // MARK: Funciones para la administración de la reproducción
    
    /**
     * Nombre explanatorio: actualiza la IU y la canción en función de la pulsación del boton
     * de play/pause
     */
    @IBAction private func playSong() {
        if isPlaying {
            playPauseButton?.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            player.pause()
            songTime.invalidate()
        } else {
            playPauseButton?.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            player.play()
            startTimerOfSong()
        }
        isPlaying = !isPlaying
    }
    
    /**
     * playFromSelectedTime: Al desplazar el slider, la canción se reproduce desde donde el usuario deja el slider
     */
    @IBAction private func playFromSelectedTime() {
        player.currentTime = Double(songDurationSlider!.value)
        initialTime?.text = String(convertDurationToString(duration: Double(songDurationSlider!.value)))
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
        initialTime?.text = convertDurationToString(duration: player.currentTime)
    }
    
    /**
     * goNextOrPreviousSong: Función que permite reproducir la siguiente o anterior cancion en función de @param mode.
     *      True -> Siguiente cancion
     *      False -> Anterior cancion
     *
     * Se añade la funcionalidad de que si la canción ha sido reproducida más de 5 segundos, al darle a "anterior cancion",
     * se reproduce de nuevo la canción actual. Si no, se reproduce la canción anterior.
     *
     * Se maneja aquí la funcionalidad de la repetición: Si está activo, la canción se vuelve a reproducir independientemente
     * del boton que se pulse ademas de si acaba la canción.
     *
     * Se maneja aquí la funcionalidad del aleatorio.
     */
    private func goNextOrPreviousSong(_ mode: Bool) {
        songTime.invalidate()
        songDurationSlider?.value = 0
        
        if isRepeatModeActive {
            player.currentTime = 0
            initialTime?.text = "0:00"
            startTimerOfSong()
            player.play()
        } else {
            let limitFromSkippingSong = secondsToTimeInterval(5)
            if !mode && Int(player.currentTime) > limitFromSkippingSong {
                player.currentTime = 0
                initialTime?.text = "0:00"
                startTimerOfSong()
            } else {
                if isShuffleModeActive { actualSongIndex = Int.random(in: 0 ..< songs!.count) }
                else {
                    if mode {
                        actualSongIndex? += 1
                        if actualSongIndex == songs!.count {
                            actualSongIndex = 0
                        }
                    } else {
                        actualSongIndex? -= 1
                        if actualSongIndex == -1 {
                            actualSongIndex = songs!.count - 1
                        }
                    }
                }
                
                let next = songs![actualSongIndex!]
                let newSong = docs.appendingPathComponent(next)
                songToBePlayed = newSong
                
                setPlayerToNewSong(newSong)
                getAndSetDataFromID3(newSong)
                
                songName?.font = UIFont.boldSystemFont(ofSize: 23)
            }
        }
    }
    
    // Nombre explanatorio
    @IBAction private func nextSong() { goNextOrPreviousSong(true) }
    
    // Nombre explanatorio
    @IBAction private func previousSong() { goNextOrPreviousSong(false) }
    
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
       
       for item in metadataList {
            switch item.commonKey!.rawValue {
                case "title":
                    songName?.text = item.value as? String
                    break
                case "artist":
                    songArtist?.text = item.value as? String
                    break
               case "artwork":
                    // TODO: Si no hay data, poner UIImage(named: "album2")
                    // portrait?.image = UIImage(named: "album2")
                    portrait?.image = UIImage(data: item.value as! Data)
               default:
                    break
           }
       }
   }
}
