//
//  TheSynth.swift
//  AudioKitMusicTheoryTutorial
//
//  Created by Cem Olcay on 28.07.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import AudioKit
import MusicTheorySwift

class TheSynth: AKMIDIListener {

  enum OSCTable {
    case saw
    case tri

    static let all: [OSCTable] = [.saw, .tri]

    var index: Double {
      guard let i = OSCTable.all.index(of: self) else { return 0 }
      return Double(OSCTable.all.count) / Double(i)
    }

    var table: AKTable {
      switch self {
      case .saw: return AKTable(.sawtooth)
      case .tri: return AKTable(.triangle)
      }
    }
  }

  var osc1: AKMorphingOscillator!
  var osc2: AKMorphingOscillator!
  var osc1table: OSCTable = .saw { didSet { update() }}
  var osc2table: OSCTable = .saw { didSet { update() }}
  var ladder: AKMoogLadder!
  var ladderEG: AKAmplitudeEnvelope!
  var ladderCutoff: Double = 0 { didSet { update() }}
  var ladderResonance: Double = 0 { didSet { update() }}
  var osc1Amp: Double = 1 { didSet { update() }}
  var osc2Amp: Double = 1 { didSet { update() }}
  var ampEG: AKAmplitudeEnvelope!
  var mixer: AKMixer!

  var sequencer: AKSequencer!
  var tempo = Tempo()
  var midi = AKMIDI()

  func setupMIDI() {
    midi.addListener(self)
    midi.createVirtualInputPort()
  }

  func start() {
    setupMIDI()

    osc1 = AKMorphingOscillator(
      waveformArray: OSCTable.all.map({ $0.table }),
      frequency: 0,
      amplitude: osc1Amp,
      detuningOffset: 0,
      detuningMultiplier: 0)

    osc2 = AKMorphingOscillator(
      waveformArray: OSCTable.all.map({ $0.table }),
      frequency: 0,
      amplitude: osc2Amp,
      detuningOffset: 0,
      detuningMultiplier: 0)

    mixer = AKMixer([osc1, osc2])
    mixer.volume = 1.0


    ladder = AKMoogLadder(
      mixer,
      cutoffFrequency:
      ladderCutoff, resonance: ladderResonance)

    ladderEG = AKAmplitudeEnvelope(
      ladder,
      attackDuration: 0,
      decayDuration: 0.1,
      sustainLevel: 0.2,
      releaseDuration: 0.1)

    ampEG = AKAmplitudeEnvelope(
      ladderEG,
      attackDuration: 0,
      decayDuration: 0.1,
      sustainLevel: 0.2,
      releaseDuration: 0.1)

    AudioKit.output = ampEG
    do {
      try AudioKit.start()
    } catch {
      print(error)
    }
  }

  func update() {
    // table
    osc1.index = osc1table.index
    osc2.index = osc2table.index
    // ladder
    ladder.cutoffFrequency = ladderCutoff
    ladder.resonance = ladderResonance
    // amp
    osc1.amplitude = osc1Amp
    osc2.amplitude = osc2Amp
  }

  func startSequencer(scale: Scale = Scale(type: .major, key: Key(type: .c)), rate: NoteValue = NoteValue(type: .quarter), octave: Int = 4, velocity: UInt8 = 90) {
    sequencer = AKSequencer()
    sequencer.setTempo(tempo.bpm)

    let track = sequencer.newTrack()
    let pitches = scale.pitches(octave: octave)
    let duration = AKDuration(seconds: tempo.duration(of: rate))
    var currentPosition = AKDuration(beats: 0)
    for pitch in pitches {
      track?.add(
        noteNumber: MIDINoteNumber(pitch.rawValue),
        velocity: velocity,
        position: currentPosition,
        duration: duration)
      currentPosition = AKDuration(seconds: currentPosition.seconds + duration.seconds)
    }

    track?.setMIDIOutput(midi.virtualInput)
    sequencer.enableLooping(currentPosition)
    sequencer.play()
  }

  func stopSequencer() {
    sequencer.stop()
  }

  // MARK: AKMIDIListener

  func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
    osc1.frequency = noteNumber.midiNoteToFrequency()
    osc2.frequency = noteNumber.midiNoteToFrequency()
    osc1.amplitude = osc1Amp
    osc2.amplitude = osc2Amp
  }

  func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
    osc1.amplitude = 0
    osc2.amplitude = 0
  }
}
