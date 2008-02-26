#!/bin/bash

# Usage:
#
#  $1 Path to gitweb web server for this repo
#     
#     Should end with '?' if pathinfo is used or ';' otherwise
#
#     Examples:
#     
#     http://git.kernel.org/gitweb.cgi?p=boot/syslinux/syslinux-gpxe.git;
#     http://repo.or.cz/w/git.git?
#
#     After this, we can append things like "a=shortlog"
#
#  $2 From address for mails to Debian BTS
set -e

URL="$1"
FROMADDR="$2"

CMD="$(dirname $(readlink -f $0))/deb-post-commit-hook"
GITREVCMD="$(dirname $(readlink -f $0))/git-find-revs.sh"

procrevs() {
    while read gitrev; do
        FILE="`mktemp -t git-deb-commit.sh.XXXXXXXXXX`"
        git show -s --pretty "$gitrev" > "$FILE"
        cat >>"$FILE" <<EOF

Diff: ${URL}a=commitdiff_plain;h=${gitrev}

EOF

        git diff-tree --stat --summary --find-copies-harder \
            "${gitrev}^..${gitrev}" >> "$FILE"

        "$CMD" -r "${gitrev}" \
            -u "`git show -s --pretty=format:%an ${gitrev}`" \
            -m "`git show -s --pretty=format:%s%n%b ${gitrev}`" \
            -s "bugs.debian.org" \
            -U "${URL}a=commit;h=${gitrev}" \
            -f "$FILE" \
            -F "$FROMADDR"

        rm "$FILE"
    done
}

${GITREVCMD} | procrevs
