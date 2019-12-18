//
//  AudioPlayer.swift
//  Waves
//
//  Created by Gabriel Garcia on 12/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

// MARK: Instancia SINGLETON para que el reproductor sea accesible en toda la aplicación

class AudioPlayer {
    // Estructura que define una cancion
    struct song {
        // Variable para determinar desde dónde se está reproduciendo la canción
        var key = "music"
        // Variables para el control de la canción
        var actualSongIndex = 0
        var isShuffleModeActive = false
        var isRepeatModeActive = false
    }
    static var sharedInstance = AudioPlayer()
    private var player: AVAudioPlayer!
    private var songParams = song()
	
    /**
     * Recoge la instancia única del player
     */
	func getInstance() -> AudioPlayer {
        return AudioPlayer.sharedInstance
	}
    
    func setSongWithParams(songParams: song) {
        self.songParams.key = songParams.key
        self.songParams.actualSongIndex = songParams.actualSongIndex
        self.songParams.isShuffleModeActive = songParams.isShuffleModeActive
        self.songParams.isRepeatModeActive = songParams.isRepeatModeActive
    }
    
    func getSongParams() -> song {
        return self.songParams
    }
    
    func setSong(song: URL) {
		player = try! AVAudioPlayer(contentsOf: song)
	}
	
    func setDelegate(sender: AVAudioPlayerDelegate) {
        self.player.delegate = sender
    }
    
	func setPlay() {
		do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {}
        UIApplication.shared.beginReceivingRemoteControlEvents()
	}
	
	func play() {
		self.player.play()
	}
	
	func prepareToPlay() {
		self.player.prepareToPlay()
	}
	
	func pause() {
		self.player.pause()
	}
    
    func stop() {
        self.player.stop()
    }
	
	func getCurrentTime() -> Double {
		return self.player.currentTime
	}
	
	func getDuration() -> Double {
		return self.player.duration
	}
	
	func getIsPlaying() -> Bool {
        if self.player == nil {
            return false
        } else {
            return self.player.isPlaying
        }
	}
	
	func setCurrentTime(at: Double) {
		self.player.currentTime = at
	}
	
    /**
    * Actualiza el índice de la siguiente canción en función de hasShuffle
    */
    func nextSong(currentIndex: Int, hasShuffle: Bool, totalSongs: Int) -> Int {
        var ind = currentIndex
        if hasShuffle {
            return Int.random(in: 0 ..< totalSongs)
        } else {
            ind += 1
            if ind == totalSongs {
                ind = 0
            }
            return ind
        }
    }
    
    /**
    * Actualiza el índice de la anterior canción en función de hasShuffle
    */
    func prevSong(currentIndex: Int, hasShuffle: Bool, totalSongs: Int) -> Int {
        var ind = currentIndex
        if hasShuffle {
            return Int.random(in: 0 ..< totalSongs)
        } else {
            ind -= 1
            if ind == -1 {
                ind = totalSongs - 1
            }
            return ind
        }
    }
    
    /**
    * Evalua la repetición de la canción en función de is está sonando o no
    */
	func evaluateOnRepeat() -> Bool {
		if self.player.isPlaying {
			setCurrentTime(at: 0)
			prepareToPlay()
			play()
			return true
		} else {
			setCurrentTime(at: 0)
			return false
		}
	}
}
