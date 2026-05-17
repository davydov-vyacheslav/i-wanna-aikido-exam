# I Wanna Aikido Exam

Practice and exam helper for Aikido practitioners.

## What it does

- Presents Aikido techniques (position + attack + technique) one at a time
- Supports count-based and time-based exam modes
- Configurable interval between techniques
- No-repeat mode ensures each technique appears only once per session
- Multiple profiles (OOTB presets + fully customisable)
- Gong sound at each technique change

## Requirements

iOS 17+, Xcode 15+

## Features

| Feature | Description |
| --- | --- |
| Profiles | Pre-built belt-level profiles or create your own |
| Randomize | Random or sequential technique order |
| Repeat control | Allow or block technique repetition |
| Skip | Jump to the next technique (safety-aware in no-repeat mode) |
| Sound | Optional gong at each advance |
| Pronunciation (TTS) | Each technique has a `name` and a `pronunciation` field. The pronunciation is spoken aloud via Text-To-Speech. Default vocabulary uses Japanese characters, so a Japanese voice is installed and used by default. If a Japanese voice is unavailable, the technique name is read in English instead. |
| Exam interruption | Switching profiles during an active exam automatically stops the exam. |

## Behaviour

- **Technique fields** — every technique now has two fields: `name` (display) and `pronunciation` (spoken by TTS).  
  - Default vocabulary stores pronunciation in Japanese characters.  
  - The app installs and uses a Japanese TTS voice as the primary voice.  
  - If the Japanese voice is not available, the technique `name` is announced in English.
- **Exam & profile switch** — changing the active profile while an exam is in progress automatically stops the exam.

## Screenshots

Main:

![Main screen](images/main.png)

Profiles:

![Profiles view](images/profiles-view.png) ![Profiles edit](images/profiles-edit.png) ![Add technics](images/profiles-add-technics.png)

Settings:

![Settings](images/settings.png)
