/*
VIEW: v_constructor_base
PURPOSE:
    - Primary analytical view at constructor/team x session grain (including Sprint and Main Race).
    - Serves as the foundation for KPI calculations regarding performance, consistency, and session-specific results.

KEY BUSINESS & DATA LOGIC:
	- Includes both Grand Prix and Sprint results (rd.type IN 'RACE_RESULT', 'SPRINT_RACE_RESULT').
    - Dynamic Grid Calculation: If a grid position is missing (Pit-Lane start or Qualifying DNS), 
      the grid_position is dynamically assigned to the total number of race entrants (rs.total_starters).
    - Pit-Lane Logic: Explicitly flags 'PL' starts and identifies drivers who bypassed the starting grid 
      using is_pitlane_start_flag (binary 1/0).
    - Reliability Tracking: dnf_flag (binary 1/0) consolidates non-classified finishes (DNF, NC, DSQ).
    - Entrant Accuracy: total_starters excludes ('DNS', 'DNQ', 'DNPQ', 'EX', 'DNP') to ensure the accuracy 
      of the calculated starting field size.
	- Includes segmentation by regulation eras for future analysis

DATA HIERARCHY & GRAIN:
    - Granularity: X rows per Constructor per Grand Prix/Sprint Race. (Dependant on how many cars each constructor entered in a race)
		*Note on Grain: In modern F1, this simplifies to Constructor x Session. However, to preserve historical accuracy (1950s-70s), 
	  	this view retains multiple records - Constructor per Race in cases of "Shared Drives" 
	- Filter: Restricted to official race events only rd.type IN ('RACE_RESULT', 'SPRINT_RACE_RESULT') and only to
	  Constructors who were included in the official results.

SOURCE TABLES:
    - race_data (Fact table)
    - race, driver, constructor (Dimensions)
    - country, continent (Geographical metadata)
*/

CREATE OR REPLACE VIEW v_constructor_base AS

-- Count of Constructors that started every session
WITH race_starters AS (
    SELECT 
		race_id, 
		type,
		COUNT(DISTINCT driver_id) AS total_starters
    FROM race_data 
    WHERE type IN ('RACE_RESULT', 'SPRINT_RACE_RESULT') AND position_text NOT IN ('DNS', 'DNQ', 'DNPQ', 'EX', 'DNP')
    GROUP BY race_id, type
),

unique_races AS (
	SELECT DISTINCT
		r.year,
		r.date,
		rd.race_id,
		rd.type
	FROM race_data rd
	JOIN race r
		ON rd.race_id = r.id
    WHERE type IN ('RACE_RESULT', 'SPRINT_RACE_RESULT') 
),

race_indexing AS (
	SELECT 
		*,
		
		-- Defining chronological race number in every season
		RANK() OVER(PARTITION BY year, type ORDER BY date) AS round,
		
		-- Total Main Races/Sprint Races in a season
		COUNT(race_id) OVER(PARTITION BY year, type) AS total_races_in_season
	FROM unique_races
), 

-- Starting grid position of every driver for both Main Races and Sprints
grid_position AS (
    SELECT 
		race_id, 
		driver_id, 
		position_number,
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
	ri.round,
	r.grand_prix_id,
	ci.name AS circuit_name,
	
	-- Normalization of session type 	
	CASE
		WHEN rd.type = 'RACE_RESULT' THEN 'RACE'
		WHEN rd.type = 'SPRINT_RACE_RESULT' THEN 'SPRINT'
	END session_type,
	
	cr.name AS constructor_name,
	rd.constructor_id,
	cy.name AS constructor_nationality,
	ct.name AS constructor_continent,

	CONCAT(
        UPPER(SUBSTRING(rd.engine_manufacturer_id, 1, 1)),
        LOWER(SUBSTRING(rd.engine_manufacturer_id, 2, LENGTH(rd.engine_manufacturer_id)))
    ) AS engine_manufacturer,
    d.name AS driver_name,
	rd.driver_id,
	
	-- Starting grid position (if a driver started from pit-lane then his starting position is last from all race entrants)
    CASE 
		WHEN g.position_number IS NULL AND rd.position_text IN ('DNQ', 'DNPQ') THEN g.position_number
		ELSE COALESCE(g.position_number, rs.total_starters)
	END grid_position,
	
	rd.position_number AS finish_position,
	COALESCE(rd.race_points,0) AS points,	
	ri.total_races_in_season,
	rs.total_starters,

	-- Dividing the data into different regulation eras
	CASE 
		WHEN r.year <= 1960 THEN 'Early F1'
		WHEN r.year BETWEEN 1961 AND 1965 THEN '1.5 Litre Era'
		WHEN r.year BETWEEN 1966 AND 1976 THEN 'Early Aero Era'
		WHEN r.year BETWEEN 1977 AND 1982 THEN 'Ground-Effect Era'
		WHEN r.year BETWEEN 1983 AND 1988 THEN 'Turbo Era'
		WHEN r.year BETWEEN 1989 AND 2005 THEN 'V10 Era'
		WHEN r.year BETWEEN 2006 AND 2013 THEN 'V8 Era'
		WHEN r.year BETWEEN 2014 AND 2021 THEN 'Turbo-Hybrid Era'
		WHEN r.year BETWEEN 2022 AND 2025 THEN 'Modern Ground-Effect Era'
	END regulation_era,

	-- Flagging constructors who started the race from pit-lane (including drivers who did not participate in qualifying but started the race)	
	COALESCE(g.is_pitlane_start_flag, 0) AS is_pitlane_start_flag,

	-- Flagging constructors who did not finish a race
    CASE 
		WHEN rd.position_text IN ('DNF', 'NC', 'DSQ') THEN 1 
		ELSE 0 
	END dnf_flag,

	-- Flagging constructors who were disqualified from the race
    CASE 
		WHEN rd.position_text = 'DSQ' THEN 1 
		ELSE 0 
	END dsq_flag,

	-- Additional information about a cause of retirement (if did not retire then 'NONE')
	CASE
		WHEN rd.race_reason_retired IS NULL THEN 'NONE'
		ELSE rd.race_reason_retired
	END retirement_cause,

	rd.race_fastest_lap AS is_fastest_lap

FROM race_data rd
JOIN race r 
	ON rd.race_id = r.id
JOIN driver d 
	ON rd.driver_id = d.id
JOIN constructor cr 
	ON rd.constructor_id = cr.id
JOIN country cy 
	ON cr.country_id = cy.id
JOIN continent ct
	ON cy.continent_id = ct.id
JOIN circuit ci
	ON r.circuit_id = ci.id

-- Joining session starters by matching race_id and specific session type (Race vs Sprint)
JOIN race_starters rs 
	ON rd.race_id = rs.race_id AND rd.type = rs.type

JOIN race_indexing ri
	ON rd.race_id = ri.race_id AND rd.type = ri.type

-- Left joining grid positions using session-mapping logic (matching results to their respective starting grids)
LEFT JOIN grid_position g 
	ON rd.race_id = g.race_id 
	AND rd.driver_id = g.driver_id 
	AND (
        (rd.type = 'RACE_RESULT' AND g.type = 'STARTING_GRID_POSITION') OR
        (rd.type = 'SPRINT_RACE_RESULT' AND g.type = 'SPRINT_STARTING_GRID_POSITION')
    )
-- Filtering data by Main Race and Sprint Race events and not including constructors who did not participate or were excluded from final results
WHERE rd.type IN ('RACE_RESULT', 'SPRINT_RACE_RESULT') AND rd.position_text NOT IN ('DNS', 'DNQ', 'DNPQ', 'DNP', 'EX');