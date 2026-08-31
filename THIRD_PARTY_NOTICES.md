# Third-party software

This repository contains packaging and integration code. The resulting image
downloads, builds, or includes independent third-party projects under their own
licenses.

| Component | Source | License |
|---|---|---|
| Subtitle Edit | https://github.com/SubtitleEdit/subtitleedit | MIT |
| FFmpeg | https://ffmpeg.org/ | LGPL/GPL; this build enables GPL and version 3 components |
| MPV | https://github.com/mpv-player/mpv | GPL-2.0-or-later by default |
| Tesseract OCR | https://github.com/tesseract-ocr/tesseract | Apache-2.0 |
| LinuxServer Selkies base | https://github.com/linuxserver/docker-baseimage-selkies | Project and package-specific licenses |
| Debian packages | https://www.debian.org/ | Package-specific licenses |

Exact upstream versions and source archive hashes are recorded in
`versions.env`. Copies of the FFmpeg, MPV, and Tesseract license files are
installed under `/opt/media/share/licenses` in the image. Subtitle Edit's
license is included in its official release archive under `/opt/subtitleedit`.

The repository's MIT license applies only to the original packaging and
integration files in this repository. It does not replace any third-party
license.
