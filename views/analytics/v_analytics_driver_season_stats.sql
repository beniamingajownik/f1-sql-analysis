/*
VIEW: v_analytics_driver_season_stats
PURPOSE:
    - Provides a final, aggregated summary of driver statistic throughout a season.
	- Serves as the primary source for driver performance analysis.  
	
KEY BUSINESS & DATA LOGIC:
	- Calculates Main Race and Sprint Race statistics (average grid position, average finish position etc.) per season

DATA HIERARCHY & GRAIN:
    - Granularity: One row per driver (Driver x Season)

SOURCE TABLES:
    - v_driver_base
*/

CREATE OR REPLACE VIEW v_analytics_driver_season_stats AS

-- Filtering out "shared drives"
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, driver_id, session_type)
		*
	FROM v_driver_base
	ORDER BY year, race_id, driver_id, session_type, finish_position ASC
),

-- Calculation of Main Race and Sprint Race stats
race_stats_per_season AS (
	SELECT
		year,
		driver_name,
		driver_id,
		STRING_AGG(DISTINCT team, ' / ') AS team,
		driver_nationality,
		driver_continent,
		regulation_era,

		-- Total events per season (Main Race/Sprint Race)
		MAX(MAX(CASE WHEN session_type = 'RACE' 	THEN round END)) OVER(PARTITION BY year) 	AS total_season_races,
		MAX(MAX(CASE WHEN session_type = 'SPRINT' 	THEN round END)) OVER(PARTITION BY year) 	AS total_season_sprints,
		
		-- Average grid position, finish position, points (Main Race/Sprint Race)
		ROUND(AVG(CASE WHEN session_type = 'RACE' 	THEN grid_position END), 2) 	AS avg_race_grid,
		ROUND(AVG(CASE WHEN session_type = 'SPRINT' THEN grid_position END), 2) 	AS avg_sprint_grid,
		ROUND(AVG(CASE WHEN session_type = 'RACE' 	THEN finish_position END), 2) 	AS avg_race_finish,
		ROUND(AVG(CASE WHEN session_type = 'SPRINT' THEN finish_position END), 2) 	AS avg_sprint_finish,
		ROUND(AVG(CASE WHEN session_type = 'RACE' 	THEN points END), 2) 			AS avg_race_points,
		ROUND(AVG(CASE WHEN session_type = 'SPRINT' THEN points END), 2) 			AS avg_sprint_points,
		SUM(points) AS total_season_points,

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
		
	FROM unified_results
	GROUP BY year, driver_id, driver_name, driver_nationality, driver_continent, regulation_era
)
SELECT 
	*,
	-- Calculating percentage of fastest laps by driver in a season (Main Race/Sprint Race)
	ROUND((race_fastest_lap::numeric / NULLIF(race_starts::numeric, 0) * 100), 2)  		AS race_fastest_lap_pct,

	-- Calculating participation percentage by driver in a season (Main Race/Sprint Race)
	ROUND((race_starts::numeric / NULLIF(total_season_races::numeric, 0) * 100), 2)  	AS race_participation_pct,
	ROUND((sprint_starts::numeric / NULLIF(total_season_sprints::numeric, 0) * 100), 2) AS sprint_participation_pct
FROM race_stats_per_season