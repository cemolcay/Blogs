//
//  Sequencer.swift
//  AKSequencer-LinkKit
//
//  Created by Cem Olcay on 14.04.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import AudioKit
import MusicTheorySwift
import MIDIEventKit

class Sequencer {
  static let shared = Sequencer()
  var sequencer = AKSequencer()
  var midi = AKMIDI()

  init() {

  }
}
