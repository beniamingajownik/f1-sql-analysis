# 🏆 GOLD LAYER / `reporting` (KPI & METRICS DESCRIPTION)

## **`v_report_driver_master`**
  - A comprehensive seasonal performance matrix providing a deep dive into driver-specific achievements and race-day behavior. It consolidates WDC standings, efficiency ratios, and advanced race dynamics into a high-performance grain (Driver-Year).

**Key Features for BI:**
- **Race Dynamics**: Pre-calculated metrics for Overtaking Efficiency (`avg_pos_gain`) and Qualifying Volatility to identify "Sunday drivers" vs. "Saturday specialists."
- **Season Momentum**: Direct access to the Momentum Index, tracking how a driver's performance evolved relative to the field throughout the year.
- **Reliability Tracking**: Integrated Finish Rate % to benchmark driver consistency and operational risk across different regulation eras.


| Metric / KPI | Business Definition | Use Case (Strategic Value) |
| :--- | :--- | :--- |
| **`wdc_position`** | Final seasonal championship ranking. | **Benchmarking:** Evaluates a driver’s standing against the entire field. |
| **`is_wdc_champion`** | Boolean flag (1/0) for World Champion status. | **Highlighting:** Enables filtering for "Title-winning seasons" in dashboards. |
| **`race_win_pct`** | Efficiency ratio: Total Wins / Total Race Entries. | **Normalization:** Allows fair comparison across eras with different race counts. |
| **`avg_pos_gain`** | Overtaking Efficiency (Grid vs. Finish delta). | **Performance Insight:** Identifies "Sunday Heroes" who maximize results. |
| **`qualy_volatility`** | Standard Deviation of qualifying positions. | **Consistency Check:** Measures mental/technical stability. |
| **`race_consistency`** | Standard Deviation of finishing positions. | **Reliability Index:** Evaluates the driver’s ability to stay in points. |
| **`season_momentum`** | Improvement Index (Late vs. Full-season delta). | **Adaptability:** Tracks the "Learning Curve" and car upgrade adaptation. |
| **`finish_rate_pct`** | Reliability Benchmark (% of races finished). | **Risk Assessment:** Distinguishes mechanical failures from driver errors. |

---

## **`v_report_constructor_master`**
  - A team-centric analytics hub focusing on engineering effectiveness, technical reliability, and R&D progress. It merges seasonal WCC results with unique technical KPIs to evaluate constructor dominance from a factory perspective.

**Key Features for BI:**
- **Engineering KPIs**: Features the **Chassis Stability Index** and **Mid-Season Development Index** to measure how well a team improved their car during the championship.
- **Operational Benchmarking**: Detailed technical DNF rates and position gain metrics to assess the gap between raw car pace and race-day execution.
- **Era-Based Comparison**: Optimized for cross-era analysis, allowing users to compare team dominance (e.g., 1980s McLaren vs. 2020s Red Bull) using normalized points and win ratios.


| Metric / KPI | Business Definition | Use Case (Strategic Value) |
| :--- | :--- | :--- |
| **`wcc_position`** | Final Constructor Championship standing. | **Primary KPI:** The definitive measure of a team’s seasonal success. |
| **`team_avg_pos_gain`** | Strategic & Race Pace Efficiency. | **Operational Insight:** Evaluates pit-wall strategy and tire management. |
| **`chassis_stability`** | Standard Deviation of team qualifying pace. | **Engineering Versatility:** Measures performance across various track layouts. |
| **`mid_season_dev`** | R&D Effectiveness Index. | **Development Race:** Identifies teams that improved mid-season vs. stagnated. |
| **`team_dnf_rate`** | Operational Risk Factor (% of DNFs). | **Quality Control:** Essential for identifying systemic mechanical failures. |

---

## **`v_report_hall_of_fame_master`**
  - A unified "All-Time" career summary for both Drivers and Constructors. It consolidates lifetime achievements, including World Titles, win percentages, and long-term reliability metrics into a single, filterable reporting grain.

**Key Features for BI:**
- **Unified Schema**: Seamlessly switch between Driver and Constructor "Top 10" rankings using a single category filter.
- **Normalization**: Pre-calculated career efficiency ratios (Win %) for cross-generational legacy comparisons.
- **Legacy KPIs**: Direct access to Championship counts, which are typically scattered across seasonal records.


| Metric / KPI | Business Definition | Use Case (Strategic Value) |
| :--- | :--- | :--- |
| **`titles`** | Total World Championships (WDC/WCC). | **Legacy Peak:** Identifies the all-time elite champions of the sport. |
| **`wins`** | Total career race victories. | **Success Volume:** Basic measure of historical competitive dominance. |
| **`win_pct`** | Dominance Ratio (Wins / Starts). | **Efficiency Index:** Compares dominance across different career lengths. |
| **`podium_pct`** | Top-3 Finish Ratio (Podiums / Starts). | **Performance Consistency:** Measures frequency of high-level results. |
| **`dnf_rate`** | Career Attrition Rate (% of DNFs). | **Reliability Factor:** Evaluates long-term technical and operational risk. |
| **`starts`** | Career Longevity (Total race entries). | **Experience Metric:** Highlights long-term commitment and sustainability. |