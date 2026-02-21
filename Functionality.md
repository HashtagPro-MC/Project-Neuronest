Got it — one short paragraph for every code name (U.S. English), so you can paste each one onto a slide.

BLEFocusManager
BLEFocusManager is the main Bluetooth “sensor pipeline” manager. It scans for the ESP32 device, connects to it, discovers the correct BLE services/characteristics, subscribes to notifications, and updates the app with the newest sensor readings in real time.

BLESerialManager
BLESerialManager is a Bluetooth “serial terminal” style manager. It connects to the ESP32 and acts like a simple monitor: it receives raw text or bytes from a notify characteristic, prints them into a log, and can optionally send commands back to the ESP32 through a write characteristic.

FocusPayload
FocusPayload is a structured data model that turns raw incoming data into readable values (like motion, heart rate, focus score, and sensor fields). It standardizes the sensor output so the UI and analysis features can use consistent, typed data instead of messy strings.

BLEDevice
BLEDevice is a lightweight model that represents a discovered BLE peripheral. It stores the device identity (UUID) and name so the app can list nearby devices and connect to the correct ESP32.

NeuronestAIService
NeuronestAIService is the network/API layer for AI. It sends prompts to the AI provider (for example Mistral/Gemini/etc.), applies configuration like model choice and temperature, and returns the generated response back to the app in a clean format.

NeuronestAICore
NeuronestAICore is the “brain” that shapes what the AI should do. It builds safe system instructions, formats user context, and defines the rules (non-medical, practical, easy-to-follow) so the AI responses stay consistent and appropriate.

NeuronestAIViewModel
NeuronestAIViewModel connects the AI system to the UI. It manages loading states, handles errors, stores results, and triggers calls to the AI layer when the user taps buttons—so the screen updates smoothly without blocking the app.

HomeView
HomeView is the main dashboard screen. It displays the primary tiles (games, reports, diet planner, BLE tools, etc.) and serves as the navigation hub that routes users to each feature.

FocusDashView
FocusDashView is the focus/attention analytics screen. It shows focus-related metrics and trends (like reaction time, accuracy, and focus score) and is typically where the user sees performance feedback over time.

BLESerialView
BLESerialView is the UI screen for the BLESerialManager. It provides buttons to scan/connect/disconnect, a text box to send messages, and a scrolling console-style log where live ESP32 data appears.

NeuronestAIView
NeuronestAIView is the UI that displays AI-generated coaching or summaries. It’s where users read recommendations (like brain-friendly tips, training insights, or diet guidance) that are produced by the AI layer.

ThemeStore
ThemeStore manages the app’s appearance settings. It controls theme toggles (dark/light), persists the user’s preference, and makes sure the style updates across all screens consistently.

AppState (if used)
AppState is the global app-level state container. It typically tracks shared flags like login status, onboarding completion, or feature availability, so different parts of the app can stay in sync.

NeuronestApp
NeuronestApp is the true starting point of the iOS app. It initializes dependencies (theme, auth, managers) and sets up the initial root view so the app launches into the correct flow.

ContentView
ContentView is the “router” view that decides what the user sees first. For example, it may choose between onboarding, login, or the HomeView depending on whether the user is already authenticated or finished setup.

If you paste your slide layout (or tell me “1 slide vs multiple slides”), I can compress these into shorter science-fair-friendly lines without losing meaning.
