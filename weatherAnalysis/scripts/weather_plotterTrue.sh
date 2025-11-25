#!/bin/bash

# ------------------------------
# CONFIG
# ------------------------------
MYSQL_USER="root"
MYSQL_PASS="NiNoFan28"
MYSQL_DB="weatherDB"
PLOTS_DIR="../plots"
DATA_DIR="../data/logs/plot-data-files"

mkdir -p "$PLOTS_DIR" "$DATA_DIR"

echo "[+] Generating 10 weather plots..."

# ------------------------------
# 1. CURRENT TEMP VS TIME
# ------------------------------
echo "  Generating Plot 1: Current Temp vs Time..."

mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT DATE_FORMAT(observation_time, '%Y-%m-%d %H:%i:%s') AS ts, current_temp \
 FROM observations \
 WHERE current_temp IS NOT NULL \
 ORDER BY observation_time;" > "$DATA_DIR/plot1_data.dat"

echo " Data sample:"
head -n 3 "$DATA_DIR/plot1_data.dat"

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/1-current-vs-time.png"
set title "Temperature Over Time"
set xlabel "Time"
set ylabel "Temperature (°C)"
set grid
set datafile separator "\t"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M\n%d-%m"
set xtics rotate by -45
plot "$DATA_DIR/plot1_data.dat" using 1:2 with linespoints lw 2 lt rgb "blue" pt 7 ps 1.0 title "Current Temperature"
EOF

# ------------------------------
# 2. CURRENT VS FEELS LIKE
# ------------------------------
echo "  Generating Plot 2: Current vs Feels Like..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT CONCAT(DATE(observation_time),' ',TIME(observation_time)) AS ts, current_temp, feels_like \
 FROM observations \
 WHERE current_temp IS NOT NULL AND feels_like IS NOT NULL \
 ORDER BY observation_time;" > "$DATA_DIR/plot2_data.dat"

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/2-current-vs-feels-like.png"
set title "Actual vs Feels Like Temperature"
set xlabel "Time"
set ylabel "Temperature (°C)"
set grid
set datafile separator "\t"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%d-%m\n%H:%M"
plot "$DATA_DIR/plot2_data.dat" using 1:2 with linespoints lw 2 lt rgb "blue" pt 7 ps 1.0 title "Actual Temp", \
"$DATA_DIR/plot2_data.dat" using 1:3 with linespoints lw 2 lt rgb "red" pt 5 ps 1.0 title "Feels Like"
EOF

# ------------------------------
# 3. HUMIDITY-TEMP MAP
# ------------------------------
echo "Generating Plot 3: Humidity & Temp Over Time..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT DATE_FORMAT(observation_time, '%Y-%m-%d %H:%i:%s') AS ts, current_temp, humidity \
FROM observations \
WHERE current_temp IS NOT NULL AND humidity IS NOT NULL \
ORDER BY observation_time;" > "$DATA_DIR/plot3_data.dat"

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/3-temp-humidity-over-time.png"
set title "Temperature and Humidity Over Time"
set xlabel "Time"
set ylabel "Temperature (°C)"
set y2label "Humidity (%)"
set ytics
set y2tics
set grid
set datafile separator "\t"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M\n%d-%m"
set xtics rotate by -45
plot "$DATA_DIR/plot3_data.dat" using 1:2 with linespoints lw 2 lt rgb "blue" pt 7 ps 1.0 title "Temperature (Y1)", \
     "$DATA_DIR/plot3_data.dat" using 1:3 axes x1y2 with linespoints lw 2 lt rgb "red" pt 5 ps 1.0 title "Humidity (Y2)"
EOF

# ------------------------------
# 4. HUMIDITY VS TIME
# ------------------------------
echo "  Generating Plot 4: Humidity vs Time..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT CONCAT(DATE(observation_time),' ',TIME(observation_time)) AS ts, humidity \
 FROM observations \
 WHERE humidity IS NOT NULL \
 ORDER BY observation_time;" > "$DATA_DIR/plot4_data.dat"

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/4-humidity-vs-time.png"
set title "Humidity Over Time"
set xlabel "Time"
set ylabel "Humidity (%)"
set grid
set datafile separator "\t"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%d-%m\n%H:%M"
plot "$DATA_DIR/plot4_data.dat" using 1:2 with linespoints lw 2 lt rgb "green" pt 7 ps 1.0 title "Humidity"
EOF

# ------------------------------
# 5. TEMPERATURE HISTOGRAM
# ------------------------------
echo "  Generating Plot 5: Temperature Histogram..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT ROUND(current_temp) as temp, COUNT(*) as frequency \
 FROM observations \
 WHERE current_temp IS NOT NULL \
 GROUP BY temp \
 ORDER BY temp;" > "$DATA_DIR/plot5_data.dat"

gnuplot <<EOF
set terminal pngcairo size 800,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/5-temperature-histogram.png"
set title "Temperature Distribution"
set xlabel "Temperature (°C)"
set ylabel "Frequency"
set style data histograms
set style fill solid 0.8
set yrange [0:*]
plot "$DATA_DIR/plot5_data.dat" using 2:xtic(1) lt rgb "orange" title "Frequency"
EOF

# ------------------------------
# 6. SCRAPING SUCCESS
# ------------------------------
echo "  Generating Plot 6: Scraping Success..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT status, COUNT(*) as count \
 FROM scrape_logs \
 GROUP BY status;" > "$DATA_DIR/plot6_data.dat"

gnuplot <<EOF
set terminal pngcairo size 800,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/6-scraping-success.png"
set title "Scraping Status"
set xlabel "Status"
set ylabel "Count"
set style data histograms
set style fill solid 0.8
set boxwidth 0.8
set yrange [0:*]
plot "$DATA_DIR/plot6_data.dat" using 2:xtic(1) lt rgb "#FF6B6B" title "Count"
EOF

# ------------------------------
# 7. DAILY TEMP RANGE
# ------------------------------
echo "  Generating Plot 7: Daily Temp Range..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT DATE(observation_time) AS date, \
       MIN(current_temp), MAX(current_temp), AVG(current_temp) \
 FROM observations \
 WHERE current_temp IS NOT NULL \
 GROUP BY DATE(observation_time) \
 ORDER BY date;" > "$DATA_DIR/plot7_data.dat"

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/7-daily-temp-range.png"
set title "Daily Temperature Range"
set xlabel "Date"
set ylabel "Temperature (°C)"
set grid
set datafile separator "\t"
set xdata time
set timefmt "%Y-%m-%d"
set format x "%d-%m"
plot "$DATA_DIR/plot7_data.dat" using 1:2 with linespoints lw 2 lt rgb "blue" pt 7 ps 1.0 title "Min", \
"$DATA_DIR/plot7_data.dat" using 1:3 with linespoints lw 2 lt rgb "red" pt 5 ps 1.0 title "Max", \
"$DATA_DIR/plot7_data.dat" using 1:4 with linespoints lw 2 lt rgb "green" pt 9 ps 1.0 title "Avg"
EOF

# ------------------------------
# 8. DATA COLLECTION DENSITY OVER TIME (BAR CHART)
# ------------------------------

echo "  Generating Plot 8: Data Collection Density ..."

mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT DATE(scraped_at) AS date,
        COUNT(DISTINCT scrape_id) AS count_success
 FROM scrape_logs
 WHERE status = 'success'
 GROUP BY DATE(scraped_at)
 ORDER BY DATE(scraped_at);" > "$DATA_DIR/plot8_data.dat"

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/8-data-collection-density.png"
set title "Daily Data Collection Density (Successful Scrapes)"
set xlabel "Date"
set ylabel "Successful Scrapes"
set grid
set datafile separator "\t"
set style data histograms
set style fill solid 0.8
set boxwidth 0.7
set yrange [0:*]
plot "$DATA_DIR/plot8_data.dat" using 2:xtic(1) title "Success Count"
EOF

# ------------------------------
# 9. HIGH VS LOW VS FEELS LIKE
# ------------------------------
echo "  Generating Plot 9: High vs Low vs Feels Like..."
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT CONCAT(DATE(s.scraped_at),' ',TIME(s.scraped_at)) AS ts, \
       o.current_temp, o.feels_like, f.high_temp, f.low_temp \
 FROM scrape_logs s \
 JOIN observations o ON o.scrape_id = s.scrape_id \
 JOIN forecasts f   ON f.scrape_id = s.scrape_id \
 WHERE o.current_temp IS NOT NULL AND o.feels_like IS NOT NULL \
 ORDER BY s.scraped_at;" > "$DATA_DIR/plot9_data.dat"

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/9-high-vs-low-vs-feels-like.png"
set title "Temperature Comparison"
set xlabel "Time"
set ylabel "Temperature (°C)"
set grid
set datafile separator "\t"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M\n%d-%m"
plot "$DATA_DIR/plot9_data.dat" using 1:2 with linespoints lw 2 lt rgb "blue" pt 7 ps 0.8 title "Current", \
"$DATA_DIR/plot9_data.dat" using 1:3 with linespoints lw 2 lt rgb "red" pt 5 ps 0.8 title "Feels Like", \
"$DATA_DIR/plot9_data.dat" using 1:4 with linespoints lw 2 lt rgb "orange" pt 9 ps 0.8 title "Forecast High", \
"$DATA_DIR/plot9_data.dat" using 1:5 with linespoints lw 2 lt rgb "purple" pt 1 ps 0.8 title "Forecast Low"
EOF

# ------------------------------
# 10. SIMPLE WEATHER CLASSIFICATION
# ------------------------------
echo "  Generating Plot 10: Weather Classification..."
cat > "$DATA_DIR/plot10_simple.dat" <<EOL
Hot 0
Cold 0
Humid 0
Perfect 0
Moderate 0
EOL

mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -N -e \
"SELECT CASE \
           WHEN current_temp > 30 THEN 'Hot' \
           WHEN current_temp < 20 THEN 'Cold' \
           WHEN humidity > 80 THEN 'Humid' \
           WHEN current_temp BETWEEN 22 AND 26 THEN 'Perfect' \
           ELSE 'Moderate' \
       END AS class, \
       COUNT(*) AS cnt \
 FROM observations \
 WHERE current_temp IS NOT NULL AND humidity IS NOT NULL \
 GROUP BY class;" | while read cls cnt; do
    sed -i "s/^$cls [0-9]*/$cls $cnt/" "$DATA_DIR/plot10_simple.dat"
done

gnuplot <<EOF
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output "$PLOTS_DIR/10-weather-class-pie.png"
set title "Weather Classification"
set xlabel "Type"
set ylabel "Frequency"
set style data histograms
set style fill solid 0.8
set boxwidth 0.6
set yrange [0:*]
plot "$DATA_DIR/plot10_simple.dat" using 2:xtic(1) lt rgb "#6A5ACD" title "Frequency"
EOF

# ------------------------------
# FINISHED
# ------------------------------
echo "[✓] All 10 plots generated in $PLOTS_DIR"
echo "[✓] Data files saved in $DATA_DIR"
