# Project Plan & Evolution: F1 SQL Analysis diary

## 🎯 Executive Summary
This project has evolved from a basic SQL query exercise into a robust **End-to-End Data Warehouse** solution. The primary objective is to analyze 70+ years of Formula 1 history by transforming raw data into high-value business insights, specifically optimized for Power BI visualization.

### Primary Research Areas:
- **Driver Performance & Legacy**: Career-long tracking of efficiency and titles.
- **Constructor Engineering Effectiveness**: Technical reliability and R&D progress.
- **Race Dynamics**: Sunday overtaking efficiency vs. Saturday qualifying pace.
- **Stability & Volatility**: Measuring consistency through statistical variance (Standard Deviation).

---

## 🏗️ Architectural Evolution (The Medallion Journey)
A key milestone in this project was the transition to a **Medallion Architecture**, ensuring scalability and a "Single Source of Truth".

1. **Bronze (Raw Data)**: Sourced from the Open Source F1DB project.
2. **Silver (Warehouse)**: 
    - Implementation of complex championship logic (dropped results 1950-1990).
    - Normalization of diverse session types and technical eras.
3. **Gold (Analytics & Reporting)**:
    - **Analytics**: Modular views for granular deep-dives.
    - **Reporting**: Power BI-ready "Master Views" optimized for dashboard performance.

---

## 🏁 Completed Milestones & Development Roadmap

### Phase 1: Foundational Engine (Silver Layer) - **[COMPLETED]**
- **[CLEANING]** Developed `v_driver_base` and `v_constructor_base` to handle DNS/DNF flags, pit-lane starts, and grid normalization.
- **[LOGIC]** Solved the "Dropped Results" challenge for early F1 eras (1950-1990).
- **[LOGIC]** Standardized "Shared Drives" and driver-fault vs. car-fault DNF categorization.

### Phase 2: Analytical Insight (Gold Layer / Analytics) - **[COMPLETED]**
- **[PERFORMANCE]** Created views for seasonal and all-time career aggregates.
- **[DYNAMICS]** Developed the **Race Evolution** engine, calculating rolling averages and position deltas.
- **[RELIABILITY]** Engineered detailed DNF profiles to distinguish between human error and engineering failure.

### Phase 3: Reporting & Optimization (Gold Layer / Reporting) - **[COMPLETED]**
- **[REFACTOR]** Restructured the directory system into `views/silver/` and `views/gold/` hierarchy.
- **[MASTER VIEWS]** Developed three core reporting views (`v_report_driver_master`, `v_report_constructor_master`, `v_report_hall_of_fame_master`).
- **[STATISTICS]** Shifted heavy computations (Standard Deviation, Mid-Season Dev Indices) from DAX to SQL.

### Phase 4: Data Quality & Semantic Modeling - **[COMPLETED]**
- **[AUDIT]** Resolved UTF-8 encoding issues and character corruption across all tables (e.g., Adrián, Pérez).
- **[ETL]** Implemented Power Query **Reference** logic to create lean Dimension tables (`Dim_Drivers`, `Dim_Constructors`).
- **[MODELING]** Architected a professional **Star Schema** with a custom `Dim_Year` dimension to enable cross-report time intelligence.
- **[DOCS]** Established `FRAMEWORK_DOCS.md` to document the BI development lifecycle.

### Phase 5: Visualization & DAX - **[IN PROGRESS]**
- **[UI/UX]** Designing a three-tier dashboard (Legends, Athletes, Engineering) with a Dark Mode aesthetic.
- **[DAX]** Developing advanced measures for dynamic ranking and "Season Momentum" indices.

---

## 🛠️ Technical Deep Dive (Key KPIs Developed)
- **Overtaking Efficiency**: Average position gain per race entry.
- **Chassis Stability Index**: Qualifying volatility measured by Standard Deviation.
- **R&D Effectiveness**: Mid-season performance improvement relative to the seasonal mean.
- **Legacy Dominance**: Normalized Win % and Podium % across different era lengths.

---

## 💻 Tech Stack
- **Database**: PostgreSQL (Core transformation engine).
- **Architecture**: Medallion-style layered views (Silver/Gold).
- **Environment**: PGAdmin4 & Docker.
- **Modeling**: Power BI (Power Query ETL + DAX Semantic Layer).
- **Documentation**: Markdown (README.md, TECHNICAL_ARCHITECTURE.md).

---

### 📈 Current Project Status
**Current State**: Backend architecture and Semantic Model are 100% operational. Transitioning to final dashboard visualization.
**Next Milestone**: Implementation of the "Sunday King Index" and Season Momentum DAX measures.