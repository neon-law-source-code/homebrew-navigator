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
# ONE ACQUISITION PATH NOW: arm64 macOS and x86_64 Linux download the archive
# `deploy.yml` attaches to its Release, mirrored here (ENG-931 below). Intel
# macOS and arm64 Linux have no prebuilt archive and this formula no longer
# compiles a fallback for them — see ENG-931 in both `on_intel` blocks below for
# why.
#
# ENG-931: NAVIGATOR'S SOURCE REPOSITORY STOPPED BEING THE RELEASE HOST. Every
# `url` line here used to name `neon-law-source-code/navigator` — the source
# tree — because that repository's own Release carried the archives. It will
# not stay public, so `deploy.yml` now mirrors the same tag-exact archives onto
# THIS repository's own Release as well, and every `url` line below names this
# repository instead. `scripts/bump.sh` computes every digest from those bytes,
# same as it always did — only the host moved.
#
# The source-tarball fallback for Intel macOS and arm64 Linux is gone rather
# than moved, because it compiled `neon-law-source-code/navigator`'s ENTIRE
# workspace tarball — the whole private monorepo once that repository stops
# being public, not something this tap may mirror (ENG-931's boundary: never
# mirror the whole private monorepo, only the allowlisted LSP/rules source).
# Compiling a fallback from a mirrored tarball of just `cli/` was considered and
# rejected: the CLI's `Cargo.toml` names path dependencies elsewhere in the
# workspace, so a partial mirror would not build either, and maintaining a
# second, narrower source export for two platforms with no prebuilt archive
# cost more than documenting the reduced matrix these two `odie` calls state.
#
# Homebrew is also what makes the macOS binary usable at all, independent of
# any of the above. It is unsigned and unnotarized, and Gatekeeper blocks a
# *browser*-downloaded unsigned Mach-O outright; brew fetches with curl, which
# sets no `com.apple.quarantine` attribute, so the same bytes run. Signing is
# still worth doing — this is a workaround for its absence, not a replacement.
class Navigator < Formula
  desc "Neon Law Navigator CLI — legal workflow, notation, and deployment tooling"
  # ENG-931: the product page, not the source repository — `brew audit
  # --online` fetches this and needs it to keep resolving once the source
  # repository is private. `webapp::source_repository::NAVIGATOR_HREF` is the
  # same URL the public footer links.
  homepage "https://www.neonlaw.com/navigator"
  version "26.9.28"
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
      url "https://github.com/neon-law-source-code/homebrew-navigator/releases/download/26.9.28/navigator-26.9.28-macos.tar.gz"
      sha256 "d7209ba997ae442a1685d9947a63ea09a06a81ecc6c3c39409287660537a6ff5"
    end

    on_intel do
      # ENG-931: no prebuilt archive exists for Intel macOS — `macos-latest` is
      # Apple silicon — and this formula no longer falls back to compiling the
      # source tag. That tag used to be `neon-law-source-code/navigator`'s own
      # tarball; once that repository stops being public the tarball is gone,
      # and mirroring the whole private monorepo here to keep it working is
      # exactly what ENG-931 forbids. See the header comment above.
      odie "no prebuilt navigator archive exists for Intel macOS, and this " \
           "formula no longer compiles one from source. Install on Apple " \
           "silicon or x86_64 Linux instead, or use the Linux install script " \
           "(see docs/gitops.md's Homebrew tap section in the Navigator " \
           "repository) inside a container or VM on this machine."
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/neon-law-source-code/homebrew-navigator/releases/download/26.9.28/navigator-26.9.28-linux.tar.gz"
      sha256 "758dec46bdc918d2f30cdc4a6b831e2aca7866235be57af4caed1a03d198c88e"
    end

    on_arm do
      # Same reasoning as Intel macOS above: the release publishes x86_64
      # Linux only, and there is no source-tag fallback left to compile.
      odie "no prebuilt navigator archive exists for arm64 Linux, and this " \
           "formula no longer compiles one from source. Install on x86_64 " \
           "Linux or Apple silicon instead."
    end
  end

  def install
    # Every supported platform now installs the same way: the one prebuilt
    # archive its `on_macos`/`on_linux` block named. Nothing reaches `install`
    # for Intel macOS or arm64 Linux — the `odie` calls above abort before
    # Homebrew gets here — so there is no second branch to keep in sync with
    # them.
    bin.install "navigator"

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
    # Every prebuilt archive carries `navigator`, `LICENSE`, `NOTICE` and
    # nothing else at its root.
    prefix.install "LICENSE"
    prefix.install "NOTICE"
  end

  test do
    # The one assertion worth making: the binary reports the version this
    # formula claims. It catches a bump that patched the URL but not the
    # `version` line, and a stale asset served under a new tag.
    assert_match version.to_s, shell_output("#{bin}/navigator --version")
  end
end
