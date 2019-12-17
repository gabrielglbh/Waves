//
//  CustomToolbar.swift
//  Waves
//
//  Created by Gabriel Garcia on 17/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

class CustomToolbar {
	let af = AuxiliarFuntions()
	var fromToolbarToDisplay: Bool?

	/**
    * Añade GestureRecognizers a la toolbar cuando una canción se está reproduciendo.
    * Swipe a la izquierda: NextSong
    * Swipe a la derecha: PreviousSong
    * Tap -> Lleva a la canción que está sonando
    */
	// MARK: TODO: Parámetros para los #selector -> audioPlayer (previousSong y nextSong)
	// Utilizar un custom UISwipeGestureRecognizer que tenga como parametro el audioPlayer
	// https://stackoverflow.com/questions/43251708/passing-arguments-to-selector-in-swift
	init(_ navigationController: UINavigationController) { 
		fromToolbarToDisplay = false
	
		navigationController.toolbar.barTintColor = UIColor.darkGray
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(previousSong))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextSong))
        swipeLeft.direction = .left
        let tap = UITapGestureRecognizer(target: self, action: #selector(displaySong))
        tap.numberOfTapsRequired = 1
        
        navigationController.toolbar.addGestureRecognizer(swipeLeft)
        navigationController.toolbar.addGestureRecognizer(swipeRight)
        navigationController.toolbar.addGestureRecognizer(tap)
	}
	
	@objc private func previousSong(audioPlayer: AudioPlayer) { 
		goNextOrPreviousSong(mode: false, isOnPause: !audioPlayer.getIsPlaying()) 
	}
    
    @objc private func nextSong(audioPlayer: AudioPlayer) { 
		goNextOrPreviousSong(mode: true, isOnPause: !audioPlayer.getIsPlaying()) 
	}
    
    @objc private func displaySong() {
        setFromToolbarToDisplay(true)
        performSegue(withIdentifier: "goToPlaySong", sender: nil)
    }
	
	func getFromToolbarToDisplay() -> Bool {
		return fromToolbarToDisplay!
	}
	
	func setFromToolbarToDisplay(_ val: Bool) {
		fromToolbarToDisplay = val
	}
	
	/**
    * managePlayAction: Actualiza la IU y la canción en función de la pulsación del boton
    * de play/pause.
    */
    @objc private func managePlayAction(isPlaying: inout Bool, audioPlayer: AudioPlayer) {
        if isPlaying {
            setToolbarButtonsForPlayingSong(playButton: "play.circle")
            audioPlayer.pause()
        } else {
            setToolbarButtonsForPlayingSong(playButton: "pause.circle")
            audioPlayer.play()
        }
        isPlaying = !isPlaying
    }
	
	/**
	* goNextOrPreviousSong: Maneja todos los indices para calcular la siguiente cancion
	* en funcion de los modos de repetición y aleatorio.
	* Devuelve el indice actualizado de la cancion que va a sonar.
	*/
	func goNextOrPreviousSong(_ fileManager: CustomFileManager, _ audioPlayer: AudioPlayer, mode: Bool, 
							isOnPause: Bool, repeatMode: Bool, shuffleMode: Bool, songIndex: Int) -> Int {
		var index = songIndex
        if !repeatMode {
            let prev = index
            if mode {
                index = audioPlayer.nextSong(currentIndex: prev,
                                                        hasShuffle: shuffleMode,
                                                        totalSongs: fileManager.getCountFiles())
            } else {
                index = audioPlayer.prevSong(currentIndex: prev,
                                                        hasShuffle: shuffleMode,
                                                        totalSongs: fileManager.getCountFiles())
            }
            af.resetUIList(tableView, files: fileManager.getCountFiles())
            cellOfPlayingSong = af.setCurrentSongUI(tableView, at: index)
        }
        
        let next = fileManager.getFile(at: index)
        let newSong = fileManager.getURLFromDoc(of: next)
        
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
		
		return index
    }
	
	func setToolbarVisibility(_ navigationController: UINavigationController, visible: Bool) {
		navigationController.isToolbarHidden = visible
	}
	
	/**
     * createCustomButton: Crea un boton o un label personalizado para la UIToolbar
     */
    func createCustomButton(_ image: String?, _ title: String?, _ detail: String?) -> UIBarButtonItem {
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
    func setToolbarButtonsForPlayingSong(_ navigationController: UINavigationController, song: URL, playButton: String) {
		let fields = af.getAndSetDataFromID3ForToolbar(song)
	
        let playButton = createCustomButton(playButton, nil, nil)
        let songToolbarText = createCustomButton(nil, fields[0] + " \u{00B7} ", nil)
        let artistToolbarText = createCustomButton(nil, nil, fields[1])
        let blank = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        navigationController.toolbarItems = [songToolbarText, artistToolbarText, blank, playButton]
    }
}