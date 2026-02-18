/*
VIEW: v_analytics_constructor_season_stats
PURPOSE:
    - Provides a final, aggregated summary of constructor statistic throughout a season.
	- Serves as the primary source for constructor performance analysis.  
	
KEY BUSINESS & DATA LOGIC:
	- Calculates Main Race and Sprint Race statistics (average grid position, average finish position etc.) per season

DATA HIERARCHY & GRAIN:
    - Granularity: One row per constructor (Constructor x Season)

SOURCE TABLES:
    - v_constructor_base
	- v_constructor_championship_logic
*/

CREATE OR REPLACE VIEW v_analytics_constructor_season_stats AS

-- Joining constructor base view with constructor championship logic view in order to correctly calculate stats
WITH driver_rank AS (
	SELECT DISTINCT ON (year, race_id, driver_id, session_type)
		cb.year,
		cb.race_id,
		cb.round,
		cb.session_type,
		cb.constructor_name,
		cb.constructor_id,
		cb.constructor_nationality,
		cb.constructor_continent,
		cb.driver_name,
		cb.driver_id,
		cb.engine_manufacturer,
		cb.regulation_era,
		cb.grid_position,
		cb.finish_position,
		cb.dnf_flag,
		cb.dsq_flag,
		cb.is_fastest_lap,

		cl.team_points,
		cl.counts_to_championship
		
	FROM v_constructor_base cb
	LEFT JOIN v_constructor_championship_logic cl
		ON cb.race_id = cl.race_id AND cb.constructor_id = cl.constructor_id 
		AND cb.session_type = cl.session_type AND cb.driver_id = cl.driver_id
	ORDER BY year, race_id, driver_id, session_type, finish_position ASC
),

-- Calculation of Main Race and Sprint Race stats
race_stats_per_season AS (
	SELECT
		year,
		constructor_name,
		constructor_id,
		STRING_AGG(DISTINCT driver_name, ' / ') AS drivers,
		constructor_nationality,
		constructor_continent,
		STRING_AGG(DISTINCT engine_manufacturer, ' / ') AS engine,
		regulation_era,

		-- Total events per season (Main Race/Sprint Race)
		MAX(MAX(CASE WHEN session_type = 'RACE' 	THEN round END)) OVER(PARTITION BY year) 	AS total_season_races,
		MAX(MAX(CASE WHEN session_type = 'SPRINT' 	THEN round END)) OVER(PARTITION BY year) 	AS total_season_sprints,

		-- Calculating total constructor entries per season (Main Race/Sprint Race)
		COUNT(CASE WHEN session_type = 'RACE' 	THEN 1 END)  	AS constructor_race_entrants,
		COUNT(CASE WHEN session_type = 'SPRINT' THEN 1 END)  	AS constructor_sprint_entrants,

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

		-- Total points per season including points that were not counted towards World Constructor Championship
		ROUND(SUM(CASE WHEN session_type = 'RACE' 	THEN team_points ELSE 0 END), 2) AS total_race_points,
		ROUND(SUM(CASE WHEN session_type = 'SPRINT' THEN team_points ELSE 0 END), 2) AS total_sprint_points,
		SUM(team_points) AS unofficial_season_points,

		-- Total points which count per season (only points that counted towards World Constructor Championship)
		ROUND(SUM(CASE WHEN session_type = 'RACE' 	AND counts_to_championship = 1 
													THEN team_points ELSE 0 END), 2) AS official_race_points,
		SUM(CASE WHEN counts_to_championship = 1 	THEN team_points ELSE 0 END) 	 AS provisional_official_points,

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
	GROUP BY year, constructor_id, constructor_name, constructor_nationality, constructor_continent, regulation_era
),

points_correction AS (
	SELECT 
		*,
		-- Correcting total season points (2020 Racing Point was deducted 15pts. for illegal rear brake system while 2018 Force India went bankrupt)
		CASE
			WHEN year = 2020 AND constructor_id = 'racing-point' THEN provisional_official_points - 15.0
			WHEN year = 2018 AND constructor_id = 'force-india'	 THEN provisional_official_points - 59.0
			ELSE provisional_official_points
		END official_season_points
	FROM race_stats_per_season
)
SELECT 
	year,
	constructor_name,
	constructor_id,
	drivers,
	constructor_nationality,
	constructor_continent,
	engine,
	regulation_era,
	
	constructor_race_entrants,
	constructor_sprint_entrants,
	
	race_wins,
	sprint_wins,
	race_podiums,
	sprint_podiums,

	-- Percentage of wins in a season (Main Race/Sprint Race)
	ROUND((race_wins::numeric / NULLIF(total_season_races::numeric, 0) * 100), 2) 		AS season_race_wins_pct,
	ROUND((sprint_wins::numeric / NULLIF(total_season_sprints::numeric, 0) * 100), 2) 	AS season_sprint_wins_pct,

	-- Percentage of podiums in a season based on total entry potential - The "Efficiency" Stat (Main Race/Sprint Race)
	ROUND((race_podiums::numeric / NULLIF(constructor_race_entrants::numeric, 0) * 100), 2) 		AS race_podiums_pct,
	ROUND((sprint_podiums::numeric / NULLIF(constructor_sprint_entrants::numeric, 0) * 100), 2) 	AS sprint_podiums_pct,
	
	avg_race_grid,
	avg_race_finish,
	avg_sprint_grid,
	avg_sprint_finish,
	
	official_race_points,
	total_sprint_points,
	official_season_points,
		
	-- Average points (Main Race/Sprint Race)
	ROUND((official_race_points / NULLIF(total_season_races::numeric, 0)), 2) 	AS avg_race_points,
	ROUND((total_sprint_points / NULLIF(total_season_sprints::numeric, 0)), 2) 	AS avg_sprint_points,

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
	
FROM points_correction;