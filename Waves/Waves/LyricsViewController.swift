//
//  LyricsViewController.swift
//  Waves
//
//  Created by Gabriel Garcia on 04/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import Foundation

class LyricsViewController: UIViewController {
    
    @IBOutlet var lyrics: UITextView!
    
    var nameQuery: String?
    let headers = [
        "x-rapidapi-host": "genius.p.rapidapi.com",
        "x-rapidapi-key": ""
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*var request = URLRequest(url: URL(string: "https://api.genius.com/search?q=" +
            nameQuery!.replacingOccurrences(of: " ", with: "%20"))!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            let res = String(data: data!, encoding: String.Encoding.utf8)
            print(response)
            print(res)
        }
        task.resume()*/
    }
    
    @IBAction private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
}
