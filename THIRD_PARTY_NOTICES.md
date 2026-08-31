# Third-party software

This repository contains packaging and integration code. The resulting image
downloads, builds, or includes independent third-party projects under their own
licenses.

| Component | Source | License |
|---|---|---|
| Subtitle Edit | https://github.com/SubtitleEdit/subtitleedit | MIT |
| FFmpeg | https://ffmpeg.org/ | LGPL/GPL; Ubuntu package configuration applies |
| libplacebo | https://github.com/haasn/libplacebo | LGPL-2.1-or-later |
| MPV | https://github.com/mpv-player/mpv | GPL-2.0-or-later by default |
| Tesseract OCR | https://github.com/tesseract-ocr/tesseract | Apache-2.0 |
| LinuxServer Selkies base | https://github.com/linuxserver/docker-baseimage-selkies | Project and package-specific licenses |
| Ubuntu packages | https://ubuntu.com/ | Package-specific licenses |

Exact Subtitle Edit and Selkies pins are recorded in `versions.env`. FFmpeg,
libplacebo, MPV, and Tesseract are installed as a matched set from the Ubuntu
Resolute repositories; their package copyright files are retained under
`/usr/share/doc` in the image. Subtitle Edit's license is included in its
official release archive under `/opt/subtitleedit`.

The repository's MIT license applies only to the original packaging and
integration files in this repository. It does not replace any third-party
license.
