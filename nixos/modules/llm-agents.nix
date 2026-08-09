{ inputs, ... }: {
  flake.nixosModules.llm-agents = { pkgs, ... }: {
    # Separation: group AI/LLM tools here instead of cluttering kdj.nix
    hjem.users.kdj.packages = [
      pkgs.antigravity-ide-fhs
    ] ++ (with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      opencode
      antigravity-cli
    ]);
  };
}
