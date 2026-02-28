/*
ANALYSIS: Constructor Performance [BY ERA]
PURPOSE:
    - Exploratory insights about constructor performance by regulation era. 
	
KEY BUSINESS & DATA LOGIC:
	- Answers 'Business Questions' related to Formula 1 Constructors on a regulation era level.

SOURCE TABLES:
    - gold.v_analytics_constructor_season_stats 
	- gold.v_analytics_constructor_standings
*/


-- 1. Biggest point gaps between champion and runner-up *(Biggest domination in an era)*
WITH champion_runner_up AS (
	SELECT
		year,
		constructor_name AS champion, 
		total_points AS champion_points,
		season_position,
		LAG(constructor_name) OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up,
		LAG(total_points) 	  OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up_points,
		regulation_era
	FROM gold.v_analytics_constructor_standings
	WHERE season_position IN (1,2)
),

era_point_gap_rank AS (
	SELECT
		year,
		champion,
		champion_points,
		season_position,
		runner_up,
		runner_up_points,
		(champion_points - runner_up_points) AS points_diff,
		ROUND((champion_points - runner_up_points)::numeric / NULLIF(champion_points, 0)::numeric * 100, 2) AS points_diff_pct,
		regulation_era,
		RANK() OVER(PARTITION BY regulation_era ORDER BY (
						(champion_points - runner_up_points)::numeric / NULLIF(champion_points, 0)::numeric * 100) DESC) AS era_gap_rank
	FROM champion_runner_up
	WHERE season_position = 1
)
SELECT 
	year,
	regulation_era,
	champion,
	runner_up,
	champion_points,
	runner_up_points,
	points_diff,
	points_diff_pct
FROM era_point_gap_rank
WHERE era_gap_rank = 1
ORDER BY points_diff_pct DESC;


-- 2. Smallest point gaps between champion and runner-up *(Closest title fights in an era)*
WITH champion_runner_up AS (
	SELECT
		year,
		constructor_name AS champion, 
		total_points AS champion_points,
		season_position,
		LAG(constructor_name) OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up,
		LAG(total_points) 	  OVER(PARTITION BY year ORDER BY season_position DESC) AS runner_up_points,
		regulation_era
	FROM gold.v_analytics_constructor_standings
	WHERE season_position IN (1,2)
),

era_point_gap_rank AS (
	SELECT
		year,
		champion,
		champion_points,
		season_position,
		runner_up,
		runner_up_points,
		(champion_points - runner_up_points) AS points_diff,
		ROUND((champion_points - runner_up_points)::numeric / NULLIF(champion_points, 0)::numeric * 100, 2) AS points_diff_pct,
		regulation_era,
		RANK() OVER(PARTITION BY regulation_era ORDER BY ((champion_points - runner_up_points)::numeric / NULLIF(champion_points, 0)::numeric * 100) ASC) AS era_gap_rank
	FROM champion_runner_up
	WHERE season_position = 1
)
SELECT 
	year,
	regulation_era,
	champion,
	runner_up,
	champion_points,
	runner_up_points,
	points_diff,
	points_diff_pct
FROM era_point_gap_rank
WHERE era_gap_rank = 1
ORDER BY points_diff_pct ASC;


-- 3. Best average position gain by a constructor in a regulation era *(minimum 30 race entries)* 
WITH avg_pos_gain AS (
	SELECT
		constructor_name,
		regulation_era,
		AVG(avg_race_grid) AS avg_race_grid,
		AVG(avg_race_finish) AS avg_race_finish,
		AVG(avg_race_grid) - AVG(avg_race_finish) AS avg_pos_gain,
		RANK() OVER(PARTITION BY regulation_era ORDER BY (AVG(avg_race_grid) - AVG(avg_race_finish)) DESC) AS era_pos_gain_rank
	FROM gold.v_analytics_constructor_season_stats
	GROUP BY constructor_name, constructor_id, regulation_era
	HAVING SUM(constructor_race_entries) >= 30
)
SELECT
	regulation_era,
	constructor_name,
	ROUND(avg_race_grid, 2) AS avg_race_grid,
	ROUND(avg_race_finish, 2) AS avg_race_finish,
	ROUND(avg_pos_gain, 2) AS avg_pos_gain
FROM avg_pos_gain
WHERE era_pos_gain_rank = 1
ORDER BY avg_pos_gain DESC;


-- 4. Highest win % by constructor
WITH win_count AS (
	SELECT
		constructor_name,
		regulation_era,
		SUM(race_wins) AS total_wins,
		SUM(total_season_races) AS total_era_races,
		RANK() OVER(PARTITION BY regulation_era ORDER BY SUM(race_wins) DESC) AS era_wins_rank
	FROM gold.v_analytics_constructor_season_stats
	GROUP BY constructor_name, constructor_id, regulation_era
)
SELECT
	regulation_era,
	constructor_name,
	total_wins,
	ROUND(total_wins::numeric / NULLIF(total_era_races, 0)::numeric * 100, 2) AS era_race_wins_pct
FROM win_count
WHERE era_wins_rank = 1
ORDER BY era_race_wins_pct DESC;


-- 5. Biggest % of total points *(% out of all available points earned by all constructors) [biggest domination]*
WITH constructor_points_calc AS (
	SELECT
		constructor_name,
		regulation_era,
		SUM(total_points) AS constructor_total_era_points
	FROM gold.v_analytics_constructor_standings
	GROUP BY constructor_name, constructor_id, regulation_era
),

era_points_calc AS (
	SELECT
		*,
		SUM(constructor_total_era_points) OVER(PARTITION BY regulation_era) AS era_total_points
	FROM constructor_points_calc
),

constructor_points_share AS (
	SELECT 
		*,
		ROUND(constructor_total_era_points::numeric / NULLIF(era_total_points, 0)::numeric * 100, 2) AS points_share_pct
	FROM era_points_calc
),

era_rank AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY regulation_era ORDER BY points_share_pct DESC) AS era_points_share_rank
	FROM constructor_points_share
)
SELECT
	constructor_name,
	regulation_era,
	constructor_total_era_points,
	era_total_points,
	points_share_pct
FROM era_rank
WHERE era_points_share_rank = 1
ORDER BY points_share_pct DESC;


-- 6. Era constructors competitiveness *(how close were constructors points-wise to eachother)*
WITH constructor_era_shares AS (
	SELECT
		constructor_name,
		regulation_era,
		SUM(total_points) AS constructor_total_era_points,
		SUM(SUM(total_points)) OVER(PARTITION BY regulation_era) AS era_total_points,
		ROUND(SUM(total_points)::numeric / NULLIF(SUM(SUM(total_points)) OVER(PARTITION BY regulation_era), 0)::numeric * 100, 2) AS points_share_pct
	FROM gold.v_analytics_constructor_standings
	WHERE total_points > 0
	GROUP BY constructor_name, constructor_id, regulation_era
)
SELECT
	regulation_era,
	-- Spread between top 5 constructors 
	MAX(points_share_pct) - MIN(CASE WHEN share_rank <= 5 THEN points_share_pct END) AS top_5_spread,
	-- Full era spread 
	MAX(points_share_pct) - MIN(points_share_pct) AS full_era_spread
FROM (
	SELECT *, 
	       RANK() OVER(PARTITION BY regulation_era ORDER BY points_share_pct DESC) as share_rank
	FROM constructor_era_shares
) sub
GROUP BY regulation_era
ORDER BY top_5_spread ASC;

