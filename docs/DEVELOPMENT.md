# Development and release maintenance

This document is for maintainers building, testing, and publishing the image. Normal Unraid and Docker users should follow the main [README](../README.md).

## Repository location

On Unraid, keep the repository in a persistent development share rather than appdata:

```text
/mnt/user/development/subtitleedit
```

## Build architecture

The image uses a multi-stage build defined in `container/Dockerfile`.

The builder stage:

1. Uses the digest-pinned .NET SDK image from `versions.env`.
2. Downloads the Subtitle Edit and Avalonia source repositories from their upstream Git repositories.
3. Verifies that each checkout resolves to its pinned commit.
4. Applies the repository patches from `container/patches`.
5. Downloads and verifies the official Avalonia.X11 NuGet package.
6. Repackages the patched Avalonia.X11 assembly under the local package version recorded in `versions.env`.
7. Publishes a self-contained AMD64 Subtitle Edit application.

The runtime stage uses the digest-pinned jlesage GUI base and copies the complete publish output into `/opt/subtitleedit`. FFmpeg/FFprobe, MPV/libmpv, libplacebo, Tesseract, fonts, portal integration, and VA-API drivers are installed from the Ubuntu repositories available in that base image.

The build pins the application source, framework source, builder image, runtime image, and downloaded package inputs through immutable Git commits, container digests, and checksums. Ubuntu packages intentionally follow the repositories configured by the pinned runtime base image and are covered separately by the reproducibility policy below.

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

## Reproducibility policy

The project aims to make its maintained build inputs reproducible and auditable, but it does not claim that rebuilding the same repository commit at different dates will produce a bit-for-bit identical runtime image.

The following inputs are immutable or explicitly verified:

- the .NET SDK builder image, pinned by OCI manifest digest;
- the jlesage GUI runtime image, pinned by OCI manifest digest;
- the Subtitle Edit source, pinned by full Git commit;
- the Avalonia source, pinned by full Git commit;
- the official Avalonia.X11 NuGet package, verified by SHA-256;
- the repository integration patches, version-controlled together with the build definition.

Ubuntu APT packages are intentionally not individually version-pinned. They resolve from the Ubuntu repositories configured by the pinned jlesage base image. This allows rebuilds to receive security and maintenance updates within that Ubuntu release instead of freezing individual packages indefinitely.

Consequently, two builds from the same repository commit performed at different times can contain different Ubuntu package revisions. This is intentional.

Do not add exact APT package versions merely to make rebuilds appear deterministic. Exact package pinning should only be adopted together with a maintained Ubuntu snapshot repository or equivalent immutable package source.

Versions of behavior-sensitive runtime packages are printed during the image build so that the resolved environment is visible in build logs. The OCI image digest identifies the exact produced image, while the generated SBOM and build provenance provide additional traceability for published builds.

## Compatibility patches

The maintained source patches are:

```text
container/patches/avalonia-12.1.0-window-hints.patch
container/patches/subtitleedit-5.1.0.patch
```

These patches serve different purposes and should be reviewed independently whenever Subtitle Edit or Avalonia is updated.

### Avalonia.X11 patch and local package

`container/patches/avalonia-12.1.0-window-hints.patch` modifies Avalonia's X11 window handling. It prevents a disabled or modal window state from rewriting the main window's resize, minimize, maximize, and size hints. This prevents the Subtitle Edit main window from moving when a dialog opens while keeping it resizable.

The build:

1. fetches the Avalonia source corresponding to `AVALONIA_VERSION`;
2. verifies that the checkout resolves exactly to `AVALONIA_COMMIT`;
3. applies the maintained Avalonia X11 patch;
4. builds the patched `Avalonia.X11.dll`;
5. downloads the official Avalonia.X11 NuGet package;
6. verifies that package against `AVALONIA_X11_NUPKG_SHA256`;
7. replaces its Avalonia.X11 assembly with the locally built patched assembly;
8. changes the package version to `AVALONIA_X11_PACKAGE_VERSION`;
9. rebuilds the package and exposes it only through the build's local NuGet feed.

The resulting `Avalonia.X11 12.1.1-local.1` package is an internal build input, not an official Avalonia NuGet release.

Because the package contents are modified and reconstructed, the resulting package cannot retain a valid upstream NuGet package signature. It must not be presented or re-signed as though it were an official NuGet.org package. Its integrity instead comes from the pinned Avalonia source commit, the SHA-256-verified official NuGet input, the repository-controlled patch, and the resulting container build provenance.

### Subtitle Edit container integration patch

`container/patches/subtitleedit-5.1.0.patch` is the Subtitle Edit container integration patch. It makes two targeted changes to the pinned upstream Subtitle Edit source:

1. it sets libmpv `hwdec` to `auto`, allowing hardware decoding when suitable GPU access is available while preserving software fallback;
2. it adds an explicit `Avalonia.X11` package reference to `AVALONIA_X11_PACKAGE_VERSION`, causing Subtitle Edit to consume the locally rebuilt patched X11 package described above.

Apart from these targeted container-integration changes, the maintained application source remains the upstream Subtitle Edit source at `SUBTITLE_EDIT_STABLE_COMMIT`.

### Integrity chain

The maintained integrity chain is:

1. digest-pinned builder and runtime container images;
2. full Git commit pins for Subtitle Edit and Avalonia;
3. SHA-256 verification of the downloaded official Avalonia.X11 NuGet package;
4. repository-controlled Avalonia and Subtitle Edit integration patches;
5. the locally rebuilt Avalonia.X11 package consumed during the same build;
6. the resulting OCI image digest;
7. generated SBOM and build provenance for published images.

The patch files are version-controlled build inputs rather than separately downloaded artifacts. Their exact contents are therefore covered by the repository commit recorded in `VCS_REF` and the image provenance.

Rebase and retest both patches whenever Subtitle Edit or Avalonia is updated. Do not carry either patch forward solely because it still applies cleanly. First confirm whether the corresponding upstream behavior still requires it.

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
container/build-local.sh
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
bash -n build.sh container/build-local.sh scripts/*.sh
git diff --check

docker buildx build \
  --check \
  --file container/Dockerfile \
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
