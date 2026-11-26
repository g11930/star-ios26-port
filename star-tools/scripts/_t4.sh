#!/bin/bash
grep -v '^[+-] \*\|^[+-] \*\|^ [0-9]' /tmp/touch.diff | grep -v 'printf\|goodix_trace' | grep '^[+-]' | head -80