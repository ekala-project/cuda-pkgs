# Agent Guide for cuda-pkgs

This repository is the CUDA vertical slice for the ekapkgs poly-repo Nixpkgs fork, built on [ekala-project/corepkgs](https://github.com/ekala-project/corepkgs).

## Repository Layout

| Path | Purpose |
|------|---------|
| [`default.nix`](default.nix) | Entry point; imports pins and applies `pkgs-module.nix` via the corepkgs module system |
| [`pins.nix`](pins.nix) | Pinned Git dependencies (`corepkgs`, `nix-lib`) |
| [`pkgs-module.nix`](pkgs-module.nix) | Module that wires up the cudaPackages scope via overlays |
| [`cuda-packages.nix`](cuda-packages.nix) | Post-processing overlay for aliases and overrides applied after auto-called entries |
| [`top-level.nix`](top-level.nix) | Promotes select CUDA packages to top-level CLI applications |
| [`repos-packages.nix`](repos-packages.nix) | Standalone helper for validation/testing |
| [`cuda/lib/`](cuda/lib/) | CUDA utility functions (gencode flags, capability formatting, redist URLs) |
| [`cuda/db/`](cuda/db/) | Static data (GPU capabilities, NVCC compiler compatibility, redist metadata) |
| [`cuda/manifests/`](cuda/manifests/) | NVIDIA JSON redistributable manifests |
| [`cuda/build-redist/`](cuda/build-redist/) | Builder for NVIDIA redistributable packages |
| [`cuda/backend-stdenv/`](cuda/backend-stdenv/) | CUDA-aware stdenv with compatible GCC version |
| [`cuda/scope/`](cuda/scope/) | Scope constructor that builds a complete cudaPackages set |
| [`cuda/pkgs/`](cuda/pkgs/) | Auto-discovered CUDA package expressions |
| [`pkgs-many/cuda-packages/`](pkgs-many/cuda-packages/) | mkManyVariants for versioned cudaPackages (12.8, 13.3) |
| [`pkgs/`](pkgs/) | Native (non-CUDA) package expressions |

## How Packages Are Discovered

CUDA packages in `cuda/pkgs/` are auto-discovered by the scope constructor. The file/directory name becomes the attribute name in `cudaPackages`.

```
cuda/pkgs/libcublas.nix         -->  cudaPackages.libcublas
cuda/pkgs/cuda-cudart.nix       -->  cudaPackages.cuda_cudart
cuda/pkgs/setup-cuda-hook/      -->  cudaPackages.setupCudaHook
```

## Package Types

### Redistributable packages (most common)

Binary packages fetched from NVIDIA's CDN using manifest JSON files:

```nix
{ buildRedist }:
buildRedist {
  redistName = "cuda";
  pname = "libcublas";

  outputs = [
    "out"
    "dev"
    "include"
    "lib"
    "static"
    "stubs"
  ];

  meta = {
    description = "CUDA Basic Linear Algebra Subroutine library";
    homepage = "https://developer.nvidia.com/cublas";
  };
}
```

### Source-built packages

Packages built from source (like nccl, cutlass):

```nix
{
  backendStdenv,
  cuda_cudart,
  cuda_nvcc,
  fetchFromGitHub,
  ...
}:
backendStdenv.mkDerivation {
  pname = "nccl";
  version = "2.30.7-1";
  src = fetchFromGitHub { ... };
  # ...
}
```

## Commit Message Format

```
cudaPackages.<pname>: init at <version>
```

For updates: `cudaPackages.<pname>: <version_old> -> <version_new>`

## Validation

```bash
# Evaluate (catches syntax/dependency errors)
nix-instantiate -A cudaPackages.<pname>

# Build
nix-build -A cudaPackages.<pname>

# Specific CUDA version
nix-instantiate -A cudaPackages.variants.v12_8.<pname>

# Format
nix fmt <path-to-file>
```

## External Dependencies

| Pin | Repository | Purpose |
|-----|-----------|---------|
| `core` | [ekala-project/corepkgs](https://github.com/ekala-project/corepkgs) | Base package set and module system |
| `lib` | [jonringer/nix-lib](https://github.com/jonringer/nix-lib) | `mkAutoCalledPackageDir`, `composeManyExtensions`, and other helpers |
