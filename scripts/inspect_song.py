#!/usr/bin/env python3
"""
Diagnostic script to inspect a problematic MP3 file
"""
import os
import subprocess

FILE_PATH = os.path.expanduser(
    "~/Library/Mobile Documents/com~apple~CloudDocs/Hockey music/Intro/my_songs_know_what_you_did_in_the_dark_by_fall_out_boy.mp3"
)

def check_file_exists():
    print(f"File path: {FILE_PATH}")
    print(f"File exists: {os.path.exists(FILE_PATH)}")
    if os.path.exists(FILE_PATH):
        size = os.path.getsize(FILE_PATH)
        print(f"File size: {size:,} bytes ({size / 1024 / 1024:.2f} MB)")
        return True
    return False

def try_ffprobe():
    print("\n--- ffprobe ---")
    try:
        # Get full format info
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_format", FILE_PATH],
            capture_output=True,
            text=True
        )
        print("stdout:", result.stdout if result.stdout else "(empty)")
        print("stderr:", result.stderr if result.stderr else "(empty)")
    except Exception as e:
        print(f"Error: {e}")

def try_ffprobe_streams():
    print("\n--- ffprobe streams ---")
    try:
        result = subprocess.run(
            ["ffprobe", "-v", "error", "-show_streams", FILE_PATH],
            capture_output=True,
            text=True
        )
        print("stdout:", result.stdout if result.stdout else "(empty)")
        print("stderr:", result.stderr if result.stderr else "(empty)")
    except Exception as e:
        print(f"Error: {e}")

def try_afinfo():
    print("\n--- afinfo (macOS native) ---")
    try:
        result = subprocess.run(
            ["afinfo", FILE_PATH],
            capture_output=True,
            text=True
        )
        print("stdout:", result.stdout if result.stdout else "(empty)")
        print("stderr:", result.stderr if result.stderr else "(empty)")
    except Exception as e:
        print(f"Error: {e}")

def try_file_command():
    print("\n--- file command ---")
    try:
        result = subprocess.run(
            ["file", FILE_PATH],
            capture_output=True,
            text=True
        )
        print("stdout:", result.stdout if result.stdout else "(empty)")
    except Exception as e:
        print(f"Error: {e}")

def try_mdls():
    print("\n--- mdls (Spotlight metadata) ---")
    try:
        result = subprocess.run(
            ["mdls", "-name", "kMDItemDurationSeconds", FILE_PATH],
            capture_output=True,
            text=True
        )
        print("stdout:", result.stdout if result.stdout else "(empty)")
    except Exception as e:
        print(f"Error: {e}")

def main():
    print("=" * 60)
    print("MP3 File Inspection")
    print("=" * 60)
    
    if not check_file_exists():
        print("\nFile does not exist!")
        return
    
    try_file_command()
    try_afinfo()
    try_mdls()
    try_ffprobe()
    try_ffprobe_streams()

if __name__ == "__main__":
    main()

