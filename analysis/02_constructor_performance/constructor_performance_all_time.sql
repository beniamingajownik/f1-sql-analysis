/*
ANALYSIS: Constructor Performance [ALL TIME]
PURPOSE:
    - Exploratory insights about all-time constructor performance. 
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Constructors on an all-time level.

SOURCE TABLES:
    - gold.v_analytics_constructor_season_stats 
	- gold.v_analytics_constructor_standings
*/

-- 1. Percentage of race victories
WITH constructor_summary AS (
	SELECT
		constructor_name,
		SUM(race_wins) AS total_race_wins,
		SUM(constructor_race_entries) AS total_entries
	FROM gold.v_analytics_constructor_season_stats
	GROUP BY constructor_name, constructor_id
	HAVING SUM(constructor_race_entries) > 12
)
SELECT
	constructor_name,
	total_race_wins,
	total_entries,
	ROUND(total_race_wins::numeric / NULLIF(total_entries, 0)::numeric * 100, 2) AS race_wins_pct 
FROM constructor_summary
ORDER BY race_wins_pct DESC;


-- 2. Percentage of race podiums
WITH constructor_summary AS (
	SELECT
		constructor_name,
		SUM(distinct_race_podiums) AS total_race_podiums,
		SUM(constructor_race_entries) AS total_entries
	FROM gold.v_analytics_constructor_season_stats
	GROUP BY constructor_name, constructor_id
	HAVING SUM(constructor_race_entries) > 12
)
SELECT
	constructor_name,
	total_race_podiums,
	total_entries,
	ROUND(total_race_podiums::numeric / NULLIF(total_entries, 0)::numeric * 100, 2) AS race_podiums_pct 
FROM constructor_summary
ORDER BY race_podiums_pct DESC;


-- 3. Average starting position vs average finishing position throughout career *(minimum 30 race entries)*   
WITH constructor_avg_pos_gain AS (
	SELECT
		constructor_name,
		AVG(avg_race_grid) 		AS avg_race_grid,
		AVG(avg_race_finish) 	AS avg_race_finish,
		SUM(constructor_race_entries) AS total_entries
	FROM gold.v_analytics_constructor_season_stats
	GROUP BY constructor_name, constructor_id
	HAVING SUM(constructor_race_entries) > 30
)
SELECT
	constructor_name,
	ROUND(avg_race_grid, 2) 	AS career_avg_grid,
	ROUND(avg_race_finish, 2) 	AS career_avg_finish,
	ROUND(avg_race_grid - avg_race_finish, 2) AS career_pos_gain,
	total_entries
FROM constructor_avg_pos_gain
ORDER BY career_avg_finish;


-- 4. Constructor points market share 
WITH all_points AS (
	SELECT
		constructor_name,
		constructor_id,
		official_season_points,
		SUM(official_season_points) OVER() 	AS total_points
	FROM gold.v_analytics_constructor_season_stats
	
),
constructor_points AS (
	SELECT
		constructor_name,
		constructor_id,
		total_points,
		SUM(official_season_points) AS constructor_total_points
	FROM all_points
	GROUP BY constructor_name, constructor_id, total_points
)
SELECT 	
	constructor_name,
	constructor_total_points,
	total_points,
	ROUND(constructor_total_points::numeric / NULLIF(total_points, 0)::numeric * 100, 2) AS points_share_pct
FROM constructor_points
ORDER BY points_share_pct DESC
LIMIT 15;


-- 6. Top 10 biggest point gaps between champion and runner-up 
WITH champion_runner_up AS (
	SELECT 
		year,
		constructor_name AS champion,
		total_points AS champion_points,
		season_position,
		-- Runner-up constructor name
		LAG(constructor_name) OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up,
		-- Runner-up constructor points
		LAG(total_points) OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up_points
	FROM gold.v_analytics_constructor_standings
	WHERE season_position IN (1,2)
)
SELECT 
	year,
	champion,
	champion_points,
	runner_up,
	runner_up_points,
	-- Points difference between champion and runner-up
	(champion_points - runner_up_points) AS points_diff,
	-- Runner-up constructor points
	ROUND((champion_points - runner_up_points) / NULLIF(champion_points, 0)::numeric * 100, 2) AS points_diff_pct
FROM champion_runner_up
WHERE season_position = 1
ORDER BY points_diff_pct DESC
LIMIT 10;

	
-- 7. Top 10 smallest point gaps between champion and runner-up 
WITH champion_runner_up AS (
	SELECT 
		year,
		constructor_name AS champion,
		total_points AS champion_points,
		season_position,
		-- Runner-up constructor name
		LAG(constructor_name) OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up,
		-- Runner-up constructor points
		LAG(total_points) OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up_points
	FROM gold.v_analytics_constructor_standings
	WHERE season_position IN (1,2)
)
SELECT 
	year,
	champion,
	champion_points,
	runner_up,
	runner_up_points,
	-- Points difference between champion and runner-up
	(champion_points - runner_up_points) AS points_diff,
	-- % of points diff 
	ROUND((champion_points - runner_up_points) / NULLIF(champion_points, 0)::numeric * 100, 2) AS points_diff_pct
FROM champion_runner_up
WHERE season_position = 1
ORDER BY points_diff_pct ASC
LIMIT 10;

