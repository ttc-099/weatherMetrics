#!/bin/bash

# -----------------------------------------
# CONFIG
# -----------------------------------------
MYSQL_USER="root"
MYSQL_PASS="NiNoFan28"
MYSQL_DB="weatherDB"

# Use the updated folder name (no spaces)
PLOTS_DIR="../plots"
DATA_FILE="$PLOTS_DIR/weather_data.dat"
OUTPUT_FILE="$PLOTS_DIR/weather_plot.png"
mkdir -p "$PLOTS_DIR"

# -----------------------------------------
# FETCH DATA FROM MYSQL
# -----------------------------------------
echo "[+] Fetching weather data from MySQL..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT o.observation_time, o.current_temp, f.high_temp, f.low_temp
 FROM observations o
 JOIN forecasts f ON o.scrape_id = f.scrape_id
 ORDER BY o.observation_time ASC;" > "$DATA_FILE"

# Check if data exists
if [ ! -s "$DATA_FILE" ]; then
    echo "[✗] No data found. Cannot generate plot."
    exit 1
fi

# Optional: remove any Windows line endings
sed -i 's/\r//' "$DATA_FILE"

# -----------------------------------------
# GENERATE PLOT WITH GNUPLOT (Dark Mode)
# -----------------------------------------
echo "[+] Generating weather plot..."
gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,12'
set output "$OUTPUT_FILE"

# Dark mode background
set object 1 rect from screen 0,0 to screen 1,1 fillcolor rgb "#000000" behind

# Titles, labels, and tics in white
set title "Weather in Kuala Lumpur" textcolor rgb "white"
set xlabel "Observation Time" textcolor rgb "white"
set ylabel "Temperature (°C)" textcolor rgb "white"
set key left top textcolor rgb "white"
set tics textcolor rgb "white"

# Grid in subtle gray
set grid lc rgb "#555555" lt 1

# X-axis as time
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%d-%m\n%H:%M"

# Plot lines (colors unchanged)
plot "$DATA_FILE" using 1:2 with linespoints lt rgb "blue" lw 2 title "Current Temp", \
     "$DATA_FILE" using 1:3 with lines lt rgb "red" lw 2 title "Forecast High", \
     "$DATA_FILE" using 1:4 with lines lt rgb "green" lw 2 title "Forecast Low"
EOF


# -----------------------------------------
# FINISH
# -----------------------------------------
if [ -f "$OUTPUT_FILE" ]; then
    echo "[✓] Weather plot generated: $OUTPUT_FILE"
else
    echo "[✗] Failed to generate weather plot."
fi
