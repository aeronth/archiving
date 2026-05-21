#!/bin/bash

# Define your device paths and drive number
CHANGER_DEV="/dev/sch0"
DRIVE_DEV="/dev/st0"
DRIVE_NUM=0

echo "Starting tape logging process..."
echo "-----------------------------------"

# Loop through source slots 1 to 22
for slot in {1..22}; do
    echo "Loading tape from slot $slot into drive $DRIVE_NUM..."
    
    # Load the tape
    sudo mtx -f "$CHANGER_DEV" load "$slot" "$DRIVE_NUM"
    
    # Check if the load was successful (e.g., skip if the slot is empty)
    if [ $? -ne 0 ]; then
        echo "Notice: Failed to load slot $slot (it may be empty). Skipping..."
        echo "-----------------------------------"
        continue
    fi
    
    # Wait for the drive to thread the tape and become ready
    # Note: Adjust this sleep time if your drive takes longer to ready the tape
    echo "Waiting 15 seconds for the drive to thread the tape..."
    sleep 15
    
    # Extract the VolumeTag from mtx status
    # This parses the specific line for the loaded drive and grabs the string after "VolumeTag ="
    vol_tag=$(sudo mtx -f "$CHANGER_DEV" status | grep "Data Transfer Element $DRIVE_NUM:Full" | sed -n 's/.*VolumeTag *= *\([^ ]*\).*/\1/p' | tr -d '\r')
    
    # Fallback in case a barcode reader fails or the tape has no label
    if [ -z "$vol_tag" ]; then
        vol_tag="UNKNOWN_TAG_SLOT_${slot}"
        echo "Warning: Could not read VolumeTag for slot $slot. Using fallback name: $vol_tag"
    else
        echo "Found tape with VolumeTag: $vol_tag"
    fi
    
    # Run sg_logs and output to the uniquely named file
    log_filename="${vol_tag}.sg.logs"
    echo "Extracting sg_logs (page 0x17) to $log_filename..."
    sudo sg_logs -p 0x17 "$DRIVE_DEV" > "$log_filename"
    
    # Unload the tape back to its original slot
    echo "Unloading tape back to slot $slot..."
    sudo mtx -f "$CHANGER_DEV" unload "$slot" "$DRIVE_NUM"
    
    # Critical error check: If unload fails, halt the script to prevent damage
    if [ $? -ne 0 ]; then
        echo "CRITICAL ERROR: Failed to unload slot $slot! Aborting script to prevent mechanical collisions."
        exit 1
    fi
    
    echo "Finished processing slot $slot."
    echo "-----------------------------------"
    
    # Short pause before the next robotic movement
    sleep 2
done

echo "All slots processed successfully."
