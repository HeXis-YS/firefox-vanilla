# Firefox Vanilla

**Firefox Vanilla** is a customized build of Firefox based on the **Firefox 128 ESR** branch, focused on delivering maximum performance for Windows and Android. While initially designed as a "vanilla" version of Firefox, this project now incorporates several advanced optimizations and enhancements, including Betterfox for configuration tuning, zlib-ng for improved compression, and experimental integration with mimalloc.

## Roadmap

- [x] Android PGO
- [x] Better PGO Process (Speedometer, MotionMark, JetStream)
- [x] Betterfox (Fastfox configuration)
- [x] zlib-ng integration
- [x] Context-sensitive PGO (Not available for Rust code on Windows due to limitations in the Rust toolchain)
- [x] Android compiler wrapper
- [x] Windows compiler wrapper
- [ ] Patched libhoudini for AVD
- [ ] ~~mimalloc integration~~
- [ ] ~~Migration from ESR branch to Release branch~~

## Benchmark

### Testing Environment
- **CPU**: AMD R9-7950X
- **Memory**: 2*48GB DDR5@5200MHz
- **GPU**: RTX4060 8GB
- **SSD**: Intel Optane P5800X 1.6TB
- **Display**: 2560*1440 @ 75Hz
- **OS**: Windows 10 LTSC 2021

### Testing Candidates
- **Firefox Official 128.3.1 ESR**: The official Firefox ESR release
- **[Mercury 129.0.2 AVX2](https://github.com/Alex313031/Mercury/releases/tag/v.129.0.2)**: Mercury 129.0.2 with AVX2 support. All extensions were disabled.
- **[Firefox tete009 SSE3 132.0.1](https://tete009.pages.dev/en-US/software)**: Someone claim this is the fastest Firefox.
- **Firefox Vanilla 128.3.1 ESR**: Firefox Vanilla build for x86-64-v3, with internal jemalloc allocator.
- **Firefox Vanilla (mimalloc) 128.3.1 ESR**: Firefox Vanilla build for x86-64-v3, with dll intected mimalloc allocator.

### Benchmark Result
| Browser Version                        | Octane 2.0     | Speedometer 2.1   | Speedometer 3.0     | JetStream 3.0    | MotionMark 1.3.1 (large @ 60fps) |
|----------------------------------------|----------------|-------------------|---------------------|------------------|----------------------------------|
| Firefox Official 128.3.1 ESR           | 56452          | 451±11            | 27.7±0.51           | 166.108          | 1567.68±2.63%                    |
| Mercury 129.0.2 AVX2                   | 56415 (-0.07%) | 354±4.7 (-21.50%) | 22.4±0.23 (-19.13%) | 165.285 (-0.05%) | 1263.85±2.75% (-19.38%)          |
| Firefox tete009 SSE3 132.0.1           | 58015 (+2.77%) | 461±9.8  (+2.22%) | 28.1±0.46  (+1.44%) | 162.738 (-2.03%) | 1560.05±2.86%  (-0.49%)          |
| Firefox Vanilla 128.3.1 ESR            | 56669 (+0.38%) | 460±7.9  (+2.00%) | 28.3±0.37  (+2.17%) | 172.434 (+3.81%) | 1810.58±2.86% (+15.50%)          |
| Firefox Vanilla (mimalloc) 128.3.1 ESR | 57559 (+1.96%) | 468±8.7  (+3.77%) | 27.7±0.33  (+0.00%) | 178.084 (+7.21%) | 1727.27±2.77% (+10.18%)          |

## Features

- **Aggressive optimizations**: Aggressive optimization strategy was used in the build, trading some of the security for better performance.
- **Lightweight**: Many unnecessary components are removed or disabled.
- **PGO and Full LTO**: An improved testing process was used for PGO optimization, and the Android version enjoys the same optimizations.

- **Aggressive optimizations**: Employs an aggressive optimization strategy, trading some security features for increased performance.
- **Selective Component Removal**: Disables or removes non-essential components to enhance speed and reduce memory usage.
- **zlib-ng integration**: Replaces the original zlib with zlib-ng, boosting performance for tasks involving network requests, PNG decoding, and caching. This integration provides a significant speedup for Firefox’s compression and decompression workloads.
- **Enhanced PGO and Full LTO**: The PGO process has been refined to maximize performance, benefiting both desktop and Android builds.

## Supported Platforms and Architectures

Currently, the project supports building for:
- **Windows (x86_64)**
- **Android (aarch64)**

## System Requirements

Note: These configurations are not strict requirements. They are based on what worked for testing but can vary based on your system setup.

### Windows
1. Windows 10 or later; Windows 10 21H2 or newer is recommended.
2. At least 40 GiB of available disk space (SSD highly recommended).
3. Full-LTO builds can consume up to ~50 GiB of RAM; 64 GiB of physical RAM is recommended.

### Android
1. Debian 12 or later; other Debian-based Linux distributions may also work.
2. At least 80 GiB of available disk space (SSD highly recommended).
3. Full-LTO builds can consume up to ~50 GiB of RAM; 64 GiB of physical RAM is recommended.
4. The PGO process requires a working desktop environment with hardware-based virtualization and may use ~30 GiB of RAM.

## Build Guide

1. Clone this project:
   ```bash
   git clone https://github.com/HeXis-YS/firefox-vanilla
   cd firefox-vanilla
   ```
   Alternatively, you can download the zip package directly.

2. **For Windows**: Run the following script to install the Mozilla build environment:
   ```bash
   install-mozilla-build.bat
   ```
   This will install the build environment to `C:\mozilla-build`.
   Once installed, start the shell with:
   ```bash
   C:\mozilla-build\start-shell.bat
   ```

3. Prepare the source code and build environment:
   ```bash
   ./bootstrap.sh (windows|android)
   ```

4. Build Firefox:
   ```bash
   ./build.sh (windows|android)
   ```

5. The build process may take several hours, depending on your system performance. So sit back, relax, and maybe enjoy a cup of coffee while you wait.

## Notes

- **Personal Project**: This project was created as a personal pursuit of performance optimization. It’s tailored to my own needs and may not meet all use cases.
- **Feature Requests and Compatibility**: This project is not designed to accommodate feature requests or platform compatibility enhancements. For specific needs, forking the project is recommended.

## Contributions

This is a personal project, but contributions that improve performance or simplify the build process are welcome.

## Acknowledgement

- [Mozilla Firefox](https://github.com/mozilla/gecko-dev)
- Jamie Nicol ([@jamienicol](https://github.com/jamienicol))
- [Mercury](https://github.com/Alex313031/Mercury)
- [Fennec F-Droid](https://f-droid.org/packages/org.mozilla.fennec_fdroid)
- [Webkit](https://github.com/WebKit)
- [Betterfox](https://github.com/yokoffing/Betterfox)
- [zlib-ng](https://github.com/zlib-ng/zlib-ng)

## License

[Mozilla Public License 2.0](https://www.mozilla.org/en-US/MPL/2.0/)
