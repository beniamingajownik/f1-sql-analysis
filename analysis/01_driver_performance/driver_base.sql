/*
VIEW: driver_base
PURPOSE:
    - Primary analytical "Golden Layer" providing a unified grain of Driver x Race.
    - Standardizes race results by abstracting complex joins and cleaning source data anomalies.
    - Serves as the single source of truth for all driver-related KPIs (conversion, reliability, pace).

KEY BUSINESS & DATA LOGIC:
    - Dynamic Grid Calculation: If a grid position is missing (Pit-Lane start or Qualifying DNS), 
      the grid_position is dynamically assigned to the total number of race entrants (rs.total_starters).
    - Pit-Lane Logic: Explicitly flags 'PL' starts and identifies drivers who bypassed the starting grid 
      using is_pitlane_start_flag (binary 1/0).
    - Reliability Tracking: dnf_flag (binary 1/0) consolidates non-classified finishes (DNF, NC, DSQ).
    - Entrant Accuracy: total_starters excludes 'DNS' (Did Not Start) to ensure the accuracy 
      of the calculated starting field size.

DATA HIERARCHY & GRAIN:
    - Granularity: One row per Driver per Grand Prix.
    - Filter: Restricted to official race events only (race_data.type = 'RACE_RESULT').

SOURCE TABLES:
    - race_data (Fact table)
    - race, driver, constructor (Dimensions)
    - country, continent (Geographical metadata)
*/

CREATE OR REPLACE VIEW driver_base AS
-- Count of drivers that started every race
WITH race_starters AS (
    SELECT 
		race_id, 
		COUNT(*) AS total_starters
    FROM race_data 
    WHERE type = 'RACE_RESULT' AND position_text != 'DNS' 
    GROUP BY race_id
),

-- Starting grid position of every driver at every Grand Prix that they raced in
grid_position AS (
    SELECT 	
		race_id, 
		driver_id, 
		position_number AS grid_pos,
		
-- Flagging drivers who started the race from pit-lane
		CASE
			WHEN position_text = 'PL' THEN 1
			ELSE 0
		END is_pitlane_start_flag	
    FROM race_data 
    WHERE type = 'STARTING_GRID_POSITION'
)
SELECT 
    r.year,
    rd.race_id,
    d.name AS driver_name,
	
-- Starting grid position (if a driver started from pit-lane then his starting position is last from all race entrants)
    COALESCE(g.grid_pos, rs.total_starters) AS grid_position,
	
    rd.position_number AS finish_position,
    rd.race_points AS points,
    cr.name AS team,
    cy.name AS driver_nationality,
	ct.name AS driver_continent,
	rs.total_starters,

-- Flagged drivers who started the race from pit-lane (including drivers who did not participate in qualifying but started the race)	
	COALESCE(g.is_pitlane_start_flag,0) AS is_pitlane_start_flag,

-- Flagging drivers who did not finish a race
    CASE 
		WHEN rd.position_text IN ('DNF', 'NC', 'DSQ') THEN 1 
		ELSE 0 
	END dnf_flag
		
FROM race_data rd
JOIN race r 
	ON rd.race_id = r.id
JOIN driver d 
	ON rd.driver_id = d.id
JOIN constructor cr 
	ON rd.constructor_id = cr.id
JOIN country cy 
	ON d.nationality_country_id = cy.id
JOIN continent ct
	ON cy.continent_id = ct.id
JOIN race_starters rs 
	ON rd.race_id = rs.race_id
LEFT JOIN grid_position g 
	ON rd.race_id = g.race_id AND rd.driver_id = g.driver_id
WHERE rd.type = 'RACE_RESULT';