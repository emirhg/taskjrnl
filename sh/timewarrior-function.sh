function tw(){
  # Use awk with FPAT to match the tokens
  output=$(activeContext | awk -v FPAT='[^ "]+"[^"]+?"|[^ "]+' '{for (i=1; i<=NF; i++) print $i}')

  # Read the output line by line into an array
  CONTEXT=()
  while IFS= read -r line; do
    CONTEXT+=("$line")
  done <<< "$output"

  # Print the array contents

  TIME=$(task $@ status:pending $CONTEXT export | etw)
  #COL=$(unbuffer task $@ | tee >(head -1 | wc -c ))
  TASKS=$(unbuffer task $@)
  COL=$(printf $TASKS | head -1 | sed $'s/\033\[[0-9;]*m//g' | wc -c)
  #COL=$(unbuffer task $@ | tee /dev/stdout | head -1 | sed $'s/\033\[[0-9;]*m//g' | wc -c)

  TIME_LENGTH=$(echo $TIME | wc -c )
  PADDING=$((( $COL - $TIME_LENGTH  - 1 )))
  
  printf $TASKS
  #printf " %.0s" {1..$((( $PADDING - $TIME_LENGTH )))}
  #printf "=%.0s" {1..$((( $TIME_LENGTH * 2 )))}
  printf "\n"
  printf " %.0s" {3..$PADDING}
  printf "=%.0s" {-1..$TIME_LENGTH}
  printf "\n"
  printf " %.0s" {1..$PADDING}
  printf "%s\n" "${TIME}H"
}


