# Third-party software

This repository contains original packaging, integration, patch, and documentation files. The resulting image builds or includes independent third-party projects under their own licenses.

| Component | Source | License |
|---|---|---|
| Subtitle Edit | https://github.com/SubtitleEdit/subtitleedit | MIT |
| Avalonia | https://github.com/AvaloniaUI/Avalonia | MIT |
| .NET | https://github.com/dotnet/runtime | MIT and component-specific notices |
| jlesage baseimage-gui | https://github.com/jlesage/docker-baseimage-gui | MIT |
| noVNC | https://github.com/novnc/noVNC | MPL-2.0 |
| TigerVNC | https://github.com/TigerVNC/tigervnc | GPL-2.0-or-later and component-specific licenses |
| Openbox | https://github.com/danakj/openbox | GPL-2.0-or-later |
| FFmpeg | https://ffmpeg.org/ | LGPL/GPL; Ubuntu package configuration applies |
| libplacebo | https://code.videolan.org/videolan/libplacebo | LGPL-2.1-or-later |
| MPV | https://github.com/mpv-player/mpv | GPL-2.0-or-later by default |
| Tesseract OCR | https://github.com/tesseract-ocr/tesseract | Apache-2.0 |
| Intel media driver | https://github.com/intel/media-driver | MIT |
| Mesa | https://gitlab.freedesktop.org/mesa/mesa | MIT and component-specific licenses |
| Ubuntu packages | https://ubuntu.com/ | Package-specific licenses |

Exact source commits, container image digests, and downloaded package checksums are recorded in `versions.env`.

The build copies Subtitle Edit’s license to `/opt/subtitleedit/LICENSE` and the Avalonia license and notice to `/opt/subtitleedit/licenses`. Ubuntu package copyright and license files remain available under `/usr/share/doc` in the image. The jlesage runtime and its browser, VNC, window-manager, audio, and supporting components retain their upstream license notices.

The repository’s MIT license applies only to the original material in this repository. It does not replace or modify the licenses of any included third-party software.
