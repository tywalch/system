#!/bin/bash

set -euo pipefail

# Get today's Calendar events and nag 5 minutes before, in HH:MM format

# Allow the user to specify the number of minutes before the meeting to nag
TEST_MODE=false
if [ -z "$1" ]; then
  BEFORE_TIME=300
elif [ "$1" == "-t" ]; then
  TEST_MODE=true
else 
  BEFORE_TIME=$(($1 * 60))
fi

EVENTS=$(osascript <<'END'
set today to current date
set midnight to today - (time of today)
set tomorrow to midnight + (1 * days)
set output to ""
tell application "Calendar"
  repeat with cal in calendars
    repeat with e in (every event of cal whose start date ≥ midnight and start date < tomorrow)
      set eventName to summary of e
      set eventStart to start date of e
      set yearStr to year of eventStart as string
      set monthNum to text -2 thru -1 of ("0" & ((month of eventStart) as integer))
      set dayStr to text -2 thru -1 of ("0" & (day of eventStart as integer))
      set hourStr to text -2 thru -1 of ("0" & (hours of eventStart as integer))
      set minStr to text -2 thru -1 of ("0" & (minutes of eventStart as integer))
      set secStr to text -2 thru -1 of ("0" & (seconds of eventStart as integer))
      set timeStamp to yearStr & "-" & monthNum & "-" & dayStr & " " & hourStr & ":" & minStr & ":" & secStr
      set output to output & eventName & "\t" & timeStamp & "\n"
    end repeat
  end repeat
end tell
return output
END
)

# Parse and run `nag` for each event
while IFS=$'\t' read -r MEETING_NAME START_TIME; do
  if [ "$TEST_MODE" = true ]; then
    echo "TEST MODE: $MEETING_NAME $START_TIME"
    continue
  fi
  
  [ -z "$MEETING_NAME" ] && continue

  # Convert start time to epoch
  MEETING_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$START_TIME" "+%s")
  NAG_EPOCH=$((MEETING_EPOCH - BEFORE_TIME))
  CLOCK_TIME=$(date -r "$NAG_EPOCH" "+%H:%M")

  nag at "$CLOCK_TIME" "$MEETING_NAME"
done <<< "$EVENTS"
