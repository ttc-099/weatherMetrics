CREATE DATABASE IF NOT EXISTS weatherDB;
USE weatherDB;

CREATE TABLE weather_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    location VARCHAR(100),
    current_time DATETIME,
    latest_report DATETIME,
    current_temp FLOAT,
    feels_like FLOAT,
    forecast_high FLOAT,
    forecast_low FLOAT,
    humidity INT,
    scraped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
