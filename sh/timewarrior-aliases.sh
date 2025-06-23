alias t=task
alias ta='task +ACTIVE'
alias tadd='task add'
alias tt=tasktrack
alias tcd="task context define"
alias ctx='task context'
alias slt='task $(task +LATEST rc.verbose=nothing | grep -oP "^\d+" ) timew start pomodoro'
alias tl='task +LATEST'
alias alt='task +LATEST annotate'
alias spat='task $(task +ACTIVE limit:1 rc.verbose=nothing rc.next.columns=id rc.next.labels=id) timew start pomodoro'

# alias snp='snt pomodoro'

#alias snt='[ """$(notify-send -A -1="Cancel" -A 1="Start task" "Start new task" "$(task next_desc)" )""" -ne "-1" ] && uairctl jump work && uairctl resume &&  task $(task nextid rc.verbose=nothing) timew start pomodoro' # Start next (most urgent) task
alias snt='task $(task nextid rc.verbose=nothing) timew start pomodoro'                                       # Start next (most urgent) task
alias dnt='task `task nextid rc.verbose=nothing` done'                                                        # Mark next, most urgent task, as done.
alias dlnt='task `task nextid rc.verbose=nothing` del rc.confirmation=false rc.recurrence.confirmation=false' # Mark next, most urgent task, as done.
alias dat='task activeid rc.verbose=nothing | xargs -rI{} -exec sh -c "task {} stop; task {} done"'           # Doned active task
#alias dlat='task activeid rc.verbose=nothing | xargs -rI{} -exec sh -c "task {} stop; task {} del"'  # Doned active task
alias sat='task activeid rc.verbose=nothing | xargs -rI{} -exec sh -c "task {} stop ; timew stop"' # stop active task
alias st=start-tracked-task
# task activeid rc.verbose=nothing | xargs -r sh -c 'task "$@" timew stop pomodoro; task "$@" stop'
#
alias pat='task `task activeid rc.verbose=nothing` timew stop pomodoro' # stop active task
alias bat='task `task activeid rc.verbose=nothing` timew stop pomodoro' # stop active task
alias nt='task `task nextid rc.verbose=nothing`'
alias ntm='task $(task nextid rc.verbose=nothing) modify'
alias ntid="task nextid rc.verbose=nothing"

alias twc='timew continue'
alias tws='timew s'
alias twd='timew task :day'
alias twy='timew task :yesterday'
alias tww='timew task :week'
alias twm='timew task :month'
