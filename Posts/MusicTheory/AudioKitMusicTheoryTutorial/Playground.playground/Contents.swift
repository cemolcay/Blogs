//: Playground - noun: a place where people can play

import UIKit
import MusicTheorySwift

let cSharp = Key(type: .c, accidental: .sharp)
let minor = ScaleType.minor
let cSharpMinor = Scale(type: minor, key: cSharp)

let pitches = cSharpMinor.pitches(octave: 4)
print(pitches)
