# Play Store Deployment

This project is prepared for a Google Play Android App Bundle release.

## Current Release

| Item | Value |
| --- | --- |
| App name | Catch The Eggs |
| Package name | `com.kazolhabib.catchtheeggs` |
| Version name | `1.0.0` |
| Version code | `1` |
| Export preset | `Android Play Store` |
| Bundle output | `releases/catch-the-eggs-v1.0.0.aab` |
| Target SDK | Android 15 / API 35 |
| Architecture | `arm64-v8a` |

## Build Checklist

1. Install Godot `4.6` with Android export templates.
2. Install Android SDK platform API 35, build tools, and command line tools.
3. Configure Godot Android export paths in Editor Settings.
4. Configure a release keystore in Godot's Android export settings.
5. Export the preset `Android Play Store` as a signed `.aab`.
6. Upload `releases/catch-the-eggs-v1.0.0.aab` to Play Console.
7. Run Play Console pre-review checks before production rollout.

## Store Listing Draft

Short description:

Catch falling eggs, avoid messy hazards, and chase your best score in a fast arcade game.

Full description:

Catch The Eggs is a colorful arcade game where quick movement and sharp timing keep your basket full. Birds drop eggs from the trees while hazards fall around you, and each round gets faster as your score climbs.

Catch normal eggs for points, grab golden eggs for bonuses, avoid poop, and jump over crawling bugs before they ruin your run. The controls are simple, the rounds are quick, and the challenge keeps building as you try to beat your high score.

Features:

- Fast egg-catching arcade gameplay
- Golden eggs for bonus points
- Dangerous poop hazards, including an instant game-over golden poop
- Crawling bugs to dodge or jump over
- Mobile-friendly touch controls
- High-score chasing for quick replay sessions

## Play Console Answers

Use these as a starting point, then confirm inside Play Console before submitting.

- App category: Game / Arcade
- Ads: No, unless ads are added later
- In-app purchases: No, unless purchases are added later
- Login/account: No
- Data collection: The current game appears local-only; verify no analytics, ads SDKs, or network features are added before declaring data safety
- Permissions: No special Android permissions are enabled in the export preset
- Target audience: Choose based on the intended age rating after completing the Play Console content rating questionnaire

## Assets Needed Before Submission

- App icon: already available at `Assets/UI/app_icon.png`
- Feature graphic: `store-assets/feature-graphic-1024x500.png`
- Phone screenshots: at least 2 gameplay screenshots
- Tablet screenshots: recommended if supporting tablets
- Privacy policy URL: may be required depending on Play Console declarations and target audience

Regenerate store assets:

```bash
python3 tools/create_store_assets.py
```

## Release Notes

Initial Play Store release of Catch The Eggs.
