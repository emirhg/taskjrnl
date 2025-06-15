function tlog(){
  local JRNL_ARGS=(--config-override editor 'vi "+/^[[:space:]]*$/"')
  local ACTIVE_PROJECT=$(task +ACTIVE limit:1 rc.report.next.columns=project rc.report.next.labels=Project rc.verbose=nothing next)

  if [[ -z $ACTIVE_PROJECT ]]; then
    if (($# > 0)); then
      local ACTIVE_PROJECT=$(task $@[1] limit:1 rc.report.next.columns=project rc.report.next.labels=Project rc.verbose=nothing next)
      local PROJECT_TAGS="@${${ACTIVE_PROJECT// /-}//\./ -and @}"
      shift
      if [[ -z "$@" ]]; then
          local ARGS=($(echo "$PROJECT_TAGS") --short)
      else
          local ARGS=($(echo "$PROJECT_TAGS") $@)
      fi
    else
      local ARGS=(--short)
    fi
  else
      if [[ -z "$@" || ( $# == 1 && $@ =~ ^[0-9]+$ ) ]]; then
        local PROJECT_TAGS="@${${ACTIVE_PROJECT// /-}//\./ @}"
        local JRNL_TEMPLATE=$(mktemp)
        local ARGS=(--template $JRNL_TEMPLATE)
        local ID=$( [[ $# == 1 && $@ =~ ^[0-9]+$ ]] && task _get ${@}.uuid || task +ACTIVE limit:1 rc.report.next.columns=uuid rc.report.next.labels=uuid rc.verbose=nothing next)
        echo "ID" $ID
        task _get ${ID}.description > $JRNL_TEMPLATE 
        local tags=$(task _get ${ID}.tags)
        if [[ -n "$tags" ]]; then
            printf "\n@${tags//,/ @}" >> $JRNL_TEMPLATE
        fi
        echo "\n@${ID}\n${PROJECT_TAGS}" >> $JRNL_TEMPLATE
    else
        local PROJECT_TAGS="@${${ACTIVE_PROJECT// /-}//\./ -and @}"
        local ARGS=($(echo "$PROJECT_TAGS") $@)
    fi
  fi

  jrnl ${JRNL_ARGS} ${ARGS}
  [[ -n "$JRNL_TEMPLATE" ]] && rm $JRNL_TEMPLATE
}
