-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS weatherDB;
USE weatherDB;

-- Create table to store weather reports
CREATE TABLE IF NOT EXISTS weather_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    location VARCHAR(100) NOT NULL,
    observation_time DATETIME NOT NULL,
    latest_report DATETIME NOT NULL,
    current_temp INT NOT NULL,
    feels_like INT NOT NULL,
    forecast_high INT NOT NULL,
    forecast_low INT NOT NULL,
    humidity INT NOT NULL,
    record_inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);