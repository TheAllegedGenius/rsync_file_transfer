#!/bin/bash

# Discord webhook details
discord_webhook_url="https://discord.com/api/webhooks/XXXXXXXXX"  # Update with your Discord webhook URL

# Fill in your information here.
media_location="" # Location of the media directory on your media server.
download_location="" # Location of media files on your seedbox.
ssh_key="" # Path to SSH key for seedbox on your media server.
seedbox_username="" # The username for your seedbox user.
seedbox_ip="" # The IP address for your seedbox.

# Get variables from bash.
directory="$1" # Subdirectory of download_location where target file is located
filename="$2" # Name of target file
media_folder="$3" # Subdirectory of media_location where target file is to be downloaded (assumed to be "Movies" or "Shows"
show="$4" # Name of show (optional parameter)
season="$5" # Season number of show (optional parameter)

path="$download_location/$directory/$filename" # Path to target file/directory

# Determine download type based on the category. 
# Shows are assumed to be directories and movies and episodes are assumed to be files.
# It uses different methods to calculate the file size based on if you're downloading a file or a directory. 
case "$media_folder" in
    "Shows")
        download_type="Show"
	size=$(ssh -i $ssh_key $seedbox_username@$seedbox_ip "size=0; for f in $path/*; do size=$((size + $(stat -c %s $f))); done; echo $size")
        save_path="$media_location/Shows/$show"
        ;;
    "Movies")
        download_type="Movie"
	size=$(ssh -i $ssh_key $seedbox_username@$seedbox_ip "stat -c %s $path")
	show="N/A"
	season="N/A"
	save_path="$media_location/Movies/$(basename "$filename" .mkv)"
        ;;
    "Episode")
        download_type="Episode"
	size=$(ssh -i $ssh_key $seedbox_username@$seedbox_ip "stat -c %s '$path'")
	save_path="$media_location/Shows/$show/Season $season"
        ;;
    *)
        download_type="Unknown"
        ;;
esac

# Function to convert size from bytes to mebibytes (MiB)
calculate_size_in_mb() {
    size_in_mb=$(bc <<< "scale=2; $size / (1024 * 1024)")
    echo "$size_in_mb MiB"
}

# Function to convert size from bytes to gibibytes (GiB)
calculate_size_in_gb() {
    size_in_gb=$(bc <<< "scale=2; $size / (1024 * 1024 * 1024)")
    echo "$size_in_gb GiB"
}

# Function to convert size from bytes to kibibytes (KiB)
calculate_size_in_kb() {
    size_in_kb=$(bc <<< "scale=2; $size / 1024")
    echo "$size_in_kb KiB"
}

# Calculate the size message based on the size in megabytes, kilobytes, or gigabytes
if (( size < 1024 * 1024 )); then
    size_message=$(calculate_size_in_kb)
elif (( size < 1024 * 1024 * 1024 )); then
    size_message=$(calculate_size_in_mb)
else
    size_message=$(calculate_size_in_gb)
fi

# Function to send a notification to Discord
send_discord_notification() {
    local payload=$1
    curl -H "Content-Type: application/json" -X POST -d "$payload" "$discord_webhook_url" >/dev/null 2>&1
}

# This is the JSON payload for Discord to notify you the transfer started.
# You can change the color of the left hand stripe of the notification using the "color" field. 
initial_payload='{
    "embeds": [
        {
            "author": {
                "name": "Rsync",
                "icon_url": ""
            },
            "title": "'$download_type' transfer initiated",
            "color": 7506394,
            "fields": [
                {
                    "name": "File",
                    "value": "'$path'"
                },
                {
                    "name": "Show",
                    "value": "'$show'",
                    "inline": true
                },
                {
                    "name": "Season",
                    "value": "'$season'",
                    "inline": true
                },
                {
                    "name": "Size",
                    "value": "'$size_message'"
                },
                {
                    "name": "Save Path",
                    "value": "'$save_path'"
                }
            ]
        }
    ]
}'

# Send a Discord notification that the transfer has started.
send_discord_notification "$initial_payload"

# Here rsync is executed and any error messages are captured.
error_message=$(rsync -r -e "ssh -i $ssh_key" $seedbox_username@$seedbox_ip:"$path" "$save_path" 2>&1)

# This is the JSON payload upon success.
success_payload='{
    "embeds": [
        {
            "author": {
                "name": "Rsync",
                "icon_url": ""
            },
            "title": "'$download_type' transfer completed",
            "color": 7506394,
            "fields": [
                {
                    "name": "File",
                    "value": "'$filename'"
                },
                {
                    "name": "Show",
                    "value": "'$show'",
                    "inline": true
                },
                {
                    "name": "Season",
                    "value": "'$season'",
                    "inline": true
                },
                {
                    "name": "Size",
                    "value": "'$size_message'"
                },
                {
                    "name": "Save Path",
                    "value": "'$save_path'"
                }
            ]
        }
    ]
}'

# This is the JSON payload if there's any errors.
error_payload='{
    "embeds": [
        {
            "author": {
                "name": "Rsync",
                "icon_url": ""
            },
            "title": "'$download_type' transfer interrupted",
            "color": 7506394,
            "fields": [
                {
                    "name": "File",
                    "value": "'$filename'"
                },
                {
                    "name": "Show",
                    "value": "'$show'",
                    "inline": true
                },
                {
                    "name": "Season",
                    "value": "'$season'",
                    "inline": true
                },
                {
                    "name": "Size",
                    "value": "'$size_message'"
                },
                {
                    "name": "Save Path",
                    "value": "'$save_path'"
                },
                {
                    "name": "Error message",
                    "value": "'$error_message'"
                }
            ]
        }
    ]
}'

# Send a notification to Discord upon success or error.
if [ "$error_message" != "" ]; then
     send_discord_notification "$error_payload"
else
     send_discord_notification "$success_payload"
fi

# Print an info message in the console
echo "Discord notification sent."
