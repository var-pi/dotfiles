{
    description = "vortex nix-darwin system flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/9d45400813f0f3e7f77660f720d94be040222bfc";
        nix-darwin.url = "github:nix-darwin/nix-darwin/e95de00a471d07435e0527ff4db092c84998698e";
        nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
        neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay/df074066e65d8a575f218fbf74b00ab973144d45";
        neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ self, nix-darwin, ... }:
        let
            configuration = { pkgs, ... }: {
                environment.systemPackages = with pkgs; [
                    ty
                    gh
                    git
                    nixd
                    kitty
                    texlab
                    yt-dlp
                    ripgrep # For telescope live_grep
                    ffmpeg_7
                    python314
                    nodejs_24 # For tree-sitter
                    tree-sitter # For nvim-treesitter
                    texliveFull
                    jetbrains-mono
                    lua-language-server
                    inputs.neovim-nightly-overlay.packages.${pkgs.system}.default # Til 0.12 out
                ];

                nix.settings.experimental-features = "nix-command flakes";

                # Enable alternative shell support in nix-darwin.
                # programs.fish.enable = true;

                system.configurationRevision = self.rev or self.dirtyRev or null;
                system.stateVersion = 6;

                nixpkgs.hostPlatform = "aarch64-darwin";

                security.pam.services.sudo_local.touchIdAuth = true;
            };
        in
            {
            darwinConfigurations."vortex" = nix-darwin.lib.darwinSystem {
                modules = [ configuration ];
            };
        };
}

