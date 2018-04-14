Integrating Ableton LinkKit with AudioKit apps
===

[Ableton Link](https://www.ableton.com/en/link/) is a great technology for syncing iOS audio apps with each other as well as Ableton Live. A link session tracks the beat, bar and phrase according to tempo and the host apps can play always in time with a shared tempo.

[LinkKit](https://ableton.github.io/linkkit/) is a C++ library with functions to create a Link session, getting the beat for the current time, updating the tempo etc. from both audio thread and UI thread. The best practice is creating it once when you initilize your app with your audio engine and tracking the beat or requesting session updates in the audio render loop. You can setup your custom timer act like a audio render loop but it does not guaranties the precise accuracy.

#### Getting the LinkKit

You need to [request LinkKit](https://ableton.github.io/linkkit/) from Ableton with some information and they will give you access the private repo of the LinkKit where you download final release with UI guides and a well built example app called LinkHut. You can study the example app if you have no experience with `AudioUnit`s, Audio DSP programming, mixing Objective-C with C++ (Objective-C++). Don't worry if you are a Swift developer, it works perfectly well with Swift apps. Also, you can test your implementation with the LinkHut to check if your app is in sync with other Link apps.

#### AudioKit Integration

In case of AudioKit integration, if you have an Audio Unit where you can subscribe its render loop (the audio thread), you are basically ready to go. Also, it doesn't hurt to add one if you are not currently have one. Otherwise, you can setup your custom loop with the `NSTimer`, for example, if you are using AudioKit for just the `AKSequencer`.

Implementation
----

There are two main data structures you will work with. An engine data, where the audio engine related data goes, like, output latency, bpm, quantum etc.

```
typedef struct {
  UInt64 outputLatency;
  Float64 resetToBeatTime;
  BOOL requestStart;
  BOOL requestStop;
  Float64 proposeBpm;
  Float64 quantum;
} EngineData;
```

And Link data, the data you need in audio thread. It will have the `ABLLinkRef`, the Link itself and two `EngineData` references one is audio thread only data and other is shared between main and audio thread so changes on EngineData from different threads don't block each other. Also, it has time related datas for calculating the beats accurate as possible.


```
typedef struct {
  ABLLinkRef ablLink;
  // Shared between threads. Only write when engine not running.
  Float64 sampleRate;
  // Shared between threads. Only write when engine not running.
  Float64 secondsToHostTime;
  // Shared between threads. Written by the main thread and only
  // read by the audio thread when doing so will not block.
  EngineData sharedEngineData;
  // Copy of sharedEngineData owned by audio thread.
  EngineData localEngineData;
  // Owned by audio thread
  UInt64 timeAtLastClick;
  // Owned by audio thread
  BOOL isPlaying;
} LinkData;
``` 

In audio render loop, we sync `sharedEnigneData` to `localEngineData` with `static void pullEngineData(LinkData* linkData, EngineData* output)` function. So, tempo or play/stop state changes applied on audio thread.

```
/*
 * Pull data from the main thread to the audio thread if lock can be
 * obtained. Otherwise, just use the local copy of the data.
 */
static void pullEngineData(LinkData* linkData, EngineData* output) {
  // Always reset the signaling members to their default state
  output->resetToBeatTime = INVALID_BEAT_TIME;
  output->proposeBpm = INVALID_BPM;
  output->requestStart = NO;
  output->requestStop = NO;

  // Attempt to grab the lock guarding the shared engine data but
  // don't block if we can't get it.
  if (OSSpinLockTry(&lock)) {
    // Copy non-signaling members to the local thread cache
    linkData->localEngineData.outputLatency =
    linkData->sharedEngineData.outputLatency;
    linkData->localEngineData.quantum = linkData->sharedEngineData.quantum;

    // Copy signaling members directly to the output and reset
    output->resetToBeatTime = linkData->sharedEngineData.resetToBeatTime;
    linkData->sharedEngineData.resetToBeatTime = INVALID_BEAT_TIME;

    output->requestStart = linkData->sharedEngineData.requestStart;
    linkData->sharedEngineData.requestStart = NO;

    output->requestStop = linkData->sharedEngineData.requestStop;
    linkData->sharedEngineData.requestStop = NO;

    output->proposeBpm = linkData->sharedEngineData.proposeBpm;
    linkData->sharedEngineData.proposeBpm = INVALID_BPM;

    OSSpinLockUnlock(&lock);
  }

  // Copy from the thread local copy to the output. This happens
  // whether or not we were able to grab the lock.
  output->outputLatency = linkData->localEngineData.outputLatency;
  output->quantum = linkData->localEngineData.quantum;
}
```


And last part, in our DSP code, or audio render loop, we pull the Link data, capture the current session, check the tempo, play/stop changes and commit any requested changes by our client to session.

```
static OSStatus audioCallback(
                              void *inRefCon,
                              AudioUnitRenderActionFlags *flags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList *ioData) {
#pragma unused(inBusNumber, flags)

  // First clear buffers
  for (UInt32 i = 0; i < ioData->mNumberBuffers; ++i) {
    memset(ioData->mBuffers[i].mData, 0, inNumberFrames * sizeof(SInt16));
  }

  LinkData *linkData = (LinkData *)inRefCon;;

  // Get a copy of the current link session state.
  const ABLLinkSessionStateRef sessionState =
  ABLLinkCaptureAudioSessionState(linkData->ablLink);

  // Get a copy of relevant engine parameters.
  EngineData engineData;
  pullEngineData(linkData, &engineData);

  // The mHostTime member of the timestamp represents the time at
  // which the buffer is delivered to the audio hardware. The output
  // latency is the time from when the buffer is delivered to the
  // audio hardware to when the beginning of the buffer starts
  // reaching the output. We add those values to get the host time
  // at which the first sample of this buffer will reach the output.
  const UInt64 hostTimeAtBufferBegin =
  inTimeStamp->mHostTime + engineData.outputLatency;

  if (engineData.requestStart && !ABLLinkIsPlaying(sessionState)) {
    // Request starting playback at the beginning of this buffer.
    ABLLinkSetIsPlaying(sessionState, YES, hostTimeAtBufferBegin);
  }

  if (engineData.requestStop && ABLLinkIsPlaying(sessionState)) {
    // Request stopping playback at the beginning of this buffer.
    ABLLinkSetIsPlaying(sessionState, NO, hostTimeAtBufferBegin);
  }

  if (!linkData->isPlaying && ABLLinkIsPlaying(sessionState)) {
    // Reset the session state's beat timeline so that the requested
    // beat time corresponds to the time the transport will start playing.
    // The returned beat time is the actual beat time mapped to the time
    // playback will start, which therefore may be less than the requested
    // beat time by up to a quantum.
    ABLLinkRequestBeatAtStartPlayingTime(sessionState, 0., engineData.quantum);
    linkData->isPlaying = YES;
  }
  else if(linkData->isPlaying && !ABLLinkIsPlaying(sessionState)) {
    linkData->isPlaying = NO;
  }

  // Handle a tempo proposal
  if (engineData.proposeBpm != INVALID_BPM) {
    // Propose that the new tempo takes effect at the beginning of
    // this buffer.
    ABLLinkSetTempo(sessionState, engineData.proposeBpm, hostTimeAtBufferBegin);
  }

  ABLLinkCommitAudioSessionState(linkData->ablLink, sessionState);

  //
  // Other DSP stuff goes here
  //
  
  return noErr;
}
```

When we setup our audio render loop function to audio unit, we should send our `LinkData`. So, we can pull it from `void *inRefCon` parameter in our `audioCallback` function. 

```
  AURenderCallbackStruct ioRemoteInput;
  ioRemoteInput.inputProc = audioCallback;
  ioRemoteInput.inputProcRefCon = &_linkData;

  result = AudioUnitSetProperty(
                                _ioUnit,
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Input,
                                0,
                                &ioRemoteInput,
                                sizeof(ioRemoteInput));

```

#### Passing custom data

You can pass your custom data type as well, if you want to do something else. For example, you can setup a custom callback function like:

```
typedef void (^AudioEngineRenderCallback)(double beat);
```

And setup a property for implementing it in another class.

```
@property (copy) AudioEngineRenderCallback renderCallbackBlock;
```

In your audio engine's header file. Also, you should setup a custom struct for passing it to your audio callback function.

```
typedef struct {
  LinkData *linkRef;
  AudioEngineRenderCallback callback;
} AudioEngineRenderCallbackData;
```

Create a private reference for it in your implementation file.

```
@interface AudioEngine() {
  AudioUnit _ioUnit;
  LinkData _linkData;
  AudioEngineRenderCallbackData _renderCallbackData;
}
@end
```

And pass it to audio callback method.

```
  _renderCallbackData = AudioEngineRenderCallbackData();
  _renderCallbackData.linkRef = &_linkData;
  _renderCallbackData.callback = self.renderCallbackBlock;

  // Set Audio Callback
  AURenderCallbackStruct ioRemoteInput;
  ioRemoteInput.inputProc = audioCallback;
  ioRemoteInput.inputProcRefCon = &_renderCallbackData;

  result = AudioUnitSetProperty(
                                _ioUnit,
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Input,
                                0,
                                &ioRemoteInput,
                                sizeof(ioRemoteInput));
```

Then, in your audio callback function, pull it from `void *inRefCon`.

```
  AudioEngineRenderCallbackData *data = (AudioEngineRenderCallbackData *)inRefCon;
  LinkData *linkData = data->linkRef;
```

You can pass the current beat to your custom callback function now.

```
  // Send beat callback
  if (data->callback) {
    data->callback(ABLLinkBeatAtTime(sessionState, hostTimeAtBufferBegin, 4));
  }
```

You can find the full example in [this repo](https://github.com/cemolcay/AUSequencer).


Integrating with Swift projects
----

For Swift projects, you need a bridging header file and include the LinkKit.

```
#ifndef Bridge_h
#define Bridge_h

#include "ABLLink.h"
#include "ABLLinkUtils.h"
#include "ABLLinkSettingsViewController.h"

#endif /* Bridge_h */
```

Also, you need to link `libc++.tbd` to your linked frameworks and libraries section in General tab in your project settings.

There is a Swift port of `EngineData` and `LinkData` as Swift structs that you can grab from [here](https://gist.github.com/cemolcay/3c9badfa263888d686e3aa454a5adfb7). 

In this example, we will setup a custom timer and use it as our audio render loop. So, it will cover the projects with no audio units. The `update` function in the Swift port code is the same code in the audio render loop above. So, our custom timer should call it.

```
  // Timer
  private var timer: Timer = Timer()
  private let timerSpeed: Double = 0.1
  
  init() {
    timer = Timer.scheduledTimer(
      timeInterval: timerSpeed,
      target: ABLLinkManager.shared,
      selector: #selector(update),
      userInfo: nil,
      repeats: true)
  }
```

If you subscribe its listeners, you are going the react tempo/start/stop changes. And of course you can request the change them as well, by simply setting its properties.

```
  // Subscribe tempo change events
  ABLLinkManager.shared.add(listener: .tempo({ bpm, quantum in
    self.tempo.bpm = bpm
  }))

  // Update Link tempo
  @IBAction func tempoDidChange(sender: UIControl) { 
	 ABLLinkManager.shared.bpm = tempo.bpm
  }
```

