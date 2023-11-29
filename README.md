# rsync_file_transfer
A bash script for automating rsync file transfers with Discord notifications via webhook. It's designed to be triggered remotely, originally by an iOS Shortcut (see File transfer.shortcut in this repo).

## Purpose
To allow you to initiate file transfers between a seedbox and a media server remotely and get Discord notifications about it. I programmed it to be a part of a semi-automatic system where torrents are automatically downloaded by Jellyseerr sending requests to Radarr and Sonarr and then I manually select which files to transfer using the Shortcut.

You'll get a notification like this when the transfer starts.

<img width="532" alt="Screen Shot 2023-11-29 at 16 45 18" src="https://github.com/TheAllegedGenius/rsync_file_transfer/assets/91752579/7a070e1e-62dc-4be4-8be9-8d76ef9ee97d">

Here's what the success notification looks like.

<img width="529" alt="Screen Shot 2023-11-29 at 16 45 41" src="https://github.com/TheAllegedGenius/rsync_file_transfer/assets/91752579/819970c2-4699-4b7d-af8f-72d5f4cd0291">

And here's what the error notification looks like.

<img width="532" alt="Screen Shot 2023-11-29 at 16 45 27" src="https://github.com/TheAllegedGenius/rsync_file_transfer/assets/91752579/a3c52f59-eac7-4e75-8cbb-755e0123c0e5">



## Usage
1. Create a Discord server and then create a webhook. ([how-to](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks"))
2. Make the file executable by running `chmod +x rsync_file_transfer.sh`.
3. Edit the script to include your webhook URL, the path to your media files, the path to your torrent downloads, the username and IP address for your seedbox, and the ssh key to access your seedbox. ([guide to make ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent))
4. Now you can run the script with `./rsync_file_transfer.sh /path/to/downloads/directory filename /path/to/target/media/directory "Show title" "Season number"` (The last two parameters are optional.)
5. If you'd like to test the Discord notifications, comment out lines 124 and 207-211.

This is a major repurposing of uncapped1599's [discord_qbittorrent](https://github.com/uncapped1599/discord_qbittorrent). Credits to them for writing the Discord notification function.
