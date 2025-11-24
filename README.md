# Weather Scraper & Plotter

This project scrapes weather data for Kuala Lumpur from [Time and Date](https://www.timeanddate.com/weather/malaysia/kuala-lumpur), stores it in a MySQL database, and generates plots using Gnuplot.

---

## Project Structure

```

weatherAnalysis/
├── data/               # Raw HTML files fetched by the scraper
├── plots/              # Generated plots and temporary data files
├── scripts/
│   ├── weather_scraper.sh    # Scrapes weather data and inserts into MySQL
│   └── weather_plotter.sh    # Generates weather plots from MySQL

````

---

## Requirements

- **Bash shell** (Linux, macOS, or Git Bash on Windows)
- **MySQL** (or MariaDB) installed and running
- **Gnuplot** installed
- `curl`, `grep`, `awk`, `sed` (common command-line tools)

---

## Setup

1. **Create MySQL Database and Tables**

Use your MySQL client (Workbench, CLI) to create the database and tables:

```sql
CREATE DATABASE weatherDB;

-- Tables: locations, scrape_logs, observations, forecasts
-- See your project SQL schema for details
````

2. **Set MySQL Credentials**

Edit the scripts `weather_scraper.sh` and `weather_plotter.sh` to update:

```bash
MYSQL_USER="your_mysql_user"
MYSQL_PASS="your_mysql_password"
MYSQL_DB="weatherDB"
```

3. **Create folders**

Make sure the following directories exist:

```bash
mkdir -p data/raw_html
mkdir -p plots
```

---

## Usage

1. **Run the scraper**

This fetches the latest weather data and stores it in MySQL:

```bash
cd scripts
./weather_scraper.sh
```

Expected output:

```
[+] Fetching HTML...
[+] Extracting weather data...
[✓] Weather data inserted into normalized tables successfully.
```

2. **Generate plots**

This reads data from MySQL and generates a weather plot:

```bash
./weather_plotter.sh
```

* The generated plot is saved as `plots/weather_plot.png`.
* You can adjust the script to change colors, sizes, or plot style.

---

## Notes

* Make sure Gnuplot is installed and available in your PATH. On Windows, Git Bash may need PATH configured.
* Paths with spaces are handled automatically in the scripts.
* The x-axis shows **observation time** in the format `DD-MM HH:MM`.
* You can run the scraper periodically (e.g., via `cron` or Windows Task Scheduler) to collect ongoing weather data.


