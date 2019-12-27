#!/bin/bash
#############################################################################
#  Simple PR commit validator.
#
#  Exit with nonzero status if any PR commits (commits between the current
#   branch and origin/master do not validate, e.g. are themselves merge
#   commits, or have the word "fixup" or "squash" in the commit subect, etc.
#
#  Usage: check-pr-commits.sh [upstream ref]
#
set -e
set -o pipefail

HEAD="HEAD"
BASE="origin/master"

RESULT=0
LOG=()

# ok, not ok unicode symbols:
OK='\u2714'
NOK='\u2718'

#############################################################################
#  error log and output functions:

#  Setup color (taken from sharness)
[ "x$TERM" != "xdumb" ] && (
        [ -t 1 ] &&
        tput bold >/dev/null 2>&1 &&
        tput setaf 1 >/dev/null 2>&1 &&
        tput sgr0 >/dev/null 2>&1
    ) && color=t

if test -n "$color"; then
    color_fail=$(tput bold; tput setaf 1) # bold red
    color_pass=$(tput bold; tput setaf 2) # bold green
    color_warn=$(tput bold; tput setaf 3) # bold yellow
    color_reset=$(tput sgr0) # bold green
    log()   { LOG+=("${color_warn}$*${color_reset}"); }
    ok()    { printf "${color_pass}${OK}${color_reset}"; }
    notok() { printf "${color_fail}${NOK}${color_reset}"; }
else
    log()   { LOG+=("$*"); }
    ok()    { printf "${OK}";  }
    notok() { printf "${NOK}"; }
fi

dump_log() {
    printf "\nCommits failed validation:\n"
    for line in "${LOG[@]}"; do
        printf " $line\n"
    done
}

#############################################################################
#  Tests


is_only_child() {
    return $(git rev-list --no-walk --count --merges "$@")
}

#  Return zero if commit is a merge commit (more than one parent)
is_merge_commit() {
    if ! is_only_child $1; then
        log "$1 appears to be a merge commit"
        return 0
    fi
    return 1
}

#  Return zero if commit appears to be labeled a fixup or squash commit
is_fixup_commit() {
    if git show -s --format=%s $1 | egrep -q 'fixup|squash'; then
        log "$1 appears to be a fixup/squash commit"
        return 0
    fi
    return 1
}

#  Add more test functions here...

#############################################################################
#  Check single commit:

check_commit() {
    sha=$1
    subject=$(git show -s --format=%s $sha)
    symbol="$(ok)"
    result=0
    if is_fixup_commit $sha || \
       is_merge_commit $sha; then
        symbol="$(notok)"
        result=1
    fi
    printf "${symbol} ${sha} ${subject}\n"
    return $result
}

#############################################################################
#  Main loop:

COMMITS=$(git log --format=%h ${BASE}..${HEAD})
for sha in $COMMITS; do
    if ! check_commit $sha; then
        RESULT=1
    fi
done

[ $RESULT = 1 ] && dump_log

exit $RESULT

# vi: ts=4 sw=4 expandtab
