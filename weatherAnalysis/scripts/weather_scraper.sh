#!/bin/bash

URL="https://www.timeanddate.com/weather/malaysia/kuala-lumpur"
OUTPUT="../data/raw_html/weather_kualalumpur.html"

echo "[+] Fetching HTML..."
curl -s -A "Mozilla/5.0" "$URL" -o "$OUTPUT"

# -----------------------------------------
# PARSING FUNCTIONS
# -----------------------------------------

HTML="$OUTPUT"

echo "[+] Extracting weather data..."

# Location
LOCATION=$(grep -oP '(?<=<th>Location: </th><td>).*?(?=</td>)' "$HTML")

# Current time
CURRENT_TIME=$(grep -oP '(?<=<th>Current Time: </th><td id=wtct>).*?(?=</td>)' "$HTML")

# Latest report
LATEST_REPORT=$(grep -oP '(?<=<th>Latest Report: </th><td>).*?(?=</td>)' "$HTML")

# Current temperature
CURRENT_TEMP=$(grep -oP '(?<=<div class=h2>).+?(?=</div>)' "$HTML" | sed 's/&nbsp;//')

# Feels like temperature
FEELS_LIKE=$(grep -oP 'Feels Like:\s*\K[0-9]+(?=&nbsp;°C)' "$HTML")

# Forecast high/low
FORECAST=$(grep -oP 'Forecast:\s*\K[0-9]+ / [0-9]+' "$HTML")
FORECAST_HIGH=$(echo "$FORECAST" | awk '{print $1}')
FORECAST_LOW=$(echo "$FORECAST" | awk '{print $3}')

# Humidity
HUMIDITY=$(grep -oP '(?<=<th>Humidity: </th><td>)[0-9]+(?=%)' "$HTML")
HUMIDITY="${HUMIDITY%</td>}"   # remove </td>

# -----------------------------------------
# OUTPUT
# -----------------------------------------

echo "--- WEATHER DATA ---"
echo "Location:           $LOCATION"
echo "Current Time:       $CURRENT_TIME"
echo "Latest Report:      $LATEST_REPORT"
echo "Current Temp:       $CURRENT_TEMP"
echo "Feels Like:         $FEELS_LIKE °C"
echo "Forecast High:      $FORECAST_HIGH °C"
echo "Forecast Low:       $FORECAST_LOW °C"
echo "Humidity:           ${HUMIDITY}%"
