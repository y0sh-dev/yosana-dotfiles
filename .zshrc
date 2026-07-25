# ---------------------------------------------------------
# 1. Path & Environment (パスと環境変数の整理)
# ---------------------------------------------------------
# 重複を自動で排除
typeset -U path fpath cdpath

# pyenv の初期化 (no-rehashで高速化・ロック競合防止)
[[ -d $PYENV_ROOT/bin ]] && eval "$(pyenv init - --no-rehash)"

export ZSH="$HOME/.oh-my-zsh"
export PYENV_ROOT="$HOME/.pyenv"

# PATHを1箇所でまとめて定義
path=(
    $HOME/bin
    $HOME/.local/bin
    $HOME/.cargo/bin
    $PYENV_ROOT/bin
    /usr/local/bin
    $path
)

# ---------------------------------------------------------
# 2. Robustness & Security (堅牢化・誤操作防止)
# ---------------------------------------------------------
# 既存ファイルを > で上書きするのを禁止 (>! で強制)
setopt NOCLOBBER
# rm * を実行する前に確認を入れる
setopt RM_STAR_WAIT
# コマンドのスペルミスを指摘する
setopt CORRECT
# 履歴に実行時刻を記録する (後から「いつやったか」追えるように)
setopt EXTENDED_HISTORY

# ---------------------------------------------------------
# 3. Oh My Zsh & Plugins
# ---------------------------------------------------------
ZSH_THEME="refined"

plugins=( 
    git 
    copypath 
    aliases 
    archlinux
    zsh-autosuggestions 
    zsh-syntax-highlighting 
    you-should-use
)

# OMZの読み込み
source $ZSH/oh-my-zsh.sh

# ---------------------------------------------------------
# 4. History & Completion (履歴と補完)
# ---------------------------------------------------------
HISTSIZE=10000
SAVEHIST=10000

# 履歴の扱いをより堅牢に
setopt HIST_IGNORE_ALL_DUPS  # 重複を記録しない
setopt SHARE_HISTORY         # 別のターミナルと履歴を即座に共有
setopt HIST_REDUCE_BLANKS    # 余計なスペースを削って保存

# 補完設定
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select
setopt AUTO_LIST 
setopt AUTO_MENU 
setopt LIST_PACKED

# ---------------------------------------------------------
# 5. Aliases & Safety (エイリアス)
# ---------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='trash-put'

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ff='fastfetch'
alias nf='neofetch'

# alias ディレクトリが存在する場合のみ一括読み込み
if [ -d "$HOME/.config/alias" ]; then
    for f in "$HOME"/.config/alias/*; do
        [ -f "$f" ] && source "$f"
    done
fi

