#!/bin/bash
# Synchronize your online DALL-E history with a local copy.
#
#
#
# /!\ This requires familiarity with HTTP and the command line. /!\
#
#
#
# - Creates a directory called `tasks` (in the current directory) with a
#   subdirectory for each prompt.
# - All generated images are downloaded to the subdirectory, along with a
#   JSON file containing information about the prompt.
# - Saves a tasks/last.json in case something fails and you need to do
#   manual backups.
# - Safe to re-run if interrupted.
#
# Prerequisities: bash, jq, curl
#
# - Open Network tab in your browser's Developer Tools
# - Go to https://labs.openai.com/
# - Filter for request containing "labs/tasks"
# - Find the Authorization bearer token (sess-XXXXX), which acts like an API key
# - Run `./sync.sh` from the directory *containing* your tasks dir (or where
#   you want one to be added)

set -eu -o pipefail

UA='DALLE-history-sync/1.0'

read -e -p "Enter your OpenAI Labs session key (sess-XXXXX): " OPENAI_API_KEY

tasks="$(
  curl -sS -A "$UA" -H "Authorization: Bearer $OPENAI_API_KEY" \
       -H 'Content-Type: application/json' \
       -- https://labs.openai.com/api/labs/tasks
)"

mkdir -p tasks
echo "$tasks" > tasks/last.json

# Start from the oldest ones and process each task as a line of input.
echo "$tasks" | jq '.data|sort_by(.created)[]' -c | while IFS= read -r task; do
    # Get task ID and validate that it's safely usable on the
    # filesystem and that the format hasn't changed in a way that
    # might mean we have to rewrite par tof the script.
    task_id="$(echo "$task" | jq .id -r)"
    if [[ ! "$task_id" =~ ^task-[a-zA-Z0-9]+$ ]]; then
        echo >&2 "Potentially unsafe task ID '$task_id' -- stopping!"
        exit 1
    fi

    # Ensure we're in a good state before proceeding.
    tdir="./tasks/${task_id}"
    if [[ -d "$tdir" ]]; then
        if [[ -f "$tdir/completed" ]]; then
            echo >&2 "Skipping $task_id -- already downloaded."
            continue
        else
            echo >&2 "Warning: $task_id did not finish syncing. Will try again!"
        fi
    else
        echo <&2 "Downloading $task_id"
        mkdir -- "$tdir"
    fi

    # Save off entire task object. Can read it later to find prompt
    # and other info.
    echo "$task" | jq . > "$tdir/task.json"

    # Download generations
    echo "$task" | jq '.generations.data[]' -c | while IFS= read -r gen; do
        # Get generation ID and make sure it's safe to use on the filesystem.
        gen_id="$(echo "$gen" | jq '.id' -r)"
        if [[ ! "$gen_id" =~ ^generation-[a-zA-Z0-9]+$ ]]; then
            echo >&2 "Potentially unsafe generation ID '$gen_id' -- stopping!"
            exit 1
        fi

        # Get download URL and do a sanity check on it as well. (If
        # the file format changes, we should update what file
        # extension is used for syncing.)
        url="$(echo "$gen" | jq '.generation.image_path' -r)"
        if [[ ! "$url" =~ ^https://.+image\.webp.+ ]]; then
            echo >&2 "Generation URL doesn't look right: $url"
            exit 1
        fi

        # Download!
        echo "  ${gen_id}"
        curl -sS -A "$UA" -o "$tdir/${gen_id}.webp" -- "$url"
    done

    # Mark task as completely downloaded.
    touch "$tdir/completed"
done
