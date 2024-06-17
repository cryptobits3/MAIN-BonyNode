###############################################################################################################################
###############################################################################################################################
###############################################################################################################################
##################################################### MAINNET #################################################################
###############################################################################################################################
###############################################################################################################################
# arkhadian 
# andromeda
# blockx
# crossfi
# celestia
# doravota
# entangle
# point
# selfchain
# seda
# source
# terp
# timpi
###############################################################################################################################
# MAINNET 12 - arkhadian
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://arkhadian-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/arkhadian/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/arkhadian/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# andromeda
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://andromeda-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/andromeda/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/andromeda/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# blockx
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://blockx-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/blockx/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/blockx/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# crossfi
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://crossfi-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/crossfi/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/crossfi/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# celestia
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://celestia-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/celestia/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/celestia/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# doravota
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://doravota-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/doravota/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/doravota/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# entangle
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://entangle-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/entangle/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/entangle/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# point
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://point-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/point/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/point/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
###############################################################################################################################
# selfchain
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://selfchain-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/selfchain/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/selfchain/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# seda
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://seda-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/seda/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/seda/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# source
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://source-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/source/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/source/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# terp
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://terp-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/terp/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/terp/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# timpi
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://timpi-mainnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/mainnet-files/timpi/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/mainnet-files/timpi/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################
##################################################   TESTNET   ################################################################
###############################################################################################################################
###############################################################################################################################
# airchains
# alignedlayer
# arkeo
# artela
# crossfi
# cardchain
# elys
# entrypoint
# galactica
# hedge
# hypersign
# initia
# lava
# mantra
# nillion
# namada
# og
# ojo
# pryzm
# selfchain
# structs
# swisstronik
# side
# union
# warden
###############################################################################################################################
# TESTNET 26 - airchains
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://airchains-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/airchains/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/airchains/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# alignedlayer
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://alignedlayer-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/alignedlayer/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/alignedlayer/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# artela
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://artela-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/artela/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/artela/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# crossfi
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://crossfi-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/crossfi/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/crossfi/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# cardchain
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://cardchain-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/cardchain/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/cardchain/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# elys
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://elys-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/elys/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/elys/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# entrypoint
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://entrypoint-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/entrypoint/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/entrypoint/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# galactica
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://galactica-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/galactica/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/galactica/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# hedge
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://hedge-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/hedge/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/hedge/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# hypersign
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://hypersign-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/hypersign/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/hypersign/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# initia
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://initia-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/initia/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/initia/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# lava
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://lava-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/lava/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/lava/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# mantra
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://mantra-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/mantra/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/mantra/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# nillion
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://nillion-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/nillion/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/nillion/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# namada
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://namada-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/namada/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/namada/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# og
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://og-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/og/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/og/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# ojo
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://ojo-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/ojo/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/ojo/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# pryzm
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://pryzm-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/pryzm/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/pryzm/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# selfchain
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://selfchain-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/selfchain/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/selfchain/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# structs
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://structs-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/structs/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/structs/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# swisstronik
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://swisstronik-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/swisstronik/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/swisstronik/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# side
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://side-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/side/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/side/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# union
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://union-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/union/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/union/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
# warden
###############################################################################################################################
#!/bin/bash
# Start command: /bin/bash rpc.sh
# Specify the rpc address
RPC="https://warden-testnet-rpc.bonynode.online:443"

echo "RPC scanner started..."

# Function  check_rpc_connection
check_rpc_connection() {
    if curl -s "$RPC" | grep -q "height" > /dev/null; then
        PARENT_NETWORK=$(curl -s "$RPC/status" | jq -r '.result.node_info.network')
        return 0
    else
        return 1
    fi
}

# Function fetch_data 
fetch_data() {
    local url=$1
    local data=$(curl -s --max-time 2 "$url")
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch data from $url" >&2
        return 1
    fi
    
    echo "$data"
    return 0
}


declare -A processed_rpc
declare -A rpc_list

# Function process_data_rpc_list
process_data_rpc_list() {
    local data=$1
    local current_rpc_url=$2 # URL текущего обрабатываемого RPC

    if [ -z "$data" ]; then
        echo "Warning: No data to process from $current_rpc_url"
        return 1
    fi

    local peers=$(echo "$data" | jq -c '.result.peers[]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON data."
        return 1
    fi

    for peer in $peers; do
        rpc_address=$(echo "$peer" | jq -r '.node_info.other.rpc_address')
        if [[ $rpc_address == *"tcp://0.0.0.0:"* ]]; then
            ip=$(echo "$peer" | jq -r '.remote_ip // ""')
            port=${rpc_address##*:}
            rpc_combined="$ip:$port"
            temp_key="$rpc_combined"
            echo "Debug: rpc_combined = $rpc_combined"
            rpc_list["${temp_key}"]="{ \"rpc\": \"$rpc_combined\" }"

            if [[ -z ${processed_rpc["$rpc_combined"]} ]]; then
                processed_rpc["$rpc_combined"]=1
                echo "Processing new RPC: $rpc_combined" 
                new_data=$(fetch_data "http://$rpc_combined/net_info")
                if [ $? -eq 0 ]; then
                    process_data_rpc_list "$new_data" "$rpc_combined" # Передаем текущий URL как параметр
                else
                    echo "Warning: Skipping $rpc_combined due to fetch error."
                fi
            fi
        fi
    done
}

# Function check_rpc_accessibility
check_rpc_accessibility() {
    local rpc=$1
    if [[ $rpc == http://* ]]; then
        protocol="http"
        rpc=${rpc#http://}
    elif [[ $rpc == https://* ]]; then
        protocol="https"
        rpc=${rpc#https://}
    else
        protocol="http"
    fi

    local status_data=$(fetch_data "$protocol://$rpc/status")
    if [[ $? -ne 0 ]]; then
        echo "Error: Unable to fetch status data from $rpc"
        return 1
    fi

    local rpc_network=$(echo "$status_data" | jq -r '.result.node_info.network' 2>/dev/null)
    if [[ "$rpc_network" == "$PARENT_NETWORK" ]]; then
        return 0 
    else
        return 1
    fi
}

# Starting collect public RPCs
if check_rpc_connection; then
    public_data=$(fetch_data "$RPC/net_info")
    process_data_rpc_list "$public_data" "$PARENT_NETWORK"
    echo "Checking chain_id = $PARENT_NETWORK..."
fi

# Creating and populating the rpc_combined.json file
FILE_PATH_JSON="/var/www/testnet-files/warden/.rpc_combined.json"

# Generate JSON data in memory
json_data="{"

first_entry=true

for rpc in "${!rpc_list[@]}"; do
    if check_rpc_accessibility "$rpc"; then
        data=$(fetch_data "$rpc/status")
        network=$(echo "$data" | jq -r '.result.node_info.network')
        moniker=$(echo "$data" | jq -r '.result.node_info.moniker')
        tx_index=$(echo "$data" | jq -r '.result.node_info.other.tx_index')
        latest_block_height=$(echo "$data" | jq -r '.result.sync_info.latest_block_height')
        earliest_block_height=$(echo "$data" | jq -r '.result.sync_info.earliest_block_height')
        catching_up=$(echo "$data" | jq -r '.result.sync_info.catching_up')
        voting_power=$(echo "$data" | jq -r '.result.validator_info.voting_power')
        scan_time=$(date '+%FT%T.%N%Z')

        # Добавление только если catching_up равно false
        if [ "$catching_up" = "false" ]; then
            if [ "$first_entry" = false ]; then
                json_data+=","
            else
                first_entry=false
            fi

            json_data+="\"$rpc\": {\"network\": \"$network\", \"moniker\": \"$moniker\", \"tx_index\": \"$tx_index\", \"latest_block_height\": \"$latest_block_height\", \"earliest_block_height\": \"$earliest_block_height\", \"catching_up\": $catching_up, \"voting_power\": \"$voting_power\", \"scan_time\": \"$scan_time\"}"
        fi
    fi
done

json_data+="}"

# Sort JSON data by earliest_block_height and format it
sorted_json=$(echo "$json_data" | jq 'to_entries | sort_by(.value.earliest_block_height | tonumber) | from_entries')

# Write sorted and formatted JSON data to file
echo "$sorted_json" > "/var/www/testnet-files/warden/.rpc_combined.json"

# Uncomment the following line if you want to see the file content
# cat $PFILE_PATH_JSON
###############################################################################################################################
