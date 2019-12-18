//
//  CustomFileManager.swift
//  Waves
//
//  Created by Gabriel Garcia on 15/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

class CustomFileManager {
    
    private var docs: URL!
    private var files = [String]()
    private var fm: FileManager!
    
    init() { }
    
    init(key: String) {
        setAllFiles()
        checkUserDefaults(key: key)
    }
    
    /**
    * Iniciación de los ficheros y el UserDefaults para una key dada
    */
    func setCFM(key: String, isPlaylist: Bool) {
        setAllFiles()
        if !isPlaylist {
            checkUserDefaults(key: key)
        } else {
            if UserDefaults.standard.object(forKey: key) == nil {
                files = []
            } else {
                files = (UserDefaults.standard.object(forKey: key)! as? [String])!
            }
        }
    }
    
    /**
    * Iniciación de los ficheros de la ruta inicial (todas las canciones)
    */
    func setAllFiles() {
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(docs.path)
        
        files = try! fm.contentsOfDirectory(atPath: docs.path)
        files.removeAll { $0 == ".DS_Store" }
    }
    
    /**
     * Set del UserDefault para una key
     */
    func checkUserDefaults(key: String) {
        if UserDefaults.standard.object(forKey: key) == nil {
            setUserDefaults(files: files, key: key)
        } else {
            files = (UserDefaults.standard.object(forKey: key)! as? [String])!
        }
    }
    
    /**
    * reloadData: Recarga de las canciones del directorio
    */
    func reloadData(key: String) {
        files = try! fm.contentsOfDirectory(atPath: docs.path)
        files.removeAll { $0 == ".DS_Store" }
        checkUserDefaults(key: key)
    }
    
    /**
    * Eliminar una cancion de los documentos y de los UserDefaults
    */
    func removeInstance(songToBeRemoved: String, key: String) {
        let path = docs.appendingPathComponent(songToBeRemoved)
        do {
            try fm.removeItem(at: path)
        } catch { print("Error al eliminar") }
        
        files = try! fm.contentsOfDirectory(atPath: docs.path)
        setUserDefaults(files: files, key: key)
    }
    
    /**
    * Actualizar una cancion en los documentos y en los UserDefaults
    */
    func updateInstance(from: Int, to: Int, key: String) {
        let song = files.remove(at: from)
        files.insert(song, at: to)
        setUserDefaults(files: files, key: key)
    }
    
    func setFiles(_ files: [String]) {
        self.files = files
    }
    
    func setUserDefaults(files: [String], key: String) {
        UserDefaults.standard.set(files, forKey: key)
    }
    
    func getFiles() -> [String] {
        return files
    }
    
    func getCountFiles() -> Int {
        return files.count
    }
    
    func getFile(at: Int) -> String {
        return files[at]
    }
    
    func getIndexOfFile(name: String) -> Int {
        for (i, file) in files.enumerated() {
            if file == name {
                return i
            }
        }
        return -1
    }
    
    /**
    * getFileFrom: Funcion para recuperar una cancion de los documentos, dentro
    * de una playlist para asociarla a ella.
    * Devuelve el nombre del fichero elegido.
    */
    func getFileFrom(at: Int, from: String, resetAt: String) -> String {
        setCFM(key: from, isPlaylist: false)
        let file = getFile(at: at)
        setCFM(key: resetAt, isPlaylist: true)
        return file
    }
    
    func getURLFromDoc(of: String) -> URL {
        return docs.appendingPathComponent(of)
    }
    
    func getNextSong(from: Int) -> URL {
        let next = getFile(at: from)
        return getURLFromDoc(of: next)
    }
}
