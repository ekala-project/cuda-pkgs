# JetPack ↔ L4T ↔ CUDA version matrix.
# Each entry contains all version-specific parameters needed to construct a jetpack scope.
{
  v5 = {
    jetpackVersion = "5.1.7";
    l4tVersion = "35.6.5";
    cudaVersion = "11.4.298";
    # L4T r35 uses l4tVersion for libnvidia-ptxjitcompiler.so versioning
    cudaDriverVersion = null;
    bspHash = "sha256-A0HUPHLUtx9dVqG9kM92MfbWoAc2E35AqgZiWK/S/lk=";
  };

  v6 = {
    jetpackVersion = "6.2.3";
    l4tVersion = "36.5.2";
    cudaVersion = "12.6.10";
    cudaDriverVersion = "540.5.0";
    bspHash = "sha256-dSMmJkxeFoJtMESnjlmuBhCUZ9N3BRQ7lOZkyRpHH0c=";
  };

  v7 = {
    jetpackVersion = "7.2.1";
    l4tVersion = "39.2.1";
    cudaVersion = "13.2.1";
    cudaDriverVersion = "595.78";
    bspHash = "sha256-LlYZCIuojoXaslJH8DPXBlm29nb/g1F2oHdm3LD9vms=";
  };
}
