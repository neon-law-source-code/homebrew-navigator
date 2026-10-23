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
  version "26.10.23"
  # The installed CLI offers either license; the tap has its own terms.
  license any_of: ["MIT", "Apache-2.0"]
  version_scheme 1

  on_macos do
    on_arm do
      url "https://github.com/neon-law-source-code/homebrew-navigator/releases/download/26.10.23/navigator-26.10.23-macos.tar.gz"
      sha256 "efc550a47aa7b3141fb0202536db1552ba7dc09b7fab6923b6f5249608f75815"
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
      url "https://github.com/neon-law-source-code/homebrew-navigator/releases/download/26.10.23/navigator-26.10.23-linux.tar.gz"
      sha256 "bc5c9d6b19e06e1c0d2bbc367d7a887304b7b92e249c7b8d153957d2b66a0a64"
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

    # Stage the CLI's own license grants and notices from the release archive.
    prefix.install "LICENSE", "LICENSE-MIT", "LICENSE-APACHE-2", "NOTICE"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/navigator --version")
    assert_match "MIT", shell_output("#{bin}/navigator --license")
    assert_match "Apache", shell_output("#{bin}/navigator --license")
    assert_match "license", shell_output("#{bin}/navigator --third-party-notices").downcase
    %w[LICENSE LICENSE-MIT LICENSE-APACHE-2 NOTICE].each do |name|
      assert_path_exists prefix/name
      refute_empty (prefix/name).read
    end
  end
end
