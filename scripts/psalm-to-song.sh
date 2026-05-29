#!/usr/bin/env bash
set -euo pipefail

# psalm-to-song.sh — Convert a Bible chapter markdown file into song lyrics
# following the template format in ~/lyrics.md.
#
# Usage: psalm-to-song.sh <chapter.md>
# Output: writes to <chapter_basename>_song.md in the same directory

if [ $# -lt 1 ]; then
    echo "Usage: $0 <chapter.md>"
    echo "Example: $0 ~/git_repos/mdbible/by_chapter/19_Psalms/Chapter_01.md"
    exit 1
fi

INPUT="$1"
if [ ! -f "$INPUT" ]; then
    echo "Error: file not found: $INPUT"
    exit 1
fi

exec python3 -c "
import sys, os, re

INPUT = '$INPUT'

SONG_TEMPLATE = '''[Intro]

[Verse]
{verse1}

[pre-chorus]
{prechorus}

[Chorus]
{chorus}

[Verse]
{verse2}

[pre-chorus]
{prechorus}

[Chorus]
{chorus}

[Bridge | Stripped Back | Intimate]
{bridge}

[Chorus]
{chorus}

[outro]
{breakdown}
'''

SUPERSCRIPTIONS = [
    'To the choirmaster', 'A Psalm of', 'A Song', 'Of ',
    'For the ', 'for the ', 'A Maskil', 'A Mikhtam', 'A Miktam',
    'A Shiggaion', 'A prayer of', 'A Contemplation', 'A Psalm',
    'A Maschil', 'To the Chief Musician', 'with stringed instruments',
    'according to', 'upon', 'Selah',
]

def parse_chapter(filepath):
    with open(filepath, 'r') as f:
        text = f.read()
    verses = []
    heading = ''
    for line in text.split('\\n'):
        line = line.strip()
        if not line or line.startswith('# '):
            continue
        m = re.match(r'^(\\d+)\\.\\s+(.*)', line)
        if m:
            verses.append(m.group(2).strip())
    if verses:
        v1 = verses[0]
        hm = re.match(r'^(.*?)(?:To the choirmaster|A Psalm of|A Song|For the |Of |A Maskil|A Mikhtam)', v1)
        if hm:
            heading = hm.group(1).strip()
        else:
            hm = re.match(
                r'^(.*?)(?:\\bBlessed is|\\bGive ear|O Lord|Hear my|Praise |I will |My God|Why |How '
                r'|Save |Make |Have |The Lord |The LORD |I love|Out of|In the |The heavens|The earth'
                r'|The fool|The mighty|Vindicate|Contend|May the|Let the|Be pleased|It is good'
                r'|Shout |Sing |Ascribe|Great is|The king|God is|How long|Answer |Awake)',
                v1
            )
            if hm:
                heading = hm.group(1).strip()
        if not heading or len(heading) < 3:
            hm = re.match(r'^([^.;:!?]+)', v1)
            if hm:
                heading = hm.group(1).strip()
        if not heading or len(heading) < 3:
            words = v1.split()
            heading = ' '.join(words[:5])
        heading = re.sub(r'[.;,:!?\\s]+$', '', heading).strip()
    return heading, verses


def strip_superscriptions(text):
    text = text.strip()
    changed = True
    while changed:
        changed = False
        for sup in SUPERSCRIPTIONS:
            for prefix in ['', ': ', ':']:
                m = re.match(r'^' + re.escape(prefix) + re.escape(sup) + r'[^;.:]*[;.:]?\\s*', text, re.IGNORECASE)
                if m:
                    text = text[m.end():].strip()
                    changed = True
                    break
            if changed:
                break
    return text


def split_into_lines(text):
    \"\"\"Split verse text into short poetic lines.\"\"\"
    # First split at sentence breaks
    parts = re.split(r'[;.]\\s*', text)
    lines = []
    for part in parts:
        part = part.strip()
        if not part or len(part) < 4:
            continue
        if len(part) > 55:
            # Split at commas, but only if resulting parts are substantial
            sub = re.split(r',\\s*', part)
            combined = []
            i = 0
            while i < len(sub):
                s = sub[i].strip()
                if not s:
                    i += 1
                    continue
                # If fragment is tiny, merge with next element
                if len(s) < 12 and i + 1 < len(sub):
                    next_s = sub[i + 1].strip()
                    s = s + ', ' + next_s
                    i += 2
                    combined.append(s)
                else:
                    combined.append(s)
                    i += 1
            for s in combined:
                if len(s) > 3:
                    lines.append(s)
        else:
            lines.append(part)
    return lines


def get_all_lines(verses, heading):
    all_lines = []
    for i, v in enumerate(verses):
        text = v
        if i == 0 and heading:
            idx = text.find(heading)
            if idx >= 0:
                text = text[idx + len(heading):]
            text = strip_superscriptions(text)
        lines = split_into_lines(text)
        for ln in lines:
            ln = ln.strip()
            if not ln or len(ln) < 5:
                continue
            if ln[-1] not in '.,;:!?,':
                ln += ','
            all_lines.append(ln)
    return all_lines


def pick(pool, indices):
    return [pool[i % len(pool)] for i in indices] if pool else []


def fmt_sec(lines):
    out = []
    for i, ln in enumerate(lines):
        clean = ln.rstrip('.,;:!?, ')
        end = ','
        if i % 2 == 0:
            out.append(clean + end)
        else:
            out.append('    ' + clean + end)
    return '\\n'.join(out)


heading, verses = parse_chapter(INPUT)

if not verses:
    print('Error: no verses found', file=sys.stderr)
    sys.exit(1)

lines = get_all_lines(verses, heading)
n = len(lines)

if n < 12:
    print(f'Warning: only {n} lines generated, padding by cycling', file=sys.stderr)
    padded = []
    while len(padded) < 28:
        padded.extend(lines)
    lines = padded[:28]
    n = len(lines)

# Distribute: split into three roughly equal pools
third = max(n // 3, 4)
first  = lines[:third]
middle = lines[third:2*third] if 2*third < n else lines[third:]
last   = lines[2*third:] if 2*third < n else middle

# Verse 1: opening portion
v1 = pick(first, [0, 1, 2, 3])

# Verse 2: different — take lines from middle portion (shifted)
v2 = pick(middle, [0, 1, 2, 3])

# Pre-chorus: middle portion, shifted by 4
pc = pick(middle, [4, 5, 6, 7]) if len(middle) >= 8 else pick(middle, [0, 1, 2, 3])

# Chorus: use the FINAL lines of the psalm (the concluding/resolution)
# Prefer lines from the very end (last 4 lines) for emotional payoff
end_lines = lines[-4:] if n >= 4 else lines
c_key = end_lines[0].rstrip('.,;:!? ')
c_sec = pick(end_lines, [1])[0].rstrip('.,;:!? ') if len(end_lines) > 1 else c_key
chorus = f'{c_key},\\n    {c_sec},\\n{c_key},\\n    {heading}.'

# Bridge: last section, mid lines
br = pick(last, [0, 1, 2, 3])

# Breakdown: last section, shifted for variety
try:
    bd = pick(last, [4, 5, 6, 7])
except (IndexError, ZeroDivisionError):
    bd = pick(last, [0, 1, 2, 3])

song = SONG_TEMPLATE.format(
    verse1=fmt_sec(v1),
    verse2=fmt_sec(v2),
    prechorus=fmt_sec(pc),
    chorus=chorus,
    bridge=fmt_sec(br),
    breakdown=fmt_sec(bd)
)

base = os.path.splitext(os.path.basename(INPUT))[0]
outdir = os.path.dirname(os.path.abspath(INPUT))
outpath = os.path.join(outdir, f'{base}_song.md')

with open(outpath, 'w') as f:
    f.write(song)

print(f'Written to {outpath}')
"
