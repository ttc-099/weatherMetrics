#!/bin/bash
# ----------------------------------------
# Master script to manage weather operations
# ----------------------------------------
# Usage:
#   ./weatherMetrics.sh scrape <location>   -> runs the scraper for a specific location
#   ./weatherMetrics.sh plot <location>     -> runs the plotter for a specific location
#   ./weatherMetrics.sh list                -> lists available locations
#   ./weatherMetrics.sh help                -> shows usage
# ----------------------------------------

# Function to run the scraper
run_scraper() {
    LOCATION="$1"
    if [ -z "$LOCATION" ]; then
        echo "[!] You must specify a location for scraping (e.g., kl)"
        exit 1
    fi

    echo "[*] Running weather scraper for $LOCATION..."
    if [ -f "./weather_scraperTrue.sh" ]; then
        bash ./weather_scraperTrue.sh "$LOCATION"
    else
        echo "[✗] Error: weather_scraperTrue.sh not found!"
        exit 1
    fi
}

# Function to run the plotter
run_plotter() {
    LOCATION="$1"
    if [ -z "$LOCATION" ]; then
        echo "[!] You must specify a location for plotting (e.g., kl)"
        exit 1
    fi

    echo "[*] Running weather plotter for $LOCATION..."
    if [ -f "./weather_plotterTrue.sh" ]; then
        bash ./weather_plotterTrue.sh "$LOCATION"
    else
        echo "[✗] Error: weather_plotterTrue.sh not found!"
        exit 1
    fi
}

# Show usage information
show_help() {
    echo "Usage: $0 <command> [location]"
    echo "Commands:"
    echo "  scrape <location>   - Fetch and store latest weather data for a location"
    echo "  plot <location>     - Generate weather plots from database for a location"
    echo "  list                - Show available locations"
    echo "  help                - Show this message"
}

# ----------------------------------------
# Main logic
# ----------------------------------------
if [ $# -eq 0 ]; then
    echo "[!] No command provided."
    show_help
    exit 1
fi

COMMAND="$1"
LOCATION="$2"

case "$COMMAND" in
    scrape)
        run_scraper "$LOCATION"
        ;;
    plot)
        run_plotter "$LOCATION"
        ;;
    list)
        echo "[*] Available locations for weather metrics:"
        echo "  - Kuala Lumpur (kl)"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "[!] Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
