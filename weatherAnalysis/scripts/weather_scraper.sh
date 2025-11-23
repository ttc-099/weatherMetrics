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

# ...

# -----------------------------------------
# MYSQL INSERTION (fixed)
# -----------------------------------------

MYSQL_USER="root"
MYSQL_PASS="NiNoFan28"       # set your password if needed
MYSQL_DB="weatherDB"

# Remove non-digit characters from numeric fields (strip °C if present)
CURRENT_TEMP=$(echo "$CURRENT_TEMP" | tr -dc '0-9')
FEELS_LIKE=$(echo "$FEELS_LIKE" | tr -dc '0-9')
FORECAST_HIGH=$(echo "$FORECAST_HIGH" | tr -dc '0-9')
FORECAST_LOW=$(echo "$FORECAST_LOW" | tr -dc '0-9')
HUMIDITY=$(echo "$HUMIDITY" | tr -dc '0-9')

# Remove comma and trailing period from time strings for date parsing
CLEAN_CURRENT_TIME=$(echo "$CURRENT_TIME" | tr -d ',' | tr -d '.')
CLEAN_LATEST_REPORT=$(echo "$LATEST_REPORT" | tr -d ',' | tr -d '.')

# Convert times to MySQL DATETIME format
CURR_TIME_SQL=$(date -d "$CLEAN_CURRENT_TIME" +"%Y-%m-%d %H:%M:%S")
LATEST_REPORT_SQL=$(date -d "$CLEAN_LATEST_REPORT" +"%Y-%m-%d %H:%M:%S")

# Build SQL query
INSERT_SQL="INSERT INTO weather_reports (
    location,
    observation_time,
    latest_report,
    current_temp,
    feels_like,
    forecast_high,
    forecast_low,
    humidity
) VALUES (
    '$LOCATION',
    '$CURR_TIME_SQL',
    '$LATEST_REPORT_SQL',
    $CURRENT_TEMP,
    $FEELS_LIKE,
    $FORECAST_HIGH,
    $FORECAST_LOW,
    $HUMIDITY
);"

# Execute insert and check for errors
if mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e "$INSERT_SQL"; then
    echo "[✓] Done! Weather data inserted successfully."
else
    echo "[✗] Failed to insert weather data."
fi
