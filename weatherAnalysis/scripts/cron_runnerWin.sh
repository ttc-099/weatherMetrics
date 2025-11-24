#!/bin/bash

# Simple version - run from your scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../data/logs/weather_cron.log"

echo "[+] Starting at $(date)" > "$LOG_FILE"

# Run scraper
if [ -f "$SCRIPT_DIR/weather_scraperTrue.sh" ]; then
    echo "[+] Running scraper..." >> "$LOG_FILE"
    bash "$SCRIPT_DIR/weather_scraperTrue.sh" >> "$LOG_FILE" 2>&1
else
    echo "[✗] Scraper not found" >> "$LOG_FILE"
fi

# Run plotter
if [ -f "$SCRIPT_DIR/weather_plotter.sh" ]; then
    echo "[+] Running plotter..." >> "$LOG_FILE"
    bash "$SCRIPT_DIR/weather_plotter.sh" >> "$LOG_FILE" 2>&1
else
    echo "[✗] Plotter not found" >> "$LOG_FILE"
fi

echo "[+] Finished at $(date)" >> "$LOG_FILE"
echo "Check log: $LOG_FILE"