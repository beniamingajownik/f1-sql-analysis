/*
VIEW: gold.v_analytics_driver_career_summary
PURPOSE:
    - Provides a final, aggregated summary of driver statistics throughout a career.
    - Serves as the primary source for driver wins/podiums/dnf, dsq insights and championship titles.  
	
KEY BUSINESS & DATA LOGIC:
    - Calculates Main Race and Sprint Race starts, wins, podiums, pole positions and DNF/DSQ insight.
    - Joins seasonal standings to aggregate total World Drivers Championships (WDC).

DATA HIERARCHY & GRAIN:
    - Granularity: One row per driver 

SOURCE TABLES:
    - silver.v_driver_base
    - gold.v_analytics_driver_standings
*/

CREATE OR REPLACE VIEW gold.v_analytics_driver_career_summary AS

-- Selecting distinct driver results
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, session_type, driver_id)
		*
	FROM silver.v_driver_base
	ORDER BY year, race_id, session_type, driver_id, finish_position ASC
),

-- Aggregating championship titles (WDC)
driver_titles AS (
	SELECT 
		driver_id,
		COUNT(*) AS total_titles
	FROM gold.v_analytics_driver_standings
	WHERE season_position = 1
	GROUP BY driver_id
),

-- Creating flags which will be used for aggregation later on
place_logic AS (
	SELECT
		*,
		-- Pole Position
		CASE 
			WHEN grid_position = 1 AND session_type = 'RACE' THEN 1
		END is_pole_position,

		-- Sprint Pole Position
		CASE 
			WHEN grid_position = 1 AND session_type = 'SPRINT' THEN 1
		END is_sprint_pole_position,

		-- Main Race win
		CASE
			WHEN finish_position = 1 AND session_type = 'RACE' THEN 1
		END is_race_win,

		-- Sprint Race win
		CASE
			WHEN finish_position = 1 AND session_type = 'SPRINT' THEN 1
		END is_sprint_win,

		-- Main Race podium
		CASE 
			WHEN finish_position IN (1, 2, 3) AND session_type = 'RACE' THEN 1
		END is_race_podium,

		-- Sprint Race podium
		CASE 
			WHEN finish_position IN (1, 2, 3) AND session_type = 'SPRINT' THEN 1
		END is_sprint_podium,

		-- DNF Flag logic
		CASE 
			WHEN dnf_flag = 1 AND retirement_cause IN (	'Accident', 'Accident damage', 'Accident on formation lap', 'Broken floor', 'Broken wing', 
														'Collision', 'Collision damage', 'Failed to serve stop-go penalty', 'Fatal accident', 
														'Fatal collision', 'Spin', 'Spun off', 'Unfit', 'Unwell', 'Withdrew') 
														THEN 'Driver fault'
														
			WHEN dnf_flag = 1 THEN 'Car reliability'							
			
		END dnf_fault,

		-- DSQ Flag logic
		CASE 
			WHEN dsq_flag = 1 AND retirement_cause IN (	'Caused collision with Trulli', 'Driving too slowly', 'Failed to serve stop-go penalty', 'Ignored black flag', 
														'Ignored blue flags', 'Ignored red light', 'Ignored yellow flags', 'Ignored yellow flags in practice', 
														'Illegal start', 'Incorrect grid formation', 'Incorrect starting procedure', 'Misled stewards', 
														'Overtaking on formation lap', 'Rejoined track illegally', 'Reversed in pits') 
														THEN 'Driver fault'
														
			WHEN dsq_flag = 1 THEN 'Team fault'							

		END dsq_fault
		
	FROM unified_results
)
SELECT 
	pl.driver_name,
	pl.driver_id,
	COALESCE(dt.total_titles, 0) AS titles, -- Added WDC title count
	
	-- Final calculations (aggregation of flags)
	SUM(pl.points) AS total_points,
	
	-- Main Race stats
	COUNT(CASE WHEN pl.session_type = 'RACE' THEN 1 END) AS race_starts,
	COUNT(pl.is_pole_position) AS pole_positions,
	COUNT(pl.is_race_win) AS race_wins,
	COUNT(pl.is_race_podium) AS race_podiums,
	
	-- Sprint Race stats
	COUNT(CASE WHEN pl.session_type = 'SPRINT' THEN 1 END) AS sprint_starts,
	COUNT(pl.is_sprint_pole_position) AS sprint_pole_positions,
	COUNT(pl.is_sprint_win) AS sprint_wins,
	COUNT(pl.is_sprint_podium) AS sprint_podiums,
	
	-- DNF/DSQ stats
	COUNT(CASE WHEN pl.dnf_fault = 'Driver fault' THEN 1 END) AS driver_caused_dnf,
	COUNT(CASE WHEN pl.dnf_fault = 'Car reliability' THEN 1 END) AS car_caused_dnf,
	COUNT(CASE WHEN pl.dsq_fault = 'Driver fault' THEN 1 END) AS driver_caused_dsq,
	COUNT(CASE WHEN pl.dsq_fault = 'Team fault' THEN 1 END) AS car_caused_dsq,	
	COUNT(pl.dnf_fault) AS total_dnf,
	COUNT(pl.dsq_fault) AS total_dsq
FROM place_logic pl
LEFT JOIN driver_titles dt ON pl.driver_id = dt.driver_id
GROUP BY pl.driver_name, pl.driver_id, dt.total_titles;