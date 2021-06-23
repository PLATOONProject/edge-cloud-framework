#!/bin/bash

# Parse command line args.
while getopts f:c flag
do
    case "${flag}" in
        c) ONLY_CONFIGURE=1;;
        f) KEY_FILE=${OPTARG};;
    esac
done

if [ -z "$KEY_FILE" ]; then
  KEY_FILE="${HOME}/.ssh/platoon_key"
fi

if [ -z "$ONLY_CONFIGURE" ]; then
  # Generate a key pair and add to ssh agent.
  ssh-keygen -f "$KEY_FILE" -N ""
  eval $(ssh-agent)
  ssh-add "$KEY_FILE"
fi

# Add the generated public key to edge nodes.
while read -r <&3 line; do
  host=$(echo "$line" | tr -d '[:space:]')
  echo "Writing the key to ${host}"
  ssh-copy-id -i "$KEY_FILE" "$host"
done 3< nodes.txt