# Sound Assets

This directory contains sound effects for the AIn't Real game.

## Required Sound Files

Add the following MP3 files:

| File | Description | Duration | Notes |
|------|-------------|----------|-------|
| `correct.mp3` | Correct answer chime | ~0.5s | Pleasant ding/chime |
| `wrong.mp3` | Wrong answer buzz | ~0.5s | Soft buzz or error tone |
| `tick.mp3` | Countdown tick | ~0.1s | Short tick/click |
| `time_up.mp3` | Timer expired | ~0.5s | Warning/alarm sound |
| `bonus.mp3` | Bonus awarded | ~1s | Celebration/coin sound |
| `streak.mp3` | Streak bonus | ~1s | Ascending chime |
| `round_start.mp3` | Round begins | ~0.5s | Whoosh or start sound |
| `reveal.mp3` | AI reveal | ~1s | Dramatic reveal sound |
| `victory.mp3` | Game won | ~2s | Celebration fanfare |
| `game_over.mp3` | Game ended | ~1.5s | Neutral end sound |

## Recommended Sources

- [Freesound.org](https://freesound.org) - Free CC0/CC-BY sounds
- [Mixkit](https://mixkit.co/free-sound-effects/) - Free sound effects
- [Zapsplat](https://www.zapsplat.com) - Free with attribution

## Format Requirements

- Format: MP3 (preferred) or WAV
- Sample rate: 44.1kHz
- Channels: Mono or Stereo
- Volume: Normalized to -6dB peak

## Placeholder Generation

To generate placeholder beep sounds for testing:

```bash
# Requires ffmpeg
ffmpeg -f lavfi -i "sine=frequency=800:duration=0.3" -ar 44100 correct.mp3
ffmpeg -f lavfi -i "sine=frequency=300:duration=0.3" -ar 44100 wrong.mp3
ffmpeg -f lavfi -i "sine=frequency=1000:duration=0.1" -ar 44100 tick.mp3
```
