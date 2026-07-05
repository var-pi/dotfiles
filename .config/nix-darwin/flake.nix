{
    description = "vortex nix-darwin system flake";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
        nix-darwin = {
            url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        neovim-nightly-overlay = {
            url = "github:nix-community/neovim-nightly-overlay";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        ymp = {
            url = "github:var-pi/ymp";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
    outputs = inputs:
        let
            configuration = { pkgs, ... }: 
                {
                    environment.systemPackages = with pkgs; [
                        ty
                        gh
                        git
                        bat
                        nixd
                        ddgr
                        kitty
                        texlab
                        ripgrep # For telescope live_grep
                        python314
                        claude-code
                        (writeShellScriptBin "julia-1.12" ''exec ${julia-bin}/bin/Julia "$@"'')
                        julia-lts-bin # For LanguageServer.jl
                        nodejs_24 # For tree-sitter
                        tree-sitter # For nvim-treesitter
                        texliveFull
                        jetbrains-mono
                        lua-language-server
                        inputs.ymp.packages.${stdenv.hostPlatform.system}.default
                        inputs.neovim-nightly-overlay.packages.${stdenv.hostPlatform.system}.default # Til 0.12 out
                    ];

                    nix.settings.experimental-features = "nix-command flakes";
                    system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
                    system.stateVersion = 6;
                    nixpkgs.hostPlatform = "aarch64-darwin";
                    security.pam.services.sudo_local.touchIdAuth = true;
                    nixpkgs.config.allowUnfree = true;
                };
        in
            {
            darwinConfigurations."vortex" = inputs.nix-darwin.lib.darwinSystem {
                modules = [ configuration ];
            };
        };
}
