#!/bin/bash
# Check if using default password and prompt to change
# This runs on first login

MARKER_FILE="$HOME/.vnc/.password_changed"
DEFAULT_PASSWORD="idea123"

# Skip if already changed
if [ -f "$MARKER_FILE" ]; then
    exit 0
fi

export DISPLAY=:1
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8

# Wait for desktop to be fully ready
sleep 8

# Wait for zenity to be available
for i in {1..10}; do
    if command -v zenity &> /dev/null && xdpyinfo &> /dev/null; then
        break
    fi
    sleep 1
done

# Show prompt dialog
RESPONSE=$(zenity --question \
    --title="安全提示 / Security Notice" \
    --text="检测到您正在使用默认密码。\n是否现在修改 VNC 密码？\n\nDefault password detected.\nWould you like to change VNC password now?" \
    --ok-label="修改密码 / Change" \
    --cancel-label="稍后 / Later" \
    --width=400 2>/dev/null)

if [ $? -ne 0 ]; then
    # User chose "Later", create marker to not ask again this session
    exit 0
fi

# Password change loop
while true; do
    # Get new password
    NEW_PASS=$(zenity --entry \
        --title="修改 VNC 密码" \
        --text="请输入新密码 (至少6位):\nEnter new password (min 6 chars):" \
        --hide-text \
        --width=350 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$NEW_PASS" ]; then
        # User cancelled
        zenity --info --title="已取消" --text="密码未修改。\nPassword not changed." --width=250 2>/dev/null
        exit 0
    fi
    
    # Check minimum length
    if [ ${#NEW_PASS} -lt 6 ]; then
        zenity --error --title="错误" --text="密码至少需要6位！\nPassword must be at least 6 characters!" --width=300 2>/dev/null
        continue
    fi
    
    # Confirm password
    CONFIRM_PASS=$(zenity --entry \
        --title="确认密码" \
        --text="请再次输入新密码:\nConfirm new password:" \
        --hide-text \
        --width=350 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        # User cancelled
        zenity --info --title="已取消" --text="密码未修改。\nPassword not changed." --width=250 2>/dev/null
        exit 0
    fi
    
    # Check if passwords match
    if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
        zenity --error --title="错误" --text="两次输入的密码不一致！\nPasswords do not match!" --width=300 2>/dev/null
        continue
    fi
    
    # Change the password
    printf "$NEW_PASS\n$NEW_PASS\n" | vncpasswd $HOME/.vnc/passwd 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Mark as changed
        touch "$MARKER_FILE"
        zenity --info \
            --title="成功 / Success" \
            --text="VNC 密码已修改成功！\n下次连接时请使用新密码。\n\nVNC password changed successfully!\nUse new password on next connection." \
            --width=350 2>/dev/null
        break
    else
        zenity --error --title="错误" --text="密码修改失败，请重试。\nFailed to change password." --width=300 2>/dev/null
    fi
done
