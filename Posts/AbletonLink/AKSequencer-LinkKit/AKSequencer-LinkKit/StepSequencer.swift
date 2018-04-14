//
//  StepSequencer.swift
//  AUSequencer
//
//  Created by Cem Olcay on 14.03.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import Foundation

indirect enum StepSequencerArpeggio: Equatable {
  case up
  case down
  case updown(StepSequencerArpeggio)
  case random(numberOfStepsSoFar: Int)

  static func ==(lhs: StepSequencerArpeggio, rhs: StepSequencerArpeggio) -> Bool {
    switch (lhs, rhs) {
    case (.up, .up): return true
    case (.down, .down): return true
    case (.random(let a), .random(let b)): return a == b
    case (.updown(let a), .updown(let b)): return a == b
    default: return false
    }
  }
}

class StepSequencer {
  var arpeggio = StepSequencerArpeggio.up

  var count = 0
  private(set) var currentStepIndex = 0

  private var isSequenceComplete = false
  var onSequenceComplete: (() -> Void)?

  func reset() {
    let index = arpeggio == .down ? count - 1 : 0
    currentStepIndex = max(index, 0)
    isSequenceComplete = false
  }

  var nextStepIndex: Int {
    if isSequenceComplete {
      onSequenceComplete?()
    }
    isSequenceComplete = false

    // Check if we have steps and we are in bounds.
    guard count > 0, currentStepIndex >= 0, currentStepIndex < count else {
      currentStepIndex = 0
      return currentStepIndex
    }

    // Hold a reference of current step index for returning.
    let current = currentStepIndex

    // Calculate next step index.
    switch arpeggio {
    case .up:
      if currentStepIndex + 1 >= count {
        currentStepIndex = 0
        isSequenceComplete = true // cycle complete
      } else {
        currentStepIndex += 1
      }
    case .down:
      if currentStepIndex - 1 < 0 {
        currentStepIndex = count - 1
        isSequenceComplete = true // cycle complete
      } else {
        currentStepIndex -= 1
      }
    case .updown(let state):
      switch state {
      case .up:
        if currentStepIndex + 1 >= count {
          currentStepIndex = count - 1
          arpeggio = .updown(.down)
        } else {
          currentStepIndex += 1
        }
      case .down:
        if currentStepIndex - 1 < 0 {
          currentStepIndex = 0
          arpeggio = .updown(.up)
          isSequenceComplete = true // cycle complete
        } else {
          currentStepIndex -= 1
        }
      default:
        currentStepIndex = 0
      }
    case .random(let numberOfStepsSoFar):
      currentStepIndex = Int(arc4random_uniform(UInt32(count)))
      arpeggio = .random(numberOfStepsSoFar: numberOfStepsSoFar + 1)

      // check if sequence complete
      if numberOfStepsSoFar + 1 == count {
        isSequenceComplete = true // cycle complete
        arpeggio = .random(numberOfStepsSoFar: 0)
      }
    }

    return current
  }
}
