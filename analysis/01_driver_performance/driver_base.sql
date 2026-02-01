/*
VIEW: driver_base
PURPOSE:
    - Primary analytical view at driver x session grain (including Sprint and Main Race).
    - Serves as the foundation for KPI calculations regarding performance, consistency, and session-specific results.

KEY BUSINESS & DATA LOGIC:
	- Includes both Grand Prix and Sprint results (rd.type IN 'RACE_RESULT', 'SPRINT_RACE_RESULT').
    - Dynamic Grid Calculation: If a grid position is missing (Pit-Lane start or Qualifying DNS), 
      the grid_position is dynamically assigned to the total number of race entrants (rs.total_starters).
    - Pit-Lane Logic: Explicitly flags 'PL' starts and identifies drivers who bypassed the starting grid 
      using is_pitlane_start_flag (binary 1/0).
    - Reliability Tracking: dnf_flag (binary 1/0) consolidates non-classified finishes (DNF, NC, DSQ).
    - Entrant Accuracy: total_starters excludes 'DNS' (Did Not Start) to ensure the accuracy 
      of the calculated starting field size.
	- Includes segmentation by regulation eras for future analysis

DATA HIERARCHY & GRAIN:
    - Granularity: One row per Driver per Grand Prix/Sprint Race.
    - Filter: Restricted to official race events only rd.type IN ('RACE_RESULT', 'SPRINT_RACE_RESULT').

SOURCE TABLES:
    - race_data (Fact table)
    - race, driver, constructor (Dimensions)
    - country, continent (Geographical metadata)
*/

CREATE OR REPLACE VIEW driver_base AS

-- Count of drivers that started every session
WITH race_starters AS (
    SELECT 
		race_id, 
		type,
		COUNT(DISTINCT driver_id) AS total_starters
    FROM race_data 
    WHERE type IN ('RACE_RESULT', 'SPRINT_RACE_RESULT') AND position_text != 'DNS' 
    GROUP BY race_id, type
),

-- Starting grid position of every driver for both Main Races and Sprints
grid_position AS (
    SELECT 
		race_id, 
		driver_id, 
		position_number AS grid_pos,
		type,
		
-- Flagging drivers who started the race from pit-lane
		CASE
			WHEN position_text = 'PL' THEN 1
			ELSE 0
		END is_pitlane_start_flag
		
    FROM race_data 
    WHERE type IN ('STARTING_GRID_POSITION', 'SPRINT_STARTING_GRID_POSITION')
)

SELECT 
    r.year,
    rd.race_id,
	r.date,
	r.grand_prix_id,
	ci.name AS circuit_name,

-- Normalization of session type 	
	CASE
		WHEN rd.type = 'RACE_RESULT' THEN 'RACE'
		WHEN rd.type = 'SPRINT_RACE_RESULT' THEN 'SPRINT'
	END session_type,
	
    d.name AS driver_name,
	rd.driver_id,
	
-- Starting grid position (if a driver started from pit-lane then his starting position is last from all race entrants)
    COALESCE(g.grid_pos, rs.total_starters) AS grid_position,
	
    rd.position_number AS finish_position,
    COALESCE(rd.race_points,0) AS points,
    cr.name AS team,
	d.date_of_birth,
	d.date_of_death,
    cy.name AS driver_nationality,
	ct.name AS driver_continent,
	rs.total_starters,

-- Dividing the data into different regulation eras
	CASE 
		WHEN year <= 1960 THEN 'Early F1'
		WHEN year BETWEEN 1961 AND 1965 THEN '1.5 Litre Era'
		WHEN year BETWEEN 1966 AND 1976 THEN 'Early Aero Era'
		WHEN year BETWEEN 1977 AND 1982 THEN 'Ground-Effect Era'
		WHEN year BETWEEN 1983 AND 1988 THEN 'Turbo Era'
		WHEN year BETWEEN 1989 AND 2005 THEN 'V10 Era'
		WHEN year BETWEEN 2006 AND 2013 THEN 'V8 Era'
		WHEN year BETWEEN 2014 AND 2021 THEN 'Turbo-Hybrid Era'
		WHEN year BETWEEN 2022 AND 2025 THEN 'Modern Ground-Effect Era'
	END regulation_era,

-- Flagging drivers who started the race from pit-lane (including drivers who did not participate in qualifying but started the race)	
	COALESCE(g.is_pitlane_start_flag, 0) AS is_pitlane_start_flag,

-- Flagging drivers who did not start a race
	CASE
		WHEN rd.position_text = 'DNS' THEN 1
		ELSE 0
	END dns_flag,

-- Flagging drivers who did not finish a race
    CASE 
		WHEN rd.position_text IN ('DNF', 'NC', 'DSQ') THEN 1 
		ELSE 0 
	END dnf_flag,

-- Additional information about a cause of retirement (if a driver did not retire then 'NONE')
	CASE
		WHEN rd.position_text IN ('DNF', 'NC', 'DSQ') THEN rd.position_text
		ELSE 'NONE'
	END retirement_cause
		
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
JOIN circuit ci
	ON r.circuit_id = ci.id

-- Joining session starters by matching race_id and specific session type (Race vs Sprint)
JOIN race_starters rs 
	ON rd.race_id = rs.race_id AND rd.type = rs.type

-- Left joining grid positions using session-mapping logic (matching results to their respective starting grids)
LEFT JOIN grid_position g 
	ON rd.race_id = g.race_id 
	AND rd.driver_id = g.driver_id 
	AND (
        (rd.type = 'RACE_RESULT' AND g.type = 'STARTING_GRID_POSITION') OR
        (rd.type = 'SPRINT_RACE_RESULT' AND g.type = 'SPRINT_STARTING_GRID_POSITION')
    )
WHERE rd.type IN ('RACE_RESULT', 'SPRINT_RACE_RESULT');