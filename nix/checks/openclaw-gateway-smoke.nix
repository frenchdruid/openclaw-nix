{
  lib,
  stdenv,
  openclawGateway,
}:

stdenv.mkDerivation {
  pname = "openclaw-gateway-smoke";
  version = lib.getVersion openclawGateway;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  env = {
    OPENCLAW_GATEWAY = openclawGateway;
  };

  doCheck = true;
  checkPhase = "${../scripts/check-gateway-smoke.sh}";
  installPhase = "${../scripts/empty-install.sh}";
}
