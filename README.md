############################# 🧠 Neuronest

<p align="center">
    <img width="579" height="379" alt="image" src="https://github.com/user-attachments/assets/c42b0233-d0d4-4c7c-9533-7ebbdd46bfde" />
</p>

<p align="center">
<strong>AI-Powered Biofeedback & Cognitive Assistance Platform</strong><br>
Wearable hardware meets real-time intelligence.
</p>

<p align="center">
  <a href="CHANGELOG.md">Changelog</a> |
  <a href="#architecture">Architecture</a> |
  <a href="#roadmap">Roadmap</a> |
  <a href="https://github.com/YOURUSERNAME/Neuronest/issues">Report Issue</a> |
  <a href="https://discord.gg/nbZBCArAWn">Join Discord</a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/HashtagPro-MC/Project-Neuronest?style=for-the-badge">
  <img src="https://img.shields.io/github/forks/HashtagPro-MC/Project-Neuronest?style=for-the-badge">
  <img src="https://img.shields.io/github/license/HashtagPro-MC/Project-Neuronest?style=for-the-badge">
</p>

---

# 🚀 Introduction

<p align="center">
Neuronest is a full-stack intelligent wearable system designed to monitor cognitive focus and physiological stability in real time.
</p>

<p align="center">
It integrates embedded hardware, Bluetooth Low Energy communication, advanced signal filtering, and AI-driven cognitive coaching into a scalable architecture.
</p>

<p align="center">
This is not just an app — it is a modular intelligence platform.
</p>

---

# 🎯 Problem Statement

Most wearable devices collect physiological data — but do not interpret it intelligently.

Neuronest bridges the gap between:

<p align="center">
📡 Sensor Data → 🧠 Signal Processing → 🤖 AI Interpretation → 🔔 Adaptive Feedback
</p>

Instead of passive tracking, Neuronest delivers actionable cognitive assistance.

---

# 🧠 Core System Layers

---

## 1️⃣ Hardware Layer

**Components**
- ESP32 WROOM-32
- MAX30105 IR Pulse Sensor
- MPU6050 Motion Sensor
- PWM Vibration Motor

**Responsibilities**
- Real-time sampling
- Signal filtering (noise reduction & smoothing)
- Focus state classification
- BLE packet transmission

Focus States:
- `NO_FINGER`
- `FOCUSED`
- `NOT_FOCUSED`

---

## 2️⃣ Bluetooth Communication Layer

Built with CoreBluetooth.

Features:
- Auto BLE scanning
- Peripheral discovery
- Characteristic subscription
- Motor control write characteristic
- Real-time payload streaming

Designed for low-latency communication (<50ms typical).

---

## 3️⃣ Application Layer (SwiftUI + MVVM)

Core Components:
- `BLEFocusManager`
- `FocusPayload`
- `NeuronestAIViewModel`
- `ThemeStore`
- `HomeView`
- `FocusDashView`

Responsibilities:
- State management
- Focus visualization
- Live telemetry
- Motor triggering interface
- AI coaching display

Architecture:
MVVM for clear separation between logic and UI.

---

## 4️⃣ AI Intelligence Layer

AI engine generates structured cognitive guidance.

Responsibilities:
- Interpret focus states
- Generate contextual coaching
- Maintain safety boundaries
- Produce structured responses

Designed for future expansion into:
- Personalized models
- Session memory
- Longitudinal pattern detection

---

# 🏗 System Architecture

<p align="center">

ESP32 Sensors  
⬇  
Signal Filtering & Classification  
⬇  
Bluetooth Low Energy  
⬇  
SwiftUI App  
⬇  
AI Coaching Engine  
⬇  
User Feedback (UI + Motor)

</p>

---

# 🛠 Installation

## iOS App

```bash
git clone https://github.com/HashtagPro-MC/Project-Neuronest
