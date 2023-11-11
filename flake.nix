{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
    { 

      defaultPackage = pkgs.stdenv.mkDerivation rec {
       pname = "gnoll";
       version = "4.3.4";

       src = ./.;

       nativeBuildInputs = [ pkgs.python3Packages.setuptools pkgs.flex pkgs.bison ];
       buildInputs = [ pkgs.gnumake ];
       defaultCommand = "make all";
        installPhase = "mkdir -p $out/bin ; make DESTDIR=$out/bin install";

     };

     shellHook = ''
       export PATH="${self.packages.python3}/bin:$PATH"
     '';


    devShells.default = pkgs.mkShell {
      packages = [
        pkgs.python3
        pkgs.flex
        pkgs.bison
        pkgs.gnumake
                 ];
        };
    });

}
