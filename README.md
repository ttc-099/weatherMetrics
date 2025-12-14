# COMP1314 - Automated Weather Metrics Scraper

This project is a Linux Shell and MySQL-based system for collecting, storing, and visualizing weather data from timeanddate.com. It includes automated scraping, data storage, and chart generation using GNUPLOT.

## Features
- Scrapes current weather metrics (temperature, humidity, feels-like) into MySQL
- Generates historical weather charts using GNUPLOT
- Runs automatically via CRONTAB at scheduled intervals
- Fully configurable for different locations and database credentials

## Setup Instructions

### 1. Linux Environment (WSL 2)
Run PowerShell as Admin and execute:
```powershell
wsl --install
```
Restart when prompted, then set up your Linux username/password.

### 2. Install MySQL in WSL
```bash
sudo apt update
sudo apt install mysql-server
sudo mysql_secure_installation
```

### 3. Configure CRONTAB
Edit crontab:
```bash
crontab -e
```
Add tasks (update paths to match your project location):
```
@reboot sudo service mysql start
@reboot sleep 10 && bash -c "cd /path/to/scripts && . ../.env && ./weather_scraperTrue.sh" >> /path/to/logs/weather_cron.log 2>&1
0 * * * * bash -c "cd /path/to/weatherAnalysis && . ../.env && ./scripts/weather_scraperTrue.sh" >> /path/to/logs/weather_scraper_cron.log 2>&1
2 * * * * bash -c "cd /path/to/weatherAnalysis && . ../.env && ./scripts/weather_plotterTrue.sh" >> /path/to/logs/weather_plotter_cron.log 2>&1
```

### 4. Set Up Environment Variables
Create `.env` in your project root:
```bash
nano .env
```
Add your MySQL credentials:
```bash
export DB_HOST=127.0.0.1
export DB_USER=root
export DB_PASSWORD=your_password
export DB_NAME=weatherDB
```

## Running the System

### Manual Test
```bash
cd /path/to/scripts
. ../.env && bash weather_scraperTrue.sh
. ../.env && bash weather_plotterTrue.sh
```

### Verify Automation
Check logs:
```bash
cat /path/to/logs/weather_scraper_cron.log
cat /path/to/logs/weather_plotter_cron.log
```

## Viewing Results
Install GNUPLOT if missing:
```bash
sudo apt install gnuplot
```
Charts are saved as PNG files in:
```
weatherAnalysis/plots/
```

## Notes
- Update location in scraper script to change weather source.
- Ensure all file paths in scripts and CRONTAB match your Windows/WSL project structure.
- MySQL must be running for scripts to work.

## File Structure
```
weatherAnalysis/
├── data/
│   ├── logs/
│   │   ├── weather_cron.log          # CRONTAB execution log (Scraper, upon reboot)
│   │   ├── weather_plotter_cron.log  # CRONTAB execution log (Plotter output)
│   │   └── weather_scraper_cron.log  # CRONTAB execution log (Scraper output)
│   └── plot-data-files/        # Data files for GNUPLOT
├── raw_html/                   # Raw HTML from scraping
├── plots/                      # Generated chart images (.png)
├── scripts/
│   ├── weather_scraperTrue.sh  # Main scraper script
│   ├── weather_plotterTrue.sh  # Main plotter script
│   ├── weatherMetrics.sh       # Additional weather script
│   └── cron.log                # CRONTAB execution log (Plotter, upon reboot)
├── sql/
│   └── createTable.sql         # MySQL table creation script
├── .env                        # Database credentials
├── erd_weatherTrue.jpg         # Database ER diagram
└── README.md                   # This file! Hi!

```

---
*Project built for COMP1314 Semester 1 – Automated Data Scraper*
