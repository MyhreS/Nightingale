#!/usr/bin/env python3
import os
import json
import subprocess

SONGS_ROOT = os.path.expanduser("~/Library/Mobile Documents/com~apple~CloudDocs/Hockey music")

FOLDER_TO_GROUP = {
    "Break": "break",
    "Crowd": "crowd",
    "Face-Offs": "faceoff",
    "Goal": "goal",
    "Intro": "intro",
    "Penalty Box": "penalty",
    "Victory": "victory",
    "Warm-Ups": "warmup",
}

def get_mp3_duration_ms(filepath):
    try:
        result = subprocess.run(
            [
                "ffprobe",
                "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                filepath
            ],
            capture_output=True,
            text=True
        )
        output = result.stdout.strip()
        if not output or output == "N/A":
            print(f"Warning: Could not read duration for {os.path.basename(filepath)} (file may be syncing from iCloud)")
            return 0
        duration_seconds = float(output)
        return int(duration_seconds * 1000)
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return 0

def scan_songs(root_path):
    results = []
    
    for folder_name in os.listdir(root_path):
        folder_path = os.path.join(root_path, folder_name)
        if not os.path.isdir(folder_path):
            continue
            
        group = FOLDER_TO_GROUP.get(folder_name, folder_name.lower())
        
        for filename in os.listdir(folder_path):
            if not filename.endswith(".mp3"):
                continue
                
            filepath = os.path.join(folder_path, filename)
            duration = get_mp3_duration_ms(filepath)
            
            results.append({
                "id": filename,
                "group": group,
                "duration_ms": duration,
                "duration_formatted": f"{duration // 60000}:{(duration % 60000) // 1000:02d}"
            })
    
    return results

def main():
    if not os.path.exists(SONGS_ROOT):
        print(f"Songs folder not found at: {SONGS_ROOT}")
        return
    
    print(f"Scanning: {SONGS_ROOT}\n")
    results = scan_songs(SONGS_ROOT)
    
    results.sort(key=lambda x: (x["group"], x["id"]))
    
    print(f"{'ID':<70} {'Group':<10} {'Duration':<10} {'MS':<10}")
    print("-" * 100)
    
    for song in results:
        print(f"{song['id']:<70} {song['group']:<10} {song['duration_formatted']:<10} {song['duration_ms']:<10}")
    
    print(f"\nTotal songs: {len(results)}")
    
    print("\n\n--- JSON duration map (id -> duration_ms) ---\n")
    duration_map = {song["id"]: song["duration_ms"] for song in results}
    print(json.dumps(duration_map, indent=2))

if __name__ == "__main__":
    main()
