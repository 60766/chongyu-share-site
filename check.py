#!/usr/bin/env python3
import json
try:
    with open("/Users/lishilong/IOS开发/虫遇/虫遇/虫遇/Resources/characters.json", "r") as f:
        json.load(f)
        print("JSON valid")
except json.JSONDecodeError as e:
    print(f"Error: {e}")
