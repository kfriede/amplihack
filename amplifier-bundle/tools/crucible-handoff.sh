#!/usr/bin/env bash

# Usage: crucible-handoff.sh [--dry-run] [PRODUCT_BRIEF_FILE|-]
# Reads a Crucible ProductBrief from a file path or stdin, assembles smart-orchestrator
# context, shows the exact amplihack command, prompts for confirmation, and optionally runs it.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: crucible-handoff.sh [--dry-run] [PRODUCT_BRIEF_FILE|-]

Bridge a Crucible ProductBrief into amplihack's smart-orchestrator.

Options:
  --dry-run   Show the assembled context and command without executing
  -h, --help  Show this help text

Input:
  - Pass a ProductBrief file path
  - Pass - to read from stdin
  - Omit the file path and pipe ProductBrief content into stdin
EOF
}

trim() {
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

collapse_text() {
    awk '
        BEGIN { first = 1 }
        {
            line = $0
            gsub(/^[[:space:]]*-[[:space:]]*/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line == "") next
            if (!first) printf " "
            printf "%s", line
            first = 0
        }
        END { printf "\n" }
    '
}

normalize_list() {
    awk '
        {
            line = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            if (line == "") next
            if (line ~ /^\[[^][]+\]$/) {
                gsub(/^\[[[:space:]]*|[[:space:]]*\]$/, "", line)
                n = split(line, parts, /,[[:space:]]*/)
                for (i = 1; i <= n; i++) {
                    item = parts[i]
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", item)
                    if (item != "") print item
                }
                next
            }
            sub(/^[[:space:]]*-[[:space:]]*/, "", line)
            if (line != "") print line
        }
    '
}

extract_field() {
    local key="$1"
    awk -v key="$key" '
        function trim(s) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
            return s
        }
        function indent_len(line) {
            match(line, /^[[:space:]]*/)
            return RLENGTH
        }
        function is_key(line) {
            return line ~ /^[[:space:]]*[A-Za-z0-9_]+:[[:space:]]*(.*)$/
        }
        BEGIN {
            capture = 0
            key_indent = -1
        }
        {
            if (capture == 0) {
                pattern = "^[[:space:]]*" key ":[[:space:]]*(.*)$"
                if ($0 ~ pattern) {
                    capture = 1
                    key_indent = indent_len($0)
                    line = $0
                    sub("^[[:space:]]*" key ":[[:space:]]*", "", line)
                    sub(/[[:space:]]+#.*$/, "", line)
                    line = trim(line)
                    if (line == "" || line == "|" || line == ">" || line == "|-" || line == ">-" || line == "|+" || line == ">+") {
                        next
                    }
                    print line
                    exit
                }
                next
            }

            if (is_key($0) && indent_len($0) <= key_indent) {
                exit
            }

            line = $0
            sub(/^[[:space:]]+/, "", line)
            print line
        }
    ' <<<"$BRIEF_CONTENT"
}

shell_join() {
    printf '%q ' "$@"
}

dry_run=0
input_path=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            dry_run=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -)
            input_path="-"
            ;;
        --*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [ -n "$input_path" ]; then
                echo "Only one ProductBrief input may be provided." >&2
                usage >&2
                exit 1
            fi
            input_path="$1"
            ;;
    esac
    shift
done

if [ -n "$input_path" ] && [ "$input_path" != "-" ]; then
    if [ ! -f "$input_path" ]; then
        echo "ProductBrief file not found: $input_path" >&2
        exit 1
    fi
    BRIEF_CONTENT=$(cat -- "$input_path")
elif [ "$input_path" = "-" ] || [ ! -t 0 ]; then
    BRIEF_CONTENT=$(cat)
else
    usage >&2
    exit 1
fi

if [ -z "$(printf '%s' "$BRIEF_CONTENT" | tr -d '[:space:]')" ]; then
    echo "ProductBrief input is empty." >&2
    exit 1
fi

one_liner=$(extract_field "one_liner" | collapse_text | trim)
architecture=$(extract_field "architecture" | collapse_text | trim)
stories=$(extract_field "stories" | normalize_list)
complexity_estimate=$(extract_field "complexity_estimate" | collapse_text | trim)
mvp_scope=$(extract_field "mvp_scope" | collapse_text | trim)
out_of_scope=$(extract_field "out_of_scope" | normalize_list)
estimated_effort=$(extract_field "estimated_effort" | collapse_text | trim)

if [ -z "$one_liner" ]; then
    one_liner="Implement the attached Crucible ProductBrief."
fi

complexity_hint=""
complexity_value=$(printf '%s' "$complexity_estimate" | tr '[:upper:]' '[:lower:]')
case "$complexity_value" in
    simple*|small*|low*)
        complexity_hint="Recipe hint: likely a single-workstream execution unless the orchestrator finds hidden complexity."
        ;;
    medium*|moderate*)
        complexity_hint="Recipe hint: expect smart-orchestrator to validate scope and possibly split a few workstreams."
        ;;
    complex*|high*|large*)
        complexity_hint="Recipe hint: expect smart-orchestrator to decompose into multiple workstreams."
        ;;
    "")
        complexity_hint=""
        ;;
    *)
        complexity_hint="Recipe hint from complexity_estimate: $complexity_estimate"
        ;;
esac

stories_block=""
if [ -n "$stories" ]; then
    stories_block=$(printf '%s\n' "$stories" | awk 'NF { print "- " $0 }')
fi

out_of_scope_block=""
if [ -n "$out_of_scope" ]; then
    out_of_scope_block=$(printf '%s\n' "$out_of_scope" | awk 'NF { print "- " $0 }')
fi

task_description="$one_liner"

if [ -n "$architecture" ]; then
    task_description+=$'\n\nArchitecture context:\n'
    task_description+="$architecture"
fi

if [ -n "$stories_block" ]; then
    task_description+=$'\n\nWorkstream decomposition hints from ProductBrief stories:\n'
    task_description+="$stories_block"
fi

if [ -n "$mvp_scope" ]; then
    task_description+=$'\n\nMVP scope constraints:\n'
    task_description+="$mvp_scope"
fi

if [ -n "$out_of_scope_block" ]; then
    task_description+=$'\n\nExplicit exclusions / out of scope:\n'
    task_description+="$out_of_scope_block"
fi

if [ -n "$estimated_effort" ]; then
    task_description+=$'\n\nPlanning context:\n'
    task_description+="Estimated effort: $estimated_effort"
fi

if [ -n "$complexity_hint" ]; then
    task_description+=$'\n'
    task_description+="$complexity_hint"
fi

cmd=(
    amplihack recipe run amplifier-bundle/recipes/smart-orchestrator.yaml
    -c "task_description=$task_description"
    -c "repo_path=."
    --verbose
)

show_value() {
    local label="$1"
    local value="$2"
    if [ -n "$value" ]; then
        printf '%s\n%s\n\n' "$label" "$value"
    else
        printf '%s\n%s\n\n' "$label" "(not provided)"
    fi
}

printf '\n=== Crucible → amplihack handoff ===\n\n'
show_value "Assembled task description:" "$task_description"
show_value "Architecture context:" "$architecture"
show_value "Stories / workstream hints:" "$stories_block"
show_value "Complexity estimate:" "$complexity_estimate"
show_value "Recipe selection hint:" "$complexity_hint"
show_value "MVP scope:" "$mvp_scope"
show_value "Out of scope:" "$out_of_scope_block"
show_value "Estimated effort:" "$estimated_effort"
printf 'Command to run:\n%s\n\n' "$(shell_join "${cmd[@]}")"

if [ "$dry_run" -eq 1 ]; then
    echo "Dry run only; not executing."
    exit 0
fi

if [ ! -r /dev/tty ]; then
    echo "No TTY available for confirmation prompt; refusing to execute. Use --dry-run to inspect the handoff." >&2
    exit 1
fi

read -r -p "Launch amplihack build? (y/n) " reply </dev/tty
case "$reply" in
    y|Y|yes|YES)
        exec "${cmd[@]}"
        ;;
    *)
        echo "Aborted."
        ;;
esac
