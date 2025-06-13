function activeContext(){
  task context rc.defaultwidth:200| grep -oP "(?<=read  ).*(?=yes)" 
}

function tasktrack(){
  task add "$@"
  #ID=$(task +LATEST | grep -oP "^\d+")
  ID=$(task +LATEST rc.report.next.columns=id rc.report.next.labels=ID rc.verbose=nothing next)
  echo "Last ID $ID"
  task "${ID}" timew start pomodoro
}

function timewlogged(){
  timew s $(task ${1:-$(task nextid rc.verbose=nothing)} id rc.verbose=nothing) :all
}

function snt(){
  POMODORO="$1"
  RESPONSE=1
  # echo "Entering IF $(date +"%s.%N")"
  # if [[ ! "$POMODORO" = "pomodoro" ]]; then
  #   echo "Entering Notify dialog $(date +"%s.%N")"
  #   # RESPONSE="""$(notify-send -A -1="Cancel" -A 1="Start task" -t 2000 "Start new task" "$(task next_desc)" )"""
  #   # echo "Exiting Notify dialog $(date +"%s.%N")"
  #   #POMODORO="pomodoro"
  # fi
  echo "Entering IF $(date +"%s.%N")"
  # if [ ! "$RESPONSE" -eq -1 ]; then
    echo "Entering Pomodoro $(date +"%s.%N")"
    [ "$POMODORO" = "pomodoro" ] && [ $(uairctl fetch "{state}") = "Break" ] && uairctl jump work && uairctl resume 
    echo "Entering task tracking $(task nextid rc.verbose=nothing) $POMODORO $(date +"%s.%N")"
    task $(task nextid rc.verbose=nothing) timew start $POMODORO
    echo "Exiting task tracking $POMODORO $(date +"%s.%N")"
  # fi
}

function task-summary(){
  # Show a summary of all the projects, including the completed ones.
  if [ $# -eq 1 ]; then
    DEEP_LEVEL="{,$(( $1 * 2 ))}"
  else
    DEEP_LEVEL="*"
  fi
  unbuffer task summary rc.summary.all.projects:1 | grep --color=never -P "^(\e\[(48;5;234m|4m))?(\s$DEEP_LEVEL)?[A-z]" | tee >(echo $(( $(wc -l) - 1 )) "projects")
}
