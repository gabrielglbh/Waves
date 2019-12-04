//
//  LyricsViewController.swift
//  Waves
//
//  Created by Gabriel Garcia on 04/12/2019.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

class LyricsViewController: UIViewController {
    
    @IBOutlet var lyrics: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
}
