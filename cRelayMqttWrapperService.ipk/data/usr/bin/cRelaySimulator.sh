#!/bin/sh
STATE_FILE="/tmp/cRelaysimState"
NumberOfRelaysSimulated=4

Recur(){
    key="Relay ${1}: "	
	value=$(grep "^$key" "$STATE_FILE")	
	
	if [ -n "$value" ]; then
		echo $value
	else
		WriteToFile $1 off
        #echo "Relay $key not found"	
    fi

}

WriteToFile(){
	key="Relay ${1}: "	
    value="$2"
	
    # Remove existing entry for the key	
    grep -v "^$key" "$STATE_FILE" > "${STATE_FILE}.tmp"	
    echo "$key$value" >> "${STATE_FILE}.tmp"
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "Set $key$value"
}


# Ensure the state file exists
touch "$STATE_FILE"
FLAG_I=false
# Parse optional flags
while getopts ":f:n:i" opt; do	
	case "${opt}" in
    f) STATE_FILE="$OPTARG" ;;
    n) NumberOfRelaysSimulated="$OPTARG" ;;	
	i) FLAG_I=true ;;
    *) echo "Usage: $0 [-f state_file] [-n num_relays] [-i] [relay] [ON|OFF]" >&2
       exit 1 ;;
  esac
done

# Shift away parsed options
shift $((OPTIND - 1))


if [ "$FLAG_I" = true ]; then
	echo Card 1: Serial number 87654321, $NumberOfRelaysSimulated relays
	for i in $(seq 1 $NumberOfRelaysSimulated)
	do
		Recur $i
	done

else
# If two arguments are given, update the value

	if [ $# -eq 2 ]; then
		WriteToFile $1 $2 
	#    key="$1"
	#    value="$2"

	# If one argument is given, retrieve the value
	elif [ $# -eq 1 ]; then
		Recur $1

	elif [ $# -eq 0 ]; then
		echo 'Spoof of real version, gotten through copilot'
		echo 'crelay, version 0.11'
		echo ''
		echo 'This utility provides a unified way of controlling different types of relay cards.'
		echo 'Currently supported relay cards:'
		echo ' - Conrad USB 4-channel relay card'
		echo ' - Sainsmart USB 4/8-channel relay card'
		echo ' - HID API compatible relay card'
		echo ' - Sainsmart USB-HID 16-channel relay card'
		echo ' - Generic GPIO relays'
		echo ''
		echo 'Usage:'
		echo '  crelay [-s <serial number>] -i'
		echo '  crelay [<relay number>] [ON|OFF]'
		echo ''
		echo 'The card which is detected first will be used, unless -s switch and a serial number is passed.'

		# Invalid usage
	else
		echo "Usage:"
		echo "  $0 script1 on|off     # Set value"
		echo "  $0 script1        # Get value"
		exit 1
	fi
fi
		