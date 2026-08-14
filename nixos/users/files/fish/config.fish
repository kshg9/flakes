zoxide init fish | source
starship init fish | source
fzf --fish | source
direnv hook fish | source

alias cd="z"
set -gx EDITOR hx
set -gx SOPS_AGE_KEY_FILE "$HOME/.config/sops/age/keys.txt"
set -g fish_greeting ""
alias cat="bat"
alias find="fd"
alias ls="eza"
alias ll="eza --long"
alias lt="eza --tree"

# Dim the autosuggestions (edge/suggestion) so they read as a ghost of
# what's already typed instead of matching the live foreground.
set -g fish_color_autosuggestion '#6c7086'
set -g fish_color_edge '#6c7086'
set -g fish_color_selection --background=#585b70

function y
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    set -l code $status
    if test -s "$tmp"
        set -l cwd (string trim < "$tmp")
        if test -n "$cwd"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
    end
    command rm -f -- "$tmp"
    return $code
end
