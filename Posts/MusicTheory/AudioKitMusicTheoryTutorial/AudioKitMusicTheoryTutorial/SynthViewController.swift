//
//  SynthViewController.swift
//  AudioKitMusicTheoryTutorial
//
//  Created by Cem Olcay on 4.08.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import Eureka
import MusicTheorySwift

class SynthViewController: FormViewController {
  let synth = TheSynth()
  let osc1Section = Section("OSC1")
  let osc2Section = Section("OSC2")
  let filterSection = Section("FILTER")
  let ampSection = Section("AMP")
  let sequencerSection = Section("SEQUENCER")

  override func viewDidLoad() {
    super.viewDidLoad()
    synth.start()
    setupForm()
  }

  func setupForm() {

    // OSC Section

    osc1Section <<< SegmentedRow<String>() {
      $0.options = TheSynth.OSCTable.all.map({ $0.description })
    }.cellUpdate({ cell, row in
      cell.segmentedControl.selectedSegmentIndex = self.synth.osc1table.rawValue
    }).onChange({
      let selectedIndex = $0.cell.segmentedControl.selectedSegmentIndex
      guard let wavetable = TheSynth.OSCTable(rawValue: selectedIndex) else { return }
      self.synth.osc1table = wavetable
    })

    osc1Section <<< SliderRow() {
      $0.title = "Amp"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 1
      $0.value = Float(self.synth.osc1Amp)
      }.cellUpdate({ cell, row in
        cell.slider.value = Float(self.synth.osc1Amp)
      }).onChange({
        guard let value = $0.value else { return }
        self.synth.osc1Amp = Double(value)
      })

    osc2Section <<< SegmentedRow<String>() {
      $0.options = TheSynth.OSCTable.all.map({ $0.description })
    }.cellUpdate({ cell, row in
      cell.segmentedControl.selectedSegmentIndex = self.synth.osc2table.rawValue
    }).onChange({
      let selectedIndex = $0.cell.segmentedControl.selectedSegmentIndex
      guard let wavetable = TheSynth.OSCTable(rawValue: selectedIndex) else { return }
      self.synth.osc2table = wavetable
    })

    osc2Section <<< SliderRow() {
      $0.title = "Amp"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 1
      $0.value = Float(self.synth.osc2Amp)
      }.cellUpdate({ cell, row in
        cell.slider.value = Float(self.synth.osc2Amp)
      }).onChange({
        guard let value = $0.value else { return }
        self.synth.osc2Amp = Double(value)
      })


    // Filter Section

    filterSection <<< SliderRow() {
      $0.title = "Cutoff"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 1000
      $0.value = Float(self.synth.ladderCutoff)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ladderCutoff)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ladderCutoff = Double(value)
    })

    filterSection <<< SliderRow() {
      $0.title = "Resonance"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 1000
      $0.value = Float(self.synth.ladderResonance)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ladderResonance)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ladderResonance = Double(value)
    })

    filterSection <<< SliderRow() {
      $0.title = "Attack"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ladderEG.attackDuration)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ladderEG.attackDuration)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ladderEG.attackDuration = Double(value)
    })

    filterSection <<< SliderRow() {
      $0.title = "Decay"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ladderEG.decayDuration)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ladderEG.decayDuration)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ladderEG.decayDuration = Double(value)
    })

    filterSection <<< SliderRow() {
      $0.title = "Sustain"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ladderEG.sustainLevel)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ladderEG.sustainLevel)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ladderEG.sustainLevel = Double(value)
    })

    filterSection <<< SliderRow() {
      $0.title = "Release"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ladderEG.releaseDuration)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ladderEG.releaseDuration)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ladderEG.releaseDuration = Double(value)
    })

    // AMP Section

    ampSection <<< SliderRow() {
      $0.title = "Attack"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ampEG.attackDuration)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ampEG.attackDuration)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ampEG.attackDuration = Double(value)
    })

    ampSection <<< SliderRow() {
      $0.title = "Decay"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ampEG.decayDuration)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ampEG.decayDuration)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ampEG.decayDuration = Double(value)
    })

    ampSection <<< SliderRow() {
      $0.title = "Sustain"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ampEG.sustainLevel)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ampEG.sustainLevel)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ampEG.sustainLevel = Double(value)
    })

    ampSection <<< SliderRow() {
      $0.title = "Release"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 5
      $0.value = Float(self.synth.ampEG.releaseDuration)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.ampEG.releaseDuration)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.ampEG.releaseDuration = Double(value)
    })

    // Sequencer Section

    sequencerSection <<< PickerInputRow<String> {
      $0.title = "Key"
      $0.options = Key.keysWithSharps.map({ $0.description })
      $0.value = Key.keysWithSharps[0].description
    }.onChange({
      self.synth.key = Key.keysWithSharps[$0.cell.picker.selectedRow(inComponent: 0)]
    })

    sequencerSection <<< PickerInputRow<String> {
      $0.title = "Scale"
      $0.options = ScaleType.all.map({ $0.description })
      $0.value = ScaleType.all[0].description
    }.onChange({
      self.synth.scaleType = ScaleType.all[$0.cell.picker.selectedRow(inComponent: 0)]
    })

    sequencerSection <<< SliderRow() {
      $0.title = "Tempo"
      $0.cell.slider.minimumValue = 10
      $0.cell.slider.maximumValue = 300
      $0.value = Float(self.synth.tempo.bpm)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.tempo.bpm)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.tempo.bpm = Double(value)
    })

    sequencerSection <<< PickerInputRow<String> {
      $0.title = "Rate"
      $0.options = TheSynth.SynthRate.all.map({ $0.description })
      $0.value = "Quarter"
    }.onChange({
      self.synth.rate = TheSynth.SynthRate.all[$0.cell.picker.selectedRow(inComponent: 0)].rate
    })

    sequencerSection <<< SliderRow() {
      $0.title = "Velocity"
      $0.cell.slider.minimumValue = 0
      $0.cell.slider.maximumValue = 127
      $0.value = Float(self.synth.velocity)
    }.cellUpdate({ cell, row in
      cell.slider.value = Float(self.synth.velocity)
    }).onChange({
      guard let value = $0.value else { return }
      self.synth.velocity = UInt8(value)
    })

    sequencerSection <<< PickerInputRow<String> {
      $0.title = "Octave"
      $0.options = [Int](-1...8).map({ "\($0)" })
      $0.value = "\(self.synth.octave)"
    }.onChange({
      self.synth.octave = $0.cell.picker.selectedRow(inComponent: 0) - 1
    })

    sequencerSection <<< ButtonRow() {
      $0.title = self.synth.sequencer?.isPlaying == true ? "Stop" : "Play"
    }.cellUpdate({ cell, row in
      row.title = self.synth.sequencer?.isPlaying == true ? "Stop" : "Play"
    }).onCellSelection({ cell, row in
      if self.synth.sequencer?.isPlaying == true {
        self.synth.stopSequencer()
      } else {
        self.synth.startSequencer()
      }
      
      cell.textLabel?.text = self.synth.sequencer?.isPlaying == true ? "Stop" : "Play"
    })

    form +++ osc1Section
      +++ osc2Section
      +++ filterSection
      +++ ampSection
      +++ sequencerSection
  }
}
