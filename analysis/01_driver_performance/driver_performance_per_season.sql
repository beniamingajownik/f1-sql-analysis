/*
ANALYSIS: Driver Performance [PER SEASON]
PURPOSE:
    - Exploratory insights about season driver performance. 
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Drivers on a season level.

SOURCE TABLES:
    - gold.v_analytics_driver_season_stats 
*/

-- 1. Percentage of race victories 
SELECT 
	year,
	driver_name,
	team,
	race_wins,
	total_season_races,
	season_race_wins_pct
FROM gold.v_analytics_driver_season_stats
WHERE race_wins > 0
ORDER BY season_race_wins_pct DESC;


-- 2. Percentage of race podiums  
SELECT 
	year,
	driver_name,
	team,
	race_podiums,
	total_season_races,
	season_race_podiums_pct
FROM gold.v_analytics_driver_season_stats
WHERE race_podiums > 0
ORDER BY season_race_podiums_pct DESC;


-- 3. Percentage of sprint victories
SELECT 
	year,
	driver_name,
	team,
	sprint_wins,
	total_season_sprints,
	season_sprint_wins_pct
FROM gold.v_analytics_driver_season_stats
WHERE sprint_wins > 0
ORDER BY season_sprint_wins_pct DESC;


-- 4. Percentage of sprint podiums  
SELECT 
	year,
	driver_name,
	team,
	sprint_podiums,
	total_season_sprints,
	season_sprint_podiums_pct
FROM gold.v_analytics_driver_season_stats
WHERE sprint_podiums > 0
ORDER BY season_sprint_podiums_pct DESC;


-- 5. Highest average points
SELECT
	*
FROM (
	SELECT
		year,
		driver_name,
		team,
		regulation_era,
		avg_race_points,
		season_race_entries,
		total_season_races,
		RANK() OVER(PARTITION BY year ORDER BY avg_race_points DESC) AS highest_avg_rank
	FROM gold.v_analytics_driver_season_stats
	WHERE season_race_entries > 4
	)
WHERE highest_avg_rank = 1 
ORDER BY year;


-- 6. Driver points trend over time (year-over-year)
WITH driver_performance AS (
	SELECT 
		year,
		driver_name,
		team,
		official_season_points,
		season_race_entries AS current_year_entries,
		-- Previous season points
		LAG(official_season_points) OVER(PARTITION BY driver_id ORDER BY year ASC) AS prev_season_points,
		-- Previous year
		LAG(year) OVER(PARTITION BY driver_id ORDER BY year ASC) AS prev_year
	FROM gold.v_analytics_driver_season_stats
)
SELECT 
	year,
	driver_name,
	team,
	current_year_entries,
	official_season_points AS current_points,
	prev_season_points,
	-- Point diff shows progress compared to previous year (positive number = progress)
	(official_season_points - prev_season_points) AS points_diff,
	-- Growth KPI as a percentage 
	ROUND((official_season_points - prev_season_points)::numeric / NULLIF(prev_season_points, 0) * 100, 2) AS yoy_growth_pct
FROM driver_performance
WHERE prev_season_points IS NOT NULL 
	AND year = prev_year + 1 
	AND current_year_entries > 1 
ORDER BY year; 
