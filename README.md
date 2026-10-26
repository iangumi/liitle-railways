# Little Railways — v0.3 Passenger Adventures

A colorful, **offline** Godot 4 Android-friendly train simulator designed for kids aged 5–10. No account, analytics, ads, external asset downloads, or in-app purchases.

> **Build status:** Godot project source is committed and smoke-test automation is configured. An APK has **not** been built or device-tested in this environment.

## What is playable

- Drive a train along a circular countryside railway, stopping at **Sunflower**, **Riverbend**, and **Pine Hill** stations.
- Open the doors when safely stopped to **pick up passengers**; close them to depart. Animated waiting passengers walk toward the train.
- Deliver passengers to the highlighted destination to earn **10–20 tickets** and **1–3 stars** for accurate stopping.
- Finish **10 short trips** in sequence, with no time limit, health bar, or penalties. Wrong stops simply offer helpful guidance.
- Unlock **Forest Steam** after 3 deliveries, and **Sky Bullet** after 7. Use **TRAINS** to switch between the unlocked models.
- Progress, ticket totals, best stars, current trip, train selection, and location are saved locally with Godot `ConfigFile`.
- **REPLAY** becomes available after trip 10; keep your tickets and train unlocks when you replay.
- Three camera views, smooth animated wheels and door panels, generated horn/engine/arrival audio, stylized stations and natural scenery.

## Quick start (desktop editor)

1. Install **Godot 4.4.1** (standard edition).
2. Import `project.godot` in Project Manager.
3. Press **F5**. On a computer, mouse clicks emulate touch input.
4. You start next to Sunflower Station. Press **DOORS** to board the first passengers, **CLOSE** to secure the doors, then **GO +** to drive toward Riverbend.
5. Use **SLOW -** and **BRAKE** near the destination. At a full stop beside the station, press **DOORS** to deliver passengers and collect tickets.

### Touch buttons

| Button | Action |
| --- | --- |
| GO + | Tap to increase power; hold to increase gradually |
| SLOW - | Tap/hold to lower power |
| BRAKE | Press/hold to slow down; power resets to zero |
| DOORS / CLOSE | Safely open/close the train doors at a station |
| HORN | Play a synthesized two-tone horn |
| CAMERA | Cycle chase, driver and scenic views |
| TRAINS | Cycle unlocked train models |
| REPLAY | Restart ten trips after completing the final delivery, retaining rewards |

**Safety helpers:** Doors only open when stopped near a station; power is locked to zero until the doors close. Station arrivals cannot be claimed twice.

## Automated tests

`godot --headless --path . --editor --import --quit`

`godot --headless --path . --script res://tests/smoke_test.gd`

GitHub Actions runs this smoke test on every push and pull request. Tests check the scene, train audio, braking/door interlock, 10 trips, scoring, unlock thresholds, replay, and save/load. This does **not** replace Android device testing.

## Android APK export

1. Install Godot Android export templates and Android SDK/JDK 17; set SDK/JDK paths in **Editor Settings > Export > Android**.
2. Add an **Android** export preset under **Project > Export**, with a unique application ID and your own signing credentials.
3. Export a **debug APK**, test it on a physical Android device in landscape mode, and check performance, multitouch and audio levels.
4. For publication, use a signed **AAB** and check Google's current Families policies.

No generated APK or signing keys are stored in this repository.

## Project layout

```text
project.godot           Godot settings
main.tscn              Main scene
main.gd                Touch HUD, cameras, game and station interactions
scripts/world.gd       Track, terrain, stations and decorations
scripts/train.gd       Three procedurally modeled locomotives and animated doors
scripts/passengers.gd  Waiting passengers and walking-to-train animation
scripts/mission.gd     Ten-trip campaign, rewards, progression and local save
scripts/sound_fx.gd    Procedural horn, motor and arrival chime
tests/smoke_test.gd    Headless gameplay and save/replay regression checks
.github/workflows/    Automatic headless regression checks
```

## Known limitations

- Only one rail loop; no track switches, rail construction, other moving trains, or collision-based traffic.
- Passengers use lightweight box/sphere shapes; their movement to the train is intentionally simplified.
- The three locomotive variants share one chassis, not three realistic physics models.
- Mission guidance is English-only, with no voice prompts yet.
- Saving occurs after boarding, deliveries, model changes, and when the app pauses or closes. A hard crash mid-trip may restore the last checkpoint.
- A Godot runtime and physical Android phone are still required for validation before calling this a release-ready game.

## Candidate v0.4 goals

New route branching, additional passenger types, animated level crossings, optional touch-simplified "Little Driver" mode, and a downloadable debug APK from CI.
