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
    private var key = "music"
    
    init() { }
    
    /**
    * Iniciación de los ficheros y el UserDefaults para una key fija
    */
    init(key: String) {
        self.key = key
        setAllFiles()
        checkUserDefaults(key: self.key)
    }
    
    /**
    * Iniciación de los ficheros y el UserDefaults para una key dinámica
    */
    func setCFM(key: String, isPlaylist: Bool) {
        self.key = key
        setAllFiles()
        if !isPlaylist {
            checkUserDefaults(key: self.key)
        } else {
            if UserDefaults.standard.object(forKey: self.key) == nil {
                files = []
            } else {
                files = (UserDefaults.standard.object(forKey: key)! as? [String])!
            }
        }
    }
    
    /**
    * setFiles: Iniciación de los ficheros de la ruta inicial
    */
    func setAllFiles() {
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(docs.path)
        
        files = try! fm.contentsOfDirectory(atPath: docs.path)
        files.removeAll { $0 == ".DS_Store" }
    }
    
    func setFiles(_ files: [String]) {
        self.files = files
    }
    
    func checkUserDefaults(key: String) {
        self.key = key
        if UserDefaults.standard.object(forKey: self.key) == nil {
            setUserDefaults(files: files)
        } else {
            files = (UserDefaults.standard.object(forKey: key)! as? [String])!
        }
    }
    
    /**
    * reloadData: Recarga de las canciones del directorio
    */
    func reloadData() {
        files = try! fm.contentsOfDirectory(atPath: docs.path)
        files.removeAll { $0 == ".DS_Store" }
        checkUserDefaults(key: self.key)
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
    func getFileFrom(at: Int, from: String) -> String {
        setCFM(key: from, isPlaylist: false)
        let file = getFile(at: at)
        setCFM(key: key, isPlaylist: true)
        return file
    }
    
    func getURLFromDoc(of: String) -> URL {
        return docs.appendingPathComponent(of)
    }
    
    /**
    * getNextSong: Devuelve la URL del directorio para una cancion
    */
    func getNextSong(from: Int) -> URL {
        let next = getFile(at: from)
        return getURLFromDoc(of: next)
    }
    
    /**
    * removeInstance: Eliminar una cancion de los documentos y de los UserDefaults
    */
    func removeInstance(songToBeRemoved: String) {
        let path = docs.appendingPathComponent(songToBeRemoved)
        do {
            try fm.removeItem(at: path)
        } catch { print("Error al eliminar") }
        
        files = try! fm.contentsOfDirectory(atPath: docs.path)
        setUserDefaults(files: files)
    }
    
    /**
    * updateInstance: Actualizar una cancion en los documentos y en los UserDefaults
    */
    func updateInstance(from: Int, to: Int) {
        let song = files.remove(at: from)
        files.insert(song, at: to)
        setUserDefaults(files: files)
    }
    
    func setUserDefaults(files: [String]) {
        UserDefaults.standard.set(files, forKey: key)
    }
}
