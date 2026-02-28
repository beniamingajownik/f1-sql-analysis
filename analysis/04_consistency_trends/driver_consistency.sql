/*
ANALYSIS: Driver Consistency
PURPOSE:
    - Exploratory insights about driver consistency throughout each season and consistency related achievements
		like point scoring / win streaks. 
	
KEY BUSINESS & DATA LOGIC:
	- Filters out high-retirement seasons (< 20% DNF) to focus on driver-controlled performance.
    - Validates race sequence integrity (DNS/Injury handling) to ensure streak accuracy.
    - Standardizes consistency scores for cross-era comparisons.

SOURCE TABLES:
    - silver.v_driver_base
*/

-- 1. Most consistent drivers in Main Races (Mean Absolute Deviation (MAD))
-- *Taking into account only drivers who entered more than half of a season races and had retirement % of less than 20%*
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, driver_id)
		year,
		race_id,
		round,
		regulation_era,
		circuit_name,
		driver_name,
		driver_id,
		finish_position,
		MAX(round) OVER(PARTITION BY year) AS total_season_rounds,
		CASE WHEN retirement_cause != 'NONE' OR finish_position IS NULL THEN 1 ELSE 0 END race_retirement
	FROM silver.v_driver_base
	WHERE session_type = 'RACE'
	ORDER BY year, race_id, driver_id, finish_position ASC
),

race_finishes AS (
	SELECT
		*,
		-- Driver retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year, driver_id)::numeric / 
			NULLIF(COUNT(driver_id) OVER(PARTITION BY year, driver_id), 0) * 100::numeric) AS driver_dnf_pct,

		-- Overall driver retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year)::numeric / 
			NULLIF(COUNT(race_id) OVER(PARTITION BY year), 0) * 100::numeric) AS grid_dnf_pct
	FROM unified_results
),

variability_calc AS (
	SELECT 
		*,
		AVG(finish_position) OVER(PARTITION BY year, driver_id) AS avg_pos,
		ABS(ROUND(AVG(finish_position) OVER(PARTITION BY year, driver_id), 2) - finish_position::numeric) AS pos_variability,
		COUNT(driver_id) OVER(PARTITION BY year, driver_id) AS race_entries
	FROM race_finishes
)
SELECT
	year,
	driver_name,
	regulation_era,
	ROUND(AVG(avg_pos), 2) AS season_avg_finish,
	ROUND(AVG(pos_variability), 2) AS avg_variability,
	race_entries || '/' || total_season_rounds AS season_participation,
	ROUND(driver_dnf_pct, 2) AS driver_dnf_pct,
	ROUND(grid_dnf_pct, 2) AS grid_dnf_pct
FROM variability_calc
-- Analyzing only the drivers who completed more than half of a season
WHERE race_entries > total_season_rounds / 2
GROUP BY year, driver_name, driver_id, regulation_era, avg_pos, race_entries, total_season_rounds, driver_dnf_pct, grid_dnf_pct
HAVING driver_dnf_pct < 20
ORDER BY avg_variability ASC , season_avg_finish ASC;


-- 2. Standard deviation of finishing positions
-- *Taking into account only drivers who entered more than half of a season races and had retirement % of less than 20%*
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, driver_id)
		year,
		race_id,
		round,
		regulation_era,
		circuit_name,
		driver_name,
		driver_id,
		finish_position,
		
		MAX(round) OVER(PARTITION BY year) AS total_season_rounds,
		CASE WHEN retirement_cause != 'NONE' OR finish_position IS NULL THEN 1 ELSE 0 END race_retirement
	FROM silver.v_driver_base
	WHERE session_type = 'RACE' 
	ORDER BY year, race_id, driver_id, finish_position ASC
),

race_finishes AS (
	SELECT
		*,
		-- Driver retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year, driver_id)::numeric / 
			NULLIF(COUNT(driver_id) OVER(PARTITION BY year, driver_id), 0) * 100::numeric) AS driver_dnf_pct,

		-- Overall driver retirement % per season
		(SUM(race_retirement) OVER(PARTITION BY year)::numeric / 
			NULLIF(COUNT(race_id) OVER(PARTITION BY year), 0) * 100::numeric) AS grid_dnf_pct
	FROM unified_results
),

variability_calc AS (
	SELECT 
		*,
		AVG(finish_position) OVER(PARTITION BY year, driver_id) AS avg_pos,
		STDDEV(finish_position) OVER(PARTITION BY year, driver_id) AS std_dev_pos,
		COUNT(driver_id) OVER(PARTITION BY year, driver_id) AS race_entries
	FROM race_finishes
)
SELECT
	year,
	driver_name,
	regulation_era,
	ROUND(AVG(avg_pos), 2) AS season_avg_finish,
	ROUND(AVG(std_dev_pos), 2) AS consistency_score, 
	race_entries || '/' || total_season_rounds AS season_participation,
	ROUND(driver_dnf_pct, 2) AS driver_dnf_pct,
	ROUND(grid_dnf_pct, 2) AS grid_dnf_pct
FROM variability_calc
WHERE race_entries > total_season_rounds / 2
GROUP BY year, driver_name, driver_id, regulation_era, race_entries, total_season_rounds, driver_dnf_pct, grid_dnf_pct
HAVING driver_dnf_pct < 20
ORDER BY consistency_score ASC, season_avg_finish ASC;


-- 3. Number of consecutive points finishes (Main Races only)
WITH race_check AS (
	SELECT
		year,
		race_id,
		date,
		regulation_era,
		driver_name,
		driver_id,
		points,

		-- Defining previous race entered by a driver
		LAG(race_id) OVER(PARTITION BY driver_id ORDER BY date ASC) AS drivers_prev_race,

		-- Defining previous official race held
		LAG(points) OVER(PARTITION BY driver_id ORDER BY date ASC) AS prev_points,
		(race_id - 1) AS prev_race
	FROM silver.v_driver_base
	WHERE session_type = 'RACE'
),

streak AS (
	SELECT
		*,
		-- Streak logic
		SUM(CASE 
				WHEN prev_points = 0 THEN 1
				WHEN prev_race != drivers_prev_race THEN 1
				WHEN drivers_prev_race IS NULL THEN 1
			ELSE 0 END) OVER(PARTITION BY driver_id ORDER BY date ASC) AS streak_id
	FROM race_check
)
SELECT 
	driver_name,
	regulation_era,
	MAX(streak_duration) AS longest_streak
FROM (
		SELECT
			driver_name,
			driver_id,
			regulation_era,
			-- Count of every point streak duration per driver
			COUNT(*) AS streak_duration
		FROM streak
		WHERE points > 0 
		GROUP BY driver_id, driver_name, regulation_era, streak_id
) streak_dur_sub
GROUP BY driver_id, driver_name, regulation_era
HAVING MAX(streak_duration) > 10
ORDER BY longest_streak DESC
LIMIT 10;

	
-- 4. Longest streak of classified race finishes
WITH retirement_check AS (
	SELECT
		year,
		race_id,
		round,
		date,
		regulation_era,
		circuit_name,
		driver_name,
		driver_id,
		finish_position,
		CASE WHEN retirement_cause != 'NONE' THEN 1 ELSE 0 END is_retired,
		LAG(race_id) OVER(PARTITION BY driver_id ORDER BY date ASC) AS drivers_prev_race,
		LAG(retirement_cause) OVER(PARTITION BY driver_id ORDER BY date ASC) AS retirement_prev_race
	FROM silver.v_driver_base
	WHERE session_type = 'RACE'
),

streak AS (
	SELECT
		*,
		SUM(CASE 
				WHEN is_retired = 1 THEN 1
				WHEN drivers_prev_race IS NULL THEN 1
				WHEN drivers_prev_race != race_id - 1 THEN 1 
			ELSE 0 END
				) OVER(PARTITION BY driver_id ORDER BY date ASC) AS streak_id
	FROM retirement_check
)
SELECT 
	driver_name,
	regulation_era,
	MAX(streak_duration) AS race_finish_streak
FROM (
	SELECT
		driver_name,
		driver_id,
		regulation_era,
		streak_id,
		COUNT(*) AS streak_duration
	FROM streak
	WHERE is_retired = 0
	GROUP BY driver_id, driver_name, regulation_era, streak_id
)
GROUP BY driver_name, driver_id, regulation_era
HAVING MAX(streak_duration) > 10
ORDER BY race_finish_streak DESC;


-- 5. Longest win streaks
WITH win_check AS (
	SELECT
		year,
		race_id,
		round,
		date,
		regulation_era,
		circuit_name,
		driver_name,
		driver_id,
		finish_position,
		CASE WHEN finish_position = 1 THEN 1 ELSE 0 END is_race_win,
		LAG(race_id) OVER(PARTITION BY driver_id ORDER BY date ASC) AS drivers_prev_race
	FROM silver.v_driver_base
	WHERE session_type = 'RACE'
),

streak AS (
	SELECT 
		*,
		SUM(CASE
				WHEN is_race_win = 0 THEN 1 
				WHEN drivers_prev_race != race_id - 1 THEN 1
				WHEN drivers_prev_race IS NULL THEN 1
			ELSE 0 END
				) OVER(PARTITION BY driver_id ORDER BY date ASC) AS streak_id
	FROM win_check
)
SELECT 
	driver_name,
	regulation_era,
	MAX(streak_duration) AS race_win_streak
FROM (
	SELECT
		driver_name,
		driver_id,
		regulation_era,
		streak_id,
		COUNT(*) AS streak_duration
	FROM streak
	WHERE is_race_win = 1
	GROUP BY driver_name, driver_id, regulation_era, streak_id
)
GROUP BY driver_id, driver_name, regulation_era
HAVING MAX(streak_duration) > 3
ORDER BY race_win_streak DESC
LIMIT 10;


-- 6. Longest podium streaks
WITH podium_check AS (
	SELECT
		year,
		race_id,
		round,
		date,
		regulation_era,
		circuit_name,
		driver_name,
		driver_id,
		finish_position,
		CASE WHEN finish_position IN (1, 2, 3) THEN 1 ELSE 0 END is_race_podium,
		LAG(race_id) OVER(PARTITION BY driver_id ORDER BY date ASC) AS drivers_prev_race
	FROM silver.v_driver_base
	WHERE session_type = 'RACE'
),

streak AS (
	SELECT 
		*,
		SUM(CASE
				WHEN is_race_podium = 0 THEN 1 
				WHEN drivers_prev_race != race_id - 1 THEN 1
				WHEN drivers_prev_race IS NULL THEN 1
			ELSE 0 END
				) OVER(PARTITION BY driver_id ORDER BY date ASC) AS streak_id
	FROM podium_check
)
SELECT 
	driver_name,
	regulation_era,
	MAX(streak_duration) AS race_podium_streak
FROM (
	SELECT
		driver_name,
		driver_id,
		regulation_era,
		streak_id,
		COUNT(*) AS streak_duration
	FROM streak
	WHERE is_race_podium = 1
	GROUP BY driver_name, driver_id, regulation_era, streak_id
)
GROUP BY driver_id, driver_name, regulation_era
HAVING MAX(streak_duration) > 3
ORDER BY race_podium_streak DESC
LIMIT 10;

