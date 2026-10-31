# jfc-net_webrtc
The [jfc-net](https://github.com/jfcameron/jfc-net) transport interface, implemented over browser WebRTC data channels, built with Emscripten.

API documentation: https://jfcameron.github.io/jfc-net_webrtc/

## Getting Started
Install cmake 3.21 or greater, Emscripten and node
```
# initialize the tree
git submodule update --init --recursive

# generate the script to build the library and its tests
emcmake cmake --preset emscripten-test

# build the library and tests
cmake --build --preset emscripten-test

# run the tests
ctest --preset emscripten-test
```
See `CMakePresets.json` for the presets. See `.github/workflows/ci.yml` to see exactly how CI runners build it.

To use it from another project, add it with `add_subdirectory` and link `jfcnet_webrtc`, which links the JavaScript bridge too. The installed package is `jfc-net_webrtc`, target `jfc::net_webrtc`. A project that has already added jfc-net gets one copy of it. It builds for the browser only: a native project uses [jfc-net_enet](https://github.com/jfcameron/jfc-net_enet).

## Overview
### `webrtc_host`
The same polled host as every other jfc-net transport. The caller exchanges opaque offer and answer descriptions, configures any STUN and TURN services, and supplies elapsed time for connection deadlines. It starts no threads, timers or application loop. See [the browser backend guide](docs/webrtc.md) for setup, delivery limits and tests.
