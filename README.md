# Subtitle Edit container for Unraid

This project builds the official native Linux x64 release of Subtitle Edit into a LinuxServer Selkies browser desktop. It includes its own FFmpeg, MPV, and file manager. It does not use Wine, a VM, or your separate FFmpeg Community App.

The default is the stable Subtitle Edit 5.1.0 release. The downloaded release archive is verified with its pinned SHA-256 before extraction.

## What persists

- `/config` -> `/mnt/user/appdata/subtitle-edit/config`: Subtitle Edit settings and browser-desktop home directory
- `/data` -> `/mnt/user/data`: media and subtitle files
- The application, FFmpeg, and MPV are baked into the image. Rebuilding replaces them; it does not erase `/config` or `/data`.

## 1. Copy the project to Unraid

Extract this archive on Unraid and keep the folder somewhere persistent, for example:

```bash
mkdir -p /mnt/user/appdata/subtitle-edit/{build,config}
tar -xzf subtitle-edit-unraid-project.tar.gz \
  --strip-components=1 \
  -C /mnt/user/appdata/subtitle-edit/build
cd /mnt/user/appdata/subtitle-edit/build
```

## 2. Build the image

Run from an Unraid terminal:

```bash
chmod +x build.sh
./build.sh
```

This creates the local images `goztepe/subtitle-edit:5.1.0` and `goztepe/subtitle-edit:latest`. The first build downloads the Selkies base, packages, and the 59 MB Subtitle Edit archive, so it can take several minutes.

## 3. Create the encoding network

Skip this if it already exists:

```bash
docker network inspect encoding >/dev/null 2>&1 || docker network create encoding
```

## 4A. Start with Compose

```bash
cp .env.example .env
nano .env
docker compose up -d
```

Open `https://UNRAID-IP:3001`. The Selkies certificate is self-signed, so the browser will warn on this direct test connection.

## 4B. Or install through the Unraid Docker page

Copy the included template:

```bash
cp unraid/my-subtitle-edit.xml /boot/config/plugins/dockerMan/templates-user/my-subtitle-edit.xml
```

Then open **Docker -> Add Container**, select the `my-subtitle-edit` user template, enter a strong Web password, and apply it.

## Paths inside Subtitle Edit

Choose videos and subtitles under `/data`. For example, the host file:

```text
/mnt/user/data/media/movies/example.mkv
```

appears inside Subtitle Edit as:

```text
/data/media/movies/example.mkv
```

## Intel iGPU

The supplied configurations map `/dev/dri` and enable Selkies automatic GPU selection. This shares the iGPU with other containers; it does not dedicate the GPU as a VM would.

If the container fails because `/dev/dri` does not exist, remove the `devices` section from `compose.yaml`, or remove `--device=/dev/dri` from the Unraid template. Subtitle Edit will still work with CPU rendering.

## Private access

Port 3001 is published only to make the first test easy. Once your private reverse proxy/Tailscale route can reach the `encoding` network, remove the 3001 host-port mapping. Do not expose this desktop directly to the public Internet. Keep the Selkies password enabled even behind the private route.

## Updating Subtitle Edit

For another release, obtain the SHA-256 of its `SubtitleEdit-Linux-x64.tar.gz`, then run:

```bash
SUBTITLE_EDIT_SHA256='THE_NEW_SHA256' ./build.sh 5.2.0-beta28
```

Update the image tag in `compose.yaml` or the Unraid template, then recreate the container. `/config` and `/data` remain intact.

## Useful checks

```bash
docker logs -f subtitle-edit
docker exec subtitle-edit ffmpeg -version
docker exec subtitle-edit mpv --version
docker exec subtitle-edit /usr/local/bin/subtitleedit --version
```

If video playback does not initialize, first check the container log and test MPV against one mapped file. Subtitle Edit can switch between its MPV video backends in its settings; Wayland environments sometimes need the alternate MPV backend.
