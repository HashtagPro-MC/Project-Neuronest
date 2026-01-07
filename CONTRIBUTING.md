# Contributing to AI-Neuronest

Thanks for your interest in contributing!

## Code of Conduct
By participating, you agree to follow our Code of Conduct (see `CODE_OF_CONDUCT.md`).

## Project Structure
- `arduino/` : Arduino firmware (MAX30102 + vibration motor logic)
- `esp32/` : ESP32 BLE bridge (UART -> BLE Notify)
- `ios/` : iOS application (CoreBluetooth, UI, logging)
- `docs/` : diagrams, prototypes, research notes

## How to Contribute
1) Fork the repo
2) Create a feature branch  
   - `feature/<short-name>` or `fix/<short-name>`
3) Make changes with clear commits
4) Open a Pull Request (PR) to `main`

## PR Requirements
- Describe the change and why it is needed
- Include screenshots for UI changes (iOS)
- Include serial logs or test notes for firmware changes (Arduino/ESP32)
- Keep PRs small and focused when possible

## Coding Standards
### Arduino / ESP32
- Avoid blocking delays (prefer `millis()` loops)
- Document pin maps at the top of the sketch
- Use stable output formats for data transfer (CSV or JSON lines)

### iOS
- Prefer clear separation of BLE layer and UI layer
- Don’t hardcode private keys, tokens, or personal health data

## Data & Privacy
Do not commit:
- Personal identifiable information (PII)
- Raw health data tied to a real identity
- API keys, secrets, or credentials

## Issue Templates (Recommended)
When filing an issue, include:
- Board type (Arduino model / ESP32 model)
- Sensor module type (MAX30102/MAX30105)
- OS version (iOS version)
- Logs (Arduino Serial / ESP32 logs)
- Steps to reproduce
