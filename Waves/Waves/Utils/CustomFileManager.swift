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
    private var files: [String]?
    private var fm: FileManager!
    private var key: String!
    
    init() { }
    
	/**
	* Iniciación de los ficheros y el UserDefaults para una key fija
	*/
    init(key: String) {
        self.key = key
        setFiles()
        
        if UserDefaults.standard.object(forKey: self.key) == nil {
            UserDefaults.standard.set(files!, forKey: self.key)
        } else {
            files = UserDefaults.standard.object(forKey: self.key)! as? [String]
        }
    }
    
	/**
	* Iniciación de los ficheros y el UserDefaults para una key dinámica
	*/
    func setCFM(key: String) {
        self.key = key
        setFiles()
        
        if UserDefaults.standard.object(forKey: self.key) == nil {
            UserDefaults.standard.set(files!, forKey: self.key)
        } else {
            files = UserDefaults.standard.object(forKey: self.key)! as? [String]
        }
    }
    
	/**
	* setFiles: Iniciación de los ficheros únicamente
	*/
    func setFiles() {
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(docs.path)
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
    }
    
	/**
	* reloadData: Recarga de las canciones del directorio
	*/
    func reloadData() {
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
    }
    
    func getFiles() -> [String] {
        return files!
    }
    
    func getCountFiles() -> Int {
        return files!.count
    }
    
    func getFile(at: Int) -> String {
        return files![at]
    }
    
	/**
	* getFileFrom: Funcion para recuperar una cancion de los documentos, dentro 
	* de una playlist para asociarla a ella.
	* Devuelve el nombre del fichero elegido.
	*/
    func getFileFrom(at: Int, from: String) -> String {
        setCFM(key: from)
        let file = getFile(at: at)
        setCFM(key: self.key)
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
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        setUserDefaults(files: files!)
    }
    
	/**
	* updateInstance: Actualizar una cancion en los documentos y en los UserDefaults
	*/
    func updateInstance(from: Int, to: Int) {
        let song = files!.remove(at: from)
        files!.insert(song, at: to)
        setUserDefaults(files: files!)
    }
    
    func setUserDefaults(files: [String]) {
        UserDefaults.standard.set(files, forKey: key)
    }
}
