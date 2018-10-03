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

  enum OSCTable: Int, CustomStringConvertible {
    case saw
    case tri
    case sin
    case sqr

    static let all: [OSCTable] = [.sin, .tri, .saw, .sqr]

    var morphingIndex: Double {
      guard let i = OSCTable.all.index(of: self) else { return 0 }
      return Double(i) / Double(OSCTable.all.count)
    }

    var table: AKTable {
      switch self {
      case .saw: return AKTable(.sawtooth)
      case .tri: return AKTable(.triangle)
      case .sin: return AKTable(.sine)
      case .sqr: return AKTable(.square)
      }
    }

    var description: String {
      switch self {
      case .saw: return "Sawtooth"
      case .tri: return "Triangle"
      case .sin: return "Sine"
      case .sqr: return "Square"
      }
    }
  }

  enum SynthRate: Int, CustomStringConvertible {
    case whole
    case wholeDotted
    case wholeTriplet
    case half
    case halfDotted
    case halfTriplet
    case quarter
    case quarterDotted
    case quarterTriplet
    case eighth
    case eighthDotted
    case eighthTriplet
    case sixteenth
    case sixtheenthDotted
    case sixteenthTriplet
    case thirtysecond
    case thirtysecondDotted
    case thirtysecondTriplet
    case sixtyfourth
    case sixtyfourthDotted
    case sixtyfourthTriplet

    static let all: [SynthRate] = [
      .whole, .wholeDotted, .wholeTriplet,
      .half, .halfDotted, .halfTriplet,
      .quarter, .quarterDotted, .quarterTriplet,
      .eighth, .eighthDotted, .eighthTriplet,
      .sixteenth, .sixtheenthDotted, .sixteenthTriplet,
      .thirtysecond, .thirtysecondDotted, .thirtysecondTriplet,
      .sixtyfourth, .sixtyfourthDotted, .sixtyfourthTriplet
    ]

    var rate: NoteValue {
      switch self {
      case .whole: return NoteValue(type: .whole, modifier: .default)
      case .wholeDotted: return NoteValue(type: .whole, modifier: .dotted)
      case .wholeTriplet: return NoteValue(type: .whole, modifier: .triplet)

      case .half: return NoteValue(type: .half, modifier: .default)
      case .halfDotted: return NoteValue(type: .half, modifier: .dotted)
      case .halfTriplet: return NoteValue(type: .half, modifier: .triplet)

      case .quarter: return NoteValue(type: .quarter, modifier: .default)
      case .quarterDotted: return NoteValue(type: .quarter, modifier: .dotted)
      case .quarterTriplet: return NoteValue(type: .quarter, modifier: .triplet)

      case .eighth: return NoteValue(type: .eighth, modifier: .default)
      case .eighthDotted: return NoteValue(type: .eighth, modifier: .dotted)
      case .eighthTriplet: return NoteValue(type: .eighth, modifier: .triplet)

      case .sixteenth: return NoteValue(type: .sixteenth, modifier: .default)
      case .sixtheenthDotted: return NoteValue(type: .sixteenth, modifier: .dotted)
      case .sixteenthTriplet: return NoteValue(type: .sixteenth, modifier: .triplet)

      case .thirtysecond: return NoteValue(type: .thirtysecond, modifier: .default)
      case .thirtysecondDotted: return NoteValue(type: .thirtysecond, modifier: .dotted)
      case .thirtysecondTriplet: return NoteValue(type: .thirtysecond, modifier: .triplet)

      case .sixtyfourth: return NoteValue(type: .sixtyfourth, modifier: .default)
      case .sixtyfourthDotted: return NoteValue(type: .sixtyfourth, modifier: .dotted)
      case .sixtyfourthTriplet: return NoteValue(type: .sixtyfourth, modifier: .triplet)
      }
    }

    var description: String {
      let type = "\(rate.type)"
      let modifier = rate.modifier == .default ? "" : "\(rate.modifier)"
      return "\(type.capitalized) \(modifier.capitalized)"
    }
  }

  // OSC
  var osc1 = AKMorphingOscillator(waveformArray: OSCTable.all.map({ $0.table }))
  var osc2 = AKMorphingOscillator(waveformArray: OSCTable.all.map({ $0.table }))
  var osc1table: OSCTable = .saw { didSet { update() }}
  var osc2table: OSCTable = .saw { didSet { update() }}
  var mixer: AKMixer!

  // Filter
  var ladder: AKMoogLadder!
  var ladderEG: AKAmplitudeEnvelope! { didSet { update() }}
  var ladderCutoff: Double = 0 { didSet { update() }}
  var ladderResonance: Double = 0 { didSet { update() }}

  // Amp
  var osc1Amp: Double = 1
  var osc2Amp: Double = 1
  var ampEG: AKAmplitudeEnvelope!

  // Sequencer
  let midi = AKMIDI()
  var sequencer: AKSequencer!
  var tempo = Tempo() { didSet { sequencer?.setTempo(tempo.bpm) }}
  var velocity: UInt8 = 90 { didSet { restartSequencer() }}

  // Sequence
  var key = Key(type: .c) { didSet { restartSequencer() }}
  var scaleType = ScaleType.major { didSet { restartSequencer() }}
  var rate = NoteValue(type: .quarter) { didSet { restartSequencer() }}
  var octave: Int = 4 { didSet { restartSequencer() }}

  // MARK: Lifecycle

  func start() {
    // Mixer
    mixer = AKMixer([osc1, osc2])
    osc1.rampDuration = 0
    osc2.rampDuration = 0

    // Filter
    ladder = AKMoogLadder(
      mixer,
      cutoffFrequency: ladderCutoff,
      resonance: ladderResonance)

    ladderEG = AKAmplitudeEnvelope(
      ladder,
      attackDuration: 0,
      decayDuration: 0.1,
      sustainLevel: 0.2,
      releaseDuration: 0.1)

    // AMP
    ampEG = AKAmplitudeEnvelope(
      ladderEG,
      attackDuration: 0,
      decayDuration: 0.1,
      sustainLevel: 0.2,
      releaseDuration: 0.1)

    // MIDI
    midi.createVirtualInputPort()
    midi.addListener(self)

    // AudioKit
    do {
      AudioKit.output = osc1
      try AudioKit.start()
    } catch {
      print(error)
    }
  }

  func update() {
    // table
    osc1.index = osc1table.morphingIndex
    osc2.index = osc2table.morphingIndex
    // ladder
    ladder.cutoffFrequency = ladderCutoff
    ladder.resonance = ladderResonance
  }

  // MARK: Sequencer

  func startSequencer() {
    sequencer = AKSequencer()
    sequencer.setTempo(tempo.bpm)

    let track = sequencer.newTrack()
    let scale = Scale(type: scaleType, key: key)
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
//    osc1.play()
    osc2.play()
  }

  func stopSequencer() {
    sequencer.stop()
//    osc1.stop()
    osc2.stop()
  }

  func restartSequencer() {
    if sequencer?.isPlaying == true {
      stopSequencer()
      startSequencer()
    }
  }

  // MARK: AKMIDIListener

  func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
    osc1.frequency = noteNumber.midiNoteToFrequency()
    osc2.frequency = noteNumber.midiNoteToFrequency()
    osc1.amplitude = osc1Amp
    osc2.amplitude = osc2Amp
    print(osc1Amp, osc2Amp)
  }

  func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel) {
    osc1.amplitude = 0
    osc2.amplitude = 0
  }
}
