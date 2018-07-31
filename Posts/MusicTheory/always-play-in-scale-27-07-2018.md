Always Play in Scale - A Music Theory Library for iOS in Swift
===

Table of Contents
---
- [Introduction](#intro)
- [A Little Back Story](#backstory)
- [MusicTheory Library](#music-theory)
- [Creating a Simple AudioKit Synth](#aksynth)
- [Preparing AKSequencer](#aksequencer)
- [The App](#app)

Introduction <a name="intro"></a>
---

In this tutorial, I'll cover my MusicTheory Swift library, with a case study app where AKSequencer drives a simple AudioKit Synth in a scale and rate we want. So, basically we will learn how to use MusicTheory, how to create a simple AudioKit synth, hooking it up with AKSequencer and using MusicTheory library in action.

A little back story <a name="backstory"></a>
---

I started to write this little library back in January 2017, after I quit my startup job in the Valley. As a guitar/keyboard player and iOS developer, I always wanted to work on a music app. So, with all my free time, I've get started on my iOS music app development journey where my two passions, creating music and developing apps merged. 

First thing first, I wanted to make computer play something. So, I needed music notes, a parser that converts musical notes to MIDI data and a synthesizer that generate sound from that MIDI data. It didn't take too long for me to find AudioKit where you can create your synths easily with ready-to-use MIDI layer, AKMIDI, which saves you from low-level CoreMIDI API. Since AudioKit take care of MIDI and Synth layers, all I need was a meaningful, easy-to-use music theory API just like AudioKit did with its Swift API. 

As a person who took his last music theory class like a decade ago, I started to learn music theory again, with a software-engineer point of view. When you deal with music notes, intervals, scales, chords, rhythmes, time-signatures etc, you actually deal with some set of numbers that produces a sound we call music. Luckly, people from 15th-16th century did this mathematical work perfectly. It's so perfect, it's almost like a specifiaction for music theory that you can implement it in any language you want. Which I did for Swift. So let's dive in.

MusicTheory Library <a name="music-theory"></a>
---

This is a universal library for iOS, iOS Extensions, macOS, tvOS and watchOS. You can use it with cocoapods by adding `pod 'MusicTheorySwift'` into your podfile.  

It has mainly `Key`, `Accidental`, `Pitch`, `Interval` data types that defines the building blocks of music. Also has `Scale` and `Chord` data types for making things as easy as possible. Lastly, `Tempo`, `TimeSignature` and `NoteValue` data types are great for making time related calculations for a sequencer or sampler implementation.

Let's prepare a Xcode Playground project and do some coding.  

- First, create a Single View iOS app 

![](ss1.png)
![](ss2.png)

- Then, create a Podfile and add `MusicTheorySwift` pod.

```
target 'AudioKitMusicTheoryTutorial' do
  use_frameworks!
  pod 'MusicTheorySwift'
end

post_install do |installer|

  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
    end
  end
end
```

The last `post_install` part will help us on using pod module with playgrounds.
For more information visit [this github issue](https://github.com/ReactiveX/RxSwift/issues/1660).

- Nice, now make a `pod install` and open up the workspace CocoaPods created for us.
- Let's build our project with `⌘+B`.
- And add a iOS Playground file inside our project.
- Let's `import MusicTheorySwift` to our playground.
![](ss3.png)

We are ready to roll now! Let's begin exploring the library.

### Scales

* Let's create C#-minor scale and print out it's pitches for octave 4.
* C-major scale has two main parts. 
* A `Key`, which is C# in our case.
	* Notice that it has a `Key` of C and an `Accidental` sharp.	 
* And a `minor` scale.

```
let cSharp = Key(type: .c, accidental: .sharp)
let minor = ScaleType.minor
let cSharpMinor = Scale(type: minor, key: cSharp)
```

Great, we created our first C# minor! Now, let's print the pitches.

```
let pitches = cSharpMinor.pitches(octave: 4)
print(pitches)
// [C♯4, D♯4, E4, F♯4, G♯4, A4, B4]
```

Try to change `Key` and `ScaleType` to produce other scales!

### Chords

Now, let's take look at `Chord`s.
  
* Let's create C#-minor chord now.  
* Minor chord is built by three notes with 
	* First, third and fifth notes of the scale, minor-scale in this case.
	* First note is the root, C# in this case
	* Second note is the minor third of the root, E
	* Third note is the perfect fifth of the root, G#
* `Chord` data type lets you build chords very extensively. We can basically define all the chord parts as we defined above, take a look.

```
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
```

For a C#m7 (C-sharp minor seventh) chord we can do

```
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
```

Try to define other chords with other keys, scales and chord parts yourself!



