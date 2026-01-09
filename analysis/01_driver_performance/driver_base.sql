-- VIEW: driver_base
-- PURPOSE:
-- Base analytical view at driver x race grain.
-- Contains race results for drivers, limited to race events only.
-- This view serves as the foundation for all KPI calculations
-- related to driver performance and consistency.
--
-- KEY BUSINESS RULES:
-- - Only race results are included (rd.type = 'RACE_RESULT')
-- - DNF / NC / DSQ are flagged using dnf_flag
-- - Points reflect official race points
--
-- SOURCE TABLES:
-- - race_data
-- - race
-- - driver


CREATE OR REPLACE VIEW driver_base AS
SELECT

    r.year,
    r.date AS race_date,
    r.official_name AS race_name, 

    d.name AS driver_name,
    rd.constructor_id,

    rd.race_grid_position_number AS grid_position,
    rd.position_number AS finish_position,
    rd.race_points AS points,
    rd.race_positions_gained AS positions_gained,

    CASE
        WHEN rd.position_text IN ('DNF', 'NC', 'DSQ') THEN 1
        ELSE 0
    END AS dnf_flag

FROM race_data rd
JOIN race r
    ON rd.race_id = r.id
JOIN driver d
    ON rd.driver_id = d.id

WHERE rd.type = 'RACE_RESULT';