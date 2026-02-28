/*
VIEW: gold.v_report_hall_of_fame_master
PURPOSE:
    - Consolidates career-long legacy data for both Drivers and Constructors into a unified reporting table.
    - Provides a high-level overview of historical achievements and granular reliability metrics for Power BI "Hall of Fame" dashboards.
	
KEY BUSINESS & DATA LOGIC:
    - Combines Driver and Constructor career summaries using a categorical identifier (category).
    - Features a detailed breakdown of DNF rates, distinguishing between 'Driver fault' and 'Car reliability' to assess technical vs. operational risk.
    - Normalizes performance metrics (Win % and Podium %) to allow fair comparison across different eras and career lengths.

DATA HIERARCHY & GRAIN:
    - Granularity: One row per Entity (Driver or Constructor)

SOURCE TABLES:
    - gold.v_analytics_driver_career_summary
    - gold.v_analytics_constructor_career_summary
*/

CREATE OR REPLACE VIEW gold.v_report_hall_of_fame_master AS

-- Part 1: Driver Career Legacy
SELECT
    driver_name AS entity_name,
    'Driver' AS category,
    race_starts AS starts,
    race_wins AS wins,
    race_podiums AS podiums,
    titles,
    ROUND((race_wins::numeric / NULLIF(race_starts, 0)) * 100, 2) AS win_pct,
    ROUND((race_podiums::numeric / NULLIF(race_starts, 0)) * 100, 2) AS podium_pct,
    driver_caused_dnf,
    ROUND((driver_caused_dnf::numeric / NULLIF(race_starts, 0)) * 100, 2) AS driver_caused_dnf_rate,
    car_caused_dnf,
    ROUND((car_caused_dnf::numeric / NULLIF(race_starts, 0)) * 100, 2) AS car_caused_dnf_rate,
    total_dnf,
    ROUND((total_dnf::numeric / NULLIF(race_starts, 0)) * 100, 2) AS total_dnf_rate
FROM gold.v_analytics_driver_career_summary d

UNION ALL

-- Part 2: Constructor Career Legacy
SELECT
    constructor_name AS entity_name,
    'Constructor' AS category,
    race_starts AS starts,
    race_wins AS wins,
    race_podiums AS podiums,
    titles,
    ROUND((race_wins::numeric / NULLIF(race_starts, 0)) * 100, 2) AS win_pct,
    ROUND((race_podiums::numeric / NULLIF(race_starts, 0)) * 100, 2) AS podium_pct,
    driver_caused_dnf,
    ROUND((driver_caused_dnf::numeric / NULLIF(race_starts, 0)) * 100, 2) AS driver_caused_dnf_rate,
    car_caused_dnf,
    ROUND((car_caused_dnf::numeric / NULLIF(race_starts, 0)) * 100, 2) AS car_caused_dnf_rate,
    total_dnf,
    ROUND((total_dnf::numeric / NULLIF(race_starts, 0)) * 100, 2) AS total_dnf_rate
FROM gold.v_analytics_constructor_career_summary c;