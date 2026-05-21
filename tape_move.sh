#!/bin/bash

# Define your tape changer device path here
CHANGER_DEV="/dev/sch0"

echo "Starting tape transfer process..."

# Loop through source slots 15 to 23
for source in {15..23}; do
    # Calculate the destination slot (source - 2)
    dest=$((source - 2))
    
    echo "Attempting to move tape from slot $source to slot $dest..."
    
    # Execute the mtx command
    mtx -f "$CHANGER_DEV" transfer "$source" "$dest"
    
    # Check if the mtx command was successful
    if [ $? -eq 0 ]; then
        echo "Success: Moved $source -> $dest"
    else
        echo "Error: Failed to move tape from $source to $dest. Aborting."
        # Exit on failure to prevent sequential errors or collisions
        exit 1 
    fi
    
    # Pause for 2 seconds to let the physical mechanism settle between operations
    sleep 2
done

echo "All tape transfers completed successfully."
