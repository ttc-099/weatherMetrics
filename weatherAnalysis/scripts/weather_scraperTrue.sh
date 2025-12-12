#!/bin/bash

# --- CONFIGURATION / ENVIRONMENT VARIABLE READING ---
if [ -f ../../.env ]; then
    echo "[*] Sourcing environment variables from the project root (../../.env)"
    set -a
    source ../../.env
    set +a
fi

MYSQL_HOST="${DB_HOST:-127.0.0.1}"
MYSQL_USER="${DB_USER:-root}"
MYSQL_DB="${DB_NAME:-weatherDB}"

if [ -z "$DB_PASSWORD" ]; then
    echo "[!] ERROR: DB_PASSWORD environment variable is not set." >&2
    exit 1
fi
MYSQL_PASS="$DB_PASSWORD"

# --- SECURE MYSQL CONFIG ---
MY_CNF_FILE=$(mktemp)

cleanup() {
    [ -f "$MY_CNF_FILE" ] && rm -f "$MY_CNF_FILE" && echo "[✓] Temporary MySQL config deleted."
}
trap cleanup EXIT INT TERM

cat > "$MY_CNF_FILE" << EOF
[client]
host=$MYSQL_HOST
user=$MYSQL_USER
password=$MYSQL_PASS
database=$MYSQL_DB
EOF
chmod 600 "$MY_CNF_FILE"

# --- FORCE SCRIPT DIRECTORY ---
cd "$(dirname "$0")" || exit 1

# --- CONFIG / URL / OUTPUT ---
URL="https://www.timeanddate.com/weather/malaysia/kuala-lumpur"
OUTPUT="../data/raw_html/weather_kualalumpur.html"

# --- ERROR HANDLING: FETCH HTML ---
MAX_RETRIES=3
for i in $(seq 1 $MAX_RETRIES); do
    curl -s -A "Mozilla/5.0" "$URL" -o "$OUTPUT" && break
    echo "[!] Retry $i/$MAX_RETRIES..."
    sleep 2
done

if [ ! -s "$OUTPUT" ]; then
    echo "[✗] Failed to fetch HTML or file is empty."
    exit 1
fi

unset LC_ALL
unset LANG
HTML="$OUTPUT"

echo "[+] Extracting weather data..."

# --- DATA PARSING ---
LOCATION=$(grep -oP '(?<=<th>Location: </th><td>).*?(?=</td>)' "$HTML")
LOCATION=${LOCATION:-Unknown}

CURRENT_TIME=$(grep -oP '(?<=<th>Current Time: </th><td id=wtct>).*?(?=</td>)' "$HTML")
CURRENT_TIME=${CURRENT_TIME:-"1970-01-01 00:00"}

LATEST_REPORT=$(grep -oP '(?<=<th>Latest Report: </th><td>).*?(?=</td>)' "$HTML")
LATEST_REPORT=${LATEST_REPORT:-"1970-01-01 00:00"}

CURRENT_TEMP=$(grep -oP '(?<=<div class=h2>).+?(?=</div>)' "$HTML" | sed 's/&nbsp;//' | sed 's/°C/ °C/')
CURRENT_TEMP=${CURRENT_TEMP:-0}

FEELS_LIKE=$(grep -oP 'Feels Like:\s*\K[0-9]+(?=&nbsp;°C)' "$HTML")
FEELS_LIKE=${FEELS_LIKE:-0}

FORECAST=$(grep -oP 'Forecast:\s*\K[0-9]+ / [0-9]+' "$HTML")
FORECAST_ARRAY=($(echo "$FORECAST" | tr -d ' ' | tr '/' ' '))
FORECAST_HIGH=${FORECAST_ARRAY[0]:-0}
FORECAST_LOW=${FORECAST_ARRAY[1]:-0}

HUMIDITY=$(grep -oP '(?<=<th>Humidity: </th><td>)[0-9]+(?=%)' "$HTML")
HUMIDITY=${HUMIDITY:-0}

STATE=$(grep -oP '(?<=&amp;state=)[^&]+' "$HTML" | sed 's/%20/ /g')
STATE=${STATE:-Unknown}

COUNTRY=$(grep -oP '(?<=&amp;country=)[^&]+' "$HTML" | sed 's/%20/ /g')
COUNTRY=${COUNTRY:-Unknown}

# --- DATA MANIPULATION ---
# Clean numeric values
for var in CURRENT_TEMP FEELS_LIKE FORECAST_HIGH FORECAST_LOW HUMIDITY; do
    eval "$var=\$(echo \${$var} | tr -dc '0-9')"
    eval "$var=\${$var:-0}"
done

# Clean and convert dates
CLEAN_CURRENT_TIME=$(echo "$CURRENT_TIME" | sed 's/,//g; s/\.$//; s/Mac/Mar/g; s/Mei/May/g; s/Ogos/Aug/g; s/Okt/Oct/g; s/Dis/Dec/g')
CLEAN_LATEST_REPORT=$(echo "$LATEST_REPORT" | sed 's/,//g; s/\.$//; s/Mac/Mar/g; s/Mei/May/g; s/Ogos/Aug/g; s/Okt/Oct/g; s/Dis/Dec/g')

CURR_TIME_SQL=$(LC_ALL=en_US.UTF-8 date -d "$CLEAN_CURRENT_TIME" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date +"%Y-%m-%d %H:%M:%S")
LATEST_REPORT_SQL=$(LC_ALL=en_US.UTF-8 date -d "$CLEAN_LATEST_REPORT" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date +"%Y-%m-%d %H:%M:%S")

# --- OUTPUT DEBUG ---
echo "--- WEATHER DATA ---"
echo "Location:           $LOCATION"
echo "State:              $STATE"
echo "Country:            $COUNTRY"
echo "Current Time:       $CURRENT_TIME"
echo "Latest Report:      $LATEST_REPORT"
echo "Current Temp:       $CURRENT_TEMP"
echo "Feels Like:         $FEELS_LIKE"
echo "Forecast High:      $FORECAST_HIGH"
echo "Forecast Low:       $FORECAST_LOW"
echo "Humidity:           $HUMIDITY%"

# --- DATABASE INSERTION WITH ERROR CHECK ---
MYSQL_EXIT_CODE=0
mysql --defaults-file="$MY_CNF_FILE" <<EOF || MYSQL_EXIT_CODE=$?
START TRANSACTION;

INSERT INTO locations (name, state, country)
SELECT '$LOCATION', '$STATE', '$COUNTRY'
WHERE NOT EXISTS (SELECT 1 FROM locations WHERE name='$LOCATION');

SET @loc_id = (SELECT location_id FROM locations WHERE name='$LOCATION');

INSERT INTO scrape_logs (location_id, scraped_at, status)
VALUES (@loc_id, NOW(), 'SUCCESS');

SET @scrape_id = LAST_INSERT_ID();

INSERT INTO observations (
    location_id, scrape_id, observation_time, current_temp, feels_like, humidity, created_at
) VALUES (
    @loc_id, @scrape_id, '$CURR_TIME_SQL', $CURRENT_TEMP, $FEELS_LIKE, $HUMIDITY, NOW()
);

INSERT INTO forecasts (
    location_id, scrape_id, high_temp, low_temp
) VALUES (
    @loc_id, @scrape_id, $FORECAST_HIGH, $FORECAST_LOW
);

COMMIT;
EOF

if [ $MYSQL_EXIT_CODE -eq 0 ]; then
    echo "[✓] Weather data inserted successfully."
else
    echo "[✗] Database insert failed with exit code $MYSQL_EXIT_CODE."
fi
