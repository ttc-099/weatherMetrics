-- ====================================================
-- ENUM for scrape status
-- ====================================================
CREATE TYPE scrape_status AS ENUM ('success', 'failure', 'partial');

-- ====================================================
-- Table: locations
-- ====================================================
CREATE TABLE locations (
    location_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    state           VARCHAR(255),
    country         VARCHAR(255) NOT NULL
);

-- ====================================================
-- Table: scrape_logs
-- ====================================================
CREATE TABLE scrape_logs (
    scrape_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id     INTEGER NOT NULL,
    scraped_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    status          scrape_status NOT NULL,

    CONSTRAINT fk_scrape_location
        FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
        ON DELETE CASCADE
);

-- ====================================================
-- Table: observations
-- ====================================================
CREATE TABLE observations (
    observation_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id         INTEGER NOT NULL,
    scrape_id           INTEGER NOT NULL,
    observation_time    TIMESTAMP NOT NULL,
    current_temp        FLOAT,
    feels_like          FLOAT,
    humidity            FLOAT,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_obs_location
        FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_obs_scrape
        FOREIGN KEY (scrape_id)
        REFERENCES scrape_logs(scrape_id)
        ON DELETE CASCADE
);

-- ====================================================
-- Table: forecasts
-- ====================================================
CREATE TABLE forecasts (
    forecast_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scrape_id       INTEGER NOT NULL,
    location_id     INTEGER NOT NULL,
    high_temp       FLOAT,
    low_temp        FLOAT,

    CONSTRAINT fk_forecast_scrape
        FOREIGN KEY (scrape_id)
        REFERENCES scrape_logs(scrape_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_forecast_location
        FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
        ON DELETE CASCADE
);
