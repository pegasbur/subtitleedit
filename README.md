# Subtitle Edit for Unraid

Run the native Linux version of
[Subtitle Edit](https://github.com/SubtitleEdit/subtitleedit) from a web browser.
The container includes a complete browser desktop, FFmpeg, MPV, and Tesseract
OCR. It does not use Wine or a virtual machine.

> This is an unofficial AMD64 Unraid package. It is not maintained or endorsed
> by the Subtitle Edit or LinuxServer teams.

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
5. Apply the template.

Open the WebUI from the Unraid Docker page, or browse to:

```text
https://UNRAID-IP:3001
```

The direct WebUI uses a self-signed certificate, so the browser will display a
certificate warning. The host port can be changed if `3001` is already used by
another container.

## Stable or beta

| Image tag | Intended use |
|---|---|
| `latest` | Latest tested stable Subtitle Edit release; recommended |
| `beta` | Latest tested beta; useful for new Linux fixes and features |

Use a separate appdata directory when evaluating the beta, for example
`/mnt/user/appdata/subtitle-edit-beta`. A beta may change settings in ways that
are not safe to downgrade.

## CPU and GPU setup

A GPU is optional. Subtitle Edit works with CPU/software rendering, although
the browser stream and video playback may use more CPU.

| Hardware | Unraid configuration |
|---|---|
| CPU only | Leave **GPU device** blank; keep Extra Parameters as `--shm-size=1g` |
| Intel or AMD | Set **Intel/AMD GPU device** to `/dev/dri`; keep Extra Parameters as `--shm-size=1g` |
| NVIDIA | Leave the Intel/AMD device blank; in Advanced View set Extra Parameters to `--runtime=nvidia --gpus all --shm-size=1g` |

NVIDIA requires the production branch of the Unraid Nvidia Driver plugin and a
working Nvidia container runtime. Follow the current
[LinuxServer Selkies GPU instructions](https://docs.linuxserver.io/images/docker-baseimage-selkies/#gpu-acceleration)
for driver, DRM modesetting, and headless-GPU requirements.

GPU access accelerates the browser desktop, video rendering, and stream
encoding. It does **not** automatically make Tesseract or a CPU edition of an
optional OCR engine use the GPU.

## Files and persistence

The default mappings are:

| Unraid path | Container path | Purpose |
|---|---|---|
| `/mnt/user/appdata/subtitle-edit` | `/config` | Settings, desktop state, OCR data, and downloaded models |
| `/mnt/user/data` | `/data` | Media and subtitle files |

Open media from `/data` inside Subtitle Edit. Anything stored only elsewhere
inside the container is temporary and may disappear when the image is updated.

The application and bundled tools are part of the image. Replacing or updating
the container does not erase `/config` or `/data`.

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

When a new tested image is published, use Unraid's normal **Check for Updates**
and **Update** controls. Your settings, downloaded OCR models, and media remain
in their mapped folders.

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

Build instructions, version-pin maintenance, validation, and publishing are in
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

The integration files are MIT licensed. Included software retains its own
license; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
