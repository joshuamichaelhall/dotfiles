echo 'eval "$(rbenv init -)"'
PATH=$PATH:/path/to/postgresql/bin
export EDITOR="cli_editor_command -w"
export VISUAL="cli_editor_command -w"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
