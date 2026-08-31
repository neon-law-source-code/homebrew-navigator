# Homebrew Navigator

The Homebrew tap for the [Neon Law Navigator](https://github.com/neon-law-source-code/navigator) CLI.

```bash
brew install neon-law-source-code/navigator/navigator
```

That one line taps this repository and installs `navigator`. Upgrades come with `brew upgrade navigator`, and the
formula is bumped automatically minutes after each Navigator release, so a `brew update && brew upgrade` is always
enough.

## What you get

| Platform | How it installs |
| --- | --- |
| macOS, Apple silicon | Downloads the release archive. Seconds. |
| Linux, x86_64 | Downloads the release archive. Seconds. |
| macOS, Intel | Compiles the source tag. Needs a Rust toolchain, which brew installs; takes tens of minutes. |
| Linux, arm64 | Compiles the source tag. Same cost. |

A Navigator release publishes prebuilt archives for two architectures — `macos-latest` is Apple silicon and the
container images are x86_64 Linux — so the other two platforms compile the immutable source tag instead. The result is
the same binary reporting the same version; only the wait differs.

**On macOS, Homebrew is the install path that works.** The released binary is unsigned and unnotarized, and Gatekeeper
blocks an unsigned Mach-O downloaded through a browser outright. Homebrew fetches with `curl`, which sets no
`com.apple.quarantine` attribute, so the same bytes run. Signing the release is still the right fix; this is what
stands in until it lands.

## How a release reaches this tap

1. Someone pushes a `YY.M.D` tag to `neon-law-source-code/navigator`.
2. That repository's `deploy.yml` proves the workspace, publishes the images, and builds three CLI archives on the
   free `windows-latest`, `ubuntu-latest`, and `macos-latest` runners, attaching them to the GitHub Release.
3. Its `release-homebrew-tap` job fires a `repository_dispatch` at this repository carrying the tag.
4. [`.github/workflows/bump.yml`](.github/workflows/bump.yml) downloads each published artifact, computes its sha256,
   rewrites [`Formula/navigator.rb`](Formula/navigator.rb), installs and tests the result on the runner, and pushes.

**The digests are computed here, from the published bytes.** The dispatch carries a tag and nothing else. A payload
carrying digests would let a malformed dispatch pin the formula to bytes nobody verified, and it would mean this
repository could not repair itself from a bare tag.

### Bumping by hand

Both halves work standalone. Run the workflow from the Actions tab (`bump` → *Run workflow* → the tag), or locally:

```bash
scripts/bump.sh 26.8.17
```

The script patches anchored lines and then asserts the result — a structural edit to the formula that breaks the patch
fails loudly rather than committing a formula whose URL and digest describe different releases. Edit the formula's
structure freely; the five values it moves are not yours to hand-edit.

## Testing

[`.github/workflows/test.yml`](.github/workflows/test.yml) installs and tests the formula on every push and pull
request for the two prebuilt platforms, and weekly for the two that compile from source. All four runner classes are
free for public repositories.

The weekly run also checks that the formula still points at the newest Navigator release. Every other job proves the
formula it finds installs; none of them notices when the bump stops running, which is how `brew install` came to serve
a version two releases behind for three days.

## Licence

Navigator is **source-available, not open source**, under the [Business Source License 1.1](LICENSE): `BUSL-1.1`. This
tap is offered under the same terms. Read it, build it, fork it, redistribute it, and make any non-production use of
it. **Production use needs a commercial licence** from Shook Law PLLC. Four years after a version is published, that
version converts to `AGPL-3.0-only` and the restriction ends for it permanently.

The formula installs the licence text alongside the binary, because BUSL requires it to be displayed on every copy of
the Licensed Work, and whoever runs `brew install` holds the binary rather than this repository.

Copyright (C) 2026 **Shook Law PLLC**.

The NEON LAW marks are reserved — BUSL grants rights in copyright, not in trademarks, so nothing in `LICENSE` reaches
the name. Outside contributions are currently closed; reach the maintainers at <contact@neonlaw.org>.
