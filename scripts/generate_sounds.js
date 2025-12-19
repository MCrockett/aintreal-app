#!/usr/bin/env node
/**
 * Generate WAV sound files matching the web game's tones.
 * Based on the sounds object in aintreal-game/ui/game.js
 *
 * Web game sounds use Web Audio API with these patterns:
 * - click: 800Hz, 0.1s, sine
 * - roundStart: ascending beeps (400->500->600Hz)
 * - tick: 600Hz, 0.05s, sine
 * - select: 500Hz, 0.1s, triangle
 * - correct: ascending (523->659->784Hz) C-E-G
 * - wrong: descending (400->300Hz) sawtooth
 * - bonus: sparkle (800->1000->1200Hz)
 * - reveal: dramatic (200->400Hz)
 * - victory: fanfare (523->659->784->1047Hz) C-E-G-C
 */

const fs = require('fs');
const path = require('path');

const SAMPLE_RATE = 44100;
const OUTPUT_DIR = path.join(__dirname, '..', 'assets', 'sounds');

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

// Generate a sine wave sample
function sineWave(t, frequency) {
  return Math.sin(2 * Math.PI * frequency * t);
}

// Generate a triangle wave sample
function triangleWave(t, frequency) {
  const period = 1 / frequency;
  const phase = (t % period) / period;
  return 4 * Math.abs(phase - 0.5) - 1;
}

// Generate a sawtooth wave sample
function sawtoothWave(t, frequency) {
  const period = 1 / frequency;
  const phase = (t % period) / period;
  return 2 * phase - 1;
}

// Apply envelope with soft attack to prevent click/pop at start
function envelope(t, duration, startVolume = 0.3, attackTime = 0.01) {
  // Fade-in over attack time to prevent audio distortion/clicks
  let attackMultiplier = 1.0;
  if (t < attackTime) {
    // Use smoother ease-in-out curve (sine squared) for gentler attack
    const progress = t / attackTime;
    attackMultiplier = Math.pow(Math.sin(progress * Math.PI / 2), 2);
  }

  // Exponential decay for natural sound
  const decayRate = Math.log(startVolume / 0.01) / duration;
  return startVolume * Math.exp(-decayRate * t) * attackMultiplier;
}

// Generate a tone with given parameters
function generateTone(frequency, duration, waveType = 'sine', volume = 0.3) {
  const numSamples = Math.floor(SAMPLE_RATE * duration);
  const samples = new Float32Array(numSamples);

  // Calculate attack time based on frequency - lower frequencies need longer attack
  // to prevent distortion. At least 4 full wave cycles for smooth attack.
  const minCycles = 4;
  const attackFromFreq = minCycles / frequency;
  // More aggressive minimum attack for low frequencies (50ms for 200Hz, 25ms for 400Hz)
  const attackTime = Math.max(0.025, Math.min(0.06, attackFromFreq));

  for (let i = 0; i < numSamples; i++) {
    const t = i / SAMPLE_RATE;
    let sample;

    switch (waveType) {
      case 'triangle':
        sample = triangleWave(t, frequency);
        break;
      case 'sawtooth':
        sample = sawtoothWave(t, frequency);
        break;
      case 'sine':
      default:
        sample = sineWave(t, frequency);
    }

    // Apply envelope for natural decay with frequency-aware attack
    samples[i] = sample * envelope(t, duration, volume, attackTime);
  }

  return samples;
}

// Combine multiple tones with delays
function combineTones(tones, addSilencePrefix = true) {
  // Add a longer silence prefix to prevent audio initialization distortion on mobile
  const silencePrefix = addSilencePrefix ? 0.035 : 0; // 35ms silence at start

  // Calculate total duration
  let maxEnd = 0;
  for (const tone of tones) {
    const end = silencePrefix + tone.delay + tone.duration;
    if (end > maxEnd) maxEnd = end;
  }

  // Add a small fade-out buffer at the end
  const fadeOutTime = 0.01;
  maxEnd += fadeOutTime;

  const numSamples = Math.floor(SAMPLE_RATE * maxEnd);
  const combined = new Float32Array(numSamples);

  for (const tone of tones) {
    const samples = generateTone(tone.frequency, tone.duration, tone.waveType, tone.volume);
    const startSample = Math.floor((silencePrefix + tone.delay) * SAMPLE_RATE);

    for (let i = 0; i < samples.length && startSample + i < numSamples; i++) {
      combined[startSample + i] += samples[i];
    }
  }

  // Apply gentle fade-out at the end to prevent end clicks
  const fadeOutSamples = Math.floor(fadeOutTime * SAMPLE_RATE);
  const fadeOutStart = numSamples - fadeOutSamples;
  for (let i = fadeOutStart; i < numSamples; i++) {
    const fadeProgress = (i - fadeOutStart) / fadeOutSamples;
    combined[i] *= Math.cos(fadeProgress * Math.PI / 2); // Smooth cosine fade-out
  }

  // Normalize to prevent clipping
  let maxAmp = 0;
  for (let i = 0; i < combined.length; i++) {
    if (Math.abs(combined[i]) > maxAmp) maxAmp = Math.abs(combined[i]);
  }
  if (maxAmp > 0.9) {
    const scale = 0.9 / maxAmp;
    for (let i = 0; i < combined.length; i++) {
      combined[i] *= scale;
    }
  }

  return combined;
}

// Convert float samples to 16-bit PCM WAV file buffer
function samplesToWav(samples) {
  const numChannels = 1;
  const bitsPerSample = 16;
  const bytesPerSample = bitsPerSample / 8;
  const blockAlign = numChannels * bytesPerSample;
  const byteRate = SAMPLE_RATE * blockAlign;
  const dataSize = samples.length * bytesPerSample;
  const fileSize = 36 + dataSize;

  const buffer = Buffer.alloc(44 + dataSize);

  // WAV header
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(fileSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // fmt chunk size
  buffer.writeUInt16LE(1, 20); // audio format (PCM)
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(SAMPLE_RATE, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(bitsPerSample, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  // Audio data
  for (let i = 0; i < samples.length; i++) {
    const sample = Math.max(-1, Math.min(1, samples[i]));
    const intSample = Math.floor(sample * 32767);
    buffer.writeInt16LE(intSample, 44 + i * 2);
  }

  return buffer;
}

// Save samples as WAV file
function saveWav(filename, samples) {
  const wavBuffer = samplesToWav(samples);
  const filepath = path.join(OUTPUT_DIR, filename);
  fs.writeFileSync(filepath, wavBuffer);
  console.log(`Generated: ${filename}`);
}

// Generate all game sounds
console.log('Generating game sounds...\n');

// tick: 600Hz, 0.05s, sine
saveWav('tick.wav', generateTone(600, 0.05, 'sine', 0.15));

// time_up: warning tone - slightly longer tick at lower pitch
saveWav('time_up.wav', generateTone(440, 0.1, 'sine', 0.2));

// correct: Happy ascending C-E-G
saveWav('correct.wav', combineTones([
  { frequency: 523, duration: 0.15, waveType: 'sine', volume: 0.3, delay: 0 },
  { frequency: 659, duration: 0.15, waveType: 'sine', volume: 0.3, delay: 0.1 },
  { frequency: 784, duration: 0.2, waveType: 'sine', volume: 0.3, delay: 0.2 },
]));

// wrong: Sad descending
saveWav('wrong.wav', combineTones([
  { frequency: 400, duration: 0.2, waveType: 'sawtooth', volume: 0.2, delay: 0 },
  { frequency: 300, duration: 0.3, waveType: 'sawtooth', volume: 0.15, delay: 0.15 },
]));

// bonus: Sparkle effect
saveWav('bonus.wav', combineTones([
  { frequency: 800, duration: 0.1, waveType: 'sine', volume: 0.25, delay: 0 },
  { frequency: 1000, duration: 0.1, waveType: 'sine', volume: 0.25, delay: 0.08 },
  { frequency: 1200, duration: 0.15, waveType: 'sine', volume: 0.3, delay: 0.16 },
]));

// streak: Same as bonus but slightly different timing
saveWav('streak.wav', combineTones([
  { frequency: 700, duration: 0.1, waveType: 'sine', volume: 0.25, delay: 0 },
  { frequency: 900, duration: 0.1, waveType: 'sine', volume: 0.25, delay: 0.07 },
  { frequency: 1100, duration: 0.15, waveType: 'sine', volume: 0.3, delay: 0.14 },
  { frequency: 1300, duration: 0.15, waveType: 'sine', volume: 0.25, delay: 0.21 },
]));

// round_start: Ascending beeps
saveWav('round_start.wav', combineTones([
  { frequency: 400, duration: 0.15, waveType: 'sine', volume: 0.25, delay: 0 },
  { frequency: 500, duration: 0.15, waveType: 'sine', volume: 0.25, delay: 0.15 },
  { frequency: 600, duration: 0.2, waveType: 'sine', volume: 0.3, delay: 0.3 },
]));

// reveal: Dramatic reveal - starts at higher frequency to avoid low-freq distortion
saveWav('reveal.wav', combineTones([
  { frequency: 300, duration: 0.35, waveType: 'sine', volume: 0.15, delay: 0 },
  { frequency: 500, duration: 0.3, waveType: 'sine', volume: 0.25, delay: 0.25 },
]));

// victory: Fanfare C-E-G-C - reduce overlapping volumes to prevent distortion
saveWav('victory.wav', combineTones([
  { frequency: 523, duration: 0.25, waveType: 'sine', volume: 0.2, delay: 0 },
  { frequency: 659, duration: 0.25, waveType: 'sine', volume: 0.2, delay: 0.2 },
  { frequency: 784, duration: 0.25, waveType: 'sine', volume: 0.2, delay: 0.4 },
  { frequency: 1047, duration: 0.35, waveType: 'sine', volume: 0.25, delay: 0.6 },
]));

// game_over: Similar to wrong but more final - higher frequencies to avoid distortion
saveWav('game_over.wav', combineTones([
  { frequency: 400, duration: 0.3, waveType: 'sine', volume: 0.15, delay: 0 },
  { frequency: 300, duration: 0.4, waveType: 'sine', volume: 0.2, delay: 0.25 },
]));

console.log('\nAll sounds generated successfully!');
console.log(`Output directory: ${OUTPUT_DIR}`);
