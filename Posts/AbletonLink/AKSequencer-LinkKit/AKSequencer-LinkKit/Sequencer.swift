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

enum SequencerStepNoteType {
  case note(key: NoteType, octave: Int)
  case chord(key: NoteType, type: ChordThirdType, octave: Int)

  var notes: [Note] {
    switch self {
    case .note(let key, let octave):
      return [Note(type: key, octave: octave)]
    case .chord(let key, let type, let octave):
      let chord = Chord(type: ChordType(third: type), key: key)
      return chord.notes(octave: octave)
    }
  }
}

struct SequencerStepData {
  var type: SequencerStepNoteType
  var isEnabeld: Bool
}

class SequencerData {
  var steps: [SequencerStepData]

  init(steps: [SequencerStepData]) {
    self.steps = steps
  }

  subscript(_ stepIndex: Int) -> SequencerStepData {
    get {
      return steps[stepIndex]
    } set {
      steps[stepIndex] = newValue
    }
  }
}

class Sequencer {
  static let stepCount = 4
  var data: [SequencerData]
  var stepSequencer: StepSequencer

  var linkTimer = Timer()
  var linkTimerInterval = 0.1

  private var lastBeat = 0
  var onNextStep: ((_ index: Int, _ notes: [Note]) -> Void)?

  var bpm: Double {
    get {
      return ABLLinkManager.shared.bpm
    } set {
      ABLLinkManager.shared.bpm = newValue
    }
  }

  var isPlaying: Bool {
    get {
      return ABLLinkManager.shared.isPlaying
    } set {
      ABLLinkManager.shared.isPlaying = newValue
      stepSequencer.reset()
      lastBeat = 0
    }
  }

  init(data: [SequencerData]) {
    self.data = data.map({ SequencerData(steps: Array($0.steps.prefix(Sequencer.stepCount))) })
    stepSequencer = StepSequencer()
    stepSequencer.count = Sequencer.stepCount

    // Setup link manager
    ABLLinkManager.shared.setup(bpm: bpm, quantum: Float64(Sequencer.stepCount))

    linkTimer = Timer.scheduledTimer(
      timeInterval: linkTimerInterval,
      target: self,
      selector: #selector(timerTick(userInfo:)),
      userInfo: nil,
      repeats: true)
  }

  deinit {
    linkTimer.invalidate()
  }

  @objc func timerTick(userInfo: Any) {
    ABLLinkManager.shared.update()
    let currentBeat = Int(ABLLinkManager.shared.beatTime)

    if isPlaying, ABLLinkManager.shared.beatTime > 0, lastBeat != currentBeat {
      // Get current beat from step sequencer.
      let currentStep = stepSequencer.nextStepIndex
      // Combine and send all notes of each sequencer with callback.
      onNextStep?(currentStep, data.map({ $0.steps[currentStep].type.notes }).reduce([], +))
      // Sync current beat.
      lastBeat = currentBeat
    }
  }
}
