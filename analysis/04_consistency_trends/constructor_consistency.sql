/*
ANALYSIS: Constructor Consistency
PURPOSE:
    - Exploratory insights about constructor consistency throughout each season and consistency related achievements
		like point scoring / win streaks. 
	
KEY BUSINESS & DATA LOGIC:
	- Filters out high-retirement seasons (< 20% DNF) to focus on driver-controlled performance.
    - Validates race sequence integrity (DNS/Injury handling) to ensure streak accuracy.
    - Standardizes consistency scores for cross-era comparisons.

SOURCE TABLES:
    - silver.v_constructor_base
*/

-- 1. Most consistent constructor in Main Races (Mean Absolute Deviation (MAD))
-- *Taking into account only constructors who entered more than 75% of season races and had retirement % of less than 20%*
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, driver_id)
		year,
		race_id,
		round,
		regulation_era,
		circuit_name,
		constructor_name,
		constructor_id,
		driver_id,
		finish_position,
		MAX(round) OVER(PARTITION BY year) AS total_season_rounds,
		CASE WHEN retirement_cause != 'NONE' OR finish_position IS NULL THEN 1 ELSE 0 END race_retirement
	FROM silver.v_constructor_base
	WHERE session_type = 'RACE'
	ORDER BY year, race_id, driver_id, finish_position ASC
),

race_finishes AS (
	SELECT
		*,
		-- Constructor retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year, constructor_id)::numeric / 
			NULLIF(COUNT(driver_id) OVER(PARTITION BY year, constructor_id), 0) * 100::numeric) AS constructor_dnf_pct,

		-- Overall constructor retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year)::numeric / 
			NULLIF(COUNT(race_id) OVER(PARTITION BY year), 0) * 100::numeric) AS grid_dnf_pct
	FROM unified_results
),

variability_calc AS (
	SELECT 
		*,
		AVG(finish_position) OVER(PARTITION BY year, constructor_id) AS avg_pos,
		ABS(ROUND(AVG(finish_position) OVER(PARTITION BY year, constructor_id), 2) - finish_position::numeric) AS pos_variability,
		COUNT(driver_id) OVER(PARTITION BY year, constructor_id) AS race_entries
	FROM race_finishes
)
SELECT
	year,
	constructor_name,
	regulation_era,
	ROUND(AVG(avg_pos), 2) AS season_avg_finish,
	ROUND(AVG(pos_variability), 2) AS avg_variability,
	race_entries || '/' || total_season_rounds AS season_participation,
	ROUND(constructor_dnf_pct, 2) AS constructor_dnf_pct,
	ROUND(grid_dnf_pct, 2) AS grid_dnf_pct
FROM variability_calc
-- Analyzing only the constructors who competed in more than 75% of the season
WHERE race_entries > (total_season_rounds * 1.5) 
GROUP BY year, constructor_name, constructor_id, regulation_era, avg_pos, race_entries, total_season_rounds, constructor_dnf_pct, grid_dnf_pct
HAVING constructor_dnf_pct < 20
ORDER BY avg_variability ASC , season_avg_finish ASC;


-- 2. Standard deviation of finishing positions
-- *Taking into account only constructors who entered more than 75% of season races and had retirement % of less than 20%*
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, driver_id)
		year,
		race_id,
		round,
		regulation_era,
		circuit_name,
		constructor_name,
		constructor_id,
		driver_id,
		finish_position,
		
		MAX(round) OVER(PARTITION BY year) AS total_season_rounds,
		CASE WHEN retirement_cause != 'NONE' OR finish_position IS NULL THEN 1 ELSE 0 END race_retirement
	FROM silver.v_constructor_base
	WHERE session_type = 'RACE' 
	ORDER BY year, race_id, driver_id, finish_position ASC
),

race_finishes AS (
	SELECT
		*,
		-- Constructor retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year, constructor_id)::numeric / 
			NULLIF(COUNT(driver_id) OVER(PARTITION BY year, constructor_id), 0) * 100::numeric) AS constructor_dnf_pct,

		-- Overall constructor retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year)::numeric / 
			NULLIF(COUNT(race_id) OVER(PARTITION BY year), 0) * 100::numeric) AS grid_dnf_pct
	FROM unified_results
),

variability_calc AS (
	SELECT 
		*,
		AVG(finish_position) OVER(PARTITION BY year, constructor_id) AS avg_pos,
		STDDEV(finish_position) OVER(PARTITION BY year, constructor_id) AS std_dev_pos,
		COUNT(driver_id) OVER(PARTITION BY year, constructor_id) AS race_entries
	FROM race_finishes
)
SELECT
	year,
	constructor_name,
	constructor_id,
	regulation_era,
	ROUND(AVG(avg_pos), 2) AS season_avg_finish,
	ROUND(AVG(std_dev_pos), 2) AS consistency_score, 
	race_entries || '/' || total_season_rounds AS season_participation,
	ROUND(constructor_dnf_pct, 2) AS constructor_dnf_pct,
	ROUND(grid_dnf_pct, 2) AS grid_dnf_pct
FROM variability_calc
WHERE race_entries > (total_season_rounds * 1.5)
GROUP BY year, constructor_name, constructor_id, regulation_era, race_entries, total_season_rounds, constructor_dnf_pct, grid_dnf_pct
HAVING constructor_dnf_pct < 20
ORDER BY consistency_score ASC, season_avg_finish ASC;


-- 3. Number of consecutive points finishes (Main Races only)
-- *At least one constructor car finished the race in the points scoring position*
WITH race_check AS (
	SELECT
		year,
		race_id,
		regulation_era,
		constructor_name,
		constructor_id,

		-- Defining previous race entered by a constructor
		LAG(race_id) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS constructor_prev_race,

		-- Defining previous official race held
		LAG(MAX(points)) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS prev_points,
		MAX(points) AS points,
		(race_id - 1) AS prev_race
	FROM silver.v_constructor_base
	WHERE session_type = 'RACE'
	GROUP BY year, race_id, regulation_era, constructor_name, constructor_id
	HAVING MAX(points) > 0
),

streak AS (
	SELECT
		*,
		-- Streak logic
		SUM(CASE 
				WHEN prev_points IS NULL THEN 1
				WHEN prev_race != constructor_prev_race THEN 1
				WHEN constructor_prev_race IS NULL THEN 1
			ELSE 0 END) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS streak_id
	FROM race_check
)
SELECT 
	constructor_name,
	regulation_era,
	MAX(streak_duration) AS longest_streak
FROM (
		SELECT
			constructor_name,
			constructor_id,
			STRING_AGG(DISTINCT regulation_era, ' / ') AS regulation_era,
			-- Count of every point streak duration per driver
			COUNT(*) AS streak_duration
		FROM streak
		GROUP BY constructor_id, constructor_name, streak_id
) streak_dur_sub
GROUP BY constructor_id, constructor_name, regulation_era
HAVING MAX(streak_duration) > 10
ORDER BY longest_streak DESC
LIMIT 10;

	
-- 4. Longest streak of classified race finishes
-- *At least one constructor car finished the race*
WITH race_finishes AS (
	SELECT
		year,
		race_id,
		regulation_era,
		constructor_name,
		constructor_id,

		-- Defining previous race entered by a constructor
		LAG(race_id) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS constructor_prev_race
	FROM silver.v_constructor_base
	WHERE 	session_type = 'RACE' AND 
			finish_position IS NOT NULL AND 
			retirement_cause = 'NONE' AND 
			dnf_flag = 0 AND 
			dsq_flag = 0
	GROUP BY year, race_id, regulation_era, constructor_name, constructor_id
),

streak AS (
	SELECT
		*,
		-- Streak logic
		SUM(CASE 
				WHEN constructor_prev_race IS NULL THEN 1
				WHEN constructor_prev_race != race_id - 1 THEN 1 
			ELSE 0 END
				) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS streak_id
	FROM race_finishes
)
SELECT 
	years,
	constructor_name,
	regulation_era,
	MAX(streak_duration) AS race_finish_streak
FROM (
	SELECT
		constructor_name,
		constructor_id,
		STRING_AGG(DISTINCT regulation_era, ' / ') AS regulation_era,
		MIN(year) || ' - ' || MAX(year) AS years,
		streak_id,
		COUNT(*) AS streak_duration
	FROM streak
	GROUP BY constructor_id, constructor_name, streak_id
)
GROUP BY constructor_id, constructor_name, regulation_era, years
HAVING MAX(streak_duration) > 10
ORDER BY race_finish_streak DESC
LIMIT 10;


-- 5. Longest win streaks
WITH win_check AS (
	SELECT
		year,
		race_id,
		round,
		regulation_era,
		circuit_name,
		constructor_name,
		constructor_id,
		
		-- Defining previous race entered by a constructor
		LAG(race_id) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS constructor_prev_race
	FROM silver.v_constructor_base
	WHERE session_type = 'RACE' AND finish_position = 1
	GROUP BY year, race_id, round, regulation_era, circuit_name, constructor_name, constructor_id
),

streak AS (
	SELECT 
		*,
		SUM(CASE 
				WHEN constructor_prev_race != race_id - 1 THEN 1
				WHEN constructor_prev_race IS NULL THEN 1
			ELSE 0 END
				) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS streak_id
	FROM win_check
)
SELECT 
	years,
	constructor_name,
	regulation_era,
	MAX(streak_duration) AS race_win_streak
FROM (
	SELECT
		constructor_name,
		constructor_id,
		STRING_AGG(DISTINCT regulation_era, ' / ') AS regulation_era,
		MIN(year) || ' - ' || MAX(year) AS years,
		streak_id,
		COUNT(*) AS streak_duration
	FROM streak
	GROUP BY constructor_id, constructor_name, streak_id
)
GROUP BY constructor_id, constructor_name, years, regulation_era
HAVING MAX(streak_duration) > 3
ORDER BY race_win_streak DESC
LIMIT 10;


-- 6. Longest podium streaks
-- *At least one constructor car finished the race on the podium*
WITH podium_check AS (
	SELECT
		year,
		race_id,
		round,
		regulation_era,
		circuit_name,
		constructor_name,
		constructor_id,
		
		-- Defining previous race entered by a constructor
		LAG(race_id) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS constructor_prev_race
	FROM silver.v_constructor_base
	WHERE session_type = 'RACE' AND finish_position IN (1, 2, 3)
	GROUP BY year, race_id, round, regulation_era, circuit_name, constructor_name, constructor_id
),

streak AS (
	SELECT 
		*,
		SUM(CASE 
				WHEN constructor_prev_race != race_id - 1 THEN 1
				WHEN constructor_prev_race IS NULL THEN 1
			ELSE 0 END
				) OVER(PARTITION BY constructor_id ORDER BY race_id ASC) AS streak_id
	FROM podium_check
)
SELECT 
	years,
	constructor_name,
	regulation_era,
	MAX(streak_duration) AS race_podium_streak
FROM (
	SELECT
		constructor_name,
		constructor_id,
		STRING_AGG(DISTINCT regulation_era, ' / ') AS regulation_era,
		MIN(year) || ' - ' || MAX(year) AS years,
		streak_id,
		COUNT(*) AS streak_duration
	FROM streak
	GROUP BY constructor_id, constructor_name, streak_id
)
GROUP BY constructor_id, constructor_name, years, regulation_era
HAVING MAX(streak_duration) > 3
ORDER BY race_podium_streak DESC
LIMIT 10;

