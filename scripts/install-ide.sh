#!/bin/bash
# JetBrains IDE Installer Script (Professional/Ultimate Only)

export DISPLAY=:1

echo ""
echo "=========================================="
echo "   JetBrains IDE Installer"
echo "   (Professional/Ultimate Editions)"
echo "=========================================="
echo ""

# IDE options (Professional/Ultimate only)
OPTIONS=(
    "PyCharm Professional 2024"
    "WebStorm 2024"
    "CLion 2024"
    "GoLand 2024"
    "PhpStorm 2024"
    "DataGrip 2024"
    "Rider 2024"
    "RubyMine 2024"
    "Cancel"
)

# Download URLs (all Professional/Ultimate 2024)
declare -A URLS
URLS["PyCharm Professional 2024"]="https://download.jetbrains.com/python/pycharm-professional-2024.3.1.1.tar.gz"
URLS["WebStorm 2024"]="https://download.jetbrains.com/webstorm/WebStorm-2024.3.1.1.tar.gz"
URLS["CLion 2024"]="https://download.jetbrains.com/cpp/CLion-2024.3.1.1.tar.gz"
URLS["GoLand 2024"]="https://download.jetbrains.com/go/goland-2024.3.1.1.tar.gz"
URLS["PhpStorm 2024"]="https://download.jetbrains.com/webide/PhpStorm-2024.3.1.1.tar.gz"
URLS["DataGrip 2024"]="https://download.jetbrains.com/datagrip/datagrip-2024.3.4.tar.gz"
URLS["Rider 2024"]="https://download.jetbrains.com/rider/JetBrains.Rider-2024.3.2.tar.gz"
URLS["RubyMine 2024"]="https://download.jetbrains.com/ruby/RubyMine-2024.3.1.1.tar.gz"

# Install directories
declare -A DIRS
DIRS["PyCharm Professional 2024"]="pycharm"
DIRS["WebStorm 2024"]="webstorm"
DIRS["CLion 2024"]="clion"
DIRS["GoLand 2024"]="goland"
DIRS["PhpStorm 2024"]="phpstorm"
DIRS["DataGrip 2024"]="datagrip"
DIRS["Rider 2024"]="rider"
DIRS["RubyMine 2024"]="rubymine"

# Script names
declare -A SCRIPTS
SCRIPTS["PyCharm Professional 2024"]="pycharm.sh"
SCRIPTS["WebStorm 2024"]="webstorm.sh"
SCRIPTS["CLion 2024"]="clion.sh"
SCRIPTS["GoLand 2024"]="goland.sh"
SCRIPTS["PhpStorm 2024"]="phpstorm.sh"
SCRIPTS["DataGrip 2024"]="datagrip.sh"
SCRIPTS["Rider 2024"]="rider.sh"
SCRIPTS["RubyMine 2024"]="rubymine.sh"

# Show selection dialog
CHOICE=$(zenity --list --title="Install JetBrains IDE" \
    --column="IDE" "${OPTIONS[@]}" \
    --width=400 --height=400 2>/dev/null)

if [ -z "$CHOICE" ] || [ "$CHOICE" = "Cancel" ]; then
    echo "Installation cancelled."
    exit 0
fi

URL="${URLS[$CHOICE]}"
DIR="${DIRS[$CHOICE]}"
SCRIPT="${SCRIPTS[$CHOICE]}"
INSTALL_PATH="/opt/${DIR}"

echo "Installing: $CHOICE"
echo "URL: $URL"
echo "Path: $INSTALL_PATH"
echo ""

# Check if already installed
if [ -d "$INSTALL_PATH" ]; then
    zenity --question --title="Already Installed" \
        --text="$CHOICE is already installed.\nDo you want to reinstall?" \
        --width=300 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Installation cancelled."
        exit 0
    fi
    sudo rm -rf "$INSTALL_PATH"
fi

# Download and install
echo "Downloading $CHOICE..."
(
    cd /tmp
    wget -q --show-progress "$URL" -O ide.tar.gz 2>&1 | \
    while read line; do
        echo "# Downloading... $line"
    done
    echo "# Extracting..."
    sudo mkdir -p "$INSTALL_PATH"
    sudo tar -xzf ide.tar.gz -C "$INSTALL_PATH" --strip-components=1
    sudo chmod +x "$INSTALL_PATH/bin/"*.sh
    rm ide.tar.gz
    echo "# Done!"
) | zenity --progress --title="Installing $CHOICE" \
    --text="Downloading..." --pulsate --auto-close --width=400 2>/dev/null

# Configure activation (same as IDEA)
JETBRA_DIR="/opt/jetbra"
VMOPTIONS_FILE="$INSTALL_PATH/bin/${SCRIPT%.sh}64.vmoptions"

if [ -f "$VMOPTIONS_FILE" ]; then
    echo "" | sudo tee -a "$VMOPTIONS_FILE" > /dev/null
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED" | sudo tee -a "$VMOPTIONS_FILE" > /dev/null
    echo "--add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED" | sudo tee -a "$VMOPTIONS_FILE" > /dev/null
    echo "-javaagent:${JETBRA_DIR}/active-agt.jar" | sudo tee -a "$VMOPTIONS_FILE" > /dev/null
    echo "[OK] Configured activation for $CHOICE"
fi

# Create desktop shortcut
DESKTOP_FILE="/home/developer/Desktop/${DIR}.desktop"
ICON_FILE="$INSTALL_PATH/bin/${SCRIPT%.sh}.png"

cat > /tmp/ide.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$CHOICE
Icon=$ICON_FILE
Exec=$INSTALL_PATH/bin/$SCRIPT
Terminal=false
Categories=Development;IDE;
EOF

cp /tmp/ide.desktop "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"
chown developer:developer "$DESKTOP_FILE"

echo ""
echo "=========================================="
echo "   Installation Complete!"
echo "=========================================="
echo ""
echo "$CHOICE has been installed to $INSTALL_PATH"
echo "Desktop shortcut created."
echo ""
echo "To activate, run the Activate script first,"
echo "then start the IDE and enter the activation code."
echo ""

zenity --info --title="Installation Complete" \
    --text="$CHOICE installed successfully!\n\nDesktop shortcut created.\n\nRemember to activate using the Activate script." \
    --width=350 2>/dev/null

read -p "Press Enter to close..."
