/*
VIEW: v_analytics_constructor_career_summary
PURPOSE:
    - Provides a final, aggregated summary of constructor statistic throughout a career.
	- Serves as the primary source for constructor wins/podiums/dnf,dsq insights.  
	
KEY BUSINESS & DATA LOGIC:
	- Calculates Main Race and Sprint Race starts, wins, podiums, pole positions and DNF/DSQ insight (driver/teams fault) 

DATA HIERARCHY & GRAIN:
    - Granularity: One row per constructor 

SOURCE TABLES:
    - v_constructor_base
*/

CREATE OR REPLACE VIEW v_analytics_constructor_career_summary AS

-- Selecting distinct constructor results (in case of multiple rows per driver per race)
WITH unified_results AS (
	SELECT DISTINCT ON (year, race_id, session_type, constructor_id)
		*
	FROM v_constructor_base
	ORDER BY year, race_id, session_type, constructor_id, finish_position ASC
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

		-- DNF Flag (distinguishing who caused the DNF for e.g. was it a car reliability issue or a drivers mistake)
		CASE 
			WHEN dnf_flag = 1 AND retirement_cause IN (	'Accident', 'Accident damage', 'Accident on formation lap', 'Broken floor', 'Broken wing', 
														'Collision', 'Collision damage', 'Failed to serve stop-go penalty', 'Fatal accident', 
														'Fatal collision', 'Spin', 'Spun off', 'Unfit', 'Unwell', 'Withdrew') 
														THEN 'Driver fault'
														
			WHEN dnf_flag = 1 THEN 'Car reliability'							
			
		END dnf_fault,

		-- DSQ Flag (distinguishing who caused the DSQ for e.g. was it a car regulation breach or a drivers reckless driving / not obeying to rules etc.)
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
	constructor_name,
	constructor_id,
	
-- Final calculations (aggregation of flags)
	-- Total points scored per constructor (including dropped results from 1950 - 1989 Era)
	SUM(points) AS total_points,
	
	-- Main Race stats
	COUNT(CASE WHEN session_type = 'RACE' THEN 1 END) AS race_starts,
	COUNT(is_pole_position) AS pole_positions,
	COUNT(is_race_win) AS race_wins,
	COUNT(is_race_podium) AS race_podiums,
	
	-- Sprint Race stats
	COUNT(CASE WHEN session_type = 'SPRINT' THEN 1 END) AS sprint_starts,
	COUNT(is_sprint_pole_position) AS sprint_pole_positions,
	COUNT(is_sprint_win) AS sprint_wins,
	COUNT(is_sprint_podium) AS sprint_podiums,
	
	-- DNF/DSQ stats
	COUNT(CASE WHEN dnf_fault = 'Driver fault' THEN 1 END) AS driver_caused_dnf,
	COUNT(CASE WHEN dnf_fault = 'Car reliability' THEN 1 END) AS car_caused_dnf,
	COUNT(CASE WHEN dsq_fault = 'Driver fault' THEN 1 END) AS driver_caused_dsq,
	COUNT(CASE WHEN dsq_fault = 'Team fault' THEN 1 END) AS car_caused_dsq	
FROM place_logic
GROUP BY constructor_name, constructor_id;