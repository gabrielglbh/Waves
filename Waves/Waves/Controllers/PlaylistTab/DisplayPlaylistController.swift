//
//  DisplayPlaylistController.swift
//  Waves
//
//  Created by Gabriel Garcia on 12/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

class DisplayPlaylistController: UIViewController {

    var docs: URL!
    var files: [String]?
    var newPlaylist = [String]()
    var fm: FileManager!
    
    @IBOutlet var addSongs: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSongs.layer.cornerRadius = 20
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController!.navigationBar.tintColor = UIColor.systemYellow
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
        
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
        
        if UserDefaults.standard.object(forKey: title!) == nil {
            UserDefaults.standard.set(files!, forKey: title!)
        } else {
            files = UserDefaults.standard.object(forKey: title!)! as? [String]
        }
    }
    
    @IBAction func unwindToDisplayPlaylist(_ unwind: UIStoryboardSegue) {
        let view = unwind.source as! SelectSongsController
        
        for ind in view.selectedSongs! {
            newPlaylist.append(files![ind])
            // TODO: Refresh tableView con newPlaylist
        }
    }
}
