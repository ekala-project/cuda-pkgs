# Post-processing overlay for cudaPackages scope
# Applied after auto-discovered packages
final: prev: {
  # NCCL releases from 2.27 onward require CUDA 12. Pin the last release that supports older
  # toolkits here so ./cuda/pkgs/nccl.nix stays a plain version/hash pair for ekapkgs-update.
  nccl =
    if final.cudaOlder "12.0" then
      prev.nccl.overrideAttrs (
        finalAttrs: prevAttrs: {
          version = "2.25.1-1";
          src = prevAttrs.src.override {
            tag = "v${finalAttrs.version}";
            hash = "sha256-3snh0xdL9I5BYqdbqdl+noizJoI38mZRVOJChgEE1I8=";
          };
          passthru = prevAttrs.passthru // {
            ekapkgs-update.skip = true;
          };
        }
      )
    else
      prev.nccl;
}
