#!/bin/bash

# -----------------------------------------
# FORCE SCRIPT TO RUN FROM ITS OWN DIRECTORY
# -----------------------------------------
cd "$(dirname "$0")" || exit 1

# -----------------------------------------
# CONFIG / URL
# -----------------------------------------
URL="https://www.timeanddate.com/weather/malaysia/kuala-lumpur"
OUTPUT="../data/raw_html/weather_kualalumpur.html"

echo "[+] Fetching HTML..."
curl -s -A "Mozilla/5.0" "$URL" -o "$OUTPUT"

# -----------------------------------------
# PARSING FUNCTIONS
# -----------------------------------------
unset LC_ALL
unset LANG

HTML="$OUTPUT"

echo "[+] Extracting weather data..."

# Location
LOCATION=$(grep -oP '(?<=<th>Location: </th><td>).*?(?=</td>)' "$HTML")

# Current time
CURRENT_TIME=$(grep -oP '(?<=<th>Current Time: </th><td id=wtct>).*?(?=</td>)' "$HTML")

# Latest report
LATEST_REPORT=$(grep -oP '(?<=<th>Latest Report: </th><td>).*?(?=</td>)' "$HTML")

# Current temperature
CURRENT_TEMP=$(grep -oP '(?<=<div class=h2>).+?(?=</div>)' "$HTML" | sed 's/&nbsp;//' | sed 's/°C/ °C/')

# Feels like temperature
FEELS_LIKE=$(grep -oP 'Feels Like:\s*\K[0-9]+(?=&nbsp;°C)' "$HTML")

# Forecast high/low
FORECAST=$(grep -oP 'Forecast:\s*\K[0-9]+ / [0-9]+' "$HTML")
FORECAST_HIGH=$(echo "$FORECAST" | awk '{print $1}')
FORECAST_LOW=$(echo "$FORECAST" | awk '{print $3}')

# Humidity
HUMIDITY=$(grep -oP '(?<=<th>Humidity: </th><td>)[0-9]+(?=%)' "$HTML")
HUMIDITY="${HUMIDITY%</td>}"   # remove </td>

# State and country from og:image meta
STATE=$(grep -oP '(?<=&amp;state=)[^&]+' "$HTML" | sed 's/%20/ /g')
COUNTRY=$(grep -oP '(?<=&amp;country=)[^&]+' "$HTML" | sed 's/%20/ /g')

# -----------------------------------------
# OUTPUT
# -----------------------------------------
echo "--- WEATHER DATA ---"
echo "Location:           $LOCATION"
echo "State:              $STATE"
echo "Country:            $COUNTRY"
echo "Current Time:       $CURRENT_TIME"
echo "Latest Report:      $LATEST_REPORT"
echo "Current Temp:       $CURRENT_TEMP"
echo "Feels Like:         $FEELS_LIKE °C"
echo "Forecast High:      $FORECAST_HIGH °C"
echo "Forecast Low:       $FORECAST_LOW °C"
echo "Humidity:           ${HUMIDITY}%"

# -----------------------------------------
# MYSQL INSERTION 
# -----------------------------------------
MYSQL_USER="root"
MYSQL_PASS="NiNoFan28"
MYSQL_DB="weatherDB"

# Clean numeric fields
CURRENT_TEMP=$(echo "$CURRENT_TEMP" | tr -dc '0-9')
FEELS_LIKE=$(echo "$FEELS_LIKE" | tr -dc '0-9')
FORECAST_HIGH=$(echo "$FORECAST_HIGH" | tr -dc '0-9')
FORECAST_LOW=$(echo "$FORECAST_LOW" | tr -dc '0-9')
HUMIDITY=$(echo "$HUMIDITY" | tr -dc '0-9')

# Clean times
CLEAN_CURRENT_TIME_FIXED=$(echo "$CLEAN_CURRENT_TIME" \
    | sed 's/Jan/Jan/g; s/Feb/Feb/g; s/Mar/Mar/g; s/Mac/Mar/g; s/Apr/Apr/g; s/Mei/May/g; s/Jun/Jun/g; s/Jul/Jul/g; s/Ogos/Aug/g; s/Sep/Sep/g; s/Okt/Oct/g; s/Nov/Nov/g; s/Dis/Dec/g')

CLEAN_LATEST_REPORT_FIXED=$(echo "$CLEAN_LATEST_REPORT" \
    | sed 's/Jan/Jan/g; s/Feb/Feb/g; s/Mar/Mar/g; s/Mac/Mar/g; s/Apr/Apr/g; s/Mei/May/g; s/Jun/Jun/g; s/Jul/Jul/g; s/Ogos/Aug/g; s/Sep/Sep/g; s/Okt/Oct/g; s/Nov/Nov/g; s/Dis/Dec/g')

# Convert to MySQL datetime using English locale
CURR_TIME_SQL=$(LC_ALL=en_US.UTF-8 date -d "$CLEAN_CURRENT_TIME_FIXED" +"%Y-%m-%d %H:%M:%S")
LATEST_REPORT_SQL=$(LC_ALL=en_US.UTF-8 date -d "$CLEAN_LATEST_REPORT_FIXED" +"%Y-%m-%d %H:%M:%S")

# Execute SQL statements in a transaction for safety using TCP to connect to Windows MySQL
mysql -h 127.0.0.1 -P 3306 -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" <<EOF
START TRANSACTION;

-- Insert location if not exists
INSERT INTO locations (name, state, country)
SELECT '$LOCATION', '$STATE', '$COUNTRY'
WHERE NOT EXISTS (
    SELECT 1 FROM locations WHERE name='$LOCATION'
);

-- Get location_id
SET @loc_id = (SELECT location_id FROM locations WHERE name='$LOCATION');

-- Insert scrape log
INSERT INTO scrape_logs (location_id, scraped_at, status)
VALUES (@loc_id, NOW(), 'SUCCESS');

-- Get scrape_id
SET @scrape_id = LAST_INSERT_ID();

-- Insert observation
INSERT INTO observations (
    location_id, scrape_id, observation_time, current_temp, feels_like, humidity, created_at
) VALUES (
    @loc_id, @scrape_id, '$CURR_TIME_SQL', $CURRENT_TEMP, $FEELS_LIKE, $HUMIDITY, NOW()
);

-- Insert forecast
INSERT INTO forecasts (
    location_id, scrape_id, high_temp, low_temp
) VALUES (
    @loc_id, @scrape_id, $FORECAST_HIGH, $FORECAST_LOW
);

COMMIT;
EOF

if [ $? -eq 0 ]; then
    echo "[✓] Done! Weather data inserted into tables successfully."
else
    echo "[✗] Failed to insert weather data."
fi
