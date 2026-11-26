#!/bin/bash
R=/root/micode-star
ls $R/drivers 2>/dev/null | head -20
echo "--- spi ---"
ls $R/drivers/spi 2>/dev/null | head -10
echo "--- tty/serial ---"
ls $R/drivers/tty/serial 2>/dev/null | head
echo "--- input ---"
ls $R/drivers/input 2>/dev/null | head
</>
