/*
ANALYSIS: Driver Race Dynamics
PURPOSE:
	- Exploratory insights about driver Overtaking Efficiency, Mid-Season Progress and Stability of results.

KEY BUSINESS & DATA LOGIC:
	- Filters out Indy500 Race to focus on F1 drivers who participated in most of the 'Early F1' era races.
	- Skips first 5 rounds in order to achieve more reliable standard deviation results.

SOURCE TABLES:
	- gold.v_analytics_race_evolution
*/

-- 1. Highest average position gain in a season (Driver Overtaking Efficiency)
SELECT
	year,
	driver_name,
	regulation_era,
	ROUND(AVG(grid_position), 3) AS driver_avg_grid,
	ROUND(AVG(finish_position), 3) AS driver_avg_finish,
	ROUND(AVG(grid_position - finish_position), 3) AS driver_avg_pos_gain
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
	AND grid_position IS NOT NULL
	AND finish_position IS NOT NULL
GROUP BY year, regulation_era, driver_name, driver_id
HAVING COUNT(*) > 12
ORDER BY driver_avg_pos_gain DESC
LIMIT 15;


-- 2. Highest average position gain in an era (Driver Overtaking Efficiency)
SELECT
	regulation_era,
	driver_name,
	ROUND(AVG(grid_position), 3) AS driver_avg_grid,
	ROUND(AVG(finish_position), 3) AS driver_avg_finish,
	ROUND(AVG(grid_position - finish_position), 3) AS driver_avg_pos_gain
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY regulation_era, driver_name, driver_id
HAVING COUNT(*) > 40
ORDER BY driver_avg_pos_gain DESC
LIMIT 15;


-- 3. Qualifying Volatility in a season
-- High stddev in qualifying suggests a driver who is inconsistent in one-lap pace or struggles with car setup.
SELECT
	year,
	driver_name,
	regulation_era,
	ROUND(AVG(driver_cum_stddev_grid), 3) AS qualifying_volatility,
	ROUND(AVG(grid_position), 3) AS avg_driver_grid
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
	AND round > 5
GROUP BY year, driver_name, driver_id, regulation_era
HAVING COUNT(*) > 12
ORDER BY qualifying_volatility DESC
LIMIT 15;


-- 4. Race finish position volatility in a season
-- High stddev suggests inconsistent race pace, frequent incidents, or technical issues.
SELECT
year,
	regulation_era,
	driver_name,
	ROUND(AVG(driver_cum_stddev_finish), 3) AS finish_pos_volatility,
	ROUND(AVG(finish_position), 3) AS avg_driver_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
	AND round > 5
GROUP BY year, regulation_era, driver_id, driver_name
HAVING COUNT(*) > 12
ORDER BY finish_pos_volatility DESC
LIMIT 15;


-- 5. Race finish position volatility in an era
SELECT
	regulation_era,
	driver_name,
	ROUND(AVG(driver_cum_stddev_finish), 3) AS finish_pos_volatility,
	ROUND(AVG(finish_position), 3) AS avg_driver_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
	AND round > 5
GROUP BY regulation_era, driver_id, driver_name
HAVING COUNT(*) > 40
ORDER BY finish_pos_volatility DESC
LIMIT 15;


-- 6. Qualifying position improvement in a season (Mid-Season Progress)
-- Measures driver progress in qualifying relative to the seasonal mean (negative values mean qualifying better than season average).
SELECT
	year,
	regulation_era,
	driver_name,
	ROUND(AVG(driver_grid_season_delta), 3) AS qualy_development_index
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND round > total_season_races / 2.0
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY year, driver_name, driver_id, regulation_era
HAVING COUNT(*) > 7
ORDER BY qualy_development_index ASC
LIMIT 15;


-- 7. Race position improvement in a season (Mid-Season Progress)
SELECT
	year,
	regulation_era,
	driver_name,
	ROUND(AVG(driver_finish_season_delta), 3) AS race_development_index
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND round > total_season_races / 2.0
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY year, driver_name, driver_id, regulation_era
HAVING COUNT(*) > 7
ORDER BY race_development_index ASC
LIMIT 15;


-- 8. Race position improvement in an era (Mid-Season Progress)
SELECT
	regulation_era,
	driver_name,
	ROUND(AVG(driver_finish_season_delta), 3) AS race_development_index
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
	AND round > total_season_races / 2
	AND circuit_name != 'Indianapolis' -- Excluding Indy 500 races
GROUP BY driver_name, driver_id, regulation_era
HAVING COUNT(*) > 40
ORDER BY race_development_index ASC
LIMIT 15;


-- 9. Season race position stability (Stability of results across a Season)
SELECT
	year,
	regulation_era,
	driver_name,
	ROUND(AVG(driver_cum_stddev_finish), 3) AS season_finishing_stability,
	ROUND(AVG(finish_position), 3) AS season_avg_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE'
GROUP BY year, regulation_era, driver_name, driver_id
HAVING COUNT(*) > 12
ORDER BY season_avg_finish ASC, season_finishing_stability ASC
LIMIT 15;


-- 10. Era race position stability (Stability of results across Regulation Eras)
SELECT
	regulation_era,
	driver_name,
	ROUND(AVG(driver_cum_stddev_finish), 3) AS era_finishing_stability,
	ROUND(AVG(finish_position), 3) AS era_avg_finish
FROM gold.v_analytics_race_evolution
WHERE session_type = 'RACE' 
GROUP BY regulation_era, driver_name, driver_id
HAVING COUNT(*) > 40
ORDER BY era_avg_finish ASC, era_finishing_stability ASC
LIMIT 15;