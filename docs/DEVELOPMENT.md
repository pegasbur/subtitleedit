# Development and release maintenance

This document is for maintainers building and publishing the image. Normal
Unraid users should follow the main [README](../README.md).

## Repository location

Keep the repository in a persistent development share rather than appdata:

```text
/mnt/user/development/subtitle-edit
```

## Runtime stack

The immutable LinuxServer Selkies base image and Subtitle Edit releases are
pinned in `versions.env`. Subtitle Edit archives are verified with their
published SHA-256 digests.

FFmpeg/FFprobe, libplacebo, MPV/libmpv, Tesseract, fonts, and desktop runtime
packages come from the Ubuntu Resolute repositories in the pinned Selkies base.
Ubuntu maintains these as a compatible distribution set. Tesseract includes
English and orientation/script data by default.

Large optional engines remain on-demand downloads stored under `/config`.

## Local builds

Build stable:

```bash
./build.sh stable
```

Build beta:

```bash
./build.sh beta
```

Tags include the channel and an immutable release/revision tag:

```text
pegasbur/subtitle-edit:latest
pegasbur/subtitle-edit:VERSION-rREVISION
pegasbur/subtitle-edit:beta
```

The first build downloads the Selkies base, Ubuntu packages, and Subtitle Edit.
Later builds reuse Docker BuildKit layers when their inputs have not changed.

## Isolated local test

Create the ignored environment file:

```bash
cp .env.example .env
nano .env
```

Start with CPU/software rendering:

```bash
docker compose up -d
```

Start with Intel/AMD `/dev/dri` access:

```bash
docker compose \
  -f compose.yaml \
  -f compose.gpu.yaml \
  up -d
```

The test instance uses separate appdata and direct HTTPS port `3101`:

```text
/mnt/user/appdata/subtitle-edit-test
https://UNRAID-IP:3101
```

## Updating pinned versions

Check the maintained pins:

```bash
scripts/check-versions.sh
```

Update Subtitle Edit and its published asset digest:

```bash
scripts/update-subtitle-edit.sh stable
scripts/update-subtitle-edit.sh beta
```

Update Selkies and its immutable manifest digest:

```bash
scripts/update-selkies.sh
```

Review `versions.env` after every updater. Increment `IMAGE_REVISION` when the
container changes without a new Subtitle Edit version. Rebuilding against an
updated Selkies base obtains the matched Ubuntu package set available in that
base.

## Release validation

Before publishing either channel, verify at minimum:

- Subtitle Edit starts, restarts, and retains settings.
- Common H.264, HEVC, AV1, MPEG-2, AAC, AC-3/E-AC-3, DTS, and TrueHD media open.
- Playback, seeking, audio, frame stepping, and waveform generation work.
- FFprobe inspection and FFmpeg extraction/conversion work.
- PGS/SUP and VobSub OCR work with Tesseract and an on-demand OCR engine.
- The main Save and Save As dialogs work under Selkies/Wayland.
- The known transport-stream raw Export behavior is checked and documented.
- Intel VA-API streaming works with `/dev/dri`.
- CPU/software fallback works without `/dev/dri`.
- Direct HTTPS `3001` and reverse-proxied HTTP `3000` work as documented.

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

Every push to `main` runs repository validation. The manual `Publish image`
GitHub Actions workflow builds AMD64 and publishes to:

```text
ghcr.io/pegasbur/subtitle-edit
```

Choose `stable` or `beta` when running the workflow. Stable publishes `latest`
and versioned tags; beta publishes `beta` and versioned tags. The package must
remain public for anonymous Unraid pulls.

After publishing, pull the public tag without registry credentials and inspect
the finished image before announcing it.
