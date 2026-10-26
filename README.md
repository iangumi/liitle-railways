# Little Railways — v0.4 Android Debug Build

A colorful, **offline** Godot 4 Android-friendly train simulator designed for kids aged 5–10. No account, analytics, ads, external asset downloads, or in-app purchases.

> **Build status:** The GitHub Actions workflow is configured to build a signed **debug APK** and upload it for testing. The APK and device behavior are **not confirmed** until the workflow succeeds and someone installs it on Android.

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

## Get the installable Android debug APK (GitHub Actions)

1. Open **[GitHub Actions → Build Android debug APK](https://github.com/iangumi/liitle-railways/actions/workflows/android-debug-apk.yml)**.
2. Open the newest successful run (green check). If there is no run yet, choose **Run workflow** on the `main` branch.
3. Scroll to **Artifacts**, download `little-railways-v0.4-debug-apk` and extract the ZIP.
4. Transfer `little-railways-debug.apk` to the Android phone, open it, and allow **Install unknown apps** for the app you used to open the APK if Android prompts.
5. Launch **Little Railways** and test the checklist below.

**This is a debug build, not a Play Store release.** The download is a build artifact, not a GitHub Release. Artifacts are retained 30 days and GitHub may require signing in. If a new APK refuses to install over the old one, uninstall the old test app and retry. This happens if builds were signed with different ephemeral debug keys (uninstalling may remove local save data).

To keep debug updates installable **without uninstalling**, create a stable local test keystore (alias `androiddebugkey`, password `android`) and add its base64 contents as the private GitHub Actions secret `ANDROID_DEBUG_KEYSTORE_BASE64`. **Never commit the keystore or a production key.** This secret is optional and is not required to build a first debug APK.

The CI build uses **Godot 4.4.1**, matching export templates, Java 17 and the Android SDK. Its workflow imports scripts, runs gameplay smoke tests, exports APK, checks the APK archive and uploads its SHA256 checksum. Builds stop if earlier tests fail.

### Local Android export

1. Install Godot 4.4.1 and matching Android export templates.
2. Install Android SDK and JDK 17, set both paths under **Editor Settings → Export → Android**.
3. Set debug signing in Godot; `export_presets.cfg` includes only nonsecret options.
4. Run `python3 tools/verify_android_build.py`, then `godot --headless --path . --editor --import --quit` and `godot --headless --path . --script res://tests/smoke_test.gd`.
5. Export the `Android` debug preset to `build/little-railways-debug.apk`, or execute `godot --headless --path . --export-debug Android build/little-railways-debug.apk`.

### Physical Android test checklist

- [ ] App installs and opens in **landscape** without crashing.
- [ ] HUD/buttons fit on the phone and remain touchable near the screen edges.
- [ ] GO, SLOW and BRAKE change train motion; doors cannot open while moving.
- [ ] Doors allow passenger boarding when stopped at Sunflower.
- [ ] Arrival at Riverbend completes trip 1, awards stars/tickets and moves to the next mission.
- [ ] HORN and arrival chime are audible; CAMERA cycles all three views.
- [ ] Background/close/reopen preserves progress and train choice.
- [ ] Longer driving doesn't freeze, overheat, or drop frames excessively.

For eventual Google Play publication, we'll need a signed production AAB and the Families policy requirements, not this debug artifact.

## Project layout

```text
export_presets.cfg      Safe Android export preset (no secrets)
project.godot           Godot settings
main.tscn              Main scene
main.gd                Touch HUD, cameras, game and station interactions
scripts/world.gd       Track, terrain, stations and decorations
scripts/train.gd       Three procedurally modeled locomotives and animated doors
scripts/passengers.gd  Waiting passengers and walking-to-train animation
scripts/mission.gd     Ten-trip campaign, rewards, progression and local save
scripts/sound_fx.gd    Procedural horn, motor and arrival chime
tests/smoke_test.gd    Headless gameplay and save/replay regression checks
.github/workflows/    Automated Godot tests + Android debug APK artifact
tools/                  Standalone static Android build preflight
```

## Known limitations

- Only one rail loop; no track switches, rail construction, other moving trains, or collision-based traffic.
- Passengers use lightweight box/sphere shapes; their movement to the train is intentionally simplified.
- The three locomotive variants share one chassis, not three realistic physics models.
- Mission guidance is English-only, with no voice prompts yet.
- Saving occurs after boarding, deliveries, model changes, and when the app pauses or closes. A hard crash mid-trip may restore the last checkpoint.
- A successful GitHub Actions build and physical Android gameplay session are still required before calling this a verified playable build.

## Candidate v0.5 goals

Add touch-simplified **Little Driver** mode for ages 5–6, responsive layout on small phones, animated level crossings, and a first performance-tested mobile visual pass.
