#!/usr/bin/env python3
import csv
import glob
import os
import sys

def generate_songs_csv(output_file="all_songs.csv"):
    # Find all files ending in *song.md in the current directory AND subdirectories
    song_files = glob.glob("**/*song.md", recursive=True)
    
    if not song_files:
        print("No *song.md files found.")
        return

    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        # Header
        writer.writerow(["title", "lyrics", "tags", "instrumental", "model"])
        
        for file in song_files:
            with open(file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Row format: <blank>, <contents>, <blank>, <false>, chirp-fenix
            writer.writerow(["", content, "", "false", "chirp-fenix"])

    print(f"Successfully generated {output_file} with {len(song_files)} songs.")

if __name__ == "__main__":
    generate_songs_csv()
