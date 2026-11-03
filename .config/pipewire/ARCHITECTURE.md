# PipeWire Audio Architecture & Evaluation Guide

This document explains the audio architecture, active devices, configuration parameters, and practical evaluation metrics for this system.

---

## 1. Core Philosophy: Balancing 4 Audio Paradigms

A modern Linux desktop audio system balances four different paradigms:

```
                  ┌─────────────────────────────────────────┐
                  │          Audio System Goals             │
                  └────────────────────┬────────────────────┘
          ┌─────────────────┬──────────┴──────────┬─────────────────┐
          ▼                 ▼                     ▼                 ▼
   [ Audiophile ]    [ DSP Correction ]    [ Low Latency ]    [ Convenience ]
    Bit-perfect &     EasyEffects EQ &      DAW-grade speed   Auto-routing &
    highest quality   acoustic filters      zero XRUN drop    per-app volume
```

1. **Audiophile Fidelity**: Maximize signal quality (highest resampling quality, high-end dithering, native DAC sample rates).
2. **DSP Acoustic Correction**: Equalize frequency response and reduce ear fatigue via EasyEffects.
3. **Low Latency (Pro-Audio)**: Keep buffer sizes small (5ms–20ms) with zero audio dropouts (`XRUN = 0`).
4. **Desktop Convenience**: Smooth mixing across browsers, games, Discord, and media players without manual patching.

---

## 2. Hardware Topology & Routing

### Connected Audio Devices
- **Primary DAC / Interface (Sink & Source)**:
  - `alsa_output.usb-AT_AT-UMX3-00.analog-stereo` (Audio-Technica AT-UMX3)
  - `alsa_input.usb-AT_AT-UMX3-00.analog-stereo`
- **Secondary Devices**:
  - `fifine Microphone` (USB Microphone / monitoring jack)
  - `Navi 48 HDMI/DP Audio Controller` (GPU digital output to display)
  - `Radeon High Definition Audio` / `Ryzen HD Audio` (Motherboard onboard)

### Audio Signal Flow Diagram

```mermaid
flowchart TD
    subgraph Playback_Flow["Playback Flow (Audio Output)"]
        App[Apps: Browser, Spotify, Games] -->|Pulse / ALSA / JACK| EESink["easyeffects_sink (ee_sink_group)"]
        EESink -->|DSP: EQ, BassEnhancer| UMX3_Out["AT-UMX3 Analog Stereo (Physical DAC)"]
        UMX3_Out --> Headphones[Headphones / Monitor]
    end

    subgraph Capture_Flow["Capture Flow (Microphone Input)"]
        Mic[AT-UMX3 Mic / fifine Mic] -->|Physical Input| EESource["ee_source_group"]
        EESource -->|Noise Gate / Filter| EESinkVirtual["easyeffects_source (Virtual Mic)"]
        EESinkVirtual -->|Clean Voice| ChatApp[Discord / Browser / Zoom]
    end
```

---

## 3. How to Evaluate Audio Quality (The 4 Metrics)

To evaluate whether your audio setup is operating properly, monitor these four specific metrics:

| Metric | Tool | What to Check | Ideal Target |
| :--- | :--- | :--- | :--- |
| **1. Stability (XRUN)** | `pw-top` | Column: `ERR` | Exactly `0`. No increments during high CPU load. |
| **2. Buffer Latency** | `pw-top` | Columns: `QUANT`, `RATE` | `QUANT` / `RATE` $\approx$ 5ms to 20ms. |
| **3. DSP Overhead** | `pw-top` | Columns: `WAIT`, `BUSY` | `BUSY` time below 500µs per cycle (< 5% CPU). |
| **4. Routing Purity** | `wpctl status` | Sinks & Sources tree | No unused dummy drivers or duplicate bridges. |

### How to use `pw-top`
Run `pw-top` in your terminal to see real-time performance:
```bash
pw-top
```
- **`ERR` Column**: Counts XRUNs (buffer under/overruns). If this number increases, you will hear audio crackling/pops.
- **`QUANT` Column**: Current buffer size in frames (e.g., `1024` or `512`).
- **`RATE` Column**: Active clock rate (e.g., `44100` or `48000`).
- **Formula for latency**: $\text{Latency (seconds)} = \frac{\text{QUANT}}{\text{RATE}}$
  - Example: $\frac{1024}{48000} \approx 21.3\text{ ms}$
  - Example: $\frac{256}{48000} \approx 5.3\text{ ms}$

---

## 4. Configuration Deep-Dive (Why These Values?)

The configuration files reside in `~/.config/pipewire/`.

### 1. Resampling Quality (`resample.quality = 14`)
- **Location**: `client.conf.d/stream-properties.conf`, `pipewire-pulse.conf.d/stream-properties.conf`
- **Default**: `4` (standard polyphase filter)
- **Why `14`?**: Uses the maximum SOXR / libspeexdsp filter quality. Frequency response distortion and aliasing artifacts are pushed beyond $-140\text{ dB}$, completely imperceptible to human ears.

### 2. Dithering (`dither.method = wannamaker3`)
- **Location**: `pipewire-pulse.conf.d/stream-properties.conf`, `client.conf.d/stream-properties.conf`
- **Why `wannamaker3`?**: Wannamaker-3 noise shaping moves quantization noise into higher, less sensitive frequency bands (above 18kHz). This yields cleaner micro-details across all PulseAudio, ALSA, and native PipeWire streams.

### 3. Native Sample Rates & Buffer Size (`allowed-rates` & `quantum`)
- **Location**: `pipewire.conf.d/clock-rate.conf`
  ```spa-json
  context.properties = {
      default.clock.rate          = 44100
      default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
      default.clock.quantum       = 512
      default.clock.min-quantum   = 128
      default.clock.max-quantum   = 2048
  }
  ```
- **Why?**:
  - `44100 Hz`: Standard for CD audio, music files, and YouTube music.
  - `48000 Hz`: Standard for video games, movies, and system audio.
  - `quantum = 512`: Lowers base buffer latency to ~10.6ms (at 48kHz) or ~11.6ms (at 44.1kHz), providing snappier feedback without causing XRUNs.

### 4. Low-Latency PulseAudio Settings
- **Location**: `pipewire-pulse.conf.d/pulse-properties.conf`
  ```spa-json
  pulse.properties = {
      pulse.min.req          = 256/48000     # 2.7ms minimum request
      pulse.min.quantum      = 256/48000     # 2.7ms minimum quantum
      pulse.default.format   = F32           # 32-bit floating point precision
  }
  ```
- **Why?**: Forces PulseAudio clients (e.g. Discord, browsers) to process audio with 32-bit floating-point precision and low latency buffers.

---

## 5. Quickshell Integration & `PwObjectTracker`

Quickshell controls PipeWire volume natively through C++ bindings via `Quickshell.Services.Pipewire`.

### The `PwObjectTracker` Gotcha
In QML (`components/Volume.qml`):
```qml
readonly property var sink: Pipewire.defaultAudioSink

// REQUIRED: Binds the node to enable mutation and property changes
PwObjectTracker {
    objects: volumeRoot.sink ? [volumeRoot.sink] : []
}
```
- **Why is `PwObjectTracker` required?**:
  To conserve memory and CPU cycles, Quickshell does **not** listen to events or enable mutation on all system audio nodes by default.
  Registering a node inside `PwObjectTracker` instructs the C++ engine to hook PipeWire events to that object. Without it, reading properties may work, but modifying volume (`sink.audio.volume = ...`) or mute (`sink.audio.muted = ...`) will fail silently.

---

## 6. Emergency Runbook (Quick Troubleshooting)

### 1. Check current status
```bash
wpctl status
```
Look for the `*` symbol next to `Sinks` (output) and `Sources` (input). The asterisk indicates the current default device.

### 2. Switch Default Sink / Source manually
If audio switches to the wrong device (e.g., HDMI instead of AT-UMX3):
```bash
# 1. Find the ID from 'wpctl status' (e.g. 87 for AT-UMX3)
# 2. Set default:
wpctl set-default <ID>

# Example:
wpctl set-default 87
```

### 3. Adjust volume from CLI
```bash
# Set volume to 80%
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.8

# Toggle mute
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

### 4. Restart Audio Stack (Zero Reboots Needed)
If the audio service becomes unresponsive:
```bash
systemctl --user restart pipewire wireplumber pipewire-pulse
```

---

## 7. Applied Optimizations & Next Steps

### Completed Optimizations:
1. **Low Latency Buffer Tuning (`quantum = 512`)**:
   - Base buffer latency dropped from ~21.3ms to ~10.6ms.
2. **Unified Wannamaker-3 Dithering**:
   - Configured `dither.method = wannamaker3` across both PulseAudio and ALSA/PipeWire client streams.
3. **Consolidated Drop-in Configurations**:
   - Clocks and quantum parameters are now cleanly centralized in `pipewire.conf.d/clock-rate.conf`.

### Future Ideas to Explore:
1. **EasyEffects Dynamic Bypass**:
   - Route specific audiophile players (e.g. mpv, strawberry) directly to the AT-UMX3 hardware sink when strict bit-perfect playback is preferred over DSP.
2. **WirePlumber 0.5 Device Priority Rules**:
   - Define custom WirePlumber rules in `~/.config/wireplumber/wireplumber.conf.d/` if automatic device switching needs explicit custom priorities.
