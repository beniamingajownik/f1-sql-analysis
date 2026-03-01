CREATE VIEW gold.v_analytics_constructor_standings AS
 WITH aggregated_season AS (
         SELECT v_constructor_championship_logic.year,
            v_constructor_championship_logic.constructor_name,
            v_constructor_championship_logic.constructor_id,
            string_agg(DISTINCT (v_constructor_championship_logic.driver_name)::text, ' / '::text) AS season_drivers,
            v_constructor_championship_logic.constructor_nationality,
            v_constructor_championship_logic.constructor_continent,
            v_constructor_championship_logic.engine_manufacturer,
            v_constructor_championship_logic.regulation_era,
            sum(
                CASE
                    WHEN (v_constructor_championship_logic.counts_to_championship = 1) THEN v_constructor_championship_logic.team_points
                    ELSE (0)::numeric
                END) AS total_points_before_correction
           FROM silver.v_constructor_championship_logic
          GROUP BY v_constructor_championship_logic.year, v_constructor_championship_logic.constructor_name, v_constructor_championship_logic.constructor_id, v_constructor_championship_logic.constructor_nationality, v_constructor_championship_logic.constructor_continent, v_constructor_championship_logic.engine_manufacturer, v_constructor_championship_logic.regulation_era
        ), points_correction AS (
         SELECT aggregated_season.year,
            aggregated_season.constructor_name,
            aggregated_season.constructor_id,
            aggregated_season.season_drivers,
            aggregated_season.constructor_nationality,
            aggregated_season.constructor_continent,
            aggregated_season.engine_manufacturer,
            aggregated_season.regulation_era,
            aggregated_season.total_points_before_correction,
                CASE
                    WHEN ((aggregated_season.year = 2020) AND ((aggregated_season.constructor_id)::text = 'racing-point'::text)) THEN (aggregated_season.total_points_before_correction - 15.0)
                    WHEN ((aggregated_season.year = 2018) AND ((aggregated_season.constructor_id)::text = 'force-india'::text)) THEN (aggregated_season.total_points_before_correction - 59.0)
                    ELSE aggregated_season.total_points_before_correction
                END AS total_points
           FROM aggregated_season
        )
 SELECT year,
    constructor_name,
    constructor_id,
    season_drivers,
    constructor_nationality,
    constructor_continent,
    engine_manufacturer,
    regulation_era,
    total_points_before_correction,
    total_points,
        CASE
            WHEN (year < 1958) THEN (0)::bigint
            ELSE rank() OVER (PARTITION BY year ORDER BY total_points DESC)
        END AS season_position
   FROM points_correction;


--
-- TOC entry 278 (class 1259 OID 20927)
-- Name: v_analytics_constructor_career_summary; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_analytics_constructor_career_summary AS
 WITH unified_results AS (
         SELECT DISTINCT ON (v_constructor_base.year, v_constructor_base.race_id, v_constructor_base.session_type, v_constructor_base.constructor_id) v_constructor_base.year,
            v_constructor_base.race_id,
            v_constructor_base.date,
            v_constructor_base.round,
            v_constructor_base.grand_prix_id,
            v_constructor_base.circuit_name,
            v_constructor_base.session_type,
            v_constructor_base.constructor_name,
            v_constructor_base.constructor_id,
            v_constructor_base.constructor_nationality,
            v_constructor_base.constructor_continent,
            v_constructor_base.engine_manufacturer,
            v_constructor_base.driver_name,
            v_constructor_base.driver_id,
            v_constructor_base.grid_position,
            v_constructor_base.finish_position,
            v_constructor_base.points,
            v_constructor_base.total_races_in_season,
            v_constructor_base.total_starters,
            v_constructor_base.regulation_era,
            v_constructor_base.is_pitlane_start_flag,
            v_constructor_base.dnf_flag,
            v_constructor_base.dsq_flag,
            v_constructor_base.retirement_cause,
            v_constructor_base.is_fastest_lap
           FROM silver.v_constructor_base
          ORDER BY v_constructor_base.year, v_constructor_base.race_id, v_constructor_base.session_type, v_constructor_base.constructor_id, v_constructor_base.finish_position
        ), constructor_titles AS (
         SELECT v_analytics_constructor_standings.constructor_id,
            count(*) AS total_titles
           FROM gold.v_analytics_constructor_standings
          WHERE (v_analytics_constructor_standings.season_position = 1)
          GROUP BY v_analytics_constructor_standings.constructor_id
        ), place_logic AS (
         SELECT unified_results.year,
            unified_results.race_id,
            unified_results.date,
            unified_results.round,
            unified_results.grand_prix_id,
            unified_results.circuit_name,
            unified_results.session_type,
            unified_results.constructor_name,
            unified_results.constructor_id,
            unified_results.constructor_nationality,
            unified_results.constructor_continent,
            unified_results.engine_manufacturer,
            unified_results.driver_name,
            unified_results.driver_id,
            unified_results.grid_position,
            unified_results.finish_position,
            unified_results.points,
            unified_results.total_races_in_season,
            unified_results.total_starters,
            unified_results.regulation_era,
            unified_results.is_pitlane_start_flag,
            unified_results.dnf_flag,
            unified_results.dsq_flag,
            unified_results.retirement_cause,
            unified_results.is_fastest_lap,
                CASE
                    WHEN ((unified_results.grid_position = 1) AND (unified_results.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_pole_position,
                CASE
                    WHEN ((unified_results.grid_position = 1) AND (unified_results.session_type = 'SPRINT'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_sprint_pole_position,
                CASE
                    WHEN ((unified_results.finish_position = 1) AND (unified_results.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_race_win,
                CASE
                    WHEN ((unified_results.finish_position = 1) AND (unified_results.session_type = 'SPRINT'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_sprint_win,
                CASE
                    WHEN ((unified_results.finish_position = ANY (ARRAY[1, 2, 3])) AND (unified_results.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_race_podium,
                CASE
                    WHEN ((unified_results.finish_position = ANY (ARRAY[1, 2, 3])) AND (unified_results.session_type = 'SPRINT'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_sprint_podium,
                CASE
                    WHEN ((unified_results.dnf_flag = 1) AND ((unified_results.retirement_cause)::text = ANY ((ARRAY['Accident'::character varying, 'Accident damage'::character varying, 'Accident on formation lap'::character varying, 'Broken floor'::character varying, 'Broken wing'::character varying, 'Collision'::character varying, 'Collision damage'::character varying, 'Failed to serve stop-go penalty'::character varying, 'Fatal accident'::character varying, 'Fatal collision'::character varying, 'Spin'::character varying, 'Spun off'::character varying, 'Unfit'::character varying, 'Unwell'::character varying, 'Withdrew'::character varying])::text[]))) THEN 'Driver fault'::text
                    WHEN (unified_results.dnf_flag = 1) THEN 'Car reliability'::text
                    ELSE NULL::text
                END AS dnf_fault,
                CASE
                    WHEN ((unified_results.dsq_flag = 1) AND ((unified_results.retirement_cause)::text = ANY ((ARRAY['Caused collision with Trulli'::character varying, 'Driving too slowly'::character varying, 'Failed to serve stop-go penalty'::character varying, 'Ignored black flag'::character varying, 'Ignored blue flags'::character varying, 'Ignored red light'::character varying, 'Ignored yellow flags'::character varying, 'Ignored yellow flags in practice'::character varying, 'Illegal start'::character varying, 'Incorrect grid formation'::character varying, 'Incorrect starting procedure'::character varying, 'Misled stewards'::character varying, 'Overtaking on formation lap'::character varying, 'Rejoined track illegally'::character varying, 'Reversed in pits'::character varying])::text[]))) THEN 'Driver fault'::text
                    WHEN (unified_results.dsq_flag = 1) THEN 'Team fault'::text
                    ELSE NULL::text
                END AS dsq_fault
           FROM unified_results
        )
 SELECT pl.constructor_name,
    pl.constructor_id,
    COALESCE(ct.total_titles, (0)::bigint) AS titles,
    sum(pl.points) AS total_points,
    count(
        CASE
            WHEN (pl.session_type = 'RACE'::text) THEN 1
            ELSE NULL::integer
        END) AS race_starts,
    count(pl.is_pole_position) AS pole_positions,
    count(pl.is_race_win) AS race_wins,
    count(pl.is_race_podium) AS race_podiums,
    count(
        CASE
            WHEN (pl.session_type = 'SPRINT'::text) THEN 1
            ELSE NULL::integer
        END) AS sprint_starts,
    count(pl.is_sprint_pole_position) AS sprint_pole_positions,
    count(pl.is_sprint_win) AS sprint_wins,
    count(pl.is_sprint_podium) AS sprint_podiums,
    count(
        CASE
            WHEN (pl.dnf_fault = 'Driver fault'::text) THEN 1
            ELSE NULL::integer
        END) AS driver_caused_dnf,
    count(
        CASE
            WHEN (pl.dnf_fault = 'Car reliability'::text) THEN 1
            ELSE NULL::integer
        END) AS car_caused_dnf,
    count(
        CASE
            WHEN (pl.dsq_fault = 'Driver fault'::text) THEN 1
            ELSE NULL::integer
        END) AS driver_caused_dsq,
    count(
        CASE
            WHEN (pl.dsq_fault = 'Team fault'::text) THEN 1
            ELSE NULL::integer
        END) AS car_caused_dsq,
    count(pl.dnf_fault) AS total_dnf,
    count(pl.dsq_fault) AS total_dsq
   FROM (place_logic pl
     LEFT JOIN constructor_titles ct ON (((pl.constructor_id)::text = (ct.constructor_id)::text)))
  GROUP BY pl.constructor_name, pl.constructor_id, ct.total_titles;


--
-- TOC entry 273 (class 1259 OID 20876)
-- Name: v_analytics_constructor_season_stats; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_analytics_constructor_season_stats AS
 WITH driver_rank AS (
         SELECT DISTINCT ON (cb.year, cb.race_id, cb.driver_id, cb.session_type) cb.year,
            cb.race_id,
            cb.round,
            cb.session_type,
            cb.constructor_name,
            cb.constructor_id,
            cb.constructor_nationality,
            cb.constructor_continent,
            cb.driver_name,
            cb.driver_id,
            cb.engine_manufacturer,
            cb.regulation_era,
            cb.grid_position,
            cb.finish_position,
            cb.dnf_flag,
            cb.dsq_flag,
            cb.is_fastest_lap,
            cl.team_points,
            cl.counts_to_championship,
                CASE
                    WHEN ((cb.finish_position = 1) AND (count(
                    CASE
                        WHEN (cb.finish_position = 2) THEN 1
                        ELSE NULL::integer
                    END) OVER (PARTITION BY cb.race_id, cb.constructor_id, cb.session_type) > 0)) THEN 1
                    ELSE 0
                END AS is_one_two_finish
           FROM (silver.v_constructor_base cb
             LEFT JOIN silver.v_constructor_championship_logic cl ON (((cb.race_id = cl.race_id) AND ((cb.constructor_id)::text = (cl.constructor_id)::text) AND (cb.session_type = cl.session_type) AND ((cb.driver_id)::text = (cl.driver_id)::text))))
          ORDER BY cb.year, cb.race_id, cb.driver_id, cb.session_type, cb.finish_position
        ), race_stats_per_season AS (
         SELECT driver_rank.year,
            driver_rank.constructor_name,
            driver_rank.constructor_id,
            string_agg(DISTINCT (driver_rank.driver_name)::text, ' / '::text) AS drivers,
            driver_rank.constructor_nationality,
            driver_rank.constructor_continent,
            string_agg(DISTINCT driver_rank.engine_manufacturer, ' / '::text) AS engine,
            driver_rank.regulation_era,
            max(max(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.round
                    ELSE NULL::bigint
                END)) OVER (PARTITION BY driver_rank.year) AS total_season_races,
            max(max(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.round
                    ELSE NULL::bigint
                END)) OVER (PARTITION BY driver_rank.year) AS total_season_sprints,
            count(DISTINCT
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.round
                    ELSE NULL::bigint
                END) AS constructor_race_entries,
            count(DISTINCT
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.round
                    ELSE NULL::bigint
                END) AS constructor_sprint_entries,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN 1
                    ELSE NULL::integer
                END) AS constructor_race_entrants,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN 1
                    ELSE NULL::integer
                END) AS constructor_sprint_entrants,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.finish_position = 1)) THEN 1
                    ELSE NULL::integer
                END) AS race_wins,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'SPRINT'::text) AND (driver_rank.finish_position = 1)) THEN 1
                    ELSE NULL::integer
                END) AS sprint_wins,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.finish_position = ANY (ARRAY[1, 2, 3]))) THEN 1
                    ELSE NULL::integer
                END) AS race_podiums,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'SPRINT'::text) AND (driver_rank.finish_position = ANY (ARRAY[1, 2, 3]))) THEN 1
                    ELSE NULL::integer
                END) AS sprint_podiums,
            count(DISTINCT
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.finish_position = ANY (ARRAY[1, 2, 3]))) THEN driver_rank.round
                    ELSE NULL::bigint
                END) AS distinct_race_podiums,
            count(DISTINCT
                CASE
                    WHEN ((driver_rank.session_type = 'SPRINT'::text) AND (driver_rank.finish_position = ANY (ARRAY[1, 2, 3]))) THEN driver_rank.round
                    ELSE NULL::bigint
                END) AS distinct_sprint_podiums,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.is_one_two_finish = 1)) THEN driver_rank.is_one_two_finish
                    ELSE NULL::integer
                END) AS race_one_two_finishes,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'SPRINT'::text) AND (driver_rank.is_one_two_finish = 1)) THEN driver_rank.is_one_two_finish
                    ELSE NULL::integer
                END) AS sprint_one_two_finishes,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.grid_position
                    ELSE NULL::bigint
                END), 2) AS avg_race_grid,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.grid_position
                    ELSE NULL::bigint
                END), 2) AS avg_sprint_grid,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.finish_position
                    ELSE NULL::integer
                END), 2) AS avg_race_finish,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.finish_position
                    ELSE NULL::integer
                END), 2) AS avg_sprint_finish,
            round(sum(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.team_points
                    ELSE (0)::numeric
                END), 2) AS total_race_points,
            round(sum(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.team_points
                    ELSE (0)::numeric
                END), 2) AS total_sprint_points,
            sum(driver_rank.team_points) AS unofficial_season_points,
            round(sum(
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.counts_to_championship = 1)) THEN driver_rank.team_points
                    ELSE (0)::numeric
                END), 2) AS official_race_points,
            sum(
                CASE
                    WHEN (driver_rank.counts_to_championship = 1) THEN driver_rank.team_points
                    ELSE (0)::numeric
                END) AS provisional_official_points,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dnf_flag
                    ELSE 0
                END) AS race_dnf,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dnf_flag
                    ELSE NULL::integer
                END * 100)), 2) AS race_dnf_pct,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dsq_flag
                    ELSE 0
                END) AS race_dsq,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dsq_flag
                    ELSE NULL::integer
                END * 100)), 2) AS race_dsq_pct,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dnf_flag
                    ELSE 0
                END) AS sprint_dnf,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dnf_flag
                    ELSE NULL::integer
                END * 100)), 2) AS sprint_dnf_pct,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dsq_flag
                    ELSE 0
                END) AS sprint_dsq,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dsq_flag
                    ELSE NULL::integer
                END * 100)), 2) AS sprint_dsq_pct,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.driver_id
                    ELSE NULL::character varying
                END) AS race_starts,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.driver_id
                    ELSE NULL::character varying
                END) AS sprint_starts,
            count(
                CASE
                    WHEN ((driver_rank.is_fastest_lap = true) AND (driver_rank.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END) AS race_fastest_lap
           FROM driver_rank
          GROUP BY driver_rank.year, driver_rank.constructor_id, driver_rank.constructor_name, driver_rank.constructor_nationality, driver_rank.constructor_continent, driver_rank.regulation_era
        ), points_correction AS (
         SELECT race_stats_per_season.year,
            race_stats_per_season.constructor_name,
            race_stats_per_season.constructor_id,
            race_stats_per_season.drivers,
            race_stats_per_season.constructor_nationality,
            race_stats_per_season.constructor_continent,
            race_stats_per_season.engine,
            race_stats_per_season.regulation_era,
            race_stats_per_season.total_season_races,
            race_stats_per_season.total_season_sprints,
            race_stats_per_season.constructor_race_entries,
            race_stats_per_season.constructor_sprint_entries,
            race_stats_per_season.constructor_race_entrants,
            race_stats_per_season.constructor_sprint_entrants,
            race_stats_per_season.race_wins,
            race_stats_per_season.sprint_wins,
            race_stats_per_season.race_podiums,
            race_stats_per_season.sprint_podiums,
            race_stats_per_season.distinct_race_podiums,
            race_stats_per_season.distinct_sprint_podiums,
            race_stats_per_season.race_one_two_finishes,
            race_stats_per_season.sprint_one_two_finishes,
            race_stats_per_season.avg_race_grid,
            race_stats_per_season.avg_sprint_grid,
            race_stats_per_season.avg_race_finish,
            race_stats_per_season.avg_sprint_finish,
            race_stats_per_season.total_race_points,
            race_stats_per_season.total_sprint_points,
            race_stats_per_season.unofficial_season_points,
            race_stats_per_season.official_race_points,
            race_stats_per_season.provisional_official_points,
            race_stats_per_season.race_dnf,
            race_stats_per_season.race_dnf_pct,
            race_stats_per_season.race_dsq,
            race_stats_per_season.race_dsq_pct,
            race_stats_per_season.sprint_dnf,
            race_stats_per_season.sprint_dnf_pct,
            race_stats_per_season.sprint_dsq,
            race_stats_per_season.sprint_dsq_pct,
            race_stats_per_season.race_starts,
            race_stats_per_season.sprint_starts,
            race_stats_per_season.race_fastest_lap,
                CASE
                    WHEN ((race_stats_per_season.year = 2020) AND ((race_stats_per_season.constructor_id)::text = 'racing-point'::text)) THEN (race_stats_per_season.provisional_official_points - 15.0)
                    WHEN ((race_stats_per_season.year = 2018) AND ((race_stats_per_season.constructor_id)::text = 'force-india'::text)) THEN (race_stats_per_season.provisional_official_points - 59.0)
                    ELSE race_stats_per_season.provisional_official_points
                END AS official_season_points
           FROM race_stats_per_season
        )
 SELECT year,
    constructor_name,
    constructor_id,
    drivers,
    constructor_nationality,
    constructor_continent,
    engine,
    regulation_era,
    constructor_race_entrants,
    constructor_sprint_entrants,
    constructor_race_entries,
    constructor_sprint_entries,
    race_wins,
    sprint_wins,
    race_podiums,
    distinct_race_podiums,
    sprint_podiums,
    distinct_sprint_podiums,
    race_one_two_finishes,
    sprint_one_two_finishes,
    round((((race_wins)::numeric / NULLIF((total_season_races)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_race_wins_pct,
    round((((sprint_wins)::numeric / NULLIF((total_season_sprints)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_sprint_wins_pct,
    round((((race_podiums)::numeric / NULLIF((constructor_race_entrants)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_race_podiums_pct,
    round((((sprint_podiums)::numeric / NULLIF((constructor_sprint_entrants)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_sprint_podiums_pct,
    avg_race_grid,
    avg_race_finish,
    avg_sprint_grid,
    avg_sprint_finish,
    official_race_points,
    total_sprint_points,
    official_season_points,
    round((official_race_points / NULLIF((total_season_races)::numeric, (0)::numeric)), 2) AS avg_race_points,
    round((total_sprint_points / NULLIF((total_season_sprints)::numeric, (0)::numeric)), 2) AS avg_sprint_points,
    race_dnf,
    race_dnf_pct,
    race_dsq,
    race_dsq_pct,
    sprint_dnf,
    sprint_dnf_pct,
    sprint_dsq,
    sprint_dsq_pct,
    round((((race_fastest_lap)::numeric / NULLIF((total_season_races)::numeric, (0)::numeric)) * (100)::numeric), 2) AS race_fastest_lap_pct,
    total_season_races,
    total_season_sprints
   FROM points_correction;


--
-- TOC entry 276 (class 1259 OID 20897)
-- Name: v_analytics_driver_standings; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_analytics_driver_standings AS
 WITH aggregated_season AS (
         SELECT v_driver_championship_logic.year,
            v_driver_championship_logic.driver_name,
            v_driver_championship_logic.driver_id,
            string_agg(DISTINCT (v_driver_championship_logic.team)::text, ' / '::text) AS team,
            v_driver_championship_logic.driver_nationality,
            v_driver_championship_logic.driver_continent,
            v_driver_championship_logic.regulation_era,
            sum(
                CASE
                    WHEN (v_driver_championship_logic.counts_to_championship = 1) THEN v_driver_championship_logic.points
                    ELSE (0)::numeric
                END) AS total_points
           FROM silver.v_driver_championship_logic
          GROUP BY v_driver_championship_logic.year, v_driver_championship_logic.driver_name, v_driver_championship_logic.driver_id, v_driver_championship_logic.driver_nationality, v_driver_championship_logic.driver_continent, v_driver_championship_logic.regulation_era
        )
 SELECT year,
    driver_name,
    driver_id,
    team,
    driver_nationality,
    driver_continent,
    regulation_era,
    total_points,
    rank() OVER (PARTITION BY year ORDER BY total_points DESC) AS season_position
   FROM aggregated_season;


--
-- TOC entry 279 (class 1259 OID 20932)
-- Name: v_analytics_driver_career_summary; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_analytics_driver_career_summary AS
 WITH unified_results AS (
         SELECT DISTINCT ON (v_driver_base.year, v_driver_base.race_id, v_driver_base.session_type, v_driver_base.driver_id) v_driver_base.year,
            v_driver_base.race_id,
            v_driver_base.date,
            v_driver_base.round,
            v_driver_base.grand_prix_id,
            v_driver_base.circuit_name,
            v_driver_base.session_type,
            v_driver_base.driver_name,
            v_driver_base.driver_id,
            v_driver_base.driver_nationality,
            v_driver_base.driver_continent,
            v_driver_base.engine_manufacturer,
            v_driver_base.constructor_name,
            v_driver_base.constructor_id,
            v_driver_base.grid_position,
            v_driver_base.finish_position,
            v_driver_base.points,
            v_driver_base.total_races_in_season,
            v_driver_base.team,
            v_driver_base.date_of_birth,
            v_driver_base.date_of_death,
            v_driver_base.total_starters,
            v_driver_base.regulation_era,
            v_driver_base.is_pitlane_start_flag,
            v_driver_base.dnf_flag,
            v_driver_base.dsq_flag,
            v_driver_base.retirement_cause,
            v_driver_base.is_fastest_lap
           FROM silver.v_driver_base
          ORDER BY v_driver_base.year, v_driver_base.race_id, v_driver_base.session_type, v_driver_base.driver_id, v_driver_base.finish_position
        ), driver_titles AS (
         SELECT v_analytics_driver_standings.driver_id,
            count(*) AS total_titles
           FROM gold.v_analytics_driver_standings
          WHERE (v_analytics_driver_standings.season_position = 1)
          GROUP BY v_analytics_driver_standings.driver_id
        ), place_logic AS (
         SELECT unified_results.year,
            unified_results.race_id,
            unified_results.date,
            unified_results.round,
            unified_results.grand_prix_id,
            unified_results.circuit_name,
            unified_results.session_type,
            unified_results.driver_name,
            unified_results.driver_id,
            unified_results.driver_nationality,
            unified_results.driver_continent,
            unified_results.engine_manufacturer,
            unified_results.constructor_name,
            unified_results.constructor_id,
            unified_results.grid_position,
            unified_results.finish_position,
            unified_results.points,
            unified_results.total_races_in_season,
            unified_results.team,
            unified_results.date_of_birth,
            unified_results.date_of_death,
            unified_results.total_starters,
            unified_results.regulation_era,
            unified_results.is_pitlane_start_flag,
            unified_results.dnf_flag,
            unified_results.dsq_flag,
            unified_results.retirement_cause,
            unified_results.is_fastest_lap,
                CASE
                    WHEN ((unified_results.grid_position = 1) AND (unified_results.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_pole_position,
                CASE
                    WHEN ((unified_results.grid_position = 1) AND (unified_results.session_type = 'SPRINT'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_sprint_pole_position,
                CASE
                    WHEN ((unified_results.finish_position = 1) AND (unified_results.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_race_win,
                CASE
                    WHEN ((unified_results.finish_position = 1) AND (unified_results.session_type = 'SPRINT'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_sprint_win,
                CASE
                    WHEN ((unified_results.finish_position = ANY (ARRAY[1, 2, 3])) AND (unified_results.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_race_podium,
                CASE
                    WHEN ((unified_results.finish_position = ANY (ARRAY[1, 2, 3])) AND (unified_results.session_type = 'SPRINT'::text)) THEN 1
                    ELSE NULL::integer
                END AS is_sprint_podium,
                CASE
                    WHEN ((unified_results.dnf_flag = 1) AND ((unified_results.retirement_cause)::text = ANY ((ARRAY['Accident'::character varying, 'Accident damage'::character varying, 'Accident on formation lap'::character varying, 'Broken floor'::character varying, 'Broken wing'::character varying, 'Collision'::character varying, 'Collision damage'::character varying, 'Failed to serve stop-go penalty'::character varying, 'Fatal accident'::character varying, 'Fatal collision'::character varying, 'Spin'::character varying, 'Spun off'::character varying, 'Unfit'::character varying, 'Unwell'::character varying, 'Withdrew'::character varying])::text[]))) THEN 'Driver fault'::text
                    WHEN (unified_results.dnf_flag = 1) THEN 'Car reliability'::text
                    ELSE NULL::text
                END AS dnf_fault,
                CASE
                    WHEN ((unified_results.dsq_flag = 1) AND ((unified_results.retirement_cause)::text = ANY ((ARRAY['Caused collision with Trulli'::character varying, 'Driving too slowly'::character varying, 'Failed to serve stop-go penalty'::character varying, 'Ignored black flag'::character varying, 'Ignored blue flags'::character varying, 'Ignored red light'::character varying, 'Ignored yellow flags'::character varying, 'Ignored yellow flags in practice'::character varying, 'Illegal start'::character varying, 'Incorrect grid formation'::character varying, 'Incorrect starting procedure'::character varying, 'Misled stewards'::character varying, 'Overtaking on formation lap'::character varying, 'Rejoined track illegally'::character varying, 'Reversed in pits'::character varying])::text[]))) THEN 'Driver fault'::text
                    WHEN (unified_results.dsq_flag = 1) THEN 'Team fault'::text
                    ELSE NULL::text
                END AS dsq_fault
           FROM unified_results
        )
 SELECT pl.driver_name,
    pl.driver_id,
    COALESCE(dt.total_titles, (0)::bigint) AS titles,
    sum(pl.points) AS total_points,
    count(
        CASE
            WHEN (pl.session_type = 'RACE'::text) THEN 1
            ELSE NULL::integer
        END) AS race_starts,
    count(pl.is_pole_position) AS pole_positions,
    count(pl.is_race_win) AS race_wins,
    count(pl.is_race_podium) AS race_podiums,
    count(
        CASE
            WHEN (pl.session_type = 'SPRINT'::text) THEN 1
            ELSE NULL::integer
        END) AS sprint_starts,
    count(pl.is_sprint_pole_position) AS sprint_pole_positions,
    count(pl.is_sprint_win) AS sprint_wins,
    count(pl.is_sprint_podium) AS sprint_podiums,
    count(
        CASE
            WHEN (pl.dnf_fault = 'Driver fault'::text) THEN 1
            ELSE NULL::integer
        END) AS driver_caused_dnf,
    count(
        CASE
            WHEN (pl.dnf_fault = 'Car reliability'::text) THEN 1
            ELSE NULL::integer
        END) AS car_caused_dnf,
    count(
        CASE
            WHEN (pl.dsq_fault = 'Driver fault'::text) THEN 1
            ELSE NULL::integer
        END) AS driver_caused_dsq,
    count(
        CASE
            WHEN (pl.dsq_fault = 'Team fault'::text) THEN 1
            ELSE NULL::integer
        END) AS car_caused_dsq,
    count(pl.dnf_fault) AS total_dnf,
    count(pl.dsq_fault) AS total_dsq
   FROM (place_logic pl
     LEFT JOIN driver_titles dt ON (((pl.driver_id)::text = (dt.driver_id)::text)))
  GROUP BY pl.driver_name, pl.driver_id, dt.total_titles;


--
-- TOC entry 275 (class 1259 OID 20891)
-- Name: v_analytics_driver_season_stats; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_analytics_driver_season_stats AS
 WITH driver_rank AS (
         SELECT DISTINCT ON (db.year, db.race_id, db.driver_id, db.session_type) db.year,
            db.race_id,
            db.round,
            db.session_type,
            db.driver_name,
            db.driver_id,
            db.constructor_name,
            db.constructor_id,
            db.engine_manufacturer,
            db.driver_nationality,
            db.driver_continent,
            db.regulation_era,
            db.grid_position,
            db.finish_position,
            db.dnf_flag,
            db.dsq_flag,
            db.is_fastest_lap,
            dl.points,
            dl.counts_to_championship
           FROM (silver.v_driver_base db
             LEFT JOIN silver.v_driver_championship_logic dl ON (((db.race_id = dl.race_id) AND (db.session_type = dl.session_type) AND ((db.driver_id)::text = (dl.driver_id)::text))))
          ORDER BY db.year, db.race_id, db.driver_id, db.session_type, db.finish_position
        ), race_stats_per_season AS (
         SELECT driver_rank.year,
            driver_rank.driver_name,
            driver_rank.driver_id,
            driver_rank.constructor_name AS team,
            driver_rank.driver_nationality,
            driver_rank.driver_continent,
            string_agg(DISTINCT driver_rank.engine_manufacturer, ' / '::text) AS engine,
            driver_rank.regulation_era,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.driver_id
                    ELSE NULL::character varying
                END) AS season_race_entries,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.driver_id
                    ELSE NULL::character varying
                END) AS season_sprint_entries,
            max(max(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.round
                    ELSE NULL::bigint
                END)) OVER (PARTITION BY driver_rank.year) AS total_season_races,
            max(max(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.round
                    ELSE NULL::bigint
                END)) OVER (PARTITION BY driver_rank.year) AS total_season_sprints,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.finish_position = 1)) THEN 1
                    ELSE NULL::integer
                END) AS race_wins,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'SPRINT'::text) AND (driver_rank.finish_position = 1)) THEN 1
                    ELSE NULL::integer
                END) AS sprint_wins,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.finish_position = ANY (ARRAY[1, 2, 3]))) THEN 1
                    ELSE NULL::integer
                END) AS race_podiums,
            count(
                CASE
                    WHEN ((driver_rank.session_type = 'SPRINT'::text) AND (driver_rank.finish_position = ANY (ARRAY[1, 2, 3]))) THEN 1
                    ELSE NULL::integer
                END) AS sprint_podiums,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.grid_position
                    ELSE NULL::bigint
                END), 2) AS avg_race_grid,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.grid_position
                    ELSE NULL::bigint
                END), 2) AS avg_sprint_grid,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.finish_position
                    ELSE NULL::integer
                END), 2) AS avg_race_finish,
            round(avg(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.finish_position
                    ELSE NULL::integer
                END), 2) AS avg_sprint_finish,
            round(sum(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.points
                    ELSE (0)::numeric
                END), 2) AS total_race_points,
            round(sum(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.points
                    ELSE (0)::numeric
                END), 2) AS total_sprint_points,
            sum(driver_rank.points) AS unofficial_season_points,
            round(sum(
                CASE
                    WHEN ((driver_rank.session_type = 'RACE'::text) AND (driver_rank.counts_to_championship = 1)) THEN driver_rank.points
                    ELSE (0)::numeric
                END), 2) AS official_race_points,
            sum(
                CASE
                    WHEN (driver_rank.counts_to_championship = 1) THEN driver_rank.points
                    ELSE (0)::numeric
                END) AS official_season_points,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dnf_flag
                    ELSE 0
                END) AS race_dnf,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dnf_flag
                    ELSE NULL::integer
                END * 100)), 2) AS race_dnf_pct,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dsq_flag
                    ELSE 0
                END) AS race_dsq,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.dsq_flag
                    ELSE NULL::integer
                END * 100)), 2) AS race_dsq_pct,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dnf_flag
                    ELSE 0
                END) AS sprint_dnf,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dnf_flag
                    ELSE NULL::integer
                END * 100)), 2) AS sprint_dnf_pct,
            sum(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dsq_flag
                    ELSE 0
                END) AS sprint_dsq,
            round(avg((
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.dsq_flag
                    ELSE NULL::integer
                END * 100)), 2) AS sprint_dsq_pct,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'RACE'::text) THEN driver_rank.driver_id
                    ELSE NULL::character varying
                END) AS race_starts,
            count(
                CASE
                    WHEN (driver_rank.session_type = 'SPRINT'::text) THEN driver_rank.driver_id
                    ELSE NULL::character varying
                END) AS sprint_starts,
            count(
                CASE
                    WHEN ((driver_rank.is_fastest_lap = true) AND (driver_rank.session_type = 'RACE'::text)) THEN 1
                    ELSE NULL::integer
                END) AS race_fastest_lap
           FROM driver_rank
          GROUP BY driver_rank.year, driver_rank.driver_name, driver_rank.driver_id, driver_rank.constructor_name, driver_rank.driver_nationality, driver_rank.driver_continent, driver_rank.regulation_era
        )
 SELECT year,
    driver_name,
    driver_id,
    team,
    driver_nationality,
    driver_continent,
    engine,
    regulation_era,
    season_race_entries,
    season_sprint_entries,
    race_wins,
    sprint_wins,
    race_podiums,
    sprint_podiums,
    round((((race_wins)::numeric / NULLIF((total_season_races)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_race_wins_pct,
    round((((sprint_wins)::numeric / NULLIF((total_season_sprints)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_sprint_wins_pct,
    round((((race_podiums)::numeric / NULLIF((total_season_races)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_race_podiums_pct,
    round((((sprint_podiums)::numeric / NULLIF((total_season_sprints)::numeric, (0)::numeric)) * (100)::numeric), 2) AS season_sprint_podiums_pct,
    avg_race_grid,
    avg_race_finish,
    avg_sprint_grid,
    avg_sprint_finish,
    official_race_points,
    total_sprint_points,
    official_season_points,
    unofficial_season_points,
    round((official_race_points / NULLIF((season_race_entries)::numeric, (0)::numeric)), 2) AS avg_race_points,
    round((total_sprint_points / NULLIF((season_sprint_entries)::numeric, (0)::numeric)), 2) AS avg_sprint_points,
    race_dnf,
    race_dnf_pct,
    race_dsq,
    race_dsq_pct,
    sprint_dnf,
    sprint_dnf_pct,
    sprint_dsq,
    sprint_dsq_pct,
    round((((race_fastest_lap)::numeric / NULLIF((total_season_races)::numeric, (0)::numeric)) * (100)::numeric), 2) AS race_fastest_lap_pct,
    total_season_races,
    total_season_sprints
   FROM race_stats_per_season;


--
-- TOC entry 277 (class 1259 OID 20912)
-- Name: v_analytics_race_evolution; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_analytics_race_evolution AS
 WITH unified_results AS (
         SELECT DISTINCT ON (v_driver_base.year, v_driver_base.race_id, v_driver_base.driver_id, v_driver_base.session_type) v_driver_base.year,
            v_driver_base.race_id,
            v_driver_base.round,
            v_driver_base.circuit_name,
            v_driver_base.session_type,
            v_driver_base.driver_name,
            v_driver_base.driver_id,
            v_driver_base.constructor_name,
            v_driver_base.constructor_id,
            v_driver_base.engine_manufacturer,
            v_driver_base.regulation_era,
            v_driver_base.grid_position,
            v_driver_base.finish_position,
            (v_driver_base.grid_position - v_driver_base.finish_position) AS pos_gain
           FROM silver.v_driver_base
          ORDER BY v_driver_base.year, v_driver_base.race_id, v_driver_base.driver_id, v_driver_base.session_type, v_driver_base.finish_position
        ), cumulative_base AS (
         SELECT unified_results.year,
            unified_results.race_id,
            unified_results.round,
            unified_results.circuit_name,
            unified_results.session_type,
            unified_results.driver_name,
            unified_results.driver_id,
            unified_results.constructor_name,
            unified_results.constructor_id,
            unified_results.engine_manufacturer,
            unified_results.regulation_era,
            unified_results.grid_position,
            unified_results.finish_position,
            unified_results.pos_gain,
            avg(unified_results.grid_position) OVER (PARTITION BY unified_results.year, unified_results.driver_id, unified_results.session_type ORDER BY unified_results.race_id) AS d_cum_avg_grid,
            avg(unified_results.grid_position) OVER (PARTITION BY unified_results.year, unified_results.driver_id, unified_results.session_type) AS d_seas_avg_grid,
            avg(unified_results.finish_position) OVER (PARTITION BY unified_results.year, unified_results.driver_id, unified_results.session_type ORDER BY unified_results.race_id) AS d_cum_avg_finish,
            avg(unified_results.finish_position) OVER (PARTITION BY unified_results.year, unified_results.driver_id, unified_results.session_type) AS d_seas_avg_finish,
            avg(unified_results.grid_position) OVER (PARTITION BY unified_results.year, unified_results.constructor_id, unified_results.session_type ORDER BY unified_results.race_id) AS c_cum_avg_grid,
            avg(unified_results.grid_position) OVER (PARTITION BY unified_results.year, unified_results.constructor_id, unified_results.session_type) AS c_seas_avg_grid,
            avg(unified_results.finish_position) OVER (PARTITION BY unified_results.year, unified_results.constructor_id, unified_results.session_type ORDER BY unified_results.race_id) AS c_cum_avg_finish,
            avg(unified_results.finish_position) OVER (PARTITION BY unified_results.year, unified_results.constructor_id, unified_results.session_type) AS c_seas_avg_finish,
            max(unified_results.round) OVER (PARTITION BY unified_results.year) AS total_season_races
           FROM unified_results
        )
 SELECT year,
    race_id,
    round,
    circuit_name,
    ((round || '/'::text) || total_season_races) AS round_of_total,
    total_season_races,
    session_type,
    driver_name,
    driver_id,
    constructor_name,
    constructor_id,
    regulation_era,
    grid_position,
    finish_position,
    round(d_cum_avg_grid, 2) AS driver_cum_avg_grid,
    round(stddev(grid_position) OVER (PARTITION BY year, driver_id, session_type ORDER BY race_id), 2) AS driver_cum_stddev_grid,
    round((d_cum_avg_grid - d_seas_avg_grid), 2) AS driver_grid_season_delta,
    round(d_cum_avg_finish, 2) AS driver_cum_avg_finish,
    round(stddev(finish_position) OVER (PARTITION BY year, driver_id, session_type ORDER BY race_id), 2) AS driver_cum_stddev_finish,
    round((d_cum_avg_finish - d_seas_avg_finish), 2) AS driver_finish_season_delta,
    round(c_cum_avg_grid, 2) AS constructor_cum_avg_grid,
    round(stddev(grid_position) OVER (PARTITION BY year, constructor_id, session_type ORDER BY race_id), 2) AS constructor_cum_stddev_grid,
    round((c_cum_avg_grid - c_seas_avg_grid), 2) AS constructor_grid_season_delta,
    round(c_cum_avg_finish, 2) AS constructor_cum_avg_finish,
    round(stddev(finish_position) OVER (PARTITION BY year, constructor_id, session_type ORDER BY race_id), 2) AS constructor_cum_stddev_finish,
    round((c_cum_avg_finish - c_seas_avg_finish), 2) AS constructor_finish_season_delta
   FROM cumulative_base;


--
-- TOC entry 280 (class 1259 OID 20942)
-- Name: v_report_constructor_master; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_report_constructor_master AS
 SELECT cs.year,
    cs.constructor_id,
    cs.constructor_name,
    cs.regulation_era,
    cst.season_position AS wcc_position,
        CASE
            WHEN (cst.season_position = 1) THEN 1
            ELSE 0
        END AS is_wcc_champion,
    cs.official_season_points,
    cs.constructor_race_entries AS total_season_entries,
    cs.race_wins,
    cs.race_podiums,
    round(avg((re.grid_position - re.finish_position)), 3) AS team_avg_pos_gain,
    round(avg(re.constructor_cum_stddev_grid), 3) AS chassis_stability_index,
    round(avg(re.constructor_finish_season_delta), 3) AS mid_season_dev_index,
    cs.race_dnf AS team_dnfs,
    round((((cs.race_dnf)::numeric / (NULLIF(cs.constructor_race_entries, 0))::numeric) * (100)::numeric), 2) AS team_dnf_rate
   FROM ((gold.v_analytics_constructor_season_stats cs
     LEFT JOIN gold.v_analytics_constructor_standings cst ON ((((cs.constructor_id)::text = (cst.constructor_id)::text) AND (cs.year = cst.year))))
     LEFT JOIN gold.v_analytics_race_evolution re ON ((((cs.constructor_id)::text = (re.constructor_id)::text) AND (cs.year = re.year) AND (re.session_type = 'RACE'::text))))
  GROUP BY cs.year, cs.constructor_id, cs.constructor_name, cs.regulation_era, cst.season_position, cs.official_season_points, cs.constructor_race_entries, cs.race_wins, cs.race_podiums, cs.race_dnf;


--
-- TOC entry 282 (class 1259 OID 20952)
-- Name: v_report_driver_master; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_report_driver_master AS
 SELECT ds.year,
    ds.driver_id,
    ds.driver_name,
    ds.team AS constructor_name,
    ds.regulation_era,
    st.season_position AS wdc_position,
        CASE
            WHEN (st.season_position = 1) THEN 1
            ELSE 0
        END AS is_wdc_champion,
    ds.official_season_points,
    ds.season_race_entries,
    ds.race_wins,
    ds.race_podiums,
    round((((ds.race_wins)::numeric / (NULLIF(ds.season_race_entries, 0))::numeric) * (100)::numeric), 2) AS race_win_pct,
    round((((ds.race_podiums)::numeric / (NULLIF(ds.season_race_entries, 0))::numeric) * (100)::numeric), 2) AS race_podium_pct,
    round(avg((re.grid_position - re.finish_position)), 0) AS avg_pos_gain,
    round(avg(re.driver_cum_stddev_grid), 3) AS qualy_volatility,
    round(avg(re.driver_cum_stddev_finish), 3) AS race_consistency,
    round(avg(re.driver_finish_season_delta), 3) AS season_momentum_index,
    ds.race_dnf AS total_dnfs,
    round((((1)::numeric - ((ds.race_dnf)::numeric / (NULLIF(ds.season_race_entries, 0))::numeric)) * (100)::numeric), 2) AS finish_rate_pct
   FROM ((gold.v_analytics_driver_season_stats ds
     LEFT JOIN gold.v_analytics_driver_standings st ON ((((ds.driver_id)::text = (st.driver_id)::text) AND (ds.year = st.year))))
     LEFT JOIN gold.v_analytics_race_evolution re ON ((((ds.driver_id)::text = (re.driver_id)::text) AND (ds.year = re.year) AND (re.session_type = 'RACE'::text))))
  GROUP BY ds.year, ds.driver_id, ds.driver_name, ds.team, ds.regulation_era, st.season_position, ds.official_season_points, ds.season_race_entries, ds.race_wins, ds.race_podiums, ds.race_dnf;


--
-- TOC entry 281 (class 1259 OID 20947)
-- Name: v_report_hall_of_fame_master; Type: VIEW; Schema: gold; Owner: -
--

CREATE VIEW gold.v_report_hall_of_fame_master AS
 SELECT d.driver_name AS entity_name,
    'Driver'::text AS category,
    d.race_starts AS starts,
    d.race_wins AS wins,
    d.race_podiums AS podiums,
    d.titles,
    round((((d.race_wins)::numeric / (NULLIF(d.race_starts, 0))::numeric) * (100)::numeric), 2) AS win_pct,
    round((((d.race_podiums)::numeric / (NULLIF(d.race_starts, 0))::numeric) * (100)::numeric), 2) AS podium_pct,
    d.driver_caused_dnf,
    round((((d.driver_caused_dnf)::numeric / (NULLIF(d.race_starts, 0))::numeric) * (100)::numeric), 2) AS driver_caused_dnf_rate,
    d.car_caused_dnf,
    round((((d.car_caused_dnf)::numeric / (NULLIF(d.race_starts, 0))::numeric) * (100)::numeric), 2) AS car_caused_dnf_rate,
    d.total_dnf,
    round((((d.total_dnf)::numeric / (NULLIF(d.race_starts, 0))::numeric) * (100)::numeric), 2) AS total_dnf_rate
   FROM gold.v_analytics_driver_career_summary d
UNION ALL
 SELECT c.constructor_name AS entity_name,
    'Constructor'::text AS category,
    c.race_starts AS starts,
    c.race_wins AS wins,
    c.race_podiums AS podiums,
    c.titles,
    round((((c.race_wins)::numeric / (NULLIF(c.race_starts, 0))::numeric) * (100)::numeric), 2) AS win_pct,
    round((((c.race_podiums)::numeric / (NULLIF(c.race_starts, 0))::numeric) * (100)::numeric), 2) AS podium_pct,
    c.driver_caused_dnf,
    round((((c.driver_caused_dnf)::numeric / (NULLIF(c.race_starts, 0))::numeric) * (100)::numeric), 2) AS driver_caused_dnf_rate,
    c.car_caused_dnf,
    round((((c.car_caused_dnf)::numeric / (NULLIF(c.race_starts, 0))::numeric) * (100)::numeric), 2) AS car_caused_dnf_rate,
    c.total_dnf,
    round((((c.total_dnf)::numeric / (NULLIF(c.race_starts, 0))::numeric) * (100)::numeric), 2) AS total_dnf_rate
   FROM gold.v_analytics_constructor_career_summary c;

