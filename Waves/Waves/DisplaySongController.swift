//
//  DisplaySongController.swift
//  Waves
//
//  Created by Gabriel Garcia on 19/11/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import AVFoundation

class DisplaySongController: UIViewController {

    var player: AVAudioPlayer!
    var song: URL?
    
    @IBOutlet var songName: UILabel?
    @IBOutlet var songArtist: UILabel?
    @IBOutlet var initialTime: UILabel?
    @IBOutlet var lastTime: UILabel?
    
    @IBOutlet var playPauseButton: UIButton?
    
    @IBOutlet var timeLeft: UIProgressView?
    
    @IBOutlet var portrait: UIImageView?
    
    var isPlaying = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        player = try! AVAudioPlayer(contentsOf: song!)
        player.prepareToPlay()
        player.play()
        
        initialTime?.text = "0:00"
        lastTime?.text = convertDurationToString(duration: player.duration)
        
        portrait?.image = UIImage(named: "album2")
    }

    @IBAction private func playSong() {
        if (isPlaying) {
            playPauseButton?.setImage(UIImage(systemName: "play.fill"), for: .normal)
            player.pause()
        } else {
            playPauseButton?.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            player.play()
        }
        isPlaying = !isPlaying
    }

    private func convertDurationToString(duration: Double) -> String {
        let totalMin = String(format: "%.2f", (duration) / 60)
        let parted = totalMin.components(separatedBy: ".")
        var minutes = Int(parted[0])!
        var seconds = Int(parted[1])!
        
        if seconds >= 60 {
            minutes += 1
            seconds -= 60
        }
        
        if seconds == 0 {
            return String(minutes) + ":" + String(seconds) + "0"
        } else {
            return String(minutes) + ":" + String(seconds)
        }
    }
}
