# Capture the script directory when this file is sourced
# Try BASH_SOURCE first, fall back to other methods
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    _script_path="${BASH_SOURCE[0]}"
elif [[ -n "$0" && "$0" != "-bash" && "$0" != "bash" ]]; then
    _script_path="$0"
else
    # Last resort - use pwd if we're sourced from an interactive shell
    _script_path="$(pwd)/${BASH_SOURCE[0]}"
fi
_PRESENTLOG_SCRIPT_DIR="$(cd "$(dirname "$_script_path")/.." && pwd)"
unset _script_path

function presentlog() {
    local fifo_path="/tmp/presentlog.fifo"

    tlog $@ --export json | ${_PRESENTLOG_SCRIPT_DIR}/python/jrnl-to-presenterm.py --date >$fifo_path

    cat $fifo_path
    presenterm $fifo_path
    rm $fifo_path
}
