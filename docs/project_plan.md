# Project Plan & Evolution: F1 SQL Analysis diary

## 🎯 Executive Summary
This project has evolved from a basic SQL query exercise into a robust **End-to-End Data Warehouse** solution. The primary objective is to analyze 70+ years of Formula 1 history by transforming raw data into high-value business insights, specifically optimized for Power BI visualization.

### Primary Research Areas:
- **Driver Performance & Legacy:** Career-long tracking of efficiency and titles.
- **Constructor Engineering Effectiveness:** Technical reliability and R&D progress.
- **Race Dynamics:** Sunday overtaking efficiency vs. Saturday qualifying pace.
- **Stability & Volatility:** Measuring consistency through statistical variance (Standard Deviation).

---

## 🏗️ Architectural Evolution (The Medallion Journey)
A key milestone in this project was the transition from a flat folder structure to a **Medallion Architecture**, ensuring scalability and a "Single Source of Truth."

1.  **Bronze (Raw Data):** Sourced from the Open Source F1DB project.
2.  **Silver (Warehouse):** - Implementation of complex championship logic (dropped results 1950-1990).
    - Normalization of diverse session types and technical eras.
3.  **Gold (Analytics & Reporting):**
    - **Analytics:** Modular views for granular deep-dives.
    - **Reporting:** Power BI-ready "Master Views" optimized for dashboard performance.

---

## 🏁 Completed Milestones & Development Roadmap

### Phase 1: Foundational Engine (Silver Layer) - **[COMPLETED]**
- **[CLEANING]** Developed `v_driver_base` and `v_constructor_base` to handle DNS/DNF flags, pit-lane starts, and grid normalization.
- **[LOGIC]** Solved the "Dropped Results" challenge for early F1 eras (1950-1990), ensuring calculated standings match historical FIA records.
- **[LOGIC]** Standardized "Shared Drives" and driver-fault vs. car-fault DNF categorization.

### Phase 2: Analytical Insight (Gold Layer / Analytics) - **[COMPLETED]**
- **[PERFORMANCE]** Created views for seasonal and all-time career aggregates (Wins, Podiums, Points Market Share).
- **[DYNAMICS]** Developed the **Race Evolution** engine, calculating rolling averages and position deltas for every race since 1950.
- **[RELIABILITY]** Engineered detailed DNF profiles to distinguish between human error and engineering failure.

### Phase 3: Reporting & Optimization (Gold Layer / Reporting) - **[COMPLETED]**
- **[REFACTOR]** Restructured the entire directory system into a `views/silver/` and `views/gold/` hierarchy to meet professional Data Engineering standards.
- **[MASTER VIEWS]** Developed three core reporting views (`v_report_driver_master`, `v_report_constructor_master`, `v_report_hall_of_fame`) designed to serve as wide fact tables for Power BI.
- **[STATISTICS]** Shifted heavy computations (Standard Deviation for Volatility, Mid-Season Development Indices) from DAX to SQL to maximize report responsiveness.

### Phase 4: Data Quality & Visualization - **[IN PROGRESS]**
- **[AUDIT]** Cross-referencing current Gold-layer outputs with official standings to ensure 100% logic accuracy.
- **[BI]** Connecting Power BI to the Reporting Layer to build the final portfolio dashboard.

---

## 🛠️ Technical Deep Dive (Key KPIs Developed)
Throughout the project, we moved beyond simple counting to advanced metrics:
- **Overtaking Efficiency:** Average position gain per race entry.
- **Chassis Stability Index:** Qualifying volatility measured by Standard Deviation.
- **R&D Effectiveness:** Mid-season performance improvement relative to the seasonal mean.
- **Legacy Dominance:** Normalized Win % and Podium % across different era lengths.

---

## 💻 Tech Stack
- **Database:** PostgreSQL (Core transformation and analytical engine).
- **Architecture:** Medallion-style layered views (Silver/Gold).
- **Environment:** PGAdmin4.
- **Version Control:** Git (Utilizing `git mv` for non-destructive architectural refactoring).
- **Visualization:** Power BI (Reporting Layer consumption).

---

### 📈 Current Project Status
**Current State:** Data Warehouse is fully operational. The backend architecture is "Power BI-Ready," with pre-calculated KPIs ready for visualization.
**Next Milestone:** Completion of the interactive Power BI Portfolio Dashboard.