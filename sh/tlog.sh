function parse_parameters(){
  # Reset all variables to prevent state leakage between calls
  PARAMS=()
  TASK_ID=""
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
  # First, check what mode we're in based on arguments
  # Display/export mode: --export, --short, @tags, or other jrnl query args
  # Template mode: no args with active task
  local HAS_TAG_QUERY=false
  local RAW_ARGS=()
  local HAS_DISPLAY_FLAG=false
  local IS_EXPORT_MODE=false

  for arg in "$@"; do
    [[ "$arg" == @* ]] && HAS_TAG_QUERY=true
    if [[ "$arg" == "--export" || "$arg" == "--short" || "$arg" == "-on" || "$arg" == "-from" || "$arg" == "-to" || "$arg" == "-contains" || "$arg" == "-and" || "$arg" == "-or" || "$arg" == "-not" ]]; then
      HAS_DISPLAY_FLAG=true
    fi
    if [[ "$arg" == "--export" ]]; then
      IS_EXPORT_MODE=true
    elif [[ "$arg" == "json" && "$IS_EXPORT_MODE" == true ]]; then
      : # Skip the json argument after --export
    else
      RAW_ARGS+=("$arg")
    fi
  done

  # If we have a display flag or tag query, we're in display/export mode (not template)
  [[ "$HAS_DISPLAY_FLAG" == true ]] && IS_EXPORT_MODE=true
  [[ "$HAS_TAG_QUERY" == true ]] && IS_EXPORT_MODE=true

  # For non-export mode (template mode), use the original parsing
  if [[ "$IS_EXPORT_MODE" != true ]]; then
    parse_parameters "$@"
  else
    # In export mode, don't use complex parsing - just use raw args
    TASK_ID=""
    TASK_TITLE=""
    TASK_DESCRIPTION=()
    PARAMS=()

    # Check for task ID in raw args (first numeric arg that's not part of a tag query)
    local FILTERED_RAW_ARGS=()
    if [[ "$HAS_TAG_QUERY" != true ]]; then
      local found_task_id=false
      for arg in "${RAW_ARGS[@]}"; do
        if [[ "$found_task_id" == false && "$arg" =~ ^[0-9]+$ ]]; then
          TASK_ID="$arg"
          found_task_id=true
          # Don't add task ID to filtered args - it will be used as UUID tag
        else
          FILTERED_RAW_ARGS+=("$arg")
        fi
      done
      RAW_ARGS=("${FILTERED_RAW_ARGS[@]}")
    fi
  fi

  echo "TASK_ID=$TASK_ID" >&2
  echo "TASK_TITLE=$TASK_TITLE" >&2
  echo "TASK_DESCRIPTION=${TASK_DESCRIPTION[*]}" >&2
  echo "PARAMS=${PARAMS[*]}" >&2
  echo "HAS_TAG_QUERY=$HAS_TAG_QUERY" >&2
  echo "RAW_ARGS=${RAW_ARGS[*]}" >&2

  local JRNL_PARAMS=(--config-override editor 'nvim --cmd "set filetype=markdown" "+/^[[:space:]]*$/"')
  local ACTIVE_PROJECT=$(task +ACTIVE limit:1 rc.report.next.columns=project rc.report.next.labels=Project rc.verbose=nothing next)

  # IS_EXPORT_MODE is already determined above, just need to finalize it
  [[ "$HAS_EXPORT_FLAG" == true ]] && IS_EXPORT_MODE=true
  [[ "$HAS_TAG_QUERY" == true ]] && IS_EXPORT_MODE=true

  if [[ "$IS_EXPORT_MODE" == true ]]; then
    # Display/export mode - never use template
    # Check if user explicitly requested --short (don't force JSON export)
    local HAS_SHORT_FLAG=false
    for arg in "$@"; do
      [[ "$arg" == "--short" ]] && HAS_SHORT_FLAG=true
    done

    if [[ "$HAS_TAG_QUERY" == true ]]; then
      # User provided tag queries - use raw args in original order
      echo "Exporting entries with tag query: ${RAW_ARGS[*]}" >&2
      if [[ "$HAS_SHORT_FLAG" == true ]]; then
        local FINAL_PARAMS=("${RAW_ARGS[@]}")
      else
        local FINAL_PARAMS=("--export" "json" "${RAW_ARGS[@]}")
      fi
    elif [[ -n "$TASK_ID" ]]; then
      # Task ID specified - look up that task's UUID and use as tag
      local ID_UUID=$(task _get ${TASK_ID}.uuid)
      echo "Using task $TASK_ID (UUID: $ID_UUID)" >&2
      if [[ "$HAS_SHORT_FLAG" == true ]]; then
        local FINAL_PARAMS=("@${ID_UUID}" "${RAW_ARGS[@]}")
      else
        local FINAL_PARAMS=("--export" "json" "@${ID_UUID}" "${RAW_ARGS[@]}")
      fi
    elif [[ -n "$ACTIVE_PROJECT" ]]; then
      # Active task - use its UUID for the tag
      local ID=$(task +ACTIVE limit:1 rc.report.next.columns=uuid rc.report.next.labels=uuid rc.verbose=nothing next)
      echo "Using active task (UUID: $ID)" >&2
      if [[ "$HAS_SHORT_FLAG" == true ]]; then
        local FINAL_PARAMS=("@${ID}" "${RAW_ARGS[@]}")
      else
        local FINAL_PARAMS=("--export" "json" "@${ID}" "${RAW_ARGS[@]}")
      fi
    elif [[ ${#RAW_ARGS[@]} -gt 0 ]]; then
      # Other args provided
      if [[ "$HAS_SHORT_FLAG" == true ]]; then
        local FINAL_PARAMS=("${RAW_ARGS[@]}")
      else
        local FINAL_PARAMS=("--export" "json" "${RAW_ARGS[@]}")
      fi
    else
      # No specific query
      if [[ "$HAS_SHORT_FLAG" == true ]]; then
        local FINAL_PARAMS=("--short")
      else
        local FINAL_PARAMS=("--export" "json")
      fi
    fi
  else
    # Template mode - for interactive entry
    if [[ -n "$ACTIVE_PROJECT" ]]; then
      # Build project tags: replace spaces with dashes, then format as @tag @tag
      local project_normalized="${ACTIVE_PROJECT// /-}"
      local PROJECT_TAGS="@${project_normalized//\./ @}"
      local JRNL_TEMPLATE=$(mktemp)
      local ID=$(task +ACTIVE limit:1 rc.report.next.columns=uuid rc.report.next.labels=uuid rc.verbose=nothing next)
      echo "ID=$ID" >&2
      task _get ${ID}.description > $JRNL_TEMPLATE
      local tags=$(task _get ${ID}.tags)
      if [[ -n "$tags" ]]; then
          printf "\n@${tags//,/ @}" >> $JRNL_TEMPLATE
      fi
      echo -e "\n@${ID}\n${PROJECT_TAGS}" >> $JRNL_TEMPLATE
      local FINAL_PARAMS=(--template $JRNL_TEMPLATE)
    elif [[ -n "$TASK_ID" ]]; then
      # Specific task ID without active task
      local PROJECT_NAME=$(task $TASK_ID limit:1 rc.report.next.columns=project rc.report.next.labels=Project rc.verbose=nothing next)
      local ID=$(task _get ${TASK_ID}.uuid)
      local JRNL_TEMPLATE=$(mktemp)
      echo "ID=$ID" >&2
      task _get ${ID}.description > $JRNL_TEMPLATE
      local tags=$(task _get ${ID}.tags)
      if [[ -n "$tags" ]]; then
          printf "\n@${tags//,/ @}" >> $JRNL_TEMPLATE
      fi
      if [[ -n "$PROJECT_NAME" ]]; then
        local project_normalized="${PROJECT_NAME// /-}"
        local PROJECT_TAGS="@${project_normalized//\./ @}"
        echo -e "\n@${ID}\n${PROJECT_TAGS}" >> $JRNL_TEMPLATE
      else
        echo -e "\n@${ID}" >> $JRNL_TEMPLATE
      fi
      local FINAL_PARAMS=(--template $JRNL_TEMPLATE)
    else
      # No task context - use default short mode
      local FINAL_PARAMS=(--short)
    fi
  fi

  echo "FINAL_PARAMS=${FINAL_PARAMS[*]}" >&2
  jrnl ${JRNL_PARAMS} ${FINAL_PARAMS}
  [[ -n "$JRNL_TEMPLATE" ]] && rm $JRNL_TEMPLATE
}
