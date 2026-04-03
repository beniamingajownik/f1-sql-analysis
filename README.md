# 🏎️ F1 Data Analytics Engine: Performance & Reliability Intelligence

### **An End-to-End SQL Analytics Ecosystem for Formula 1 Historical Data**

This project is a sophisticated data warehousing and analytics engine designed to transform raw Formula 1 racing data into actionable sporting insights. Utilizing a **Medallion Architecture**, the system processes historical data to analyze driver and constructor performance, consistency, and reliability across different regulation eras (e.g., Turbo Hybrid, Ground Effect).

---

### 🏗️ Data Architecture & Lineage
To distinguish between the source data and my analytical work, the project uses custom schemas:
* **`public` (Source)**: Raw tables and default views provided by the dataset.
* **`silver` (My Logic)**: Base transformations, data cleaning, and championship logic.
* **`gold` (My Insights)**: Final analytical marts and KPIs ready for reporting.


## 🏗️ Data Architecture

The project is structured into logical layers to ensure data integrity, scalability, and ease of reporting:

### **1. Silver Layer (Warehouse & Logic)**
* **Purpose**: Data cleaning, standardization, and core business logic implementation.
* **Core Views**: 
    * `v_driver_base` & `v_constructor_base`: Standardized race results serving as the foundation for all analytical queries.
    * `v_driver_championship_logic` & `v_constructor_championship_logic`: Implements complex points-scoring and standing rules.

### **2. Gold Layer (Analytics Marts)**
* **Purpose**: High-performance, "Business-Ready" views optimized for deep-dive analysis and Power BI reporting.
* **Key Components**:
    * `v_analytics_driver_standings` & `v_analytics_constructor_standings`: Official season rankings and title tracking.
    * `v_analytics_race_evolution`: A dynamic view tracking cumulative averages, running stats, and "Season Deltas".
    * `v_analytics_driver_season_stats` & `v_analytics_constructor_season_stats`: Aggregated season-level KPIs like average grid position and points per race.

---

## 📊 Analytics Deep-Dive

The engine answers complex sporting questions through several specialized analysis modules:

### **1. Performance Evolution (Season, Career, & Era)**
* **Dominance Metrics**: Calculates the "Point Market Share" of champions and percentage-based victory rates to measure historical domination.
* **Grid-to-Finish Dynamics**: Analyzes the `conversion_delta` — the ability to convert qualifying speed into race results.
* **YoY Progress**: Tracks Year-over-Year (YoY) point growth to identify rising talents and team improvements.
* **Era Benchmarking**: Compares point gaps between champions and runners-up to identify the most competitive eras in F1 history.

### **2. Advanced Consistency Analysis**
* **Volatility Metrics**: Uses **Standard Deviation** and **MAD (Mean Absolute Deviation)** to quantify performance stability.
* **Skill Isolation**: Filters out seasons with high technical failure rates (>20% DNF) to focus strictly on driver-controlled performance.
* **Streak Intelligence**: Employs **Gaps and Islands** logic to detect historical streaks for points, podiums, wins, and classified finishes.

### **3. Reliability & Integrity**
* **DNF Rate Benchmarking**: Calculates DNF rates for drivers and constructors per season and era to assess mechanical versus operational reliability.
* **Finish Rate Analysis**: Tracks the percentage of races finished per season to evaluate team "bulletproofness".

### **4. General Sporting Achievements**
* **Title Distribution**: Aggregates World Drivers' (WDC) and Constructors' (WCC) championships by country and continent.
* **Achievement Tracking**: Comprehensive counting of race/sprint victories and podiums for all-time leaderboards.

---

## 📊 Interactive Business Intelligence (Power BI)
This project is a complete full-stack analytical solution, featuring a professional Power BI dashboard that transforms complex SQL analysis into an immersive visual experience.

**A ready-to-use `f1-data-viz.pbix` file is available for download in the [`/powerBI`](https://github.com/beniamingajownik/f1-sql-analysis/tree/main/powerBI) directory.**

### 🏎️ Dashboard Capabilities:
* **Intuitive Navigation**: A custom navigation bar allows seamless movement between three specialized modules: **Legends** (Career Hall of Fame), **Drivers** (Seasonal Deep-Dives), and **Teams** (Constructor Performance).
* **Dynamic Performance Metrics**: Real-time tracking of **Running Totals**, **Cumulative Podiums**, and **Year-over-Year (YoY)** standings using advanced DAX and dynamic relationship modeling.
* **High-End UX**: Implemented a modern Dark Mode interface featuring custom F1 branding and visual performance indicators (▲/▼) to provide instant analytical feedback.

### 🛠️ Optimized Data Engine:
The reporting layer utilizes specialized "Wide Fact Tables" (`v_report_driver_master`, `v_report_constructor_master`) optimized for a high-performance Star Schema. These views are engineered to minimize DAX complexity while maximizing dashboard responsiveness through pre-calculated metrics:
* **Pre-calculated Volatility**: Database-level standard deviation for instant consistency visualizations.
* **Normalized Efficiency Rates**: Win/Podium percentages for fair benchmarking across different technical regulation eras.
* **Era-based Filtering**: Native support for comparing historical dominance and operational reliability.

---

## 🛠️ Technical Stack & Techniques

* **Language**: PostgreSQL 18.
* **Window Functions**: Extensive use of `LAG()`, `LEAD()`, `RANK()`, and cumulative `AVG()` for trend detection.
* **Advanced Logic**: Gaps and Islands pattern for uninterrupted streak detection.
* **Data Integrity**: Validates race sequence integrity (DNS/Injury handling) to ensure historical accuracy.
* **Mathematical Precision**: Explicit type casting (`::numeric`) and `NULLIF` handling for accurate percentage calculations.

---

## 📂 Project Structure

* `/silver/`: Warehouse foundation and core championship logic.
* `/gold/`: Specialized analytics views for Drivers, Constructors, and Races.
* `/analysis/`: Ready-to-use SQL scripts for deep-dive investigations like:
    * `driver_performance.sql`: Career and season-level KPIs.
    * `constructor_consistency.sql`: Team stability and streak logic.
    * `reliability.sql`: DNF and finish rate benchmarking.

---

## ⚙️ Setup & Installation

* Full portfolio project is available for everyone and ready to use. For user convenience It's possible to obtain the project in 3 ways:
    * Manual SQL Import (pgAdmin / psql) 
    * Automated Deployment via Docker
    * Manual Local Connection via Docker

**`For a detailed installation instructions visit:`** **[Installation instructions](https://github.com/beniamingajownik/f1-sql-analysis/blob/main/installation/readme.md)**

---

## 📚 Data Source & Attribution

The data used in this project is sourced from **F1DB**, a comprehensive open-source database for Formula 1. 

* **Data Source**: [f1db/f1db on GitHub](https://github.com/f1db/f1db)
* **License**: Licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)

All race results, driver statistics, and historical records are provided by the F1DB contributors. This project is an independent analysis and is not affiliated with the Formula 1 companies.

---

**Author**: Beniamin Gajownik - [Github](https://github.com/beniamingajownik) / [LinkedIn](https://www.linkedin.com/in/beniamin-gajownik)

**Date**: March 2026  