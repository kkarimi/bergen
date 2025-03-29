#!/bin/bash

# Required dimensions for Mac App Store screenshots (16:10 aspect ratio)
# 1280 × 800px
# 1440 × 900px
# 2560 × 1600px
# 2880 × 1800px

# Create screenshots directory if it doesn't exist
mkdir -p screenshots

# Check if sips is available for image verification
if ! command -v sips &> /dev/null; then
    echo "❌ sips command not found. This script requires macOS's built-in sips command."
    exit 1
fi

# Function to verify screenshot dimensions
verify_screenshot() {
    local file=$1
    local expected_width=$2
    local expected_height=$3
    
    if [ ! -f "$file" ]; then
        echo "❌ Screenshot file not found: $file"
        return 1
    fi
    
    # Get actual dimensions
    local dimensions=$(sips -g pixelWidth -g pixelHeight "$file" | grep -E 'pixel(Width|Height)')
    local actual_width=$(echo "$dimensions" | grep pixelWidth | awk '{print $2}')
    local actual_height=$(echo "$dimensions" | grep pixelHeight | awk '{print $2}')
    
    if [ "$actual_width" != "$expected_width" ] || [ "$actual_height" != "$expected_height" ]; then
        echo "❌ Dimension mismatch for $file"
        echo "   Expected: ${expected_width}x${expected_height}"
        echo "   Actual: ${actual_width}x${actual_height}"
        return 1
    else
        echo "✅ Dimensions verified: ${actual_width}x${actual_height}"
        return 0
    fi
}

# Function to check permissions
check_permissions() {
    # Try a simple UI scripting command to test permissions
    if ! osascript -e 'tell application "System Events" to get name of every process' &>/dev/null; then
        echo "⚠️  Terminal needs Accessibility permissions to control window size."
        echo "Please follow these steps:"
        echo "1. Open System Settings (System Preferences)"
        echo "2. Go to Privacy & Security > Privacy > Accessibility"
        echo "3. Click the lock icon to make changes"
        echo "4. Click + and add Terminal.app from Applications > Utilities"
        echo "5. Ensure the checkbox next to Terminal is checked"
        echo "6. Run this script again"
        exit 1
    fi
    
    # Check if we can take screenshots
    if ! screencapture -x test_permission.png &>/dev/null; then
        echo "⚠️  Terminal needs Screen Recording permissions to take screenshots."
        echo "Please follow these steps:"
        echo "1. Open System Settings (System Preferences)"
        echo "2. Go to Privacy & Security > Privacy > Screen Recording"
        echo "3. Click the lock icon to make changes"
        echo "4. Click + and add Terminal.app from Applications > Utilities"
        echo "5. Ensure the checkbox next to Terminal is checked"
        echo "6. Run this script again"
        rm -f test_permission.png
        exit 1
    fi
    rm -f test_permission.png
}

# Function to resize window and take screenshot
take_screenshot() {
    local width=$1
    local height=$2
    local output_file="screenshots/bergen-${width}x${height}.png"
    
    echo "📸 Taking ${width}x${height} screenshot..."
    
    # AppleScript to resize and position the window
    local window_info=$(osascript <<EOF
    tell application "Bergen"
        activate
    end tell
    
    delay 1
    
    tell application "System Events"
        tell application process "bergen"
            set targetWindow to window 1
            
            -- First set position to origin
            set position of targetWindow to {0, 0}
            delay 0.5
            
            -- Then set size (add pixels for window chrome)
            set size of targetWindow to {$((width * 2)), $((height * 2 + 44))}
            delay 0.5
            
            -- Return window position and size
            return {position of targetWindow & size of targetWindow}
        end tell
    end tell
EOF
    )
    
    # Parse window info
    if [[ -z "$window_info" ]]; then
        echo "❌ Failed to get window information"
        exit 1
    fi
    
    # Extract coordinates from window_info (format: {x, y, width, height})
    local x=$(echo "$window_info" | sed -E 's/[{}]//g' | cut -d',' -f1 | tr -d ' ')
    local y=$(echo "$window_info" | sed -E 's/[{}]//g' | cut -d',' -f2 | tr -d ' ')
    
    # Validate coordinates
    if [[ ! "$x" =~ ^[0-9]+$ ]] || [[ ! "$y" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid window coordinates: x=$x, y=$y"
        echo "Debug window_info: $window_info"
        exit 1
    fi
    
    # Add menu bar height to y coordinate
    y=$((y + 50))
    
    echo "📍 Window coordinates: x=$x, y=$y"
    
    # Take the screenshot of the specific region
    screencapture -r -R"$((x * 2)),$((y * 2)),$((width * 2)),$((height * 2))" "$output_file"
    
    # Resize the screenshot to the target dimensions
    sips -z $height $width "$output_file" >/dev/null 2>&1
    
    # Verify the screenshot dimensions
    if verify_screenshot "$output_file" $width $height; then
        echo "✅ Screenshot saved as $output_file"
    else
        echo "❌ Screenshot failed dimension verification"
        echo "⚠️  Debug info: x=$x, y=$y, width=$width, height=$height"
        exit 1
    fi
    
    # Give some time between screenshots
    sleep 2
}

echo "🔍 Checking permissions..."
check_permissions

# Make sure the app is running
if ! pgrep -x "bergen" > /dev/null; then
    echo "🚀 Starting Bergen app..."
    open -a Bergen
    sleep 5  # Wait for app to launch
fi

# Take screenshots at each required dimension
echo "📸 Taking screenshots... Please don't move the window during capture."

take_screenshot 1280 800
take_screenshot 1440 900
take_screenshot 2560 1600
take_screenshot 2880 1800

echo "✨ All screenshots have been generated in the screenshots directory!"
echo "🔍 Please verify the screenshots in the screenshots directory before submitting to the App Store." 