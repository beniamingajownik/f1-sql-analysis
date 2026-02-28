/*
ANALYSIS: Driver Performance [ALL TIME]
PURPOSE:
    - Exploratory insights about all-time driver performance. 
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Drivers on an all-time level.

SOURCE TABLES:
    - gold.v_analytics_driver_season_stats 
*/

-- 1. Percentage of race victories 
WITH drivers_stats AS (
	SELECT 
		driver_name,
		SUM(race_wins) AS total_wins,
		SUM(season_race_entries) AS total_race_starts
	FROM gold.v_analytics_driver_season_stats 
	GROUP BY driver_name
)
SELECT
	*,
	ROUND(total_wins / NULLIF(total_race_starts, 0) * 100, 2) wins_pct
FROM drivers_stats
WHERE total_wins > 0 AND total_race_starts > 10
ORDER BY wins_pct DESC;


-- 2. Percentage of race podiums 
WITH drivers_stats AS (
	SELECT 
		driver_name,
		SUM(race_podiums) AS total_podiums,
		SUM(season_race_entries) AS total_race_starts
	FROM gold.v_analytics_driver_season_stats 
	GROUP BY driver_name
)
SELECT
	*,
	ROUND(total_podiums / NULLIF(total_race_starts, 0) * 100, 2) podiums_pct
FROM drivers_stats
WHERE total_podiums > 0 AND total_race_starts > 10
ORDER BY podiums_pct DESC;


-- 3. Average starting position vs average finishing position (minimum 30 race entries)  
SELECT 
	driver_name,
	ROUND(AVG(avg_race_grid), 2) AS avg_race_grid,
	ROUND(AVG(avg_race_finish), 2) AS avg_race_finish, 
	ROUND(AVG(avg_race_grid - avg_race_finish), 2) AS avg_position_gain,
	SUM(season_race_entries) AS total_races
FROM gold.v_analytics_driver_season_stats
GROUP BY driver_name
HAVING SUM(season_race_entries) >= 30
ORDER BY avg_position_gain DESC;


-- 4. Biggest percent of total points *(% out of all available points earned by all drivers) [biggest domination all time]*
WITH season_totals AS (
    SELECT 
        year,
        driver_name,
        official_season_points,
        regulation_era,
		
        -- Calculating season points pool (sum of all points scored by drivers in a season)
        SUM(official_season_points) OVER(PARTITION BY year) AS season_points_pool,
		
        -- Number of drivers who scored points (contributors)
        COUNT(driver_id) OVER(PARTITION BY year) AS point_scoring_drivers,
		
        -- Driver rank by points 
        RANK() OVER(PARTITION BY year ORDER BY official_season_points DESC) AS season_rank
    FROM gold.v_analytics_driver_season_stats
    WHERE official_season_points > 0 
)
SELECT 
    year,
    driver_name,
    regulation_era,
    official_season_points,
    season_points_pool,
    point_scoring_drivers,
	
    -- Calculating champions share in total season points pool
    ROUND(
        (official_season_points::numeric / NULLIF(season_points_pool, 0)::numeric) * 100, 
        2
    ) AS domination_share_pct
FROM season_totals
WHERE season_rank = 1
ORDER BY domination_share_pct DESC;


-- 5. Smallest percent of total points *(% out of all available points earned by all drivers) [closests seasons all time]* 
WITH season_totals AS (
    SELECT 
        year,
        driver_name,
        official_season_points,
        regulation_era,
		
        -- Calculating season points pool (sum of all points scored by drivers in a season)
        SUM(official_season_points) OVER(PARTITION BY year) AS season_points_pool,
		
        -- Number of drivers who scored points (contributors)
        COUNT(driver_id) OVER(PARTITION BY year) AS point_scoring_drivers,
		
        -- Driver rank by points 
        RANK() OVER(PARTITION BY year ORDER BY official_season_points DESC) AS season_rank
    FROM gold.v_analytics_driver_season_stats
    WHERE official_season_points > 0 
)
SELECT 
    year,
    driver_name,
    regulation_era,
    official_season_points,
    season_points_pool,
    point_scoring_drivers,
	
    -- Calculating champions share in total season points pool
    ROUND(
        (official_season_points::numeric / NULLIF(season_points_pool, 0)::numeric) * 100, 
        2
    ) AS domination_share_pct
FROM season_totals
WHERE season_rank = 1
ORDER BY domination_share_pct ASC;


-- 6. Top 5 biggest point gaps between champion and runner-up 
WITH season_top_two AS (
	SELECT
		year,
		driver_name,
		total_points,
		season_position,
		regulation_era,

		-- 'Joining' champion and runner-up into one row before calculations
		LEAD(driver_name) 	OVER(PARTITION BY year ORDER BY season_position ASC) AS runner_up,
		LEAD(total_points) 	OVER(PARTITION BY year ORDER BY season_position ASC) AS runner_up_points
	FROM gold.v_analytics_driver_standings
	WHERE season_position IN (1, 2)
)
SELECT
	year,
	driver_name AS champion,
	total_points AS champion_points,
	runner_up,
	runner_up_points,
	regulation_era,

	total_points - runner_up_points AS point_gap,
	ROUND((total_points - runner_up_points) / NULLIF(total_points, 0) * 100, 2) AS point_gap_pct
FROM season_top_two
WHERE season_position = 1
ORDER BY point_gap_pct DESC
LIMIT 5;


-- 7. Top 5 smallest point gaps between champion and runner-up 
WITH season_top_two AS (
	SELECT
		year,
		driver_name,
		total_points,
		season_position,
		regulation_era,

		LEAD(driver_name) 	OVER(PARTITION BY year ORDER BY season_position ASC) AS runner_up,
		LEAD(total_points) 	OVER(PARTITION BY year ORDER BY season_position ASC) AS runner_up_points
	FROM gold.v_analytics_driver_standings
	WHERE season_position IN (1, 2)
)
SELECT
	year,
	driver_name AS champion,
	total_points AS champion_points,
	runner_up,
	runner_up_points,
	regulation_era,

	total_points - runner_up_points AS point_gap,
	ROUND((total_points - runner_up_points) / NULLIF(total_points, 0) * 100, 2) AS point_gap_pct
FROM season_top_two
WHERE season_position = 1
ORDER BY point_gap_pct ASC
LIMIT 5;


-- 8. Top 50 average position gain (minimum 30 race entries)
SELECT 
	driver_name,
	regulation_era,
	ROUND(AVG(avg_race_grid), 2) AS avg_race_grid,
	ROUND(AVG(avg_race_finish), 2) AS avg_race_finish, 
	ROUND(AVG(avg_race_grid - avg_race_finish), 2) AS avg_position_gain
FROM gold.v_analytics_driver_season_stats
WHERE avg_race_grid <= 10
GROUP BY driver_name, regulation_era
HAVING SUM(season_race_entries) >= 30
ORDER BY avg_position_gain DESC
LIMIT 50;