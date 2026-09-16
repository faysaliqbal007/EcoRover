# EcoRover Hardware Test Checklist

Use this checklist after connecting the phone to the EcoRover Wi-Fi network.

## Pre-Test Setup
- [ ] Power on EcoRover
- [ ] Connect phone to Wi-Fi: **EcoRover**
- [ ] Launch EcoRover app
- [ ] Confirm header shows **ONLINE** (green dot)
- [ ] Place rover on a safe surface with clearance on all sides

---

## 1. Connectivity
- [ ] **1.1** App shows ONLINE
- [ ] **1.2** Camera stream appears (LIVE indicator shown)
- [ ] **1.3** Sensor values update continuously

## 2. Camera
- [ ] **2.1** Camera Fit/Fill toggle works
- [ ] **2.2** Zoom slider 1.0x → 3.0x works
- [ ] **2.3** Zoom − and + buttons work
- [ ] **2.4** Fullscreen button enters fullscreen
- [ ] **2.5** Fullscreen exits cleanly and returns to controller

## 3. Photo Capture
- [ ] **3.1** Tap camera icon → shows "Photo saved!"
- [ ] **3.2** Open phone gallery → EcoRover album contains photo
- [ ] **3.3** Photo filename format: `EcoRover_YYYY-MM-DD_HH-MM-SS.jpg`

## 4. Video Recording
- [ ] **4.1** Tap record button → recording indicator appears
- [ ] **4.2** Recording timer counts up (MM:SS)
- [ ] **4.3** Tap record again → shows "Video saved!"
- [ ] **4.4** Open phone gallery → EcoRover album contains video
- [ ] **4.5** Video plays back correctly

## 5. Manual Drive
- [ ] **5.1** Forward — rover moves forward, button highlights
- [ ] **5.2** Tap STOP — rover stops, highlight clears
- [ ] **5.3** Backward — rover moves backward
- [ ] **5.4** STOP
- [ ] **5.5** Left — rover curves left
- [ ] **5.6** Right — rover curves right
- [ ] **5.7** Diagonal ↖ (diag-fl) — works
- [ ] **5.8** Diagonal ↗ (diag-fr) — works
- [ ] **5.9** Diagonal ↙ (diag-bl) — works
- [ ] **5.10** Diagonal ↘ (diag-br) — works
- [ ] **5.11** SPIN L — spins counterclockwise in place
- [ ] **5.12** SPIN R — spins clockwise in place
- [ ] **5.13** FAST L — strafes directly left (mecanum)
- [ ] **5.14** FAST R — strafes directly right (mecanum)
- [ ] **5.15** Drive remains active without holding button (latched behavior)

## 6. Speed Control
- [ ] **6.1** Drag speed slider → rover changes speed
- [ ] **6.2** Speed label updates in real time
- [ ] **6.3** Speed syncs from /api/status

## 7. Tilt Servo
- [ ] **7.1** Drag tilt slider → servo moves
- [ ] **7.2** Degree display updates
- [ ] **7.3** 0° = one extreme, 180° = other extreme

## 8. Pan Servo
- [ ] **8.1** Drag pan slider → servo pans
- [ ] **8.2** −5° button steps down
- [ ] **8.3** +5° button steps up
- [ ] **8.4** Degree display updates

## 9. Mode Switch
- [ ] **9.1** Switch to Smart Mode → rover goes IDLE
- [ ] **9.2** Switch back to Manual Mode → rover stays IDLE

## 10. Autonomous Mode
- [ ] **10.1** Switch to Smart Mode
- [ ] **10.2** Tap START AUTO → rover navigates autonomously
- [ ] **10.3** Button changes to STOP AUTO
- [ ] **10.4** Mode status shows "Auto"
- [ ] **10.5** Tap STOP AUTO → rover stops
- [ ] **10.6** Auto speed slider changes speed

## 11. Motion Control
- [ ] **11.1** Tap ENABLE MOTION → button shows CALIBRATING...
- [ ] **11.2** Hold phone still in neutral position
- [ ] **11.3** After ~3s button changes to STOP MOTION
- [ ] **11.4** Tilt phone forward → rover drives forward
- [ ] **11.5** Tilt phone backward → rover reverses
- [ ] **11.6** Tilt phone left → rover strafes left
- [ ] **11.7** Tilt phone right → rover strafes right
- [ ] **11.8** Hold phone level → rover stops
- [ ] **11.9** Sensitivity slider changes responsiveness
- [ ] **11.10** Tap STOP MOTION → rover stops, UDP stops

## 12. RGB Control
- [ ] **12.1** Tap Red swatch → LED turns red
- [ ] **12.2** Tap Green swatch → LED turns green
- [ ] **12.3** Tap Blue swatch → LED turns blue
- [ ] **12.4** Tap Yellow swatch → LED turns yellow
- [ ] **12.5** Tap White swatch → LED turns white
- [ ] **12.6** RGB Power toggle OFF → LED off
- [ ] **12.7** Active color highlights correctly

## 13. Buzzer
- [ ] **13.1** Buzzer switch ON → buzzer sounds
- [ ] **13.2** Buzzer switch OFF → buzzer silent (auto mode)
- [ ] **13.3** State label shows ON/AUTO correctly

## 14. Headlight
- [ ] **14.1** Headlight switch ON → headlight on
- [ ] **14.2** Headlight switch OFF → returns to LDR auto mode
- [ ] **14.3** State label shows ON/AUTO correctly

## 15. Accessory Locking
- [ ] **15.1** Start Autonomous mode → RGB/Buzzer/Headlight controls dim
- [ ] **15.2** Disabled controls cannot be tapped
- [ ] **15.3** Note says "Automatic during Auto / Motion"
- [ ] **15.4** Stop Auto → controls re-enable
- [ ] **15.5** Start Motion mode → same locking behavior

## 16. Sensor Dashboard
- [ ] **16.1** Front Ultrasonic shows distance (cm) or NO ECHO
- [ ] **16.2** Rear Ultrasonic shows distance (cm) or NO ECHO
- [ ] **16.3** Right IR shows CLEAR or BLOCKED (red)
- [ ] **16.4** LDR shows integer value
- [ ] **16.5** Obstacle shows CLEAR / DETECTED / ALL BLOCKED

## 17. Emergency Stop
- [ ] **17.1** While driving: tap EMERGENCY STOP → rover stops immediately
- [ ] **17.2** Status returns to IDLE
- [ ] **17.3** Drive button highlight clears
- [ ] **17.4** During Motion: tap Emergency → UDP stops + rover stops

## 18. App Lifecycle Safety
- [ ] **18.1** While driving manually: minimize app → rover stops
- [ ] **18.2** During Motion: minimize app → UDP stops + rover stops
- [ ] **18.3** Return to app → controls still work after reconnect

## 19. Offline Handling
- [ ] **19.1** Disconnect from EcoRover Wi-Fi → app shows OFFLINE
- [ ] **19.2** Offline panel shown with Wi-Fi instructions
- [ ] **19.3** Reconnect to Wi-Fi → app automatically shows ONLINE
- [ ] **19.4** All controls resume working

## 20. Settings
- [ ] **20.1** Settings button opens settings screen
- [ ] **20.2** Controller/Camera IPs are displayed
- [ ] **20.3** Motion diagnostic values update while in Motion mode
- [ ] **20.4** Reset to defaults works

---

## Test Result Summary

| Category | Pass | Fail | Notes |
|----------|------|------|-------|
| Connectivity | | | |
| Camera | | | |
| Photo/Video | | | |
| Manual Drive | | | |
| Servos | | | |
| Autonomous | | | |
| Motion Control | | | |
| Accessories | | | |
| Sensors | | | |
| Emergency Stop | | | |
| Lifecycle | | | |
| Settings | | | |
