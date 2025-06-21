function presentlog() {
    local script_dir=$(dirname $0:A)
    local fifo_path="/tmp/presentlog.fifo"

    tlog $@ --export json | ${script_dir}/python/jrnl-to-presenterm.py --date >$fifo_path

    presenterm $fifo_path
    rm $fifo_path
}
