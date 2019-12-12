//
//  DisplayPlaylistController.swift
//  Waves
//
//  Created by Gabriel Garcia on 12/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

class DisplayPlaylistController: UIViewController {

    @IBOutlet var addSongs: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSongs.layer.cornerRadius = 20
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController!.navigationBar.tintColor = UIColor.systemYellow
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
    }
    
    // TODO: Añadir un UITableView para las canciones añadidas
    // TODO: Crear UserDefault key con el nombre de la playlist para almacenar el orden de las canciones
}
