# 📂 LAYER ARCHITECTURE

This directory contains the core logic of the F1 Data Warehouse, organized into a multi-layer architecture to ensure data integrity, analytical depth, and reporting performance.

---

## 🥈 SILVER LAYER / (`base` / `logic`)
*The Silver Layer focuses on data normalization and the application of historical sports logic.*

- **`v_driver_base`**
    - Normalized view providing cleaned driver results, basic biography info, and unified session types across all eras.
- **`v_driver_championship_logic`**
    - Implements historical points systems and seasonal ranking logic to calculate cumulative driver standings.
- **`v_constructor_base`**
    - Normalized view for constructor results, unifying team data, engine manufacturers, and technical identifiers.
- **`v_constructor_championship_logic`**
    - Implements historical points systems and seasonal ranking logic to calculate cumulative constructor standings.

---

## 🥇 GOLD LAYER / `analytics`
*The Analytics layer provides modular "Building Blocks" for deep-dive exploration and statistical modeling.*

- **`v_analytics_driver_standings`** 
  - Final seasonal driver rankings, providing championship positions and year-end point totals.
- **`v_analytics_constructor_standings`** 
  - Final seasonal constructor rankings, providing championship positions and year-end point totals.
- **`v_analytics_driver_career_summary`** 
  - Full career aggregates (Total wins, podiums, starts, DNF rate). Powers the Achievements dashboard section.
- **`v_analytics_constructor_career_summary`** 
  - Comprehensive team career aggregates (Total wins, podiums, starts, DNF rate). Powers the Achievements dashboard section.
- **`v_analytics_driver_season_stats`** 
  - Seasonal performance metrics (Avg start position, points per race, consistency). Powers the Performance analysis section.
- **`v_analytics_constructor_season_stats`** 
  - Team-level seasonal performance metrics, mirroring the driver stats for constructor-focused analysis.
- **`v_analytics_race_evolution`** 
  - Detailed position delta data (Grid vs Finish) enhanced with rolling averages and volatility metrics. Powers the Race Dynamics section.

---

## 🏆 GOLD LAYER / `reporting` (Power BI Ready)
*The Reporting layer serves as the **Consumption Layer** for the project. These "Master Views" are optimized for Power BI integration, minimizing DAX complexity by centralizing heavy analytical computations within the SQL engine.*

- **`v_report_driver_master`** 
  - A comprehensive seasonal performance matrix. It consolidates WDC standings, Overtaking Efficiency, and **Season Momentum** metrics into a single Driver-Year grain, ideal for trend analysis.
- **`v_report_constructor_master`** 
  - A team-centric reporting table featuring strategic KPIs such as the **Chassis Stability Index** and **Mid-Season Development Index** to evaluate engineering and R&D effectiveness.
- **`v_report_hall_of_fame`** 
  - A unified legacy summary for both Drivers and Constructors. Provides normalized efficiency metrics (Win/Podium %) and granular risk profiles (Driver vs. Car DNF rates) for cross-era benchmarking.

---

### 🚀 Key Technical Features:
- **Star Schema Ready**: Views are engineered to serve as high-performance "Wide Fact Tables" in a BI environment.
- **Logic Centralization**: Complex KPIs (Volatility, Deltas) are calculated at the source to ensure a "Single Source of Truth."
- **Era-Based Normalization**: Handles the technical complexity of 70+ years of F1 regulations to provide fair historical comparisons.