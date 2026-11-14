---
name: update-cuda-pkgs
description: Update cuda-pkgs to newer NVIDIA releases — CUDA/cuDNN/cuTENSOR/TensorRT manifests, new cudaPackages_X_Y scopes, nccl, corepkgs/nix-lib pins, and JetPack sourceinfo. Use when asked to update, bump, or check for new versions in this repository.
---

# Updating cuda-pkgs

Most of this repo is driven by NVIDIA's `redistrib_<version>.json` manifests, not
by `version`/`hash` attributes, so generic updaters (ekapkgs-update, nix-update) only
cover `nccl`. Use the tools below, in this order, and keep mechanical updates and
judgement calls in separate commits.

| Tool | Covers |
|------|--------|
| `maintainers/update.py` | Manifest discovery/download, patch bumps, `pins.nix` |
| `ekapkgs-update update cudaPackages.nccl` | `cuda/pkgs/nccl.nix` (the only source-built package with an upstream release feed) |
| `maintainers/eval-sweep.sh` | Evaluating every derivation in every `cudaPackages_*` scope on x86_64-linux and aarch64-linux |

## 0. Setup

- Work on a branch off `master` (never commit to `master`).
- Export `GITHUB_TOKEN=$(gh auth token)`: TensorRT release discovery and ekapkgs-update
  hit the GitHub API, and the unauthenticated limit (60 req/h) fails quickly.
- Run `maintainers/eval-sweep.sh` first so you know the baseline: pre-existing failures
  are not yours to fix as part of an update, but mention them.

## 1. See what is available

```bash
maintainers/update.py check          # human-readable
maintainers/update.py check --json   # for scripting
```

The report has four parts:

- **Patch updates** — a newer release in the same major.minor series as a version that a
  scope selects. Mechanical; step 2.
- **New series** — e.g. CUDA 13.5 when the newest scope is 13.3, or cuDNN 9.28 when scopes
  use 9.22. Judgement required; step 4.
- **tensorrt** — NVIDIA publishes no manifest index for TensorRT, so the manifest is
  hand-written; step 5.
- **Pins** — `corepkgs` / `nix-lib` revisions; step 3.

## 2. Patch bumps (mechanical)

```bash
maintainers/update.py bump-patch     # --dry-run to preview
```

This downloads the new manifests, rewrites the selections in `pkgs-module.nix` (including
the `cudaMajorMinorPatchVersion` argument for `cuda`), and deletes manifests no scope
selects any more. Then:

1. `maintainers/eval-sweep.sh` — must not introduce new failures.
2. Diff the package set of the old and new manifest
   (`jq -r 'keys[]' <old> <new> | sort | uniq -u`). A patch release can add or drop a
   package; if it does, handle it as in step 4.4.
3. Commit, one commit per scope:
   `cudaPackages_12_8: cuda 12.8.1 -> 12.8.2`

## 3. Pins

```bash
maintainers/update.py pins
maintainers/eval-sweep.sh
```

corepkgs changes can break evaluation anywhere (e.g. its `srcOnly` differs from nixpkgs').
If the sweep regresses, find the corepkgs change responsible (`git log` between the two
revs in a corepkgs checkout at `../corepkgs`) and fix this repo, or report it if it is a
corepkgs bug. Commit as `pins: update corepkgs and nix-lib` (or name only the one that
moved).

## 4. New CUDA / cuDNN / cuTENSOR series (judgement)

**Ask the user before adding or removing a `cudaPackages_X_Y` scope or moving the default
`cudaPackages`.** The README promises a specific supported set (currently stated in
`README.md`), so this is a policy decision, not a mechanical one. Suggest a plan — usually
"replace the newest scope with the newest series and keep the oldest supported 12.x" — and
wait for an answer.

Once agreed:

1. **Fetch**: `maintainers/update.py fetch cuda=13.5.0 cudnn=9.28.1 cutensor=2.8.1`.
2. **Scope** in `pkgs-module.nix`: add/rename the `cudaPackages_X_Y = mkCudaPackages { ... } "X.Y.Z";`
   entry, and update `cudaPackages = final.cudaPackages_X_Y;` if the default moves. Remove
   manifests that are no longer selected.
3. **Compatibility data** in `cuda/db/`:
   - `nvcc-compat.nix`: add an `"X.Y"` entry with the supported GCC/Clang range from the
     "Host compiler support" table in NVIDIA's CUDA Installation Guide for Linux for that
     release. Without it `backendStdenv` has no compiler range and every source build fails.
     Check the range is satisfiable with the GCC versions corepkgs ships
     (`nix-instantiate --eval -E 'builtins.filter (n: builtins.match "gcc[0-9]+" n != null) (builtins.attrNames (import ./. {}))'`).
   - `capabilities.nix`: add new GPU architectures, and set `maxCudaMajorMinorVersion` /
     `dontDefaultAfterCudaMajorMinorVersion` for architectures the release drops or
     deprecates (see the release notes' "Deprecated or Dropped Features").
4. **Package set**: compare the new manifest's packages with the previous one's:
   ```bash
   keys() { jq -r 'to_entries[] | select(.value|type=="object") | .key' "$1" | sort; }
   comm -3 <(keys cuda/manifests/cuda/redistrib_OLD.json) <(keys cuda/manifests/cuda/redistrib_NEW.json)
   ```
   (left column: dropped, right column: new). Many manifest entries are intentionally not
   packaged (drivers, Nsight, fabricmanager, Windows-only tools); `comm -23 <(keys NEW) <(ls cuda/pkgs | sed 's/\.nix$//' | sort)`
   lists everything unpackaged. A new *library* or *compiler component* usually deserves a
   `cuda/pkgs/<name>.nix` using `buildRedist` (copy a similar package; pick `outputs` by
   inspecting the archive layout) — ask if unsure. Dropped packages need nothing —
   `buildRedist` marks them unsupported for that scope — but check nothing else depends on
   them unconditionally.
5. **cuDNN / cuTENSOR / TensorRT selection**: only select a version whose manifest
   supports the scope's CUDA major (`cuda_variant` contains it, or per-platform entries
   have a `cudaNN` key). Different scopes can select different versions.
6. **Docs**: update the supported-versions sentence in `README.md` and any version lists in
   `AGENTS.md`.
7. Validate (step 6) and commit, e.g. `cudaPackages_13_5: init at 13.5.0` and
   `cudaPackages_13_3: remove`.

## 5. TensorRT (hand-written manifest)

`check` reports the newest TensorRT release from GitHub. To add it:

1. Copy the previous `cuda/manifests/tensorrt/redistrib_<ver>.json` to the new version and
   update `release_date`, `release_label`, `version`, `cuda_variant`, and every
   `relative_path` (tarballs live under
   `https://developer.download.nvidia.com/compute/machine-learning/` + `relative_path`;
   find the exact file names in the TensorRT install guide/release notes for that version).
2. Fill in hashes with `nix store prefetch-file --json --hash-type sha256 <url>` (convert
   the SRI hash to hex with `nix hash convert --hash-algo sha256 --to base16 <sri>`). Each tarball is several GB:
   **ask the user before downloading them.**
3. Select it in the relevant scopes in `pkgs-module.nix`, remove the old manifest if
   unused, validate, and commit as `cudaPackages.tensorrt: 10.16.1 -> 11.4.0`.

A TensorRT major bump (10 -> 11) can change library names and the archive layout; review
`cuda/pkgs/tensorrt.nix` against the new tarball before assuming it still works.

## 6. nccl

```bash
GITHUB_TOKEN=$(gh auth token) NIXPKGS_ALLOW_UNFREE=1 \
  ../ekapkgs-update/target/release/ekapkgs-update update cudaPackages.nccl --commit
```

(Use `ekapkgs-update` from `PATH` if installed.) It rewrites `version`/`hash` in
`cuda/pkgs/nccl.nix`, builds it, and commits as `cudaPackages.nccl: <old> -> <new>`. The
pre-CUDA-12 pin lives in `cuda-packages.nix` and is marked `ekapkgs-update.skip`; only
touch it by hand. Read the NCCL release notes for a raised minimum CUDA version — if the
new release drops a CUDA major that a scope still uses, extend the pin in
`cuda-packages.nix` instead of letting the old scope break.

## 7. JetPack (only if `jetpack/` exists)

- Debs: `jetpack/sourceinfo/debs-update.py r<l4t-version> > jetpack/sourceinfo/r<major.minor>-debs.json`
- Git repos: `jetpack/sourceinfo/gitrepos-update.py` (see its usage line).
- BSP: bump `l4tVersion` / `bspHash` in `jetpack/db/versions.nix` (prefetch the
  `Jetson_Linux_R<ver>_aarch64.tbz2` URL built in `jetpack/bsp/default.nix`).
- Validate with `maintainers/eval-sweep.sh -s aarch64-linux jetpack.v5 jetpack.v6 jetpack.v7`
  — many jetpack attributes already fail on missing corepkgs packages, so compare against
  the baseline rather than expecting zero failures. Jetson changes cannot be built or
  tested without aarch64 hardware; say so in the PR.

## Validation (every step)

1. `maintainers/eval-sweep.sh` — no new failures compared with the baseline.
2. Build a representative sample on x86_64 (the configured remote builder is x86_64-only;
   aarch64 can only be evaluated):
   `nix-build --arg config '{ allowUnfree = true; }' -A cudaPackages.cuda_cudart -A cudaPackages.libcublas --no-out-link`
   Builds of new redistributables are cheap (download + patchelf); source builds (`nccl`)
   are slow — run them in the background.
3. `nix fmt <changed .nix files>`.

## Commits and PRs

- Message formats (from `AGENTS.md`): `cudaPackages.<pname>: <old> -> <new>`,
  `cudaPackages.<pname>: init at <version>`; for whole scopes,
  `cudaPackages_X_Y: cuda <old> -> <new>`.
- One logical change per commit; manifest downloads go in the same commit as the
  selection change that uses them.
- Don't push, force-push, or open PRs unless the user asks. When opening one, list what
  was evaluated vs built, the eval-sweep summary, and anything left for manual follow-up
  (TensorRT hashes, Jetson hardware testing, new-series decisions).
