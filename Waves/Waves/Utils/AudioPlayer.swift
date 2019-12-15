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

	static var sharedInstance = AudioPlayer()
	private var player: AVAudioPlayer!
	
	func getInstance() -> AudioPlayer {
        return AudioPlayer.sharedInstance
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
	
	func getCurrentTime() -> Double {
		return self.player.currentTime
	}
	
	func getDuration() -> Double {
		return self.player.duration
	}
	
	func getIsPlaying() -> Bool {
		return self.player.isPlaying
	}
	
	func setCurrentTime(at: Double) {
		self.player.currentTime = at
	}
	
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
