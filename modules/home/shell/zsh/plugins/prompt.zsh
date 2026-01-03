# OSC 133 Sequences - Terminal Integration
# Enables: scroll-to-prompt, command tracking, exit code capture
# Supported: Kitty, WezTerm, VSCode, iTerm2, Alacritty, Konsole

if [[ $TERM == (alacritty|kitty|wezterm|xterm-kitty|vscode|xterm-256color) ]] ||
   [[ -n $KITTY_WINDOW_ID ]] ||
   [[ -n $WEZTERM_EXECUTABLE ]] ||
   [[ -n $VSCODE_INJECTION ]] ||
   [[ -n $KONSOLE_VERSION ]]; then

  _prompt_executing=""

  function __prompt_precmd() {
    local ret="$?"

    if [[ "$_prompt_executing" != "0" ]]; then
      _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      # Wrap escape sequences in %{ %} for correct prompt length calculation
      PS1="%{$(printf '\e]133;P;k=i\a')%}$PS1%{$(printf '\e]133;B\a')%}"
      PS2="%{$(printf '\e]133;P;k=s\a')%}$PS2%{$(printf '\e]133;B\a')%}"
    fi

    if [[ -n "$_prompt_executing" ]]; then
      # Report command completion with exit code
      printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
    fi

    # Mark prompt start
    printf "\033]133;A;cl=m;aid=%s\007" "$$"
    _prompt_executing=0
  }

  function __prompt_preexec() {
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    # Mark command start
    printf "\033]133;C;\007"
    _prompt_executing=1
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __prompt_precmd
  add-zsh-hook preexec __prompt_preexec
fi
