# Development and release maintenance

This document is for maintainers building, testing, and publishing the image. Normal Unraid and Docker users should follow the main [README](../README.md).

## Repository location

On Unraid, keep the repository in a persistent development share rather than appdata:

```text
/mnt/user/development/subtitleedit
```

## Build architecture

The image uses a multi-stage build defined in `jlesage/Dockerfile`.

The builder stage:

1. Uses the digest-pinned .NET SDK image from `versions.env`.
2. Downloads the Subtitle Edit and Avalonia source repositories from their upstream Git repositories.
3. Verifies that each checkout resolves to its pinned commit.
4. Applies the repository patches from `jlesage/patches`.
5. Downloads and verifies the official Avalonia.X11 NuGet package.
6. Repackages the patched Avalonia.X11 assembly under the local package version recorded in `versions.env`.
7. Publishes a self-contained AMD64 Subtitle Edit application.

The runtime stage uses the digest-pinned jlesage GUI base and copies the complete publish output into `/opt/subtitleedit`. FFmpeg/FFprobe, MPV/libmpv, libplacebo, Tesseract, fonts, portal integration, and VA-API drivers are installed from the Ubuntu repositories available in that base image.

The build keeps the application source, framework source, builder image, runtime image, and downloaded package inputs reproducible through immutable Git commits, container digests, and checksums.

## Version pins

All maintained pins are stored in `versions.env`:

- `DOTNET_SDK_IMAGE`
- `JLESAGE_IMAGE`
- `SUBTITLE_EDIT_STABLE_VERSION`
- `SUBTITLE_EDIT_STABLE_COMMIT`
- `SUBTITLE_EDIT_JLESAGE_REVISION`
- `AVALONIA_VERSION`
- `AVALONIA_COMMIT`
- `AVALONIA_X11_PACKAGE_VERSION`
- `AVALONIA_X11_NUPKG_SHA256`

Container images must remain pinned by manifest digest, Git sources by full commit, and downloaded packages by SHA-256.

## Compatibility patches

The maintained source patches are:

```text
jlesage/patches/avalonia-12.1.0-window-hints.patch
jlesage/patches/subtitleedit-5.1.0.patch
```

The Avalonia patch prevents a disabled or modal window state from rewriting the main window’s resize, minimize, maximize, and size hints under X11. This prevents the Subtitle Edit main window from moving when a dialog opens while keeping it resizable.

The Subtitle Edit patch selects the locally patched Avalonia.X11 package and enables automatic hardware decoding in libmpv.

Rebase and retest both patches whenever Subtitle Edit or Avalonia is updated. Do not carry them forward solely because they still apply cleanly; first confirm whether the upstream behavior still requires them.

## Local build

Build the maintained image:

```bash
./build.sh
```

By default this produces:

```text
pegasbur/subtitleedit:latest
pegasbur/subtitleedit:VERSION-rREVISION
```

The local convenience wrapper uses development-oriented image tags:

```bash
jlesage/build-local.sh
```

It produces:

```text
subtitleedit-jlesage:test
subtitleedit-jlesage:VERSION-rREVISION
```

The first build downloads the pinned builder and runtime images, upstream source repositories, NuGet packages, and Ubuntu packages. Later builds reuse Docker BuildKit layers when their inputs have not changed.

## Local Compose test

Create the ignored environment file:

```bash
cp .env.example .env
```

For an isolated test instance, adjust `.env`, for example:

```text
SUBTITLE_EDIT_CONTAINER_NAME=subtitleedit-test
SUBTITLE_EDIT_HTTP_PORT=3101
SUBTITLE_EDIT_CONFIG_PATH=/mnt/user/appdata/subtitleedit-test
```

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

## Updating pinned versions

Check the maintained pins:

```bash
scripts/check-versions.sh
```

Update the Subtitle Edit stable source pin:

```bash
scripts/update-subtitleedit.sh
```

Update the jlesage runtime pin:

```bash
scripts/update-jlesage.sh
```

Review every change to `versions.env` before rebuilding. Confirm the upstream tag, exact commit, image digest, package hash, and compatibility of both patches.

When the Subtitle Edit version changes, begin a new image revision series. Increment `SUBTITLE_EDIT_JLESAGE_REVISION` when the image changes without a new Subtitle Edit release.

The .NET SDK digest and Avalonia pins are updated manually. Rebuild the patched Avalonia package and update `AVALONIA_X11_NUPKG_SHA256` only when its verified official input package changes.

## Static validation

Before a runtime test, run:

```bash
bash -n build.sh jlesage/build-local.sh scripts/*.sh
git diff --check

docker buildx build \
  --check \
  --file jlesage/Dockerfile \
  .

docker compose -f compose.yaml config --quiet
docker compose -f compose.yaml -f compose.gpu.yaml config --quiet
xmllint --noout unraid/my-subtitleedit.xml
```

Run `shellcheck` against the shell scripts when it is available.

## Runtime validation

Before publishing, verify at minimum:

- Subtitle Edit starts successfully and remains running.
- The WebUI loads through the documented host port.
- The main window remains resizable and does not move when dialogs open.
- File open, Save, and Save As dialogs work.
- Settings and GTK bookmarks survive a container recreation.
- Browser audio works and is enabled for a new browser profile.
- Common H.264, HEVC, AV1, MPEG-2, AAC, AC-3/E-AC-3, DTS, and TrueHD media open as expected.
- Playback, seeking, frame stepping, waveform generation, and audio work.
- Intel or AMD VA-API decoding works when `/dev/dri` is mapped.
- CPU/software fallback works without a GPU mapping.
- Tesseract OCR works with the bundled English data.
- Downloaded OCR models remain under `/config` after recreation.
- FFprobe inspection and FFmpeg extraction or conversion work.
- PGS/SUP and VobSub OCR workflows work.
- The Unraid template installs with the documented defaults.

Useful checks include:

```bash
docker exec subtitleedit ffmpeg -version
docker exec subtitleedit ffmpeg -hide_banner -hwaccels
docker exec subtitleedit mpv --version
docker exec subtitleedit tesseract --version
docker exec subtitleedit ldconfig -p | grep libmpv
docker logs -f subtitleedit
```

For Intel or AMD validation, use `vainfo` and the host’s GPU-monitoring tools to confirm that supported video playback uses the hardware video engine.

## Publishing

Every push to `main` runs repository validation. The manual **Publish stable image** GitHub Actions workflow builds the AMD64 image and publishes it to:

```text
ghcr.io/pegasbur/subtitleedit
```

The workflow publishes:

```text
ghcr.io/pegasbur/subtitleedit:latest
ghcr.io/pegasbur/subtitleedit:VERSION
ghcr.io/pegasbur/subtitleedit:VERSION-rREVISION
```

The workflow also generates the configured build provenance and software bill of materials. The package must remain public for anonymous Unraid and Docker pulls.

After publishing:

1. Pull the public immutable revision tag without registry credentials.
2. Recreate the test container from that public tag.
3. Repeat the critical startup, WebUI, persistence, playback, GPU, audio, file-dialog, and OCR checks.
4. Confirm the image labels, application version, and public tags before announcing the release.
