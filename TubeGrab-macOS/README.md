# TubeGrab for macOS

A native macOS YouTube video downloader built with SwiftUI.

## Features

- Modern dark-themed UI matching the original Python version
- Download queue with concurrent downloads (up to 3 simultaneous)
- Multiple quality options (4K, 1080p, 720p, 480p, 360p, Audio Only)
- Real-time progress tracking with speed and file size display
- Clipboard integration for quick URL pasting
- Configurable download folder

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+ (included with Xcode Command Line Tools)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed via Homebrew
- [ffmpeg](https://ffmpeg.org/) (optional, for some video formats)

## Building

### 1. Install Dependencies

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install yt-dlp (required)
brew install yt-dlp

# Install ffmpeg (optional but recommended)
brew install ffmpeg
```

### 2. Build the App

```bash
cd TubeGrab-macOS
./build.sh
```

This creates `TubeGrab.app` in the current directory.

### 3. Run or Install

```bash
# Run directly
open TubeGrab.app

# Or install to Applications
cp -r TubeGrab.app /Applications/
```

## Project Structure

```
TubeGrab-macOS/
├── Package.swift           # Swift Package Manager config
├── build.sh               # Build script (creates .app bundle)
├── README.md
└── Sources/TubeGrab/
    ├── TubeGrabApp.swift   # App entry point
    ├── ContentView.swift   # Main UI view
    ├── Models.swift        # Data models & DownloadManager
    └── Theme.swift         # Colors & design constants
```

## Usage

1. Launch TubeGrab
2. Paste a YouTube URL (or click the clipboard button)
3. Select video quality from the dropdown
4. Click "Add to Queue"
5. Downloads start automatically (up to 3 concurrent)

## Supported URLs

- `youtube.com/watch?v=...`
- `youtu.be/...`
- `youtube.com/shorts/...`

## Downloads Location

Default: `~/Videos/TubeGrab/`

Click the folder path in the footer to change the download location.

## Troubleshooting

**"yt-dlp not found"**
- Install yt-dlp: `brew install yt-dlp`

**"ffmpeg required"**
- Some video formats need ffmpeg: `brew install ffmpeg`

**Video unavailable/Age-restricted**
- The app cannot download private or age-restricted videos

## License

Same license as the original TubeGrab project.
# TubeGrab-for-macOS
