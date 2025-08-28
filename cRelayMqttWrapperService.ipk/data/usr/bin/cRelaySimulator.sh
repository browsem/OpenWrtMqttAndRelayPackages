#!/bin/sh

Recur(){
    key="$1"
    value=$(grep "^$key=" "$STATE_FILE" | cut -d'=' -f2)
    if [ -n "$value" ]; then
        echo "Relay $key is $value"
    else
		WriteToFile $1 off
        #echo "Relay $key not found"
    fi
}

WriteToFile(){
	key="$1"
    value="$2"
	
    # Remove existing entry for the key
    grep -v "^$key=" "$STATE_FILE" > "${STATE_FILE}.tmp"
    echo "$key=$value" >> "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "Set $key to $value"
}

STATE_FILE="/tmp/cRelaysimState.txt"

# Ensure the state file exists
touch "$STATE_FILE"

# If two arguments are given, update the value
if [ $# -eq 2 ]; then
	WriteToFile $1 $2 
#    key="$1"
#    value="$2"
#	
#    # Remove existing entry for the key
#    grep -v "^$key=" "$STATE_FILE" > "${STATE_FILE}.tmp"
#    echo "$key=$value" >> "${STATE_FILE}.tmp"
#    mv "${STATE_FILE}.tmp" "$STATE_FILE"
#    echo "Set $key to $value"

# If one argument is given, retrieve the value
elif [ $# -eq 1 ]; then
	Recur $1

elif [ $# -eq 0 ]; then
	for i in $(seq 1 4)
	do
		Recur $i
	done
# Invalid usage
else
    echo "Usage:"
    echo "  $0 script1 on|off     # Set value"
    echo "  $0 script1        # Get value"
    exit 1
fi

