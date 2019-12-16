//
//  PlayListListController.swift
//  Waves
//
//  Created by Gabriel Garcia on 12/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

class PlayListListController: UITableViewController {
    
    var playlists = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.editButtonItem.tintColor = UIColor.systemYellow
        
        title = "Mis Listas"
        
        if UserDefaults.standard.object(forKey: "playlists") == nil {
            UserDefaults.standard.set(playlists, forKey: "playlists")
        } else {
            playlists = (UserDefaults.standard.object(forKey: "playlists")! as? [String])!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController!.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemYellow]
        navigationController!.navigationBar.barTintColor = UIColor.darkGray
    }
    
    // MARK: Funciones de UITableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    /**
     * Se añade un gestureRecognizer a cada celda para poder modificar su nombre
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellPlaylist", for: indexPath)

        cell.textLabel?.text = playlists[indexPath.row]
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        cell.textLabel?.textColor = UIColor.white
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(modifyPlaylist))
        longPress.minimumPressDuration = 1
        cell.addGestureRecognizer(longPress)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            playlists.remove(at: indexPath.row)
            UserDefaults.standard.set(playlists, forKey: "playlists")
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let playlist = playlists.remove(at: fromIndexPath.row)
        playlists.insert(playlist, at: to.row)
        UserDefaults.standard.set(playlists, forKey: "playlists")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
   
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
   
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // MARK: Manejo de botones
    
    @objc private func modifyPlaylist(l: UILongPressGestureRecognizer) {
        let p = l.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: p)
        
        createAlert(isModificationMode: true, indexPath!.row)
    }
    
    @IBAction private func addPlaylist() {
        createAlert(isModificationMode: false, nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getPlaylist" {
            if (segue.destination.view != nil) {
                let view = segue.destination as! DisplayContentPlaylistController
                view.title = playlists[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    // MARK: Funciones auxiliares
    
    private func createAlert(isModificationMode: Bool, _ index: Int?) {
        let alert = UIAlertController(title: "Añadir Playlist", message: nil, preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: {
            textField in
            if isModificationMode {
                textField.text = self.playlists[index!]
            }
            textField.isSecureTextEntry = false
            textField.placeholder = "Nombre"
        })
        
        let add = UIAlertAction(title: "Ok", style: .default, handler: {
            action in
            let playlist = alert.textFields![0].text!
            if playlist != "" {
                if isModificationMode {
                    self.playlists.remove(at: index!)
                    self.playlists.insert(playlist, at: index!)
                } else {
                    self.playlists.insert(playlist, at: 0)
                }
                
                UserDefaults.standard.set(self.playlists, forKey: "playlists")
                self.tableView.reloadData()
            }
        })
        
        let dismiss = UIAlertAction(title: "Atrás", style: .default, handler: {
            action in
            self.dismiss(animated: true, completion: nil)
        })
        
        alert.addAction(dismiss)
        alert.addAction(add)
        alert.view.tintColor = UIColor.darkGray
        present(alert, animated: true)
    }
}
