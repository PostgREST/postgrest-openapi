{ stdenv, postgresql, extensionName }:

stdenv.mkDerivation {
  name = extensionName;

  buildInputs = [ postgresql ];

  src = ../.;

  installPhase = ''
    mkdir -p $out/bin

    install -D -t $out/share/postgresql/extension sql/*.sql
    install -D -t $out/share/postgresql/extension ${extensionName}.control
  '';
}
