#!/bin/bash

file="虫遇/Views/Home/HomeView.swift"
open_braces=$(grep -o "{" "$file" | wc -l)
close_braces=$(grep -o "}" "$file" | wc -l)

echo "Open braces: $open_braces"
echo "Close braces: $close_braces"

if [ "$open_braces" -eq "$close_braces" ]; then
  echo "Braces are balanced!"
else
  echo "Braces are NOT balanced!"
fi
