# Subtitle Edit for Unraid

Unofficial Unraid packaging of the native Linux build of
[Subtitle Edit](https://github.com/SubtitleEdit/subtitleedit) in a
[LinuxServer Selkies](https://github.com/linuxserver/docker-baseimage-selkies)
browser desktop. It does not use Wine or a virtual machine.

The image is designed and tested for AMD64 Unraid. It remains a normal OCI
container, but other Docker platforms are not currently supported targets.

## Included stack

| Component | Pinned version |
|---|---:|
| LinuxServer Selkies | dc0f730c-ls132 |
| Subtitle Edit stable | 5.1.0 |
| Subtitle Edit beta | 5.2.0-beta30 |
| FFmpeg/FFprobe | 9.0.1 |
| MPV/libmpv | 0.41.0 |
| Tesseract OCR | 5.5.3 |

The authoritative pins and SHA-256 values are in `versions.env`.

FFmpeg and MPV are built together so libmpv uses the same FFmpeg ABI. The
build enables the mainstream video, audio, subtitle, optical-media, Intel
QSV/VA-API, Vulkan, OpenCL, and Nvidia NVENC interfaces available from the
Debian Trixie/Selkies dependency set. Tesseract includes English and
orientation/script data by default.

Large optional engines such as PaddleOCR, CrispEmbed, Whisper, and llama.cpp
remain on-demand downloads. Subtitle Edit stores them under `/config`, so they
survive container replacement.

## Unraid installation

The Community Applications template is included in
`unraid/my-subtitle-edit.xml`, but the application is not listed in Community
Applications until its first public image and submission have been validated.

The template offers two image branches during installation:

- `latest`: tested stable Subtitle Edit release; recommended.
- `beta`: tested Subtitle Edit beta with the same media/OCR stack.

Use a separate appdata directory when testing beta releases. A beta may migrate
settings in ways that are not safe to downgrade.

Default mappings:

| Host | Container | Purpose |
|---|---|---|
| `/mnt/user/appdata/subtitle-edit` | `/config` | Settings, desktop state, OCR data, and downloaded models |
| `/mnt/user/data` | `/data` | Media and subtitle files |
| Host `3001` | Container `3001` | Direct HTTPS WebUI |

Open:

```text
https://UNRAID-IP:3001
```

Selkies uses a self-signed certificate on port 3001, so the browser will show a
certificate warning. The host port may be changed without changing container
port 3001.

Port 3000 is Selkies' plain HTTP entrance for reverse proxies. It does not need
to be published for a normal direct installation. If a reverse proxy shares a
Docker network with the container, proxy to `subtitle-edit:3000` over HTTP.
Host ports used by unrelated containers, such as Grafana's host port 3000, do
not conflict with an unpublished container port.

## Authentication and exposure

`CUSTOM_USER` and `PASSWORD` enable Selkies HTTP Basic Authentication. Set a
strong password during installation.

This browser desktop is intended for a trusted LAN or private Tailscale
connection. Do not expose it directly to the public Internet. Basic
authentication alone is not an appropriate public-access security boundary.

## GPU support

A GPU is optional. CPU/software rendering works without `/dev/dri`.

For Intel or AMD acceleration, set the optional Unraid device field to:

```text
/dev/dri
```

This lets Selkies use the render device and makes FFmpeg/MPV VA-API available.
Intel QSV support is compiled into FFmpeg as well. Nvidia use additionally
requires the Unraid Nvidia driver/runtime configuration.

## Tesseract and optional OCR models

On first GUI start, the bundled Tesseract data is copied into:

```text
/config/tessdata
```

English and OSD are immediately available. Additional compatible
`.traineddata` files may be added to that directory and persist across image
updates.

PaddleOCR, CrispEmbed, Whisper, llama.cpp, and similar engines should be
installed through Subtitle Edit's own download prompts. Their much larger
models also persist under `/config`.

## Local maintainer build

The repository belongs in a development share, not appdata:

```text
/mnt/user/development/subtitle-edit
```

Build the stable image:

```bash
./build.sh stable
```

Build the beta image:

```bash
./build.sh beta
```

The first source build compiles FFmpeg, MPV, and Tesseract and will take much
longer than the old Debian-package-only build. Docker BuildKit caches each
component stage, so changing only Subtitle Edit does not rebuild the media
stack.

Local tags follow this pattern:

```text
pegasbur/subtitle-edit:latest
pegasbur/subtitle-edit:5.1.0-r1
pegasbur/subtitle-edit:beta
pegasbur/subtitle-edit:5.2.0-beta30-r1
```

## Isolated test container

Create the local environment file:

```bash
cp .env.example .env
nano .env
```

Start without GPU access:

```bash
docker compose up -d
```

Start with `/dev/dri`:

```bash
docker compose \
  -f compose.yaml \
  -f compose.gpu.yaml \
  up -d
```

The test container uses separate appdata and host port 3101:

```text
/mnt/user/appdata/subtitle-edit-test
https://UNRAID-IP:3101
```

It therefore does not replace the existing production container.

## Updating versions

Check all top-level pins against upstream:

```bash
scripts/check-versions.sh
```

Update the stable or beta Subtitle Edit pin and asset digest automatically:

```bash
scripts/update-subtitle-edit.sh stable
scripts/update-subtitle-edit.sh beta
```

Selkies, FFmpeg, MPV, and Tesseract upgrades require editing `versions.env`,
incrementing `IMAGE_REVISION` when appropriate, rebuilding, and completing the
playback/OCR test checklist. The Selkies tag and immutable manifest digest are
both recorded. These components are intentionally not upgraded unattended
because the complete desktop and multimedia stack must be tested together.

## Release validation

Before publishing a channel, verify at minimum:

- Subtitle Edit starts, restarts, and retains settings.
- H.264, HEVC, AV1, MPEG-2, AAC, AC-3/E-AC-3, DTS, and TrueHD media open.
- Playback, seeking, audio, frame stepping, and waveform generation work.
- FFprobe media inspection and FFmpeg extraction/conversion work.
- PGS/SUP and VobSub OCR work with Tesseract and an on-demand OCR engine.
- Subtitle export and Save dialogs work under Selkies/Wayland.
- Intel VA-API streaming works with `/dev/dri`.
- CPU/software fallback works without `/dev/dri`.
- Both direct HTTPS 3001 and reverse-proxied HTTP 3000 work as documented.

Useful checks:

```bash
docker exec subtitle-edit-test ffmpeg -version
docker exec subtitle-edit-test ffmpeg -hide_banner -hwaccels
docker exec subtitle-edit-test mpv --version
docker exec subtitle-edit-test tesseract --version
docker exec subtitle-edit-test ldconfig -p | grep libmpv
docker logs -f subtitle-edit-test
```

## Publishing

The manual `Publish image` GitHub Actions workflow builds AMD64 and publishes
to:

```text
ghcr.io/pegasbur/subtitle-edit
```

Choose `stable` or `beta` when running the workflow. Stable publishes `latest`
plus versioned tags; beta publishes `beta` plus versioned tags. After the first
publish, the GHCR package must be made public in GitHub package settings.

## Project status and licensing

This is an unofficial packaging project and is not maintained or endorsed by
the Subtitle Edit or LinuxServer teams. Report container and Unraid issues in
this repository; report application bugs upstream only after confirming they
also occur outside this packaging.

Original integration files are MIT licensed. Included software retains its own
license. See `THIRD_PARTY_NOTICES.md` for details.
