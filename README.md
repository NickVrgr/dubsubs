# DubSubs

An offline subtitle teleprompter for movies that are dubbed with no
subtitles available (e.g. English-subtitled screenings of Spanish-dubbed
films in local cinemas). Load an `.srt` file and DubSubs displays each line
on screen in time with the movie — you control the clock, not a video file,
since the movie itself is playing on a separate screen.

Works fully offline on **Android**, **iOS**, and **Web**. Built with
Flutter.

|                        |                          |
| ---------------------- | ------------------------ |
| ![Library](docs/screenshots/library.png) | ![Settings](docs/screenshots/settings.png) |

## Features

- **Import any `.srt` file** from local storage — no account, no internet
  required. Imported files are stored on-device so your library survives
  app restarts.
- **Search OpenSubtitles.com** from inside the app and import a result
  directly — same subtitle database VLC uses. Requires a free API key (see
  [Configuration](#configuration) below) and **only works on Android/iOS**:
  OpenSubtitles' API mandates a custom `User-Agent` header, which browsers
  refuse to let JavaScript set, and their server also blocks the browser's
  CORS preflight — so this is unavailable in the web build. Use local
  `.srt` import on web instead.
- **Play / pause** the subtitle timeline, plus **±5s / ±10s** jump buttons
  and a scrubber for fast-forwarding or rewinding subtitles to match what's
  happening on screen.
- **Tap-to-sync**: pick the exact line being spoken from a scrollable list
  and the whole timeline snaps to it — the reliable way to get (re-)synced.
- **Mic-assisted drift correction (optional, best-effort)**: DubSubs can
  listen for speech-vs-silence transitions in the room and nudge the
  timeline when a line is about to start near a detected speech onset. This
  is **not** speech recognition or audio fingerprinting — it can't
  understand words or match across languages (the room's dubbed audio and
  your subtitles are usually in different languages, and there's no
  reference audio track to fingerprint against). It's a lightweight assist
  on top of manual tap-to-sync, not a replacement for it. No audio is ever
  recorded to disk or sent anywhere; only its loudness is inspected in
  memory, in real time.
- **Customizable display**: font size, font color, background darkness, and
  top/bottom position, all persisted between sessions.

## Getting started

Requires the Flutter **stable** channel.

```bash
flutter channel stable
flutter upgrade
flutter pub get
```

Run it:

```bash
flutter run -d chrome    # Web
flutter run -d <device>  # Android / iOS device or emulator/simulator
```

## Configuration

OpenSubtitles search needs an API key. It's optional — everything else
(including local `.srt` import) works without it.

1. Get a free key at <https://www.opensubtitles.com/en/consumers> (register
   an app; the free tier gives a shared daily download quota, currently
   ~100/day per key, no login required from the app itself).
2. Copy `env.json.example` to `env.json` and fill in your key:
   ```bash
   cp env.json.example env.json
   ```
3. Run or build with it:
   ```bash
   flutter run --dart-define-from-file=env.json
   flutter build apk --release --dart-define-from-file=env.json
   ```

`env.json` is gitignored — **never commit your API key**. For CI/CD (see
`.github/workflows/`), add it as a repository secret named
`OPENSUBTITLES_API_KEY` (Settings → Secrets and variables → Actions) and the
workflows will pick it up automatically.

Note that any key baked into a distributed build (the APK, the deployed web
bundle) is technically extractable by anyone who inspects the binary — this
is inherent to any client-only app calling a third-party API directly, the
same tradeoff VLC and other open-source players make with their bundled
OpenSubtitles credentials. It's a rate-limit identifier, not a secret that
grants account access, so that tradeoff is acceptable here.

## How syncing works

There's no video file inside the app — the movie plays on the cinema or TV
screen, and DubSubs just runs a clock you control:

1. Import your `.srt` file.
2. Hit play when the movie starts.
3. If it drifts out of sync, either jump by a fixed offset (±5s/±10s), drag
   the scrubber, or open **"Tap line to sync"** and tap the line being
   spoken right now — the timeline re-anchors to that line instantly.
4. Optionally toggle **sync assist** (the mic icon) to let DubSubs nudge
   the timeline automatically when it notices speech starting near an
   upcoming line. Keep tap-to-sync as your fallback — it's the one method
   that's always exactly right.

## Project structure

```
lib/
  models/     Plain data classes (SubtitleCue, SubtitleDocument, AppSettings, OpenSubtitlesResult)
  services/   SRT parsing, the sync clock, mic VAD assist, OpenSubtitles client, Hive storage, controllers
  screens/    Library, Player, Settings, OpenSubtitles search
  widgets/    Subtitle overlay, transport controls, tap-to-sync picker
```

## Testing

```bash
flutter analyze
flutter test
```

Unit tests cover the `.srt` parser and the sync clock's play/pause/seek/
offset math; widget tests drive the actual Player screen (tap-to-sync,
play/pause, malformed-file handling) through real user interactions.

## Roadmap ideas

- A backend proxy for OpenSubtitles so search also works on web (their API
  can't be called directly from a browser — see Features above).
- Adjustable playback speed for long-term drift correction.
- OpenSubtitles login support to raise the shared download quota.

## License

[MIT](LICENSE)
