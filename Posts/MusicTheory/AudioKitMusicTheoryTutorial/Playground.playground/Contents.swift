//: Playground - noun: a place where people can play

import UIKit
import MusicTheorySwift

let cSharp = Key(type: .c, accidental: .sharp)
let minor = ScaleType.minor
let cSharpMinor = Scale(type: minor, key: cSharp)

let pitches = cSharpMinor.pitches(octave: 4)
print(pitches)

let cSharpMinorChord = Chord(
  type: ChordType(
    third: .minor,
    fifth: .perfect,
    sixth: nil,
    seventh: nil,
    suspended: nil,
    extensions: nil),
  key: cSharp)

print(cSharpMinorChord.type.intervals)
// [Perfect 1st, Minor 3rd, Perfect 5th]

print(cSharpMinorChord.keys)
// [C♯, E, G♯]

let cSharpMinorSeventhChord = Chord(
  type: ChordType(
    third: .minor,
    fifth: .perfect,
    sixth: nil,
    seventh: .dominant,
    suspended: nil,
    extensions: nil),
  key: cSharp)

print(cSharpMinorSeventhChord.type.intervals)
// [Perfect 1st, Minor 3rd, Perfect 5th, Minor 7th]

print(cSharpMinorSeventhChord.keys)
// [C♯, E, G♯, B]
