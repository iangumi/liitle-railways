# Little Railways — v0.2 Driving Experience

A colorful, **offline-first** Godot 4 railway-driving prototype for children ages 5–10. No external assets, accounts, advertisements, or online access.

> Status: Source code is ready for editor/device testing. **This is not yet a tested Android APK.**

## Features

- One stylized locomotive with **six visible, animated wheels**, windows, stripes, and headlights.
- Smooth forward driving on a complete circular railway. Train heading follows the track tangent.
- **Large landscape touch controls** with press-and-hold acceleration/braking.
- Three camera modes: chase, elevated driver view, and scenic view.
- A procedurally generated railway world with three stations, platforms, trees, hills, and a pond.
- **Audible horn, engine rumble, and station arrival chime**, generated from PCM samples at startup (no licensed audio assets or network requests).
- Station arrival announcement when stopping near a station.
- Responsive HUD displaying speed and throttle power.

## Play in Godot

1. Install **Godot 4.3+** (standard edition).
2. Open Godot Project Manager, click Import, and select `project.godot`.
3. Run the project with **F5**. Mouse clicks emulate touch.
4. The first scene is `main.tscn`. All geometry is built at runtime.

### Controls

| Control | What happens |
|---|---|
| **GO +** | Tap to increase throttle 20%; hold to keep increasing |
| **SLOW -** | Tap to decrease throttle 20%; hold to decrease continuously |
| **BRAKE** | Tap to brake sharply and set throttle to zero; hold for stronger braking |
| **HORN** | Play a two-tone horn |
| **CAMERA** | Cycle chase → driver → scenic views |

Stop near a station at low speed to hear a pleasant arrival chime.

## Android export

1. Install the corresponding Godot Android export templates.
2. Install Android SDK and JDK 17; set their paths under **Editor > Editor Settings > Export > Android**.
3. Select **Project > Export > Add… > Android**, set a unique package ID (for example `com.example.littlerailways`), and configure local debug signing.
4. Export an **APK**, install it on an Android phone, and test landscape orientation and multi-touch interaction.
5. For Play Store releases, use **AAB** and production signing. Review current Google Play Families policies first.

No Android SDK / Godot executable is available to this assistant for a verified build in this environment.

## Project layout

```text
project.godot           Godot 4 project settings
main.tscn              Entry scene
main.gd                Mobile HUD, input, camera, station feedback
scripts/world.gd       Procedural terrain, railway, stations, scenery
scripts/train.gd       Model, track-following movement and wheel animation
scripts/sound_fx.gd    Offline horn, motor and arrival chime synthesizer
tests/smoke_test.gd    Headless behavioral smoke test
.github/workflows      GitHub Actions regression check
```

## Known limitations

- Only one train and one circular route. No track junctions yet.
- Buildings and station signs are simple procedural shapes.
- There are no passengers, missions, unlocks or saved progress yet.
- Audio is synthetic. Real-world sound design can replace it later.
- Performance, visuals, and Android touch still need device testing.

## Planned v0.3

1. Passenger pickup and animated doors.
2. Station stop scoring and 10 short missions.
3. Three selectable locomotives and unlockable liveries.
4. Save/resume progress locally.
