# CUDA Pkgs for poly-repo Nixpkgs

This is the CUDA vertical slice for the ekapkgs poly-repo nixpkgs fork.
It provides versioned `cudaPackages` scopes containing NVIDIA redistributable
packages and source-built CUDA libraries.

Two CUDA toolkit versions are supported: **12.8** and **13.3**.

## Structure

```
default.nix            # Entry point, returns pkgs + our changes in this repo
pkgs-module.nix        # Module that adds cudaPackages scopes via overlays.pkgs
cuda-packages.nix      # cudaPackages overlay for aliases/overrides, applied via overlays.cuda
top-level.nix          # Top-level overlay for promoting CUDA tools to pkgs scope

cuda/
  pkgs/                # CUDA package expressions, auto-discovered by scope constructor
  lib/                 # Utility functions (gencode flags, capability formatting, redist URLs)
  db/                  # Static data (GPU capabilities, NVCC compiler compatibility)
  manifests/           # NVIDIA JSON redistributable manifests
  build-redist/        # Builder for NVIDIA redistributable binary packages
  backend-stdenv/      # CUDA-aware stdenv with compatible GCC version selection
  scope/               # Scope constructor that assembles a complete cudaPackages set
```

## Usage

Most CUDA packages are unfree, so pass `config.allowUnfree = true` (or
`--arg config '{ allowUnfree = true; }'` on the command line).

```nix
# As a standalone package set
let pkgs = import ./. { config.allowUnfree = true; };
in pkgs.cudaPackages.libcublas

# Specific CUDA version
let pkgs = import ./. { config.allowUnfree = true; };
in pkgs.cudaPackages_12_8.cuda_cudart

# As a module in another ekapkgs repo
import core {
  modules = [ ./pkgs-module.nix ];
}
```

## Extending cudaPackages

Every versioned scope (`cudaPackages_12_8`, `cudaPackages_13_3`, and therefore
`cudaPackages`) is built with `lib.makeScope` and applies the overlays listed in
`config.overlays.cuda`. The option is declared by corepkgs alongside
`overlays.python`, `overlays.lua`, etc. To add or override packages in all CUDA
versions at once:

```nix
import ./. {
  modules = [
    {
      overlays.cuda = [
        (final: prev: {
          libcublas = prev.libcublas.overrideAttrs (old: { /* ... */ });
        })
      ];
    }
  ];
}
```

A single scope can still be adjusted with
`cudaPackages_12_8.overrideScope (final: prev: { ... })`.

## Packages

32 packages across core runtime, math libraries, profiling tools, and
higher-level frameworks:

| Category | Packages |
|----------|----------|
| Runtime | `cuda_cudart`, `cuda_nvcc`, `cuda_nvrtc`, `cccl`, `cuda_crt` |
| Math | `libcublas`, `libcufft`, `libcurand`, `libcusolver`, `libcusparse` |
| ML | `cudnn`, `libcutensor`, `tensorrt`, `nccl` |
| Tools | `cuda_cupti`, `cuda_gdb`, `cuda_nvdisasm`, `cuda_sanitizer_api` |
| Misc | `libnpp`, `libnvjpeg`, `libnvjitlink`, `libnvvm`, `cuda_nvml_dev` |
