/*
ANALYSIS: Reliability [driver / constructor / regulation era]
PURPOSE:
    - Exploratory insights about reliability of drivers / constructors. 
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 reliability performance
		of drivers and constructors on a season / career / regulation era level.

SOURCE TABLES:
    - gold.v_analytics_driver_season_stats 
	- gold.v_analytics_constructor_season_stats
*/

-- 1. Total DNFs per driver all-time (minimum 30 race entries)
WITH driver_dnf_summary AS (
	SELECT 
		driver_name,
		SUM(race_dnf) AS total_race_dnf,
		SUM(season_race_entries) AS total_race_entries		
	FROM gold.v_analytics_driver_season_stats
	GROUP BY driver_name, driver_id
	HAVING SUM(season_race_entries) > 30
)
SELECT
	*,
	ROUND(total_race_dnf::numeric / NULLIF(total_race_entries, 0)::numeric * 100, 2) AS total_race_dnf_pct
FROM driver_dnf_summary
ORDER BY total_race_dnf_pct DESC;


-- 2. Driver race finish rate (% of races finished per season)
SELECT
	year,
	driver_name,
	team,
	regulation_era,
	season_race_entries,
	race_dnf,
	ROUND((season_race_entries::numeric - race_dnf::numeric) / NULLIF(season_race_entries, 0) * 100, 2) AS race_finish_pct
FROM gold.v_analytics_driver_season_stats
WHERE season_race_entries > 3
ORDER BY year ASC, race_finish_pct DESC;


-- 3. Driver DNF rate (% of DNFs per season)
SELECT
	year,
	driver_name,
	team,
	regulation_era,
	season_race_entries,
	race_dnf,
	ROUND(race_dnf::numeric / NULLIF(season_race_entries, 0) * 100, 2) AS race_dnf_pct
FROM gold.v_analytics_driver_season_stats
WHERE season_race_entries > 3
ORDER BY year ASC, race_dnf_pct DESC;


-- 4. Driver DNF rate (% of DNFs per era)
WITH driver_era_dnf AS (
	SELECT
		driver_name,
		regulation_era,
		SUM(season_race_entries) AS era_race_entries,
		SUM(race_dnf) AS era_race_dnf
	FROM gold.v_analytics_driver_season_stats
	GROUP BY driver_name, driver_id, regulation_era
	HAVING SUM(season_race_entries) > 30
)
SELECT 
	*,
	ROUND(era_race_dnf::numeric / NULLIF(era_race_entries, 0) * 100, 2) AS era_dnf_pct
FROM driver_era_dnf
ORDER BY era_dnf_pct DESC;


-- 5. Total DNFs per constructor all-time (minimum 60 race entries)
WITH constructor_dnf_summary AS (
	SELECT 
		constructor_name,
		SUM(race_dnf) AS total_race_dnf,
		SUM(constructor_race_entrants) AS total_race_entries		
	FROM gold.v_analytics_constructor_season_stats
	GROUP BY constructor_name, constructor_id
	HAVING SUM(constructor_race_entrants) > 60
)
SELECT
	*,
	ROUND(total_race_dnf::numeric / NULLIF(total_race_entries, 0)::numeric * 100, 2) AS total_race_dnf_pct
FROM constructor_dnf_summary
ORDER BY total_race_dnf_pct DESC;

-- 6. Constructor race finish rate (% of races finished per season)
SELECT
	year,
	constructor_name,
	regulation_era,
	constructor_race_entrants,
	race_dnf,
	ROUND((constructor_race_entrants::numeric - race_dnf::numeric) / NULLIF(constructor_race_entrants, 0) * 100, 2) AS race_finish_pct
FROM gold.v_analytics_constructor_season_stats
WHERE constructor_race_entrants > 10
ORDER BY year ASC, race_finish_pct DESC;


-- 7. Constructor DNF rate (% of DNFs per season)
SELECT
	year,
	constructor_name,
	drivers,
	regulation_era,
	constructor_race_entrants,
	race_dnf,
	ROUND(race_dnf::numeric / NULLIF(constructor_race_entrants, 0) * 100, 2) AS race_dnf_pct
FROM gold.v_analytics_constructor_season_stats
WHERE constructor_race_entrants > 10
ORDER BY year ASC, race_dnf_pct DESC;


-- 8. Constructor DNF rate (% of DNFs per era)
WITH constructor_era_dnf AS (
	SELECT
		constructor_name,
		regulation_era,
		SUM(constructor_race_entrants) AS era_race_entries,
		SUM(race_dnf) AS era_race_dnf
	FROM gold.v_analytics_constructor_season_stats
	GROUP BY constructor_name, constructor_id, regulation_era
	HAVING SUM(constructor_race_entrants) > 30
)
SELECT 
	*,
	ROUND(era_race_dnf::numeric / NULLIF(era_race_entries, 0) * 100, 2) AS era_dnf_pct
FROM constructor_era_dnf
ORDER BY era_dnf_pct DESC;


-- 9. Total DNFs per regulation era (minimum 30 race entries)
WITH era_dnf_summary AS (
	SELECT 
		regulation_era,
		SUM(race_dnf) AS total_race_dnf,
		SUM(season_race_entries) AS total_entries
	FROM gold.v_analytics_driver_season_stats
	GROUP BY regulation_era
)
SELECT
	*,
	ROUND(total_race_dnf::numeric / NULLIF(total_entries, 0)::numeric * 100, 2) AS total_race_dnf_pct
FROM era_dnf_summary
WHERE total_entries > 30
ORDER BY total_race_dnf_pct DESC;