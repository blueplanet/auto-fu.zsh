# zsh automatic complete-word and list-choices

# Originally incr-0.2.zsh
# Incremental completion for zsh
# by y.fujii <y-fujii at mimosa-pudica.net>

# Thank you very much y.fujii!

# Adapted by Takeshi Banse <takebi@laafc.net>
# I want to use it with menu selection.

# To use this,
# 1) source this file.
# % source auto-fu.zsh
# 2) establish `zle-line-init' containing `auto-fu-init' something like below.
# % zle-line-init () {auto-fu-init;}; zle -N zle-line-init
# 3) use the _oldlist completer something like below.
# % zstyle ':completion:*' completer _oldlist _complete
# (If you have a lot of completer, please insert _oldlist before _complete.)
# 4) establish `zle-keymap-select' containing `auto-fu-zle-keymap-select'.
# % zle -N zle-keymap-select auto-fu-zle-keymap-select
# (This enables the afu-vicmd keymap switching coordinates a bit.)
#
# *Optionally* you can use the zcompiled file for a little faster loading on
# every shell startup, if you zcompile the necessary functions.
# *1) zcompile the defined functions. (generates ~/.zsh/auto-fu.zwc)
# % A=/path/to/auto-fu.zsh; (zsh -c "source $A ; auto-fu-zcompile $A ~/.zsh")
# *2) source the zcompiled file instead of this file and some tweaks.
# % source ~/.zsh/auto-fu; auto-fu-install
# *3) establish `zle-line-init' and such (same as a few lines above).
# Note:
# It is approximately *(6~10) faster if zcompiled, according to this result :)
# TIMEFMT="%*E %J"
# 0.041 ( source ./auto-fu.zsh; )
# 0.004 ( source ~/.zsh/auto-fu; auto-fu-install; )

# Configuration
# The auto-fu features can be configured via zstyle.

# :auto-fu:highlight
#   input
#     A highlight specification used for user input string.
#   completion
#     A highlight specification used for completion string.
#   completion/one
#     A highlight specification used for completion string if it is the
#     only one candidate.
# :auto-fu:var
#   postdisplay
#     An initial indication string for POSTDISPLAY in auto-fu-init.
#   postdisplay/clearp
#     If set, POSTDISPLAY will be cleared after the accept-lines.
#     'yes' by default.
#   enable
#     A list of zle widget names the automatic complete-word and
#     list-choices to be triggered after its invocation.
#     Only with ALL in 'enable', the 'disable' style has any effect.
#     ALL by default.
#   disable
#     A list of zle widget names you do *NOT* want the complete-word to be
#     triggered. Only used if 'enable' contains ALL. For example,
#       zstyle ':auto-fu:var' enable all
#       zstyle ':auto-fu:var' disable magic-space
#     yields; complete-word will not be triggered after pressing the
#     space-bar, otherwise automatic thing will be taken into account.
#   track-keymap-skip
#     A list of keymap names to *NOT* be treated as a keymap change.
#     In other words, these keymaps cannot be used with the standalone main
#     keymap. For example "opp". If you use my opp.zsh, please add an 'opp'
#     to this zstyle.
#   autoable-function/skipwords
#   autoable-function/skiplbuffers
#   autoable-function/skiplines
#     A list of patterns to *NOT* be treated as auto-stuff appropriate.
#     These patterns will be tested against the part of the command line
#     buffer as shown on the below figure:
#     (*) is used to denote the cursor position.
#
#       # nocorrect aptitude --assume-*yes -d install zsh && echo ready
#                            <-------->skipwords
#                   <----------------->skiplbuffers
#                   <----------------------------------->skplines
#
#     Examples:
#     - To disable auto-stuff inside single and also double quotes.
#       And less than 3 chars before the cursor.
#       zstyle ':auto-fu:var' autoable-function/skipwords \
#         "('|$'|\")*" "^((???)##)"
#
#     - To disable the rm's first option, and also after the '(cvs|svn) co'.
#       zstyle ':auto-fu:var' autoable-function/skiplbuffers \
#         'rm -[![:blank:]]#' '(cvs|svn) co *'
#
#     - To disable after the 'aptitude word '.
#       zstyle ':auto-fu:var' autoable-function/skiplines \
#         '([[:print:]]##[[:space:]]##|(#s)[[:space:]]#)aptitude [[:print:]]# *'
#   autoable-function/preds
#     A list of functions to be called whether auto-stuff appropriate or not.
#     These functions will be called with the arguments (above figure)
#       - $1 '--assume-'
#       - $2 'aptitude'
#       - $3 'aptitude --assume-'
#       - $4 'aptitude --assume-yes -d install zsh'
#     For example,
#     to disable some 'perl -M' thing, we can do by the following zsh codes.
#>
#       afu-autoable-pm-p () { [[ ! ("$2" == 'perl' && "$1" == -(#i)m*) ]] }
#
#       # retrieve default value into 'preds' to push the above function into.
#       local -a preds; afu-autoable-default-functions preds
#       preds+=afu-autoable-pm-p
#
#       zstyle ':auto-fu:var' autoable-function/preds $preds
#<
#     The afu-autoable-dots-p is actually an example of this ability to skip
#     uninteresting dots.
#   autoablep-function
#     A predicate function to determine whether auto-stuff could be
#     appropriate. (Default `auto-fu-default-autoable-pred' implements the
#     above autoablep-function/* functionality.)
#
# Configuration example

# zstyle ':auto-fu:highlight' input bold
# zstyle ':auto-fu:highlight' completion fg=black,bold
# zstyle ':auto-fu:highlight' completion/one fg=white,bold,underline
# zstyle ':auto-fu:var' postdisplay $'\n-azfu-'
# zstyle ':auto-fu:var' track-keymap-skip opp
# #zstyle ':auto-fu:var' disable magic-space

# XXX: use with the _approximate or _match completer.
# To track these completers' state, they will be called by their name with
# 'afu_approximate/afu_match' during the `complete-word'.
# If you customize the styles of these completers, please update them.
# For example,
# -- >8 --
# #zstyle ':completion:*:match:*' match-original 'only'
# zstyle ':completion:*:*match:*' match-original 'only'
# -- 8< --              ^ *Please notice here*
# I'm very sorry for this annonying behaviour.

# XXX: ignoreeof semantics changes for overriding ^D.
# You cannot change the ignoreeof option interactively. I'm verry sorry.

# XXX: zsh-syntax-highlighting
# I'm a very fond of this fancy zsh script `zsh-syntax-highlighting'.
# https://github.com/nicoulaj/zsh-syntax-highlighting
# If you want to integrate auto-fu.zsh with the zsh-syntax-highlighting,
# please source the zsh-syntax-highlighting.zsh before this file.

# TODO: play nice more with zsh-syntax-highlighting.
# TODO: http://d.hatena.ne.jp/tarao/20100531/1275322620
# TODO: pause auto stuff until something happens. ("next magic-space" etc)
# TODO: handle RBUFFER.
# TODO: signal handling during the recursive edit.
# TODO: handle empty or space characters.
# TODO: cp x /usr/loc
# TODO: region_highlight vs afu-able-p → nil
# Do *NOT* clear the region_highlight if it should.
# TODO: ^C-n could be used as the menu-select-key outside of the menuselect.
# TODO: *-directories|all-files may not be enough.
# TODO: recommend zcompiling.
# TODO: undo should reset the auto stuff's state.
# TODO: when `_match`ing,
# sometimes extra <TAB> key is needed to enter the menu select,
# sometimes is *not* needed. (already be entered menu select state.)

# History

# v0.0.1.11
# play nice with banghist.
# Thank you very much for the report, yoshikaw!
# add autoablep-function machinery.
# Thank you very much for the suggestion, tyru and kei_q!

# v0.0.1.10
# Fix not work auto-thing without extended_glob.
# Thank you very much for the report, myuhe!

# v0.0.1.9
# add auto-fu-activate, auto-fu-deactivate and auto-fu-toggle.

# v0.0.1.8.3
# in afu+complete-word PAGER=<TAB> ⇒ PAGER=PAGER= bug fix.
# Thank you very much for the report, tyru!

# v0.0.1.8.2
# afu+complete-word bug fixes.

# v0.0.1.8.1
# README.md

# v0.0.1.8
# add completion/one and postdisplay/clearp configurations.
# add kill-word and yank to afu_zles.

# v0.0.1.7
# Fix "no such keymap `isearch'" error.
# Thank you very much for the report, mooz and Shougo!

# v0.0.1.6
# Fix `parameter not set`. Thank you very much for the report, Shougo!
# Bug fix.

# v0.0.1.5
# afu+complete-word bug (directory vs others) fix.

# v0.0.1.4
# afu+complete-word bug fixes.

# v0.0.1.3
# Teach ^D and magic-space.

# v0.0.1.2
# Add configuration option and auto-fu-zcompile for a little faster loading.

# v0.0.1.1
# Documentation typo fix.

# v0.0.1
# Initial version.

# Code

afu_zles=( \
  # Zle widgets should be rebinded in the afu keymap. `auto-fu-maybe' to be
  # called after it's invocation, see `afu-initialize-zle-afu'.
  self-insert backward-delete-char backward-kill-word kill-line \
  kill-whole-line kill-word magic-space yank \
)

autoload +X keymap+widget

{
  local code=${functions[keymap+widget]/for w in *
	do
/for w in $afu_zles
  do
  }
  eval "function afu-keymap+widget () { $code }"
}

function () {
  emulate -L zsh
  setopt extended_glob
  local -a match mbegin mend
  # auto-fu uses complete-word and list-choices as they are not "rebinded".
  local -a rs; rs=($afu_zles complete-word list-choices)
  eval "
    function with-afu-zle-rebinding () {
      local -a restores
      {
        eval \"\$("${rs/(#b)(*)/afu-rebind-expand restores $match;}")\"
        function afu-zle-force-install () {
          "$(echo ${afu_zles/(#b)(*)/ \
              zle -N ${match} ${match}-by-keymap;})"
          zle -C complete-word .complete-word _main_complete
          zle -C list-choices .list-choices _main_complete
        }
        afu-zle-force-install
        { \"\$@\" }
      } always {
        eval \$restores
      }
    }
  "
}

afu-rebind-expand () {
  local place="$1"
  local w="$2"
  local x="$widgets[$w]"
  [[ $x == user:*-by-keymap    ]] && return
  [[ $x == (user|completion):* ]] || return
  local f="${x#*:}"
  [[ $x == completion:* ]] && echo " $place+=\"zle -C $w ${f/:/ };\" "
  [[ $x != completion:* ]] && echo " $place+=\"zle -N $w $f;\" "
}

afu-install () {
  zstyle -t ':auto-fu:var' misc-installed-p || {
    zmodload zsh/parameter 2>/dev/null || {
      echo 'auto-fu:zmodload error. exiting.' >&2; exit -1
    }
    afu-install-isearchmap
    afu-install-eof
  } always {
    zstyle ':auto-fu:var' misc-installed-p yes
  }

  bindkey -N afu emacs
  { "$@" }
  bindkey -M afu "^I" afu+complete-word
  bindkey -M afu "^M" afu+accept-line
  bindkey -M afu "^J" afu+accept-line
  bindkey -M afu "^O" afu+accept-line-and-down-history
  bindkey -M afu "^[a" afu+accept-and-hold
  bindkey -M afu "^X^[" afu+vi-cmd-mode

  bindkey -N afu-vicmd vicmd
}

afu-install-isearchmap () {
  zstyle -t ':auto-fu:var' isearchmap-installed-p || {
    [[ -n ${(M)keymaps:#isearch} ]] && bindkey -M isearch "^M" afu+accept-line
  } always {
    zstyle ':auto-fu:var' isearchmap-installed-p yes
  }
}

afu-install-eof () {
  zstyle -t ':auto-fu:var' eof-installed-p || {
    # fiddle the main(emacs) keymap. The assumption is it propagates down to
    # the afu keymap afterwards.
    if [[ "$options[ignoreeof]" == "on" ]]; then
      bindkey "^D" afu+orf-ignoreeof-deletechar-list
    else
      setopt ignoreeof
      bindkey "^D" afu+orf-exit-deletechar-list
    fi
  } always {
    zstyle ':auto-fu:var' eof-installed-p yes
  }
}

afu-eof-maybe () {
  local eof="$1"; shift
  [[ "$BUFFER" != '' ]] || { $eof; return }
  "$@"
}

afu-ignore-eof () { zle -M "zsh: use 'exit' to exit." }

afu-register-zle-eof () {
  local fun="$1"
  local then="$2"
  local else="${3:-delete-char-or-list}"
  eval "$fun () { afu-eof-maybe $then zle $else }; zle -N $fun"
}
afu-register-zle-eof afu+orf-ignoreeof-deletechar-list afu-ignore-eof
afu-register-zle-eof      afu+orf-exit-deletechar-list exit

afu+vi-ins-mode () { zle -K afu      ; }; zle -N afu+vi-ins-mode
afu+vi-cmd-mode () { zle -K afu-vicmd; }; zle -N afu+vi-cmd-mode

auto-fu-zle-keymap-select () { afu-track-keymap "$@" afu-adjust-main-keymap }

afu-adjust-main-keymap () { [[ "$KEYMAP" == 'main' ]] && { zle -K "$1" } }

afu-track-keymap () {
  typeset -gA afu_keymap_state # XXX: global state variable.
  local new="${KEYMAP}"
  local old="${2}"
  local fun="${3}"
  { afu-track-keymap-skip-p "$old" "$new" } && return
  local cur="${afu_keymap_state[cur]-}"
  afu_keymap_state+=(old "${afu_keymap_state[cur]-}")
  afu_keymap_state+=(cur "$old $new")
  [[ "$new" == 'main' ]] && [[ -n "$cur" ]] && {
    local -a tmp; tmp=("${(Q)=cur}")
    afu_keymap_state+=(cur "$old $tmp[1]")
    "$fun" "$tmp[1]"
  }
}

afu-track-keymap-skip-p () {
  local old="$1"
  local new="$2"
  { [[ -z "$old" ]] || [[ -z "$new" ]] } && return 0
  local -a ms; ms=(); zstyle -a ':auto-fu:var' track-keymap-skip ms
  (( ${#ms} )) || return -1
  local m; for m in $ms; do
    [[ "$old" == "$m" ]] && return 0
    [[ "$new" == "$m" ]] && return 0
  done
  return -1
}

afu-install afu-keymap+widget
function () {
  [[ -z ${AUTO_FU_NOCP-} ]] || return
  # For backward compatibility
  zstyle ':auto-fu:highlight' input bold
  zstyle ':auto-fu:highlight' completion fg=black,bold
  zstyle ':auto-fu:highlight' completion/one fg=whilte,bold,underline
  zstyle ':auto-fu:var' postdisplay $'\n-azfu-'
}

declare -a afu_accept_lines

afu-recursive-edit-and-accept () {
  local -a __accepted
  zle recursive-edit -K afu || { afu-reset; zle -R ''; zle send-break; return }
  [[ -n ${__accepted} ]] &&
  (( ${#${(M)afu_accept_lines:#${__accepted[1]}}} > 1 )) &&
  { zle "${__accepted[@]}"} || { zle accept-line }
}

afu-register-zle-accept-line () {
  local afufun="$1"
  local rawzle=".${afufun#*+}"
  local code=${"$(<=(cat <<"EOT"
  $afufun () {
    __accepted=($WIDGET ${=NUMERIC:+-n $NUMERIC} "$@")
    zle $rawzle && {
      local hi
      zstyle -s ':auto-fu:highlight' input hi
      [[ -z ${hi} ]] || {
        # XXX: subject to change.
        (($+functions[${hi}])) && "${hi}" || afu-rh-finish "0 ${#BUFFER} ${hi}"
      }
    }
    zstyle -T ':auto-fu:var' postdisplay/clearp && POSTDISPLAY=''
    return 0
  }
  zle -N $afufun
EOT
  ))"}
  eval "${${code//\$afufun/$afufun}//\$rawzle/$rawzle}"
  afu_accept_lines+=$afufun
}
afu-register-zle-accept-line afu+accept-line
afu-register-zle-accept-line afu+accept-line-and-down-history
afu-register-zle-accept-line afu+accept-and-hold

# Entry point.
afu-line-init () {
  local auto_fu_init_p=1
  local ps
  {
    local -A afu_rh_state
    local afu_in_p=0
    local afu_paused_p=0

    zstyle -s ':auto-fu:var' postdisplay ps
    [[ -z ${ps} ]] || POSTDISPLAY="$ps"

    afu-recursive-edit-and-accept
    zle -I
  } always {
    [[ -z ${ps} ]] || POSTDISPLAY=''
  }
}

auto-fu-init () { with-afu-zle-rebinding afu-line-init }; zle -N auto-fu-init

# Entry point.
with-afu-gvars () {
  (( auto_fu_init_p == 1 )) && {
    zle -M "Sorry, can't turn on or off if auto-fu-init is in effect."; return
  }
  typeset -g afu_in_p=0
  typeset -g afu_paused_p=0
  typeset -gA afu_rh_state
  "$@"
}
auto-fu-on  () { with-afu-gvars zle -K afu   }
auto-fu-off () { with-afu-gvars zle -K emacs }
auto-fu-on~ () { afu-zle-force-install; auto-fu-on  }
auto-fu-off~() { afu-zle-force-install; auto-fu-off }
zle -N auto-fu-on  auto-fu-on~
zle -N auto-fu-off auto-fu-off~

afu-register-zle-toggle () {
  local var="$1"
  local toggle="$2"
  local activate="$3"
  local deactivate="$4"
  eval "$(cat <<EOT
    $toggle () {
      (( $var == 1 )) && { $var=0; return }
      (( $var != 1 )) && { $var=1; return }
    }
    $activate () { $var=0 }
    $deactivate () { $var=1 }
    zle -N $toggle; zle -N $activate; zle -N $deactivate
EOT
  )"
}
afu-register-zle-toggle afu_paused_p \
  auto-fu-toggle auto-fu-activate auto-fu-deactivate

afu-rh-highlight-state () {
  local oplace="$1" cplace="$2"; shift 2
  : ${(P)oplace::=afu-rh-highlight-state-sync-old}
  : ${(P)cplace::=afu-rh-highlight-state-sync-cur}
  { "$@" }
}

afu-rh-highlight-state-update () {
  afu_rh_state+=(old "${afu_rh_state[cur]-}")
  afu_rh_state+=(cur "$1")
}

afu-rh-highlight-state-sync-old () {
  local -a old; : ${(A)old::=${=afu_rh_state[old]-}}
  [[ -n ${old} ]] && [[ -n ${region_highlight} ]] && {
    : ${(A)region_highlight::=${region_highlight:#"$old[2,-1]"}}
  }
}

afu-rh-highlight-state-sync-cur () {
  local -a cur; : ${(A)cur::=${=afu_rh_state[cur]-}}
  [[ -n ${cur} ]] && region_highlight+=("$cur[2,-1]")
}

afu-rh-highlight-maybe () {
  local hi="$1"
  local beg="$2"
  local end="$3"
  local hiv="$4"
  local ok ck
  afu-rh-highlight-state ok ck \
    afu-rh-highlight-state-update "$hi $beg $end $hiv"; "$ok"; "$ck";
}

afu-rh-clear-maybe () {
  local ok _ck
  afu-rh-highlight-state ok _ck \
    afu-rh-highlight-state-update ""; "$ok"
}

afu-rh-finish () {
  local -a cur; : ${(A)cur::=${=afu_rh_state[cur]-}}
  [[ -n "$cur" ]] && [[ "$cur[1]" == completion/* ]] && { afu-rh-clear-maybe }
  region_highlight+=("$1")
}

afu-clearing-maybe () {
  local clearregionp="$1"
  [[ $clearregionp == t ]] && region_highlight=()
  afu-rh-clear-maybe
  if ((afu_in_p == 1)); then
    [[ "$BUFFER" != "$buffer_new" ]] || ((CURSOR != cursor_cur)) &&
    { afu_in_p=0 }
  fi
}

afu-reset () {
  region_highlight=()
  afu_in_p=0
  local ps; zstyle -s ':auto-fu:var' postdisplay ps
  [[ -z ${ps} ]] || POSTDISPLAY=''
}

with-afu-completer-tracking () {
  # tracking last function is the afu+complete-word or not.
  # see also with-afu-menuselecting-handling
  local afucompletewordp="${1-}"
  last_afucompleteword_p=
  if [[ -n ${afu_complete_word-} ]]; then
    last_afucompleteword_p=t
    afu_complete_word=
  fi
  afu_complete_word="${afucompletewordp}"

  # tracking last afu_approximate_correcting_p or not.
  # see also with-afu-menuselecting-handling
  last_afuapproximatecorrecting_p=
  if [[ -n ${afu_approximate_correcting_p-} ]]; then
    last_afuapproximatecorrecting_p=t
    afu_approximate_correcting_p=
  fi

  # tracking current _completer value stored inside the completer
  # see also with-afu-menuselecting-handling and afu-comppost
  afu_curcompleter=

  # see also corresponding completer function.
  # _afu_approximate and afu_match.
  afu_approximate_correcting_p=
  afu_match_ret=
}

with-afu () {
  local clearp="$1"; shift
  local zlefun="$1"; shift
  local -a zs
  : ${(A)zs::=$@}
  with-afu-completer-tracking;
  afu-clearing-maybe "$clearp"
  ((afu_in_p == 1)) && { afu_in_p=0; BUFFER="$buffer_cur" }
  zle $zlefun && {
    emulate -L zsh
    setopt extended_glob nobanghist
    local es ds
    zstyle -a ':auto-fu:var' enable es; (( ${#es} == 0 )) && es=(all)
    if [[ -n ${(M)es:#(#i)all} ]]; then
      zstyle -a ':auto-fu:var' disable ds
      : ${(A)es::=${zs:#(${~${(j.|.)ds}})}}
    fi
    [[ -n ${(M)es:#${zlefun#.}} ]]
  } && { auto-fu-maybe }
}

# XXX: see also afu+complete-word~

auto-fu-extend () { "$@" }; zle -N auto-fu-extend

with-afu~ () { zle auto-fu-extend -- with-afu "$@" }

with-afu-zsh-syntax-highlighting () {
  local -i ret=0
  local -i hip=0; ((hip=$+functions[_zsh_highlight-zle-buffer]))
  ((hip==0)) && { "$1" t   "$@[2,-1]"; ret=$? }
  ((hip!=0)) && { "$1" nil "$@[2,-1]"; ret=$? }
  ((hip==1)) && _zsh_highlight-zle-buffer
  ((ret==-1)) || {
    local _ok ck
    afu-rh-highlight-state _ok ck; "$ck"
  }
}

# XXX: redefined!
zle -N auto-fu-extend with-afu-zsh-syntax-highlighting

afu-register-zle-afu () {
  local afufun="$1"
  local rawzle=".${afufun#*+}"
  eval "function $afufun () { with-afu~ $rawzle $afu_zles; }; zle -N $afufun"
}

afu-initialize-zle-afu () {
  local z
  for z in $afu_zles ;do
    afu-register-zle-afu afu+$z
  done
}
afu-initialize-zle-afu

afu-able-p () {
  # XXX: This could be done sanely in the _main_complete or $_comps[x].
  local pred=; zstyle -s ':auto-fu:var' autoablep-function pred
  "${pred:-auto-fu-default-autoable-pred}"; return $?
}

auto-fu-default-autoable-pred () {
  local -a ps; zstyle -a ':auto-fu:var' autoable-function/preds ps
  (( $#ps )) || { afu-autoable-default-functions ps }

  local -a reply; local -i REPLY REPLY2; local -a areply
  afu-split-shell-arguments

  local word="${reply[REPLY]}"
  local commandish="${areply[1]}"
  local p; for p in $ps; do
    local ret=0; "$p" \
      "$word" "$commandish" \
        "${(j..)areply[1,((REPLY-1))]}" \
        "${(j..)areply[1,-1]}"
    ret=$?
    ((ret == 1)) && return 1
    ((ret ==-1)) && return 0 # XXX: Badness.
  done
  return 0
}

afu-error-symif () {
  local fname="$1"; shift
  local place="$1"; shift
  [[ "$place" == (${~${(j.|.)@}}) ]] && {
    echo \
      "*** error in $fname; ${(qq)@} cannot be used in this context. sorry."
    return -1
  }
  return 0
}

afu-autoable-default-functions () {
  local place="$1"
  afu-error-symif "$0" "$place" defaults || return $?
  local -a defaults; defaults=(\
    afu-autoable-paused-p \
    afu-autoable-space-p \
    afu-autoable-skipword-p \
    afu-autoable-dots-p \
    afu-autoable-skiplbuffer-p \
    afu-autoable-skipline-p)
  : ${(PA)place::=$defaults}
}

afu-autoable-paused-p () { (( afu_paused_p == 0 )) }

afu-split-shell-arguments () {
  autoload -U split-shell-arguments; split-shell-arguments
  ((REPLY & 1)) && ((REPLY--))
  ((REPLY2 = ${#reply[REPLY]} + 1))

  # set up the 'areply'. (Cursor positoin (*))
  # % echo bar && command ls -a* -l | grep foo
  #                       <-------> areply holds
  local -i p; local -a tmp
  : ${(A)tmp::=$reply[1,REPLY]}
  p=${tmp[(I)(\||\|\||;|&|&&)]}; ((p)) && ((p+=2)) || ((p=1))
  while [[ $tmp[p] == (noglob|nocorrect|builtin|command) ]] do ((p+=2)) done;
  ((p!=1)) && ((p++))
  : ${(A)tmp::=$reply[p,-1]}
  p=${tmp[(I)(\||\|\||;|&|&&)]}; ((p)) && ((p-=2)) || ((p=-1))
  : ${(A)areply::=${tmp[1,p]}}
}

afu-autoable-space-p () {
  local c=$LBUFFER[-1]
  [[ $c == ''  ]] && return 1;
  [[ $c == ' ' ]] && { afu-able-space-p || return 1 && return -1 }
  return 0
}

afu-able-space-p () {
  [[ -z ${AUTO_FU_NOCP-} ]] &&
    # For backward compatibility.
    { [[ "$WIDGET" == "magic-space" ]] || return 1 }

  # TODO: This is quite iffy guesswork, broken.
  local -a x
  : ${(A)x::=${(z)LBUFFER}}
  #[[ $x[1] != (man|perldoc|ri) ]]
  [[ $x[1] != man ]]
}

afu-autoable-dots-p () { [[ "${1##*/}" != ("."|"..")  ]] }

afu-autoable-skip-pred () {
  local place="$1"
  local style="$2"
  local deffn="$3"
  local value="${(P)place}"
  local -a skips; skips=(); zstyle -a ':auto-fu:var' "$style" skips
  (($#skips==0)) && [[ -n "$deffn" ]] && { "$deffn" skips }
  local skip; for skip in $skips; do
    [[ "${value}" == ${~skip} ]] && {
      [[ -n "${AUTO_FU_DEBUG-}" ]] && {
        echo "***BREAK*** ${skip}" >> ${AUTO_FU_DEBUG-}
      }
      return 1
    }
  done
  return 0
}

afu-autoable-skipword-p () {
  local word="$1"
  afu-autoable-skip-pred word autoable-function/skipwords \
    afu-autoable-skipword-p-default
}

afu-autoable-skipword-p-default () {
  afu-error-symif "$0" "$1" a tmp || return $?
  local -a a; a=("'" "$'" "$histchars[1]");local -a tmp; tmp=("(${(j.|.)a})*")
  : ${(PA)1::=$tmp}
}

afu-autoable-skiplbuffer-p () {
  local lbuffer="$3"
  afu-autoable-skip-pred lbuffer autoable-function/skiplbuffers
}

afu-autoable-skipline-p () {
  local line="$4"
  afu-autoable-skip-pred line autoable-function/skiplines
}

auto-fu-maybe () {
  local ret=-1
  (($PENDING== 0)) && { afu-able-p } && [[ $LBUFFER != *$'\012'*  ]] &&
  { with-afu-menuselecting-handling auto-fu; ret=0 }
  return ret
}

with-afu-compfuncs () {
  compprefuncs=(afu-comppre)
  comppostfuncs=(afu-comppost)
  "$@"
}

with-afu-completer-vars () {
  emulate -L zsh
  unsetopt rec_exact
  local LISTMAX=999999
  with-afu-compfuncs "$@"
}

with-afu-menuselecting-handling () {
  local fn="$1"
  local inserts="*(approximate|match)"

  # being propagated from `afu+complete-word` then
  # `_match|_approximate|etc. ⇒ select something` or not.
  [[ "${afu_curcompleter-}" == ${~inserts} ]] &&
  [[ $WIDGET == (magic-space|accept-line*) ]] && {
    with-afu-compfuncs zle list-choices
    return
  }

  local force_menuselect_off_p=
  (( $+functions[afu-handle-menuselecting-buffer-keep-p] )) &&
  [[ -z ${AUTO_FU_NOFUNCMEMO-} ]] ||
  afu-handle-menuselecting-buffer-keep-p () {
    # `_match|_approximate|etc. ⇒ select something` or not.
    [[ "${afu_curcompleter-}" == ${~inserts} ]] && {

      # _approximating: (just selected the candidate)
      # keep the current buffer and do *NOT* call complete-word.
      [[ -n ${afu_approximate_correcting_p-} ]] && {
        { afu-hmbk-seleted-key-p } && { force_menuselect_off_p=t; return 0 }
        # TODO: describe the purpose!
        [[ $KEYS[-1] == [[:]] ]] && {
          [[ $LBUFFER[-1] == ' '       ]] && { LBUFFER=$LBUFFER[1,-2] }
          [[ $LBUFFER[-1] == $KEYS[-1] ]] && { LBUFFER=$LBUFFER[1,-2] }
         return 0
        }
      }

      # _matching: (_match completer is in use; narrowing the candidates)
      # do *NOT* call complete-word after redrawing the current buffer with
      # the old contents (ex: *ab*)
      [[ -n ${afu_match_ret-} ]] && { force_menuselect_off_p=t; return 1 }

      { afu-hmbk-seleted-key-p } || {
        [[ $LBUFFER[-1] == $KEYS[-1] ]] &&
        [[ $LBUFFER[-1] == '/' ]]       && {
          # path-ish ⇒ propagate complete-word by editing LBUFFER
        } && { LBUFFER=$LBUFFER[1,-2]; force_menuselect_off_p=t }
      }
    }
  }
  $fn afu-handle-menuselecting-buffer-keep-p

  # forcibly keep being the menuselecting state by calling complete-word,
  # otherwise we have to hit the tab key once more.
  [[ "${afu_curcompleter-}" == ignored ]] && return
  [[ -n ${last_afuapproximatecorrecting_p-} ]] && return
  [[ -z ${last_afucompleteword_p-} ]] &&
  [[ -z ${force_menuselect_off_p}  ]] &&
  [[ -z ${afu_one_match_p-}        ]] &&
  { [[ -n ${afu_match_ret-} ]] && ((${afu_match_ret} == 0)) } &&
  { with-afu-compfuncs zle complete-word }
}

afu-hmbk-seleted-key-p () {
  [[ $KEYS[-1] == ' ' ]]     && return 0
  [[ $KEYS[-1] == $'\015' ]] && return 0
  [[ $KEYS[-1] == $'\012' ]] && return 0
  [[ $KEYS[-1] == $'/' ]]    && return 0 # for example 'scp host:/'
  return 1
}

auto-fu () {
  local keepbufferp="$1"
  cursor_cur="$CURSOR"
  buffer_cur="$BUFFER"
  with-afu-completer-vars zle complete-word
  cursor_new="$CURSOR"
  buffer_new="$BUFFER"

  if [[ "$buffer_cur[1,cursor_cur]" == "$buffer_new[1,cursor_cur]" ]];
  then
    CURSOR="$cursor_cur"
    {
      local hi hiv
      [[ $afu_one_match_p == t ]] && hi=completion/one || hi=completion
      zstyle -s ':auto-fu:highlight' "$hi" hiv
      [[ -z ${hiv} ]] || {
        local -i end=$cursor_new
        [[ $BUFFER[$cursor_new] == ' ' ]] && (( end-- ))
        afu-rh-highlight-maybe $hi $CURSOR $end $hiv
      }
    }

    if [[ "$buffer_cur" != "$buffer_new" ]] || ((cursor_cur != cursor_new))
    then afu_in_p=1; { $keepbufferp } || {
      local BUFFER="$buffer_cur"
      local CURSOR="$cursor_cur"
      with-afu-completer-vars zle list-choices
    }
    fi
  else
    { $keepbufferp } || {
      BUFFER="$buffer_cur"
      CURSOR="$cursor_cur"
      with-afu-compfuncs zle list-choices
    }
  fi
}
zle -N auto-fu

afu-comppre () {
  # XXX: vs. various zstyes.
  {
    local -a match mbegin mend
    local c='_(match|approximate)'
    : ${(A)_completers::=${_completers/(#b)(#s)(${~c})(#e)/_afu${match[1]}}}
  }
  # XXX: _match + _approximate does not work as expected inside auto stuff.
  # so, filter out _approximate if _match present.
  [[ -n ${(M)_completers:#(_afu)#_match} ]] && {
    local tmp="${${:-$PREFIX$SUFFIX}#[~=]}"
    [[ "$tmp:q" = "$tmp" ]] && return
    : ${(A)_completers::=${_completers:#(_afu)#_approximate}}
  }
}

afu-comppost () {
  ((compstate[list_lines] + BUFFERLINES + 2 > LINES)) && {
    compstate[list]=''
    zle -M "$compstate[list_lines]($compstate[nmatches]) too many matches..."
  }

  typeset -g afu_one_match_p=
  (( $compstate[nmatches] == 1 )) && afu_one_match_p=t

  afu_curcompleter=$_completer
}

afu+complete-word () {
  afu-clearing-maybe "$1"
  with-afu-completer-tracking t;
  { afu-able-p } || { zle complete-word; return; }

  with-afu-completer-vars;
  if ((afu_in_p == 1)); then
    afu_in_p=0; CURSOR="$cursor_new"
    case $LBUFFER[-1] in
      (=) # --prefix= ⇒ complete-word again for `magic-space'ing the suffix
        { # TODO: this may not be accurate.
          local x="${${(@z)LBUFFER}[-1]}"
          [[ "$x" == -* ]] && zle complete-word && return
        };;
      (/) # path-ish  ⇒ propagate auto-fu if it could be
        { # TODO: this may not be enough.
          local y="((*-)#directories|all-files|(command|executable)s)"
          y=${AUTO_FU_PATHITH:-${y}}
          local -a x; x=${(M)${(@z)"${_lastcomp[tags]}"}:#${~y}}
          zle complete-word
          [[ -n $x ]] && zle -U "$LBUFFER[-1]"
          return
        };;
      (,) # glob-ish  ⇒ activate the `complete-word''s suffix
        BUFFER="$buffer_cur"; zle complete-word;
        return
        ;;
    esac
    (( $_lastcomp[nmatches]  > 1 )) &&
      # many matches ⇒ complete-word again to enter the menuselect
      zle complete-word
    (( $_lastcomp[nmatches] == 1 )) &&
      # exact match  ⇒ flag not using _oldlist for the next complete-word
      _lastcomp[nmatches]=0
  else
    [[ $LASTWIDGET == afu+*~afu+complete-word ]] && {
      afu_in_p=0; BUFFER="$buffer_cur"
    }
    zle complete-word
  fi
}

afu+complete-word~ () { zle auto-fu-extend -- afu+complete-word }

zle -N afu+complete-word afu+complete-word~

afu-install-tracking-completer () {
  local funname="$1"
  local varname="$2"
  local nozerop="${3:-}"
  local completer=${funname#_afu}
  eval "$(cat <<EOT
    $funname () {
      local ret=
      $varname=

      $completer
      ret=\$?

      if [[ -n "$nozerop" ]]; then
        $varname=\$ret
      else
        (( ret == 0 )) && $varname=t
      fi

      return ret
    }
EOT
  )"
}
afu-install-tracking-completer _afu_approximate afu_approximate_correcting_p
afu-install-tracking-completer _afu_match afu_match_ret t

[[ -z ${afu_zcompiling_p-} ]] && unset afu_zles

# NOTE: This is iffy. It dumps the necessary functions into ~/.zsh/auto-fu,
# then zrecompiles it into ~/.zsh/auto-fu.zwc.

afu-clean () {
  local d=${1:-~/.zsh}
  rm -f ${d}/{auto-fu,auto-fu.zwc*(N)}
}

afu-install-installer () {
  local match mbegin mend

  eval ${${${"$(<=(cat <<"EOT"
    auto-fu-install () {
      { $body }
      afu-install
      typeset -ga afu_accept_lines
      afu_accept_lines=($afu_accept_lines)
    }
EOT
  ))"}/\$body/
    $(print -l \
      "# afu's all zle widgets expect own keymap+widgets stuff" \
      ${${${(M)${(@f)"$(zle -l -L)"}:#zle -N (afu+*|auto-fu*)}:#(\
        ${(j.|.)afu_zles/(#b)(*)/afu+$match})}/(#b)(*)/$match} \
      "# keymap+widget machinaries" \
      "# ${afu_zles/(#b)(*)/zle -N $match ${match}-by-keymap}" \
      ${afu_zles/(#b)(*)/zle -N afu+$match})
    }/\$afu_accept_lines/$afu_accept_lines}
}

auto-fu-zcompile () {
  local afu_zcompiling_p=t

  local s=${1:?Please specify the source file itself.}
  local d=${2:?Please specify the directory for the zcompiled file.}
  local g=${d}/auto-fu
  emulate -L zsh
  setopt extended_glob no_shwordsplit

  echo "** zcompiling auto-fu in ${d} for a little faster startups..."
  { source ${s} >/dev/null 2>&1 } # Paranoid.
  echo "mkdir -p ${d}" | sh -x
  afu-clean ${d}
  afu-install-installer
  echo "* writing code ${g}"
  {
    local -a fs
    : ${(A)fs::=${(Mk)functions:#(*afu*|*auto-fu*|*-by-keymap)}}
    echo "#!zsh"
    echo "# NOTE: Generated from auto-fu.zsh ($0). Please DO NOT EDIT."; echo
    echo "$(functions \
      ${fs:#(afu-register-*|afu-initialize-*|afu-keymap+widget|\
        afu-clean|afu-install-installer|auto-fu-zcompile)})"
  }>! ${d}/auto-fu
  echo -n '* '; autoload -U zrecompile && zrecompile -p -R ${g} && {
    zmodload zsh/datetime
    touch --date="$(strftime "%F %T" $((EPOCHSECONDS - 120)))" ${g}
    [[ -z ${AUTO_FU_ZCOMPILE_NOKEEP-} ]] || { echo "rm -f ${g}" | sh -x }
    echo "** All done."
    echo "** Please update your .zshrc to load the zcompiled file like this,"
    cat <<EOT
-- >8 --
## auto-fu.zsh stuff.
# source ${s/$HOME/~}
{ . ${g/$HOME/~}; auto-fu-install; }
zstyle ':auto-fu:highlight' input bold
zstyle ':auto-fu:highlight' completion fg=black,bold
zstyle ':auto-fu:highlight' completion/one fg=white,bold,underline
zstyle ':auto-fu:var' postdisplay $'\n-azfu-'
zstyle ':auto-fu:var' track-keymap-skip opp
zle-line-init () {auto-fu-init;}; zle -N zle-line-init
zle -N zle-keymap-select auto-fu-zle-keymap-select
-- 8< --
EOT
  }
}
