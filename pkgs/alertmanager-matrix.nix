{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "alertmanager-matrix";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "silkeh";
    repo = "alertmanager_matrix";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OJkhyfcqdNDw39DJ1TxiR4sgauH1Z2DS6da4vnnYc3Y=";
  };

  vendorHash = "sha256-KwjjB6scg3VmKc9qrdx+lVMj+XLLRqe4yv9DxoMMyi0=";

  ldflags = [ "-s" ];

  meta = {
    description = "Service for managing and receiving Alertmanager alerts on Matrix";
    homepage = "https://github.com/silkeh/alertmanager_matrix";
    license = lib.licenses.eupl12;
    mainProgram = "alertmanager_matrix";
  };
})
