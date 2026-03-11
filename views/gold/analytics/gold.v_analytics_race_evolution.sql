/*
VIEW: gold.v_analytics_race_evolution
PURPOSE:
    - Provides a cumulative performance evolution of drivers and constructors.
    - Tracks how performance metrics (averages, stability) change throughout a season.
    - Serves as the primary source for trend/dynamics analysis.
	
KEY BUSINESS & DATA LOGIC:
    - Isolates Main Race and Sprint Race metrics via session partitioning.
    - Calculates cumulative averages and standard deviations (Running Stats).
    - Computes 'Season Delta' (variance between current standing and final season average).

DATA HIERARCHY & GRAIN:
    - Granularity: One row per driver, per session_type, per race event.

SOURCE TABLES:
    - silver.v_driver_base
*/

CREATE OR REPLACE VIEW gold.v_analytics_race_evolution AS

WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, driver_id, session_type)
		year,
		race_id,
		round,
		session_type,
		circuit_id,
		circuit_name,
		driver_name,
		driver_id,
		constructor_name,
		constructor_id,
		engine_manufacturer,
		regulation_era,
		grid_position,
		finish_position,
		grid_position - finish_position AS pos_gain
	FROM silver.v_driver_base
	ORDER BY year, race_id, driver_id, session_type, finish_position ASC
),

cumulative_base AS (
    -- Calculating cumulative and seasonal averages
    SELECT 
        *,
        -- Driver Averages (Cumulative vs Seasonal)
        AVG(grid_position) OVER(PARTITION BY year, driver_id, session_type ORDER BY race_id) AS d_cum_avg_grid,
        AVG(grid_position) OVER(PARTITION BY year, driver_id, session_type) AS d_seas_avg_grid,
        
        AVG(finish_position) OVER(PARTITION BY year, driver_id, session_type ORDER BY race_id) AS d_cum_avg_finish,
        AVG(finish_position) OVER(PARTITION BY year, driver_id, session_type) AS d_seas_avg_finish,

        -- Constructor Averages (Cumulative vs Seasonal)
        AVG(grid_position) OVER(PARTITION BY year, constructor_id, session_type ORDER BY race_id) AS c_cum_avg_grid,
        AVG(grid_position) OVER(PARTITION BY year, constructor_id, session_type) AS c_seas_avg_grid,
        
        AVG(finish_position) OVER(PARTITION BY year, constructor_id, session_type ORDER BY race_id) AS c_cum_avg_finish,
        AVG(finish_position) OVER(PARTITION BY year, constructor_id, session_type) AS c_seas_avg_finish
    FROM unified_results
)
-- Calculating deviations (Standard Deviation i Delta)
SELECT
    year, 
	race_id, 
	round, 
	session_type, 
	circuit_id,
	circuit_name,
	driver_name,
	driver_id,
	constructor_name, 
	constructor_id,
	regulation_era,
	grid_position, 
	finish_position,

    -- Driver metrics
    ROUND(d_cum_avg_grid, 2) AS driver_cum_avg_grid,
    ROUND(STDDEV(grid_position) OVER(PARTITION BY year, driver_id, session_type ORDER BY race_id), 2) AS driver_cum_stddev_grid,
    ROUND(d_cum_avg_grid - d_seas_avg_grid, 2) AS driver_grid_season_delta,

    ROUND(d_cum_avg_finish, 2) AS driver_cum_avg_finish,
    ROUND(STDDEV(finish_position) OVER(PARTITION BY year, driver_id, session_type ORDER BY race_id), 2) AS driver_cum_stddev_finish,
    ROUND(d_cum_avg_finish - d_seas_avg_finish, 2) AS driver_finish_season_delta,

    -- Constructor metrics
    ROUND(c_cum_avg_grid, 2) AS constructor_cum_avg_grid,
    ROUND(STDDEV(grid_position) OVER(PARTITION BY year, constructor_id, session_type ORDER BY race_id), 2) AS constructor_cum_stddev_grid,
    ROUND(c_cum_avg_grid - c_seas_avg_grid, 2) AS constructor_grid_season_delta,

    ROUND(c_cum_avg_finish, 2) AS constructor_cum_avg_finish,
    ROUND(STDDEV(finish_position) OVER(PARTITION BY year, constructor_id, session_type ORDER BY race_id), 2) AS constructor_cum_stddev_finish,
    ROUND(c_cum_avg_finish - c_seas_avg_finish, 2) AS constructor_finish_season_delta
FROM cumulative_base;

