# Little Railways — Prototype v0.1

A child-friendly, offline 3D Android train game prototype built with Godot 4 and GDScript.

## Play now
1. Install Godot 4 (standard edition) on a computer.
2. Import this directory using `project.godot`.
3. Run the main scene (F6) or the project (F5).
4. Tap GO to accelerate, SLOW to reduce power, BRAKE to stop, CAMERA to change view.

## Android APK
Install Godot Android export templates, Android SDK and JDK 17; configure paths in Godot Editor Settings. Create an Android export preset (Project > Export > Add > Android), set package ID and signing credentials, then Export Project as APK. Android export cannot be performed in this environment because Godot and Android build tools are not installed.

## Prototype limitations
This is an early playable source prototype, not a finished game: circular railway, three decorative stations, one red train, basic controls. Horn is visual text only; audio, passengers, train selection, missions, and track building are not implemented. Test in Godot before exporting to Android.

## Next milestones
1. Improve touch UI sizing, audio and horn.
2. Station stop zones, boarding animations and mission rewards.
3. Additional trains and scenery.
4. Track-building sandbox and route switching.
