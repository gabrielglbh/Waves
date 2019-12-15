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
    
    init() { }
    
    init(key: String) {
        setFiles()
        
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(files!, forKey: key)
        } else {
            files = UserDefaults.standard.object(forKey: key)! as? [String]
        }
    }
    
    func setCFM(key: String) {
        setFiles()
        
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(files!, forKey: key)
        } else {
            files = UserDefaults.standard.object(forKey: key)! as? [String]
        }
    }
    
    func setFiles() {
        fm = FileManager.default
        docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(docs.path)
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        files!.removeAll { $0 == ".DS_Store" }
    }
    
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
    
    func getFileFrom(at: Int, from: String, initial: String) -> String {
        setCFM(key: from)
        let file = getFile(at: at)
        setCFM(key: initial)
        return file
    }
    
    func getURLFromDoc(of: String) -> URL {
        return docs.appendingPathComponent(of)
    }
    
    func getNextSong(from: Int) -> URL {
        let next = getFile(at: from)
        return getURLFromDoc(of: next)
    }
    
    func removeInstance(songToBeRemoved: String, key: String) {
        let path = docs.appendingPathComponent(songToBeRemoved)
        do {
            try fm.removeItem(at: path)
        } catch { print("Error al eliminar") }
        
        files = try? fm.contentsOfDirectory(atPath: docs.path)
        UserDefaults.standard.set(files!, forKey: key)
    }
    
    func updateInstance(from: Int, to: Int, key: String) {
        let song = files!.remove(at: from)
        files!.insert(song, at: to)
        UserDefaults.standard.set(files!, forKey: key)
    }
    
    func setUserDefaults(files: [String], key: String) {
        UserDefaults.standard.set(files, forKey: key)
    }
}
