{
  description = "Flake for ";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      latexPackages = (pkgs.texlive.combine { inherit (pkgs.texlive) scheme-small minted upquote tcolorbox biblatex csquotes latexindent biber latexmk; });
    in
    {
      packages.${system} =
        {
          beamer-format = pkgs.writeShellApplication {
            name = "beamer-format";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./beamer
              mkdir -p ./out
              for file in ./*.tex; do
                echo "Formatting $file with latexindent..."
                latexindent -s -g ./out/indent.log -o "$file" "$file"
              done
            '';
          };
          document-format = pkgs.writeShellApplication {
            name = "document-format";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./document
              mkdir -p ./out
              for file in ./*.tex; do
                echo "Formatting $file with latexindent..."
                latexindent -s -g ./out/indent.log -o "$file" "$file"
              done
            '';
          };

          beamer-build = pkgs.writeShellApplication {
            name = "beamer-build";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./beamer
              # run twice to get toc right
              if [ ! -d "./out" ]; then
                mkdir -p ./out
                pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"
              fi
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Beamer.tex"

            '';
          };
          document-build = pkgs.writeShellApplication {
            name = "document-build";
            runtimeInputs = [ latexPackages ];
            text = ''
              cd ./document
              # run twice to get toc right
              if [ ! -d "./out" ]; then
                mkdir -p ./out
                pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Document.tex"
                biber ./out/Document
              fi
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Document.tex"
              echo "Running biber..."
              biber ./out/Document
              echo "Running pdflatex again..."
              pdflatex -output-directory=./out -halt-on-error -interaction=nonstopmode -shell-escape "./Document.tex"
            '';
          };

          beamer-present = pkgs.writeShellApplication {
            name = "beamer-present";
            text = ''
              echo "Generating pdfpc file..."
              (sleep 1; hyprctl dispatch killactive; echo "killing active window")&
              pdfpc -d 15 -l 3 -W -g -R ./beamer/out/Beamer.pdfpc --note-format=markdown --page-transition "fade:0.4" ./beamer/out/Beamer.pdf

              echo "Starting presentation with pdfpc..."
              sleep 1
              hyprctl dispatch workspace 22 || true # focus empty workspace
              hyprctl dispatch workspace 5 || true  # focus empty workspace
              sleep 1

              (sleep 1; hyprctl dispatch focusmonitor eDP-1; echo "focus sec monitor")&
              
              echo "Presentation started. Use Ctrl+C to stop."
              pdfpc -d 15 -l 3 -W -g -R ./beamer/out/Beamer.pdfpc --note-format=markdown --page-transition "fade:0.4" ./beamer/out/Beamer.pdf
            '';
          };
      };

      formatter.${system} = pkgs.nixpkgs-fmt;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          latexPackages
          self.packages.${system}.beamer-format
          self.packages.${system}.beamer-build
          self.packages.${system}.beamer-present
          self.packages.${system}.document-format
          self.packages.${system}.document-build
          # idk why but pdfpc from nix doesnt render the notes (install in host to fix)
          pkgs.pdfpc
        ];
      };
    };
}