<p align="center">
  <a href="https://github.com/SubtitleEdit/subtitleedit"><img src="https://avatars.githubusercontent.com/u/3008853?s=80&amp;v=4" alt="Subtitle Edit" width="80" height="80"></a>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://drive.google.com/file/d/1NfrtbOFIzg65KY1YeLBZSlTsuGQQCmbr/view"><img src="https://drive.google.com/thumbnail?id=1NfrtbOFIzg65KY1YeLBZSlTsuGQQCmbr&sz=w256" alt="Unraid" width="80" height="80"></a>
</p>

<h1 align="center">Subtitle Edit for Unraid &amp; Docker</h1>

<p align="center">
  Run the native Linux version of Subtitle Edit in a web browser.
</p>

<p align="center">
  <a href="https://github.com/pegasbur/subtitleedit/actions/workflows/validate.yml"><img alt="Repository validation" src="https://github.com/pegasbur/subtitleedit/actions/workflows/validate.yml/badge.svg?branch=main"></a>
  <a href="https://github.com/users/pegasbur/packages/container/package/subtitleedit"><img alt="Container image" src="https://img.shields.io/badge/GHCR-container-2496ED?logo=docker&logoColor=white"></a>
  <img alt="Unraid compatible" src="https://img.shields.io/badge/Unraid-compatible-F15A2C?logo=unraid&logoColor=white">
  <img alt="Architecture amd64" src="https://img.shields.io/badge/architecture-amd64-555555">
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-2ea44f"></a>
</p>

Subtitle Edit for Unraid packages the native Linux edition of Subtitle Edit with FFmpeg/FFprobe, MPV/libmpv, Tesseract OCR, optional hardware-accelerated video playback, and the jlesage browser GUI.

The primary tested platform is AMD64 Unraid, but the image can also run on an AMD64 Linux Docker host.

> This is an unofficial community project. It is not maintained or endorsed by the Subtitle Edit, Unraid, or jlesage projects.

## Contents

- [Features](#features)
- [Quick start on Unraid](#quick-start-on-unraid)
- [Quick start with Docker](#quick-start-with-docker)
- [Docker Compose](#docker-compose)
- [Image tags](#image-tags)
- [Included software](#included-software)
- [CPU and GPU setup](#cpu-and-gpu-setup)
- [Browser interface](#browser-interface)
- [Files and persistence](#files-and-persistence)
- [OCR engines](#ocr-engines)
- [Updating](#updating)
- [Network access and security](#network-access-and-security)
- [Support and development](#support-and-development)

## Features

- Native Linux Subtitle Edit available through any modern browser
- FFmpeg/FFprobe, MPV/libmpv, and Tesseract OCR included
- Browser audio and GTK file chooser integration
- Persistent settings, OCR data, downloaded models, and media mappings
- CPU operation with optional Intel and AMD GPU acceleration
- Unraid template and standard Docker deployment

## Quick start on Unraid

The template is being prepared for Community Applications. Until it is listed, install the user template from an Unraid terminal:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/pegasbur/subtitleedit/main/unraid/my-subtitleedit.xml \
  -o /boot/config/plugins/dockerMan/templates-user/my-subtitleedit.xml
```

Then open **Docker > Add Container** and select **Subtitle Edit** from the template list.

During installation:

1. Confirm the appdata and media paths.
2. Configure GPU access if required, or leave it disabled for CPU/software operation.
3. Apply the template and open its WebUI.

The default address is:

```text
http://UNRAID-IP:3001
```

The host port can be changed if `3001` is already used by another container.

## Quick start with Docker

Create persistent folders:

```bash
mkdir -p /srv/subtitleedit/config /srv/media
```

Run the container:

```bash
docker run -d \
  --name subtitleedit \
  --restart unless-stopped \
  --shm-size=1g \
  -p 3001:5800 \
  -e USER_ID=1000 \
  -e GROUP_ID=1000 \
  -e TZ=Etc/UTC \
  -e WEB_AUDIO=1 \
  -e KEEP_APP_RUNNING=1 \
  -e DISPLAY_WIDTH=1920 \
  -e DISPLAY_HEIGHT=1080 \
  -v /srv/subtitleedit/config:/config \
  -v /srv/media:/data \
  ghcr.io/pegasbur/subtitleedit:latest
```

Change the host paths, timezone, and numeric user and group IDs for your system. Then open:

```text
http://DOCKER-HOST-IP:3001
```

For Intel or AMD GPU access, add:

```bash
--device=/dev/dri
```

## Docker Compose

Copy the example environment file:

```bash
cp .env.example .env
```

Review the image, container name, WebUI port, appdata path, and media path in `.env`.

Start in CPU/software mode:

```bash
docker compose up -d
```

Start with Intel or AMD GPU access:

```bash
docker compose \
  -f compose.yaml \
  -f compose.gpu.yaml \
  up -d
```

## Image tags

| Image tag | Intended use |
|---|---|
| `ghcr.io/pegasbur/subtitleedit:latest` | Current tested Subtitle Edit release |
| `ghcr.io/pegasbur/subtitleedit:5.1.0` | Current application-version tag |
| `ghcr.io/pegasbur/subtitleedit:5.1.0-r7` | Immutable application and container-revision tag |

## Included software

| Component | Version or source |
|---|---|
| [Subtitle Edit](https://github.com/SubtitleEdit/subtitleedit) | `5.1.0` |
| [jlesage browser GUI](https://github.com/jlesage/docker-baseimage-gui) | `ubuntu-26.04-v4` |
| [Avalonia](https://github.com/AvaloniaUI/Avalonia) | `12.1.0` with an X11 compatibility patch |
| [.NET](https://github.com/dotnet/runtime) | `10.0`, self-contained |
| [FFmpeg/FFprobe](https://ffmpeg.org/) | Ubuntu 26.04 package |
| [MPV/libmpv](https://github.com/mpv-player/mpv) | Ubuntu 26.04 package |
| [libplacebo](https://code.videolan.org/videolan/libplacebo) | Ubuntu 26.04 package |
| [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) | Ubuntu 26.04 package |
| [Intel media driver](https://github.com/intel/media-driver) and [Mesa](https://www.mesa3d.org/) | Ubuntu 26.04 VA-API packages |

Exact source commits, package checksums, builder images, and runtime images are pinned in `versions.env`.

## CPU and GPU setup

A GPU is optional. Subtitle Edit remains usable through CPU/software operation without one.

| Hardware | Unraid configuration | Docker options |
|---|---|---|
| CPU/software | Leave the GPU device blank; shared memory is preconfigured | `--shm-size=1g` |
| Intel or AMD | Set the GPU device to `/dev/dri`; shared memory is preconfigured | `--device=/dev/dri --shm-size=1g` |

NVIDIA GPU acceleration is not supported by the jlesage GUI stack, so NVIDIA systems use CPU/software fallback.

GPU access can accelerate desktop rendering and supported video decoding. It does not make Tesseract or CPU-based optional OCR engines use the GPU.

## Browser interface

The browser interface is provided by the jlesage noVNC-based GUI stack.

- Web access uses container port `5800`.
- Native VNC is available on container port `5900`, but is not mapped by default.
- The side panel provides audio, clipboard, scaling, quality, and logging controls.
- Remote resizing adapts the virtual desktop to the browser window.

## Files and persistence

The principal container paths are the same on Unraid and Docker:

| Unraid host path | Container path | Purpose |
|---|---|---|
| `/mnt/user/appdata/subtitleedit` | `/config` | Application settings, GUI state, OCR data, downloaded models, and GTK bookmarks |
| `/mnt/user/data` | `/data` | Media and subtitle files |

Correctly mapped `/config` and `/data` directories remain available when the container is updated or replaced.

Additional host directories can be mapped when required.

## OCR engines

The Tesseract OCR engine, English language data, and orientation/script detection data are included.

Additional Tesseract `.traineddata` files can be placed in:

```text
/config/tessdata
```

Subtitle Edit stores application-managed Tesseract models in its own configuration directory:

```text
/config/xdg/config/Subtitle Edit/Tesseract550/tessdata
```

This directory is part of the persistent `/config` mapping and does not require an additional volume mapping.

Large optional engines and models such as PaddleOCR, CrispEmbed, Whisper, and llama.cpp can be downloaded through Subtitle Edit when requested. Their files are retained under `/config`.

Tesseract normally uses the CPU. Optional engines use a GPU only when the selected engine and downloaded package support it.

## Updating

### Unraid

Use Unraid’s normal **Check for Updates** and **Update** controls. Settings, downloaded OCR models, bookmarks, and media remain in their mapped directories.

### Docker

Pull the current image and recreate the container with the same options and volume mappings:

```bash
docker pull ghcr.io/pegasbur/subtitleedit:latest
```

Docker Compose users can run:

```bash
docker compose pull
docker compose up -d
```

## Network access and security

The WebUI is intended for a trusted LAN, Tailscale, or a secured reverse proxy and should not be exposed directly to the public Internet. It uses HTTP without built-in authentication by default (`SECURE_CONNECTION=0`, `WEB_AUTHENTICATION=0`), although HTTPS and password authentication can be enabled through the corresponding container settings.

## Support and development

Report container-image or Unraid-template problems in this repository’s [issue tracker](https://github.com/pegasbur/subtitleedit/issues). Application bugs should be reported to the [Subtitle Edit project](https://github.com/SubtitleEdit/subtitleedit/issues) after confirming that they are not specific to this container.

Build instructions, version maintenance, validation, and publishing information are available in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

The integration files are MIT licensed. Included software retains its own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
