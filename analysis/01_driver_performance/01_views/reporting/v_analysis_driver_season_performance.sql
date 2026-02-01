/*
VIEW: v_analysis_driver_season_performance
PURPOSE:
    - Provides a comprehensive breakdown of driver scoring efficiency across F1 seasons.
    - Separates performance between Main Races and Sprints to analyze session-specific strengths.
    - Calculates championship standings (rank) based on total points per year.

METRICS INCLUDED:
    - Points totals (Race, Sprint, Season)
    - Average points per entry
    - Contribution percentage for sprint era (How much of a driver's total score comes from Sprints vs. Races)
    - Yearly Championship Ranking using DENSE_RANK.

GRAIN:
    - One row per Driver per Year.
*/
CREATE OR REPLACE VIEW v_analysis_driver_season_performance AS
WITH seasonal_stats AS (
	SELECT
		year,
		driver_name,
		regulation_era,
		SUM(points) AS total_season_points,
-- Calculating total points scored in Main Races and Sprint Races
		SUM(CASE WHEN session_type = 'RACE_RESULT' THEN points ELSE 0 END) AS total_race_points,
		SUM(CASE WHEN session_type = 'SPRINT_RACE_RESULT' THEN points ELSE 0 END) AS total_sprint_points,
		
-- Calculating total Main Race and Sprint Race starts	
		COUNT(CASE WHEN (session_type = 'RACE_RESULT' AND dns_flag = 0) THEN 1 END) AS race_count,
		COUNT(CASE WHEN (session_type = 'SPRINT_RACE_RESULT' AND dns_flag = 0) THEN 1 END) AS sprint_count
	FROM v_driver_base
	GROUP BY year, driver_name, regulation_era
)
SELECT
	year,
	driver_name,	
	total_race_points,
	
-- Calculating average points scored per Main Race
	CASE
		WHEN race_count = 0 THEN 0
		ELSE ROUND((total_race_points * 1.0 / race_count),2) 
	END AS avg_points_per_race,
	
	total_sprint_points,

-- Calculating average points scored per Sprint Race
	CASE 
		WHEN sprint_count = 0 THEN 0
		ELSE ROUND((total_sprint_points * 1.0 / sprint_count),2)
	END AS avg_points_per_sprint,
	
	total_season_points,

-- Driver rank in every season they participated in
	DENSE_RANK() OVER(PARTITION BY year ORDER BY total_season_points DESC) AS championship_rank,

-- Calculating percentage of Sprint Race points in a season
	CASE 
    	WHEN (total_race_points) = 0 THEN 0
    	ELSE ROUND((total_sprint_points * 1.0  / total_season_points) * 100, 2)
	END AS sprint_points_percentage,

-- Calculating percentage of Main Race points in a season
	CASE 
		WHEN total_race_points = 0 THEN 0
		ELSE ROUND((total_race_points * 1.0 / total_season_points) * 100, 2)
	END race_points_percentage,

	regulation_era,
	
-- Adding a flag to segregate seasons with Sprint Race format
	CASE WHEN year >= 2021 THEN 1 ELSE 0 END is_sprint_era
FROM seasonal_stats