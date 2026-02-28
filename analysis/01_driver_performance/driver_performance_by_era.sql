/*
ANALYSIS: Driver Performance [BY ERA]
PURPOSE:
    - Exploratory insights about driver performance by regulation era. 
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Drivers on a regulation era level.

SOURCE TABLES:
    - gold.v_analytics_driver_season_stats 
	- gold.v_analytics_driver_standings
*/

-- 1. Biggest point gaps between champion and runner-up (Biggest domination in an era)
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
),

calculations AS (
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
),

rank_in_era AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY regulation_era ORDER BY point_gap_pct DESC) AS era_rank
	FROM calculations
)
SELECT
	*
FROM rank_in_era
WHERE era_rank = 1 
ORDER BY point_gap_pct DESC;


-- 2. Smallest point gaps between champion and runner-up (Closest title fights in an era)
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
),

calculations AS (
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
),

rank_in_era AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY regulation_era ORDER BY point_gap_pct ASC) AS era_rank
	FROM calculations
)
SELECT
	*
FROM rank_in_era
WHERE era_rank = 1 
ORDER BY point_gap_pct ASC;


-- 3. Best average position gain by a driver in a regulation era (minimum 30 race entries) 
WITH avg_pos_gain AS (
	SELECT 
		driver_name,
		regulation_era,
		ROUND(AVG(avg_race_grid), 2) AS avg_race_grid,
		ROUND(AVG(avg_race_finish), 2) AS avg_race_finish, 
		ROUND(AVG(avg_race_grid - avg_race_finish), 2) AS avg_position_gain,
		SUM(season_race_entries) AS era_race_entries,
		RANK() OVER(PARTITION BY regulation_era ORDER BY AVG(avg_race_grid - avg_race_finish) DESC) AS avg_pos_gain_rank
	FROM gold.v_analytics_driver_season_stats
	GROUP BY driver_name, regulation_era
	HAVING SUM(season_race_entries) >= 30
)
SELECT
	*
FROM avg_pos_gain
WHERE avg_pos_gain_rank = 1
ORDER BY avg_position_gain DESC;


-- 4. Highest win count by driver
WITH season_wins AS (
	SELECT 
		driver_name,
		driver_id,
		regulation_era,
		SUM(race_wins) AS total_race_wins,
		RANK() OVER(PARTITION BY regulation_era ORDER BY SUM(race_wins) DESC) AS wins_rank	
	FROM gold.v_analytics_driver_season_stats
	WHERE race_wins > 0
	GROUP BY driver_name, driver_id, regulation_era
),

total_races_by_era AS (
	SELECT
		regulation_era,
		SUM(total_season_races) AS era_total_races
	FROM (
		SELECT DISTINCT
			year,
			regulation_era,
			total_season_races
		FROM gold.v_analytics_driver_season_stats
	)
	GROUP BY regulation_era
)
SELECT
	s.driver_name,
	s.regulation_era,
	s.total_race_wins,
	t.era_total_races,
	ROUND(s.total_race_wins::numeric / NULLIF(t.era_total_races, 0)::numeric * 100, 2) AS era_wins_pct
FROM season_wins s
JOIN total_races_by_era t
	ON s.regulation_era = t.regulation_era
WHERE wins_rank = 1
ORDER BY era_wins_pct DESC;


-- 5. Average position gain (minimum 30 race entries and avg_race_grid BETWEEN 5 AND 15)
SELECT 
	regulation_era,
	ROUND(AVG(avg_race_grid), 2) AS avg_race_grid,
	ROUND(AVG(avg_race_finish), 2) AS avg_race_finish, 
	ROUND(AVG(avg_race_grid - avg_race_finish), 2) AS avg_position_gain
FROM gold.v_analytics_driver_season_stats
WHERE avg_race_grid BETWEEN 5 AND 15
GROUP BY regulation_era
HAVING SUM(season_race_entries) >= 30
ORDER BY avg_position_gain DESC;

