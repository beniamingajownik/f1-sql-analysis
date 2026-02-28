/*
ANALYSIS: Overall sporting analysis
PURPOSE:
    - Exploratory insights about general Formula 1 stats.  
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 (for e.g. success per country/continent)

DATA HIERARCHY & GRAIN:
    - ?

SOURCE TABLES:
    - gold.v_analytics_driver_standings (WDC)
	- gold.v_analytics_constructor_standings (WCC)
*/

-- 1. Count of World Drivers Champion (WDC) titles per country
SELECT 
	driver_nationality AS country,
	COUNT(*) AS country_wdc_titles
FROM gold.v_analytics_driver_standings
WHERE season_position = 1
GROUP BY driver_nationality
ORDER BY country_wdc_titles DESC;


-- 1.1 Count of World Drivers Champion (WDC) titles per continent
SELECT
	driver_continent AS continent,
	COUNT(*) AS continent_wdc_titles
FROM gold.v_analytics_driver_standings
WHERE season_position = 1
GROUP BY driver_continent
ORDER BY continent_wdc_titles DESC;

-- 2. Count of World Constructors Champion (WCC) titles per country
SELECT 
	constructor_nationality AS country,
	COUNT(*) AS country_wdc_titles
FROM gold.v_analytics_constructor_standings
WHERE season_position = 1
GROUP BY constructor_nationality
ORDER BY country_wdc_titles DESC;


-- 2.1 Count of World Constructors Champion (WCC) titles per continent
SELECT
	constructor_continent AS continent,
	COUNT(*) AS continent_wdc_titles
FROM gold.v_analytics_constructor_standings
WHERE season_position = 1
GROUP BY constructor_continent
ORDER BY continent_wdc_titles DESC;