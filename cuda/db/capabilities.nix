{ lib }:
{
  cudaCapabilityToInfo =
    lib.mapAttrs
      (
        cudaCapability:
        {
          archName,
          isJetson ? false,
          isArchitectureSpecific ? (lib.hasSuffix "a" cudaCapability),
          isFamilySpecific ? (lib.hasSuffix "f" cudaCapability),
          minCudaMajorMinorVersion,
          maxCudaMajorMinorVersion ? null,
          dontDefaultAfterCudaMajorMinorVersion ? null,
        }:
        {
          inherit
            archName
            cudaCapability
            isJetson
            isArchitectureSpecific
            isFamilySpecific
            minCudaMajorMinorVersion
            maxCudaMajorMinorVersion
            dontDefaultAfterCudaMajorMinorVersion
            ;
        }
      )
      {
        "5.0" = {
          archName = "Maxwell";
          minCudaMajorMinorVersion = "10.0";
          maxCudaMajorMinorVersion = "12.9";
          dontDefaultAfterCudaMajorMinorVersion = "11.0";
        };
        "5.2" = {
          archName = "Maxwell";
          minCudaMajorMinorVersion = "10.0";
          maxCudaMajorMinorVersion = "12.9";
          dontDefaultAfterCudaMajorMinorVersion = "11.0";
        };
        "6.0" = {
          archName = "Pascal";
          minCudaMajorMinorVersion = "10.0";
          maxCudaMajorMinorVersion = "12.9";
          dontDefaultAfterCudaMajorMinorVersion = "12.3";
        };
        "6.1" = {
          archName = "Pascal";
          minCudaMajorMinorVersion = "10.0";
          maxCudaMajorMinorVersion = "12.9";
          dontDefaultAfterCudaMajorMinorVersion = "12.3";
        };
        "7.0" = {
          archName = "Volta";
          minCudaMajorMinorVersion = "10.0";
          maxCudaMajorMinorVersion = "12.9";
          dontDefaultAfterCudaMajorMinorVersion = "12.5";
        };
        "7.5" = {
          archName = "Turing";
          minCudaMajorMinorVersion = "10.0";
        };
        "8.0" = {
          archName = "Ampere";
          minCudaMajorMinorVersion = "11.2";
        };
        "8.6" = {
          archName = "Ampere";
          minCudaMajorMinorVersion = "11.2";
        };
        "8.7" = {
          archName = "Ampere";
          minCudaMajorMinorVersion = "11.4";
          isJetson = true;
        };
        "8.9" = {
          archName = "Ada";
          minCudaMajorMinorVersion = "11.8";
        };
        "9.0" = {
          archName = "Hopper";
          minCudaMajorMinorVersion = "11.8";
        };
        "9.0a" = {
          archName = "Hopper";
          minCudaMajorMinorVersion = "12.0";
        };
        "10.0" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.7";
        };
        "10.0a" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.7";
        };
        "10.0f" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
        "10.3" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
        "10.3a" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
        "10.3f" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
        "11.0" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "13.0";
          isJetson = true;
        };
        "11.0a" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "13.0";
          isJetson = true;
        };
        "11.0f" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "13.0";
          isJetson = true;
        };
        "12.0" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.8";
        };
        "12.0a" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.8";
        };
        "12.0f" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
        "12.1" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
        "12.1a" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
        "12.1f" = {
          archName = "Blackwell";
          minCudaMajorMinorVersion = "12.9";
        };
      };
}
