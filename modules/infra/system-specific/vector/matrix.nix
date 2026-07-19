{
  pkgs,
  ...
}:

{
  imports = [
    ../../matrix
  ];

  infra.matrix =
    let
      fqdn = "continuwuity-old.bartoostveen.nl";
    in
    {
      enable = true;
      alertmanager.enable = false;
      package = pkgs.callPackage (
        {
          rustPlatform,
          fetchFromGitea,
          pkg-config,
          bzip2,
          zstd,
          rocksdb,
          rust-jemalloc-sys-unprefixed,
          liburing,
        }:
        let
          rocksdb' =
            (rocksdb.override {
              enableJemalloc = true;
              jemalloc = rust-jemalloc-sys-unprefixed;
            }).overrideAttrs
              (
                _final: _old: {
                  version = "10.10.1";
                  src = fetchFromGitea {
                    domain = "forgejo.ellis.link";
                    owner = "continuwuation";
                    repo = "rocksdb";
                    rev = "10.10.fb";
                    hash = "sha256-1ef75IDMs5Hba4VWEyXPJb02JyShy5k4gJfzGDhopRk=";
                  };
                  patches = [ ];
                }
              );
        in
        rustPlatform.buildRustPackage (finalAttrs: {
          pname = "matrix-continuwuity";
          version = "0.5.10";
          src = fetchFromGitea {
            domain = "forgejo.ellis.link";
            owner = "continuwuation";
            repo = "continuwuity";
            tag = "v${finalAttrs.version}";
            hash = "sha256-oevEGYlAK/rMJhm200CkwerT5oVak8sJj0Fa6r6+J/Q=";
          };
          cargoHash = "sha256-uvMiFURXxkLbbbwq4pG5hevsLZHQ1wVfTNvzQRTQWxE=";
          nativeBuildInputs = [
            pkg-config
            rustPlatform.bindgenHook
          ];
          buildInputs = [
            bzip2
            zstd
            rust-jemalloc-sys-unprefixed
            liburing
          ];
          env = {
            ZSTD_SYS_USE_PKG_CONFIG = true;
            ROCKSDB_INCLUDE_DIR = "${rocksdb'}/include";
            ROCKSDB_LIB_DIR = "${rocksdb'}/lib";
          };
          meta.mainProgram = "conduwuit";
        })
      ) { };
      inherit fqdn;
      domain = "server.${fqdn}";
    };
}
