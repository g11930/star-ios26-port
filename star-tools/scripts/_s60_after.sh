#!/bin/bash
# s60: what happens after boot tasks (line 1400+ of launchd log)
awk 'NR>=1400' /tmp/s60.txt | grep -E 'launchd\||EXECDBG|P28EXIT|say ' | head -50
