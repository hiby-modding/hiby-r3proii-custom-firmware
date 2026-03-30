adb wait-for-device
adb shell rm /usr/resource/litegui/boot_animation/en/0.png
adb push 0.png /usr/resource/litegui/boot_animation/en/0.png
pause
adb shell reboot