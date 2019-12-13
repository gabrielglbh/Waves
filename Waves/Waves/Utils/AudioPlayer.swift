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

class AudioPlayer: NSObject {

	static var sharedInstance = AudioPlayer()
	private var player: AVAudioPlayer!
	
	func getInstance() -> AudioPlayer {
		return sharedInstance
	}
	
	func setSong(song: URL) {
		player = try! AVAudioPlayer(contentsOf: songToBePlayed)
        player.delegate = self
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
	
	func nextSong(currentIndex: Int, hasShuffle: Bool, totalSongs: Int) -> Int {
		if hasShuffle { 
			return Int.random(in: 0 ..< totalSongs) 
		} else {
			currentIndex += 1
			if currentIndex == totalSongs {
				currentIndex = 0
			}
			return currentIndex
		}
	}
	
	func prevSong(currentIndex: Int, hasShuffle: Bool, totalSongs: Int) -> Int {
		if hasShuffle { 
			return Int.random(in: 0 ..< totalSongs) 
		} else {
			currentIndex? -= 1
			if currentIndex == -1 {
				currentIndex = totalSongs - 1
			}
			return currentIndex
		}
	}
	
	func getCurrentTime() -> Double() {
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
