#!/bin/bash

case "$1" in
    vulkan)
        vulkaninfo --summary 2>/dev/null
        ;;
    vaapi)
        vainfo 2>&1
        ;;
    glxinfo)
        glxinfo -B 2>/dev/null || echo "glxinfo not available"
        ;;
    eglinfo)
        eglinfo 2>/dev/null | head -50 || echo "eglinfo not available"
        ;;
    *)
        echo "Usage: $0 {vulkan|vaapi|glxinfo|eglinfo}"
        exit 1
        ;;
esac
