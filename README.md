# Temporary CoA Extensions.dll builder

This repository builds the maintained
[`firstoni-dev/ascension-extensions-reconstruction`](https://github.com/firstoni-dev/ascension-extensions-reconstruction)
source on GitHub's standard `windows-2022` runner.

The workflow uses the 32-bit MSVC environment, explicitly leaves
`ASCENSION_NATIVE_LOGON` and `ASCENSION_HOT_PATCH` disabled, verifies that the result is a
PE32 i386 DLL, and publishes the DLL with its source commit and SHA-256 as a one-day
artifact.

From the Linux host, run:

```bash
cd /home/drauku/games/wowcoa/coa-extensions-builder-temp
./run-github-build.sh
```

The downloaded result will be placed under `output/run-<id>/`. This workflow does not
install or replace the game client's existing DLL.
