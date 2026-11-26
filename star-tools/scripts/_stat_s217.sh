#!/bin/bash
L=/mnt/d/ios26/s217-mid-073704.bin
printf "SpringBoard[33 lines: "; grep -a -c "SpringBoard\[33" "$L"
printf "PosterBoard lines:    "; grep -a -c "PosterBoard" "$L"
printf "render pipelines:     "; grep -a -c "render pipelines" "$L"
printf "pac traps (last):     "; grep -a "pac: traps=" "$L" | tail -1
printf "applog span first:    "; grep -a -oE "2025-[0-9-]+ [0-9:]+" "$L" | head -1
printf "applog span last:     "; grep -a -oE "2025-[0-9-]+ [0-9:]+" "$L" | tail -1
