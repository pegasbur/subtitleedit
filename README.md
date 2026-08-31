<p align="center">
  <img src="unraid/icon.png" alt="Subtitle Edit logo" width="112">
</p>

<h1 align="center">Subtitle Edit for Docker &amp; Unraid</h1>

<p align="center">
  Run the native Linux version of Subtitle Edit in a web browser.
</p>

<p align="center">
  <a href="https://github.com/pegasbur/subtitle-edit/actions/workflows/validate.yml"><img alt="Repository validation" src="https://github.com/pegasbur/subtitle-edit/actions/workflows/validate.yml/badge.svg?branch=main"></a>
  <a href="https://github.com/users/pegasbur/packages/container/package/subtitle-edit"><img alt="Container image" src="https://img.shields.io/badge/GHCR-container-2496ED?logo=docker&logoColor=white"></a>
  <img alt="Unraid compatible" src="https://img.shields.io/badge/Unraid-compatible-F15A2C?logo=unraid&logoColor=white">
  <img alt="Architecture amd64" src="https://img.shields.io/badge/architecture-amd64-555555">
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-2ea44f"></a>
</p>

The image includes a complete browser desktop, FFmpeg, MPV, and Tesseract OCR.
It does not use Wine or a virtual machine. The primary tested platform is
AMD64 Unraid, but it is a normal OCI/Docker image and can also run on an AMD64
Linux Docker host.

> This is an unofficial community project. It is not maintained or endorsed
> by the Subtitle Edit, Unraid, or LinuxServer teams.

## Contents

- [Features](#features)
- [Quick start with Docker](#quick-start-with-docker)
- [Quick start on Unraid](#quick-start-on-unraid)
- [Stable or beta](#stable-or-beta)
- [CPU and GPU setup](#cpu-and-gpu-setup)
- [Files and persistence](#files-and-persistence)
- [OCR engines](#ocr-engines)
- [Updating](#updating)
- [Network access and security](#network-access-and-security)
- [Known Linux limitation](#known-linux-limitation)
- [Support and development](#support-and-development)

## Features

- Native Linux Subtitle Edit available through any modern browser
- FFmpeg/FFprobe, MPV/libmpv, and Tesseract included
- Persistent settings, OCR data, downloaded models, and media mappings
- Stable and beta release channels
- CPU rendering plus optional Intel, AMD, or NVIDIA GPU acceleration
- Direct HTTPS access or an internal HTTP endpoint for a reverse proxy

## Quick start with Docker

Create persistent folders and run the stable image:

```bash
mkdir -p /srv/subtitle-edit/config /srv/media

docker run -d \
  --name subtitle-edit \
  --restart unless-stopped \
  --shm-size=1g \
  -p 3001:3001 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e CUSTOM_USER=subtitle-edit \
  -e PASSWORD='replace-with-a-strong-password' \
  -e AUTO_GPU=true \
  -e START_DOCKER=false \
  -v /srv/subtitle-edit/config:/config \
  -v /srv/media:/data \
  ghcr.io/pegasbur/subtitle-edit:latest
```

Change the two host paths, timezone, user/group IDs, username, and password for
your system. Then open:

```text
https://DOCKER-HOST-IP:3001
```

The direct WebUI uses a self-signed certificate, so the browser will initially
display a certificate warning. For Intel or AMD acceleration, add
`--device=/dev/dri`. NVIDIA setup is shown in [CPU and GPU setup](#cpu-and-gpu-setup).

## Quick start on Unraid

The template is being prepared for Community Applications. Until it is listed,
install the user template from an Unraid terminal:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/pegasbur/subtitle-edit/main/unraid/my-subtitle-edit.xml \
  -o /boot/config/plugins/dockerMan/templates-user/my-subtitle-edit.xml
```

Then open **Docker > Add Container** and select **Subtitle Edit** from the
template list.

During installation:

1. Choose `latest` for normal use or `beta` for testing.
2. Enter a strong **Web password**.
3. Confirm the appdata and media paths.
4. Choose the GPU setup described below, or leave GPU access disabled.
5. Apply the template and open its WebUI.

The default address is `https://UNRAID-IP:3001`. The host port can be changed
if `3001` is already used by another container.

## Stable or beta

| Image tag | Intended use |
|---|---|
| `ghcr.io/pegasbur/subtitle-edit:latest` | Latest tested stable Subtitle Edit release; recommended |
| `ghcr.io/pegasbur/subtitle-edit:beta` | Latest tested beta; useful for new Linux fixes and features |

Use a separate `/config` directory when evaluating the beta, such as
`/srv/subtitle-edit-beta/config` or
`/mnt/user/appdata/subtitle-edit-beta`. A beta may change settings in ways that
are not safe to downgrade.

## CPU and GPU setup

A GPU is optional. Subtitle Edit works with CPU/software rendering, although
the browser stream and video playback may use more CPU.

| Hardware | Docker option / Unraid Extra Parameters |
|---|---|
| CPU only | `--shm-size=1g` |
| Intel or AMD | `--device=/dev/dri --shm-size=1g` |
| NVIDIA | `--runtime=nvidia --gpus all --shm-size=1g` |

On Unraid, Intel/AMD users can fill the **Intel/AMD GPU device** field with
`/dev/dri`. NVIDIA users should leave that field blank and enter the NVIDIA
options above in **Extra Parameters** in Advanced View.

NVIDIA requires a working NVIDIA container runtime. On Unraid, install the
production branch of the Nvidia Driver plugin. Follow the current
[LinuxServer Selkies GPU instructions](https://docs.linuxserver.io/images/docker-baseimage-selkies/#gpu-acceleration)
for driver, DRM modesetting, and headless-GPU requirements.

GPU access accelerates the browser desktop, video rendering, and stream
encoding. It does **not** automatically make Tesseract or a CPU edition of an
optional OCR engine use the GPU.

## Files and persistence

The container paths are the same on Docker and Unraid:

| Container path | Example Unraid host path | Purpose |
|---|---|---|
| `/config` | `/mnt/user/appdata/subtitle-edit` | Settings, desktop state, OCR data, and downloaded models |
| `/data` | `/mnt/user/data` | Media and subtitle files |

Open media from `/data` inside Subtitle Edit. Files stored elsewhere inside the
container may disappear when the image is replaced. Updating the container does
not erase correctly mapped `/config` or `/data` folders.

## OCR engines

Tesseract, English language data, and orientation/script detection are included.
Additional Tesseract `.traineddata` files can be placed in:

```text
/config/tessdata
```

Large optional engines such as PaddleOCR, CrispEmbed, Whisper, and llama.cpp
can be downloaded from Subtitle Edit when requested. Their files are stored
under `/config` and survive container updates.

Tesseract normally uses the CPU. Optional OCR engines use the GPU only when the
specific engine and downloaded package support it.

## Updating

### Docker

Pull the chosen channel, remove the old container, and recreate it with the same
options and volume mappings:

```bash
docker pull ghcr.io/pegasbur/subtitle-edit:latest
```

Docker Compose users can use `docker compose pull` followed by
`docker compose up -d`.

### Unraid

Use Unraid's normal **Check for Updates** and **Update** controls. Settings,
downloaded OCR models, and media remain in their mapped folders.

Changing from `latest` to `beta` selects the tested beta image. Changing back to
`latest` is not recommended with the same appdata directory after a beta has
migrated its settings.

## Network access and security

Set a strong web password. This desktop is intended for a trusted LAN or a
private connection such as Tailscale. Do not expose it directly to the public
Internet.

Port `3001` provides direct HTTPS access. Port `3000` is the internal HTTP port
for a reverse proxy and normally does not need a host-port mapping. A reverse
proxy sharing a Docker network with this container can proxy to
`subtitle-edit:3000`.

## Known Linux limitation

In current testing, the **Export** button in the Blu-ray/M2TS transport-stream
track picker does not reliably save a raw `.sup` file on Linux. Stable 5.1.0 may
close the application; beta 5.2.0-beta30 remains open but may not display a save
dialog. This occurs under both Wayland and X11.

To convert a graphical subtitle track to SRT, select the track, click **OK**, run
OCR, and then use **File > Save As**. That workflow works and does not require
the raw Export button.

## Support and development

Report container, image, or Unraid-template problems in this repository's
[issue tracker](https://github.com/pegasbur/subtitle-edit/issues). Application
bugs should be reported to Subtitle Edit after confirming they are not specific
to this container.

Build instructions, version updates, validation, and publishing are kept in
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md), leaving this page focused on using
the container.

The integration files are MIT licensed. Included software retains its own
license; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
