# Expose select CUDA tools as top-level packages.
# The cudaPackages scope itself is added by cudaScopeOverlay in pkgs-module.nix.
final: prev: {
  # Convenience aliases for commonly used CUDA packages
  # These are only useful when cudaPackages is available.
}
