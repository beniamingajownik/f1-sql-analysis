/*
VIEW: v_analytics_driver_season_stats
PURPOSE:
    - Provides a final, aggregated summary of driver statistic throughout a season.
	- Serves as the primary source for driver performance analysis.  
	
KEY BUSINESS & DATA LOGIC:
	- Calculates Main Race and Sprint Race statistics (average grid position, average finish position etc.) per season

DATA HIERARCHY & GRAIN:
    - Granularity: One row per driver (Driver x Season)
		*Note on Grain: If a driver switched teams mid-season then the driver will take up two or more rows.

SOURCE TABLES:
    - v_driver_base
	- v_driver_championship_logic
*/

CREATE OR REPLACE VIEW v_analytics_driver_season_stats AS

-- Joining driver base view with driver championship logic view in order to correctly calculate stats
WITH driver_rank AS (
	SELECT DISTINCT ON (year, race_id, driver_id, session_type)
		db.year,
		db.race_id,
		db.round,
		db.session_type,
		db.driver_name,
		db.driver_id,
		db.constructor_name,
		db.constructor_id,
		db.engine_manufacturer,
		db.driver_nationality,
		db.driver_continent,
		db.regulation_era,
		db.grid_position,
		db.finish_position,
		db.dnf_flag,
		db.dsq_flag,
		db.is_fastest_lap,

		dl.points,
		dl.counts_to_championship	
	FROM v_driver_base db
	LEFT JOIN v_driver_championship_logic dl
		ON db.race_id = dl.race_id AND db.session_type = dl.session_type AND db.driver_id = dl.driver_id
	ORDER BY year, race_id, driver_id, session_type, finish_position ASC
),

-- Calculation of Main Race and Sprint Race stats
race_stats_per_season AS (
	SELECT
		year,
		driver_name,
		driver_id,
		constructor_name AS team,
		driver_nationality,
		driver_continent,
		STRING_AGG(DISTINCT engine_manufacturer, ' / ') AS engine,
		regulation_era,

		-- Total season entries per driver
		COUNT(CASE WHEN session_type = 'RACE' 		THEN driver_id END) AS season_race_entries,
		COUNT(CASE WHEN session_type = 'SPRINT' 	THEN driver_id END) AS season_sprint_entries,

		-- Total events held per season (Main Race/Sprint Race)
		MAX(MAX(CASE WHEN session_type = 'RACE' 	THEN round END)) OVER(PARTITION BY year) 	AS total_season_races,
		MAX(MAX(CASE WHEN session_type = 'SPRINT' 	THEN round END)) OVER(PARTITION BY year) 	AS total_season_sprints,

		-- Total wins per season (Main Race/Sprint Race)
		COUNT(CASE WHEN session_type = 'RACE' 	AND finish_position = 1 THEN 1 END) AS race_wins,
		COUNT(CASE WHEN session_type = 'SPRINT' AND finish_position = 1 THEN 1 END) AS sprint_wins,

		-- Total podiums per season (Main Race/Sprint Race)
		COUNT(CASE WHEN session_type = 'RACE' 	AND finish_position IN (1, 2, 3) THEN 1 END) AS race_podiums,
		COUNT(CASE WHEN session_type = 'SPRINT' AND finish_position IN (1, 2, 3) THEN 1 END) AS sprint_podiums,
		
		-- Average grid position, finish position (Main Race/Sprint Race)
		ROUND(AVG(CASE WHEN session_type = 'RACE' 	THEN grid_position END), 2) 	 AS avg_race_grid,
		ROUND(AVG(CASE WHEN session_type = 'SPRINT' THEN grid_position END), 2) 	 AS avg_sprint_grid,
		ROUND(AVG(CASE WHEN session_type = 'RACE' 	THEN finish_position END), 2) 	 AS avg_race_finish,
		ROUND(AVG(CASE WHEN session_type = 'SPRINT' THEN finish_position END), 2) 	 AS avg_sprint_finish,

		-- Total points per season including points that were not counted towards World Drivers Championship
		ROUND(SUM(CASE WHEN session_type = 'RACE' 	THEN points ELSE 0 END), 2) AS total_race_points,
		ROUND(SUM(CASE WHEN session_type = 'SPRINT' THEN points ELSE 0 END), 2) AS total_sprint_points,
		SUM(points) AS unofficial_season_points,

		-- Total points which count per season (only points that counted towards World Driver Championship)
		ROUND(SUM(CASE WHEN session_type = 'RACE' 	AND counts_to_championship = 1 
													THEN points ELSE 0 END), 2) 	AS official_race_points,
		SUM(CASE WHEN counts_to_championship = 1 	THEN points ELSE 0 END) 	 	AS official_season_points,

		-- Total/Percentage of DNF,DSQ (Main Race)
		SUM(CASE WHEN session_type = 'RACE' 		THEN dnf_flag ELSE 0 END) 		AS race_dnf,
		ROUND(AVG(CASE WHEN session_type = 'RACE' 	THEN dnf_flag END * 100), 2) 	AS race_dnf_pct,
		SUM(CASE WHEN session_type = 'RACE' 		THEN dsq_flag ELSE 0 END) 		AS race_dsq,
		ROUND(AVG(CASE WHEN session_type = 'RACE' 	THEN dsq_flag END * 100), 2)  	AS race_dsq_pct,

		-- Total/Percentage of DNF,DSQ (Sprint Race)
		SUM(CASE WHEN session_type = 'SPRINT' 		THEN dnf_flag ELSE 0 END) 		AS sprint_dnf,
		ROUND(AVG(CASE WHEN session_type = 'SPRINT' THEN dnf_flag END * 100), 2) 	AS sprint_dnf_pct,
		SUM(CASE WHEN session_type = 'SPRINT' 		THEN dsq_flag ELSE 0 END) 		AS sprint_dsq,
		ROUND(AVG(CASE WHEN session_type = 'SPRINT' THEN dsq_flag END * 100), 2) 	AS sprint_dsq_pct,

		-- Total starts (Main Race/Sprint Race)
		COUNT(CASE WHEN session_type = 'RACE' 		THEN driver_id END) AS race_starts,
		COUNT(CASE WHEN session_type = 'SPRINT' 	THEN driver_id END) AS sprint_starts,

		-- Total fastest laps (Main Race/Sprint Race)
		COUNT(CASE WHEN is_fastest_lap = 'true' AND session_type = 'RACE' 	THEN 1 END) AS race_fastest_lap
		
	FROM driver_rank
	GROUP BY year, driver_name, driver_id, constructor_name, driver_nationality, driver_continent, regulation_era
)
SELECT 
	year,
	driver_name,
	driver_id,
	team,
	driver_nationality,
	driver_continent,
	engine,
	regulation_era,
	season_race_entries,
	season_sprint_entries,

	race_wins,
	sprint_wins,
	race_podiums,
	sprint_podiums,

	-- Percentage of wins in a season (Main Race/Sprint Race)
	ROUND((race_wins::numeric / NULLIF(total_season_races::numeric, 0) * 100), 2) 		AS season_race_wins_pct,
	ROUND((sprint_wins::numeric / NULLIF(total_season_sprints::numeric, 0) * 100), 2) 	AS season_sprint_wins_pct,

	-- Percentage of podiums in a season (Main Race/Sprint Race)
	ROUND((race_podiums::numeric / NULLIF(total_season_races::numeric, 0) * 100), 2) 		AS season_race_podiums_pct,
	ROUND((sprint_podiums::numeric / NULLIF(total_season_sprints::numeric, 0) * 100), 2) 	AS season_sprint_podiums_pct,
	
	avg_race_grid,
	avg_race_finish,
	avg_sprint_grid,
	avg_sprint_finish,
	
	official_race_points,
	total_sprint_points,
	official_season_points,
	unofficial_season_points,
		
	-- Average points (Main Race/Sprint Race)
	ROUND((official_race_points / NULLIF(season_race_entries::numeric, 0)), 2) 	AS avg_race_points,
	ROUND((total_sprint_points / NULLIF(season_sprint_entries::numeric, 0)), 2) AS avg_sprint_points,

	race_dnf,
	race_dnf_pct,
	race_dsq,
	race_dsq_pct,
	sprint_dnf,
	sprint_dnf_pct,
	sprint_dsq,
	sprint_dsq_pct,
	
	-- Percentage of fastest laps by driver in a season (Main Race/Sprint Race)
	ROUND((race_fastest_lap::numeric / NULLIF(total_season_races::numeric, 0) * 100), 2) AS race_fastest_lap_pct,

	total_season_races,
	total_season_sprints
	
FROM race_stats_per_season;