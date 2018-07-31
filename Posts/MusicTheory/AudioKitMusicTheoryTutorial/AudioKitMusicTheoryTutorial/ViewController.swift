//
//  ViewController.swift
//  AudioKitMusicTheoryTutorial
//
//  Created by Cem Olcay on 27.07.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  let synth = TheSynth()

  override func viewDidLoad() {
    super.viewDidLoad()
    synth.start()
    synth.startSequencer()
  }
}

