function parse_parameters(){
  PARAMS=()
  TASK_TITLE=""
  TASK_DESCRIPTION=()
  local isArg=false
  local jrnl_param_options=(--export)
  for param in "$@"; do
    if [[ $param =~ ^[0-9]+$ && $isArg = false ]]; then
      TASK_ID="$param"
    elif [[ $param =~ ^--.* || $param =~ ^-.* || $isArg = true ]]; then
      PARAMS+=("$param")
      echo $param"="$isArg  " " >&2
      if [[ $param =~ ^-.* && "${jrnl_param_options[@]}" =~ $param ]]; then
        isArg=true
      else
        isArg=false
      fi
    else
        isArg=false
        if [[ -z $TASK_TITLE ]]; then
            TASK_TITLE="$param"
        else
            TASK_DESCRIPTION+=("$param")
        fi
    fi
  done

}

function tlog(){
  parse_parameters $@
  echo "TASK_ID=$TASK_ID" >&2
  echo "TASK_TITLE=$TASK_TITLE" >&2
  echo "TASK_DESCRIPTION=${TASK_DESCRIPTION[*]}" >&2
  echo "PARAMS=${PARAMS[*]}" >&2


  local JRNL_PARAMS=(--config-override editor 'vi "+/^[[:space:]]*$/"')
  local ACTIVE_PROJECT=$(task +ACTIVE limit:1 rc.report.next.columns=project rc.report.next.labels=Project rc.verbose=nothing next)

  if [[ -z $ACTIVE_PROJECT ]]; then
    if (($# > 0)); then
      local ACTIVE_PROJECT=$(task $@[1] limit:1 rc.report.next.columns=project rc.report.next.labels=Project rc.verbose=nothing next)
      local PROJECT_TAGS="@${${ACTIVE_PROJECT// /-}//\./ -and @}"
      shift
      if [[ -z "$@" ]]; then
          local PARAMS=($(echo "$PROJECT_TAGS") --short)
      else
          local PARAMS=($(echo "$PROJECT_TAGS") $@)
      fi
    else
      local PARAMS=(--short)
    fi
  else
      if [[ -z "$@" || ( $# == 1 && $@ =~ ^[0-9]+$ ) ]]; then
        local PROJECT_TAGS="@${${ACTIVE_PROJECT// /-}//\./ @}"
        local JRNL_TEMPLATE=$(mktemp)
        local PARAMS=(--template $JRNL_TEMPLATE)
        local ID=$( [[ $# == 1 && $@ =~ ^[0-9]+$ ]] && task _get ${@}.uuid || task +ACTIVE limit:1 rc.report.next.columns=uuid rc.report.next.labels=uuid rc.verbose=nothing next)
        echo "ID" $ID >&2
        task _get ${ID}.description > $JRNL_TEMPLATE 
        local tags=$(task _get ${ID}.tags)
        if [[ -n "$tags" ]]; then
            printf "\n@${tags//,/ @}" >> $JRNL_TEMPLATE
        fi
        echo "\n@${ID}\n${PROJECT_TAGS}" >> $JRNL_TEMPLATE
    else
        local PROJECT_TAGS="@${${ACTIVE_PROJECT// /-}//\./ -and @}"
        local PARAMS=($(echo "$PROJECT_TAGS") $@)
    fi
  fi

  jrnl ${JRNL_PARAMS} ${PARAMS}
  [[ -n "$JRNL_TEMPLATE" ]] && rm $JRNL_TEMPLATE
}
