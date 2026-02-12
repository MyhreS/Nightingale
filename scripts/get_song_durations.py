#!/usr/bin/env python3

import os
import subprocess


def get_mp3_duration_ms(filepath):
    try:
        result = subprocess.run(
            [
                "ffprobe",
                "-v",
                "error",
                "-show_entries",
                "format=duration",
                "-of",
                "default=noprint_wrappers=1:nokey=1",
                filepath,
            ],
            capture_output=True,
            text=True,
        )
        output = result.stdout.strip()
        if not output or output == "N/A":
            print(
                f"Warning: Could not read duration for {os.path.basename(filepath)} (file may be syncing from iCloud)"
            )
            return 0
        duration_seconds = float(output)
        return int(duration_seconds * 1000)
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return 0


def is_mp3_file(filename):
    return os.path.isfile(filename) and filename.lower().endswith(".mp3")


def scan_songs():
    results = []

    for filename in os.listdir():
        if not is_mp3_file(filename):
            continue
        duration = get_mp3_duration_ms(filename)

        results.append(
            {
                "id": filename,
                "duration_ms": duration,
                "duration_formatted": f"{duration // 60000}:{(duration % 60000) // 1000:02d}",
            }
        )

    return results


def main():
    results = scan_songs()
    print(results)


if __name__ == "__main__":
    main()
