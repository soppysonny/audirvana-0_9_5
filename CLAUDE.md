# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Audirvana is a macOS audiophile music player (GPL v3, version 0.9.5). It focuses on bit-perfect playback via CoreAudio HAL with support for high-resolution audio formats. Written in Objective-C/Objective-C++ targeting macOS (Cocoa).

## Build Commands

Open and build via Xcode:
```bash
# Build from command line
xcodebuild -project Audirvana.xcodeproj -scheme Audirvana build

# Build release
xcodebuild -project Audirvana.xcodeproj -scheme Audirvana -configuration Release build
```

The project has two targets:
- **Audirvana** — main application (depends on AudioOutputLib)
- **AudioOutputLib** — static library containing core audio output logic

Dynamic libraries (`libsndfile.dylib`, `libtag.dylib`) are loaded at runtime from `@executable_path/../Frameworks`. The `LD_RUNPATH_SEARCH_PATHS` build setting is already configured.

## Architecture

### Threading Model
- **Main thread**: UI updates, event handling
- **IAOProc callback thread**: Real-time audio I/O (CoreAudio HAL callback — must be low-latency, no allocations)
- **Background dispatch queue**: File loading and decoding

Shared state between IAOProc and main thread lives in `AudioOutputBufferData` (aligned for atomic access).

### Audio Pipeline
```
User selects file
  → PlaylistDocument tracks the queue
  → AudioFileLoader subclass decodes audio + extracts metadata
  → Optional SRC via libsamplerate (if device rate ≠ file rate)
  → AudioOutput configures CoreAudio HAL (device, format, sample rate)
  → IAOProc callback feeds double-buffered PCM to hardware
  → Background thread pre-loads next chunk
```

### Key Components

| Component | Path | Responsibility |
|-----------|------|----------------|
| AppController | `Application/AppController.h/m` | Central controller: playback commands, metadata display, Apple Remote/media key handling |
| AudioOutput | `Player/AudioOutput.h/m` | CoreAudio HAL integration, device selection, double-buffered I/O, integer mode, dithering |
| PlaylistDocument | `Player/PlaylistDocument.h/m` | Playlist management, M3U/M3U8, shuffle/repeat, async track addition |
| AudioFileLoader | `AudioFileUtils/AudioFileLoader.h` | Abstract base for format-specific loaders |
| AudioFileCoreAudioLoader | `AudioFileUtils/AudioFileCoreAudioLoader.mm` | AAC/M4A/AIFF/WAV via CoreAudio |
| AudioFileFLACLoader | `AudioFileUtils/AudioFileFLACLoader.m` | FLAC/OGA via libFLAC |
| AudioFileSndFileLoader | `AudioFileUtils/AudioFileSndFileLoader.mm` | Additional formats via libsndfile |

### Data Model
Core Data entity `PlaylistItem` (defined in `Audirvana_DataModel.xcdatamodel`) stores: Title, Album, Artist, Composer, Duration, LengthFrames, URL.

### External Dependencies (in `extern/`)
- **libsndfile** — audio file I/O
- **TagLib** (`libtag.dylib`) — metadata tag reading
- **libsamplerate** — high-quality sample rate conversion (statically linked)
- **libFLAC** — FLAC decoding
- **Sparkle.framework** — auto-update
- **HIDRemote** — Apple Remote support

### Supported Audio Formats
MP3, MP4/AAC, FLAC, OGA, AIFF, WAV

## UI Structure
- `English.lproj/MainMenu.xib` — main window (transport controls, metadata display, volume)
- `English.lproj/Playlist.xib` — playlist window
- `English.lproj/Preferences.xib` — audio device and filter settings
- `English.lproj/Debug.xib` — developer diagnostics
- Two visual themes: Silver (default) and Black (image assets in `Images/`)
