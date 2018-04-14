//
//  ViewController.swift
//  AKSequencer-LinkKit
//
//  Created by Cem Olcay on 14.04.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import MIDIEventKit
import AudioKit

class ViewController: UIViewController {
  var sequencer = Sequencer(data: [
    SequencerData(steps: Array(0..<Sequencer.stepCount).map({ _ in SequencerStepData(type: .note(key: .c, octave: 5), isEnabeld: true) })),
    SequencerData(steps: Array(0..<Sequencer.stepCount).map({ _ in SequencerStepData(type: .chord(key: .c, type: .major, octave: 4), isEnabeld: true) })),
  ])

  override func viewDidLoad() {
    super.viewDidLoad()

    sequencer.onNextStep = { stepIndex, notes in
      print(stepIndex, notes)
    }
  }

  // Toggle Play/Stop
  @IBAction func playButtonPressed(sender: UIBarButtonItem) {
    sequencer.isPlaying = !sequencer.isPlaying
    sender.image = UIImage(named: sequencer.isPlaying ? "stopIcon" : "playIcon")
  }

  // Present Link Settings View Controller
  @IBAction func linkButtonPressed(sender: UIBarButtonItem) {
    guard let settings = ABLLinkManager.shared.settingsViewController else { return }
    let nav = UINavigationController(rootViewController: settings)
    nav.modalPresentationStyle = .popover
    nav.preferredContentSize = CGSize(width: 320, height: 400)
    nav.navigationBar.isTranslucent = false
    if let popover = nav.popoverPresentationController {
      popover.sourceView = sender.customView
    }

    settings.title = "Ableton Link"
    let doneButton = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(linkSettingsViewControllerDidPressDone(sender:)))
    settings.navigationItem.rightBarButtonItem = doneButton
    navigationController?.present(nav, animated: true, completion: nil)
  }

  @objc func linkSettingsViewControllerDidPressDone(sender: UIBarButtonItem) {
    navigationController?.dismiss(animated: true, completion: nil)
  }
}
