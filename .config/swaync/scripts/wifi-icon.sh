#!/bin/bash

if nmcli radio wifi | grep -q enabled; then
    echo "󰤨"
else
    echo "󰤭"
fi
