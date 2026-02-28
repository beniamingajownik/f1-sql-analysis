/*
ANALYSIS: Constructor Race Dynamic
PURPOSE:
    - Exploratory insights about constructor Overtaking Efficiency, Mid-Season Progress and Stability of results.
	
KEY BUSINESS & DATA LOGIC:
	- Filters out Indy500 Race to focus on F1 teams who participated in most of the 'Early F1' era races.
    - Skips first 5 rounds in order to achieve more reliable standard deviation results.

SOURCE TABLES:
    - gold.v_analytics_race_evolution
*/

-- 1. Highest average position gain in a season (Constructor Overtaking Efficiency)
SELECT 
    year,
	constructor_name,
	regulation_era,
	ROUND(AVG(grid_position), 3) AS constructor_avg_grid,
	ROUND(AVG(finish_position), 3) AS constructor_avg_finish,
    ROUND(AVG(grid_position - finish_position), 3) AS constructor_avg_pos_gain
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE' 
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
	AND grid_position IS NOT NULL 
	AND finish_position IS NOT NULL
GROUP BY year, regulation_era, constructor_name, constructor_id
HAVING COUNT(*) > 25 
ORDER BY constructor_avg_pos_gain DESC
LIMIT 15;


-- 2. Highest average position gain in an era (Constructor Overtaking Efficiency)
SELECT 
    regulation_era,
    constructor_name,
	ROUND(AVG(grid_position), 3) AS constructor_avg_grid,
	ROUND(AVG(finish_position), 3) AS constructor_avg_finish,
    ROUND(AVG(grid_position - finish_position), 3) AS constructor_avg_pos_gain
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
  AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY regulation_era, constructor_name, constructor_id
HAVING COUNT(*) > 80 
ORDER BY constructor_avg_pos_gain DESC
LIMIT 15;


-- 3. Qualifying Volatility in a season
-- High stddev in qualifying suggests a car that is hard to set up / track-dependent or the second driver lacks performance.
SELECT 
    year,
    constructor_name,
	regulation_era,
    ROUND(AVG(constructor_cum_stddev_grid), 3) AS qualifying_volatility,
    ROUND(AVG(grid_position), 3) AS avg_constructor_grid
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
 	AND round > 5 -- Skipping first 5 rounds in order to achieve more reliable stddev
GROUP BY year, constructor_name, constructor_id, regulation_era
HAVING COUNT(*) > 25
ORDER BY qualifying_volatility DESC
LIMIT 15;


-- 4. Race finish position volatility in a season
-- High stddev in qualifying suggests a car that is hard to set up / track-dependent or the second driver lacks performance.
SELECT 
	year,
    regulation_era,
    constructor_name,
    ROUND(AVG(constructor_cum_stddev_finish), 3) AS finish_pos_volatility,
    ROUND(AVG(finish_position), 3) AS avg_constructor_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
  	AND round > 5 -- Skipping first 5 rounds in order to achieve more reliable stddev
GROUP BY year, regulation_era, constructor_id, constructor_name
HAVING COUNT(*) > 25
ORDER BY finish_pos_volatility DESC
LIMIT 15;


-- 5. Race finish position volatility in an era
-- High stddev in qualifying suggests a car that is hard to set up / track-dependent or the second driver lacks performance.
SELECT 
    regulation_era,
    constructor_name,
    ROUND(AVG(constructor_cum_stddev_finish), 3) AS finish_pos_volatility,
    ROUND(AVG(finish_position), 3) AS avg_constructor_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
  	AND round > 5 -- Skipping first 5 rounds in order to achieve more reliable stddev
GROUP BY regulation_era, constructor_id, constructor_name
HAVING COUNT(*) > 80
ORDER BY finish_pos_volatility DESC
LIMIT 15;


-- 6. Qualifying position improvement in a season (Mid-Season Progress)
-- Measures technical progress in qualifying relative to the seasonal mean (negative values mean qualifying better than season average).
SELECT 
    year,
	regulation_era,
    constructor_name,
    ROUND(AVG(constructor_grid_season_delta), 3) AS qualy_development_index
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
  AND round > total_season_races / 2.0
  AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY year, constructor_name, constructor_id, regulation_era
HAVING COUNT(*) > 25
ORDER BY qualy_development_index ASC
LIMIT 15;


-- 7. Race position improvement in a season (Mid-Season Progress)
-- Measures technical progress in qualifying relative to the seasonal mean (negative values mean qualifying better than season average).
SELECT 
    year,
	regulation_era,
    constructor_name,
    ROUND(AVG(constructor_finish_season_delta), 3) AS race_development_index
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
  AND round > total_season_races / 2.0
  AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY year, constructor_name, constructor_id, regulation_era
HAVING COUNT(*) > 25
ORDER BY race_development_index ASC
LIMIT 15;


-- 8. Race position improvement in an era (Mid-Season Progress)
-- Measures technical progress in qualifying relative to the seasonal mean (negative values mean qualifying better than season average).
SELECT 
	regulation_era,
    constructor_name,
    ROUND(AVG(constructor_finish_season_delta), 3) AS race_development_index
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
  AND round > total_season_races / 2.0
  AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY constructor_name, constructor_id, regulation_era
HAVING COUNT(*) > 80
ORDER BY race_development_index ASC
LIMIT 15;


-- 9. Season race position stability (Stability of results across a Season)
SELECT 
	year,
    regulation_era,
    constructor_name,
    ROUND(AVG(constructor_cum_stddev_finish), 3) AS season_finishing_stability,
    ROUND(AVG(finish_position), 3) AS season_avg_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY year, regulation_era, constructor_name, constructor_id
HAVING COUNT(*) > 25 
ORDER BY season_avg_finish ASC, season_finishing_stability ASC
LIMIT 15;


-- 10. Era race position stability (Stability of results across Regulation Eras)
SELECT 
    regulation_era,
    constructor_name,
    ROUND(AVG(constructor_cum_stddev_finish), 3) AS era_finishing_stability,
    ROUND(AVG(finish_position), 3) AS era_avg_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY regulation_era, constructor_name, constructor_id
HAVING COUNT(*) > 80 
ORDER BY era_avg_finish ASC, era_finishing_stability ASC
LIMIT 15;