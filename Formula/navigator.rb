# The Neon Law Navigator CLI.
#
# THIS FILE IS REWRITTEN BY `scripts/bump.sh` ON EVERY RELEASE. Five values move
# — the version and four sha256 digests — and the script patches exactly those
# lines by anchored regex, then asserts the result. Structure is yours to edit
# by hand; the numbers are not.
#
# A sixth line, `version_scheme`, appears only once it is needed and is likewise
# the script's. Navigator publishes ordinary `YY.M.D` releases, same-day
# `YY.M.D-hotfix.N` prereleases, and `YY.M.D-rc.N` release candidates, and this
# formula follows whichever is newest, because it holds ONE version and every
# `brew install` resolves to it. But Homebrew's comparator is not semver — it
# ranks a `-hotfix.N` tag ABOVE the base version it patches — so a bump from a
# hotfix to that base version would read as a downgrade and `brew upgrade` would
# refuse to move. `bump.sh` detects that with Homebrew's own comparator and
# increments `version_scheme`, which outranks any lower-scheme keg regardless of
# version. A `-rc.N` tag never needs it: `rc` is a prerelease token Homebrew
# knows, so those already sort the way semver says. See `scripts/bump.sh`.
#
# The version literals here are deliberately absent. `bump.sh` rewrites the
# version on the `version` and `url` lines only, but it used to rewrite the
# whole file, and this paragraph named a release that became the formula's own
# outgoing version — so the substitution ate the example and left a sentence
# that no longer explained anything.
#
# Two acquisition paths, because the release publishes two prebuilt
# architectures and no more:
#
#   - arm64 macOS and x86_64 Linux download the archive `deploy.yml` attached to
#     the GitHub Release. Seconds, no toolchain.
#   - Intel macOS and arm64 Linux compile the immutable source tag. Minutes, and
#     a Rust toolchain — but it is the only honest option for a platform whose
#     bytes were never built.
#
# Homebrew is also what makes the macOS binary usable at all. It is unsigned and
# unnotarized, and Gatekeeper blocks a *browser*-downloaded unsigned Mach-O
# outright; brew fetches with curl, which sets no `com.apple.quarantine`
# attribute, so the same bytes run. Signing is still worth doing — this is a
# workaround for its absence, not a replacement.
class Navigator < Formula
  desc "Neon Law Navigator CLI — legal workflow, notation, and deployment tooling"
  homepage "https://github.com/neon-law-source-code/navigator"
  version "26.9.9-rc.1"
  # Navigator is BUSL-1.1: source-available, not open source. The workspace
  # manifest declares exactly that, and a formula that named a permissive
  # licence would offer recipients a grant Shook Law PLLC did not make. Read,
  # build, fork, and redistribute it freely; production use needs a commercial
  # licence until the version's Change Date, four years after it is published,
  # converts it to AGPL-3.0-only.
  license "BUSL-1.1"
  version_scheme 1

  on_macos do
    on_arm do
      url "https://github.com/neon-law-source-code/navigator/releases/download/26.9.9-rc.1/navigator-26.9.9-rc.1-macos.tar.gz"
      sha256 "d22acc8008ce037651eec616c489cd52dca1dbac2a35f76962e8e9e5016ee437"
    end

    on_intel do
      # No prebuilt x86_64 archive exists: `macos-latest` is Apple silicon, and
      # a second full release compile on the slowest runner class is not bought.
      # Compile the source tag instead.
      url "https://github.com/neon-law-source-code/navigator/archive/refs/tags/26.9.9-rc.1.tar.gz"
      sha256 "6ea521f4b77855739fd0b17037c207679124b4d816d50b8bab85c25e35c3c74b"

      depends_on "rust" => :build
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/neon-law-source-code/navigator/releases/download/26.9.9-rc.1/navigator-26.9.9-rc.1-linux.tar.gz"
      sha256 "fcb190418a3f4d9259ceffd3be41d2f3005ba01c193165d646b72398194411cd"
    end

    on_arm do
      # Same reasoning as Intel macOS: the release publishes x86_64 Linux only.
      url "https://github.com/neon-law-source-code/navigator/archive/refs/tags/26.9.9-rc.1.tar.gz"
      sha256 "6ea521f4b77855739fd0b17037c207679124b4d816d50b8bab85c25e35c3c74b"

      depends_on "rust" => :build
    end
  end

  def install
    # Which of the two URLs above was fetched is decided by the platform, and
    # the unpacked tree is the only thing that can tell us which one landed. A
    # prebuilt archive holds `navigator` at its root; a source tarball holds
    # `Cargo.toml`. Branch on the artifact rather than re-deriving the platform,
    # so the two can never disagree.
    if File.exist?("navigator")
      bin.install "navigator"
    else
      # `cli/build.rs` bakes this into `navigator --version`. Without it a
      # source build reports the workspace placeholder rather than the release
      # it was compiled from, and the `test do` block below would fail — which
      # is the point: the version a binary claims must be the version it is.
      ENV["NAVIGATOR_RELEASE_TAG"] = version.to_s
      system "cargo", "install", *std_cargo_args(path: "cli")
    end

    # LICENSE and NOTICE travel with the install, exactly as they travel with
    # the archive. These are Navigator's own two files, staged from whichever
    # tree was fetched — not this tap's; the binary carries its licence, and the
    # tap carries its own.
    #
    # BUSL requires the licence to be conspicuously displayed on every copy of
    # the Licensed Work, and it is the licence that tells the holder what they
    # may do — non-production use now, AGPL-3.0-only after the Change Date. A
    # recipient holds the binary rather than the repository — that is the whole
    # point of shipping one — so this is where the obligation is met or not at
    # all.
    #
    # NOTICE is the other half and was being dropped here. It is the file that
    # names the copyright holder, reserves the NEON LAW marks the licence does
    # not reach, and says where a commercial licence comes from. `deploy.yml`
    # stages it beside the executable in every release archive for exactly that
    # reason, and installing only LICENSE made brew — the install path macOS
    # users are told to use — the one route by which it never arrives.
    #
    # Both acquisition paths carry both files at their root: the prebuilt
    # archives hold `navigator`, `LICENSE`, `NOTICE` and nothing else, and the
    # source tag carries them at the tree root.
    prefix.install "LICENSE"
    prefix.install "NOTICE"
  end

  test do
    # The one assertion worth making: the binary reports the version this
    # formula claims. It catches a bump that patched the URL but not the
    # `version` line, a stale asset served under a new tag, and a source build
    # whose release tag never reached `build.rs`.
    assert_match version.to_s, shell_output("#{bin}/navigator --version")
  end
end
