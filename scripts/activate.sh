#!/bin/bash
# JetBrains IDE Activation Script (Linux)
# Detects installed IDEs and activates the selected one

export DISPLAY=:1
JETBRA_DIR="/opt/jetbra"
USER_HOME="/home/developer"
CONFIG_BASE="${USER_HOME}/.config/JetBrains"

echo ""
echo "=========================================="
echo "   JetBrains IDE Activation Tool"
echo "=========================================="
echo ""

# Verify activation files
if [ ! -f "${JETBRA_DIR}/active-agt.jar" ]; then
    echo "[ERROR] active-agt.jar not found!"
    exit 1
fi

echo "[OK] active-agt.jar: ${JETBRA_DIR}/active-agt.jar"
echo ""

# Detect installed IDEs
declare -A INSTALLED_IDES
declare -A IDE_KEYS
declare -A IDE_VMOPTIONS

# Check each IDE (name, path, key_file, vmoptions)
check_ide() {
    local name=$1
    local path=$2
    local key_file=$3
    local vmoptions=$4
    
    if [ -d "$path" ]; then
        INSTALLED_IDES["$name"]="$path"
        IDE_KEYS["$name"]="${JETBRA_DIR}/${key_file}"
        IDE_VMOPTIONS["$name"]="$vmoptions"
        echo "[Found] $name: $path"
    fi
}

# Each IDE has its own activation key!
check_ide "IntelliJ IDEA" "/opt/idea" "idea.key" "/opt/idea/bin/idea64.vmoptions"
check_ide "PyCharm" "/opt/pycharm" "pycharm.key" "/opt/pycharm/bin/pycharm64.vmoptions"
check_ide "WebStorm" "/opt/webstorm" "webstorm.key" "/opt/webstorm/bin/webstorm64.vmoptions"
check_ide "CLion" "/opt/clion" "clion.key" "/opt/clion/bin/clion64.vmoptions"
check_ide "GoLand" "/opt/goland" "goland.key" "/opt/goland/bin/goland64.vmoptions"
check_ide "PhpStorm" "/opt/phpstorm" "phpstorm.key" "/opt/phpstorm/bin/phpstorm64.vmoptions"
check_ide "DataGrip" "/opt/datagrip" "datagrip.key" "/opt/datagrip/bin/datagrip64.vmoptions"
check_ide "Rider" "/opt/rider" "rider.key" "/opt/rider/bin/rider64.vmoptions"
check_ide "RubyMine" "/opt/rubymine" "rider.key" "/opt/rubymine/bin/rubymine64.vmoptions"

echo ""

# Check if any IDE is installed
if [ ${#INSTALLED_IDES[@]} -eq 0 ]; then
    zenity --error --title="No IDE Found" \
        --text="No JetBrains IDE installed.\n\nPlease install an IDE first using 'Install Other IDE'." \
        --width=350 2>/dev/null
    exit 1
fi

# Build selection list
OPTIONS=()
for ide in "${!INSTALLED_IDES[@]}"; do
    OPTIONS+=("$ide")
done
OPTIONS+=("Activate All")

# Show selection dialog
CHOICE=$(zenity --list --title="Select IDE to Activate" \
    --column="IDE" "${OPTIONS[@]}" \
    --width=400 --height=350 \
    --text="Select the IDE you want to activate:" 2>/dev/null)

if [ -z "$CHOICE" ]; then
    echo "Cancelled."
    exit 0
fi

# Function to activate an IDE
activate_ide() {
    local name=$1
    local path="${INSTALLED_IDES[$name]}"
    local key_file="${IDE_KEYS[$name]}"
    local vmoptions="${IDE_VMOPTIONS[$name]}"
    
    echo ""
    echo "Activating: $name"
    echo "Path: $path"
    echo "Key: $key_file"
    
    # Check if javaagent already configured
    if grep -q "active-agt.jar" "$vmoptions" 2>/dev/null; then
        echo "[OK] javaagent already configured"
    else
        echo "" | sudo tee -a "$vmoptions" > /dev/null
        echo "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" | sudo tee -a "$vmoptions" > /dev/null
        echo "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" | sudo tee -a "$vmoptions" > /dev/null
        echo "-javaagent:${JETBRA_DIR}/active-agt.jar" | sudo tee -a "$vmoptions" > /dev/null
        echo "[OK] Configured javaagent"
    fi
    
    # Copy the specific key for this IDE to clipboard
    if [ -f "$key_file" ]; then
        if command -v xclip &> /dev/null; then
            cat "$key_file" | xclip -selection clipboard 2>/dev/null
            echo "[OK] Activation code copied to clipboard"
        fi
        # Store the key file for later display
        LAST_KEY_FILE="$key_file"
    else
        echo "[WARN] Key file not found: $key_file"
    fi
    
    echo "[OK] $name activation configured!"
}

# Initialize last key file
LAST_KEY_FILE="${JETBRA_DIR}/idea.key"

# Activate selected IDE(s)
if [ "$CHOICE" = "Activate All" ]; then
    for ide in "${!INSTALLED_IDES[@]}"; do
        activate_ide "$ide"
    done
    # For "Activate All", show message about multiple keys
    echo ""
    echo "=========================================="
    echo "   Activation Complete!"
    echo "=========================================="
    echo ""
    echo "Multiple IDEs configured."
    echo "Each IDE needs its own activation code."
    echo "Run this script again and select a specific IDE"
    echo "to get its activation code."
    echo ""
    zenity --info --title="Activation Complete" \
        --text="All IDEs configured!\n\nTo get activation codes:\nRun Activate IDE again and select a specific IDE." \
        --width=400 2>/dev/null
else
    activate_ide "$CHOICE"
    
    echo ""
    echo "=========================================="
    echo "   Activation Complete!"
    echo "=========================================="
    echo ""
    echo "Next Steps:"
    echo "1. Start $CHOICE"
    echo "2. Select 'Activation code' in dialog"
    echo "3. Press Ctrl+V to paste"
    echo "4. Click 'Activate'"
    echo ""
    
    # Show the specific activation code for selected IDE
    if [ -f "$LAST_KEY_FILE" ]; then
        zenity --text-info --title="$CHOICE Activation Code (Copied)" --width=600 --height=400 \
            --filename="$LAST_KEY_FILE" \
            --ok-label="Close" 2>/dev/null
    fi
fi

read -p "Press Enter to close..."
