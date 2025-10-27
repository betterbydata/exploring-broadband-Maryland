--Summary: Maryland broadband deployments by ZIP for 2022-2024 and state census data


-- 1️. Total CAF funding disbursed 2022, 2023, 2024
WITH caf_summary AS (
    SELECT 
        Study_Area_Code,
        Holding_Company,
        SUM(Support_Disbursed_Cumulative) AS total_disbursed
        --Total_Location_Obligation -- this shows cumulative locations obligated to carrier
        --MAX(Filing_Year) AS latest_filing_year
    FROM CAF_sample
    --WHERE Filing_Year BETWEEN 2022 AND 2024
    GROUP BY Study_Area_Code, Holding_Company
    --ORDER BY total_disbursed DESC
),

-- 2️. Count of deployments by ZIP 
deployment_summary AS (
    SELECT 
        Study_Area_Code,
        Deployment_ZIP_Code,
        COUNT(*) AS total_locations,
        --COUNT(DISTINCT Technology) AS technology_count,
        --COUNT(DISTINCT Download_Upload_Speed_Tier) AS speed_tier_count,
        MAX(Deployment_Date) AS most_recent_deployment
    FROM speedandlocation
    WHERE Filing_Year >= 2022
    GROUP BY Study_Area_Code, Deployment_ZIP_Code
    --ORDER BY total_locations DESC
),

-- 3️. Dont use! / Average statewide deployments per ZIP 
statewide_avg AS (
    SELECT 
        AVG(zip_counts) AS avg_statewide_deployments
    FROM (
        SELECT Deployment_ZIP_Code, COUNT(*) AS zip_counts
        FROM speedandlocation
        GROUP BY Deployment_ZIP_Code
    ) AS a
),

-- 4️. Maryland census demographics based on zip code tabulated area
census_data AS (
    SELECT 
        ZCTA5N AS zip_code,
        POP100 AS population_total,
        HU100 AS housing_units,
        VACNS AS vacant_units,
        POP65 AS population_65plus,
        ROUND(MEDAGE,0) AS median_age,
        ROUND(PHOWN, 2) AS ownership_rate
    FROM md_zcta
)

-- 5️. Identify most funded study area
SELECT
    d.Deployment_ZIP_Code AS zip_code,
    d.total_locations,
    --d.technology_count,
   -- d.speed_tier_count,
    --d.most_recent_deployment,
    c.Holding_Company,
    --c.Total_Location_Obligation,
    --c.total_disbursed,
    cen.population_total,
    cen.housing_units,
    cen.vacant_units,
    cen.population_65plus,
    cen.median_age,
    cen.ownership_rate,
    --s.avg_statewide_deployments

--    
CASE WHEN cen.housing_units > 0 -- prevents dividing by zero for zips with no housing units 
        THEN ROUND((CAST(d.total_locations AS FLOAT) / cen.housing_units) * 100, 0)
    ELSE NULL
END AS deployment_rate_pct

FROM deployment_summary AS d
LEFT JOIN caf_summary AS c
    ON c.Study_Area_Code = d.Study_Area_Code
LEFT JOIN census_data AS cen
    ON cen.zip_code = d.Deployment_ZIP_Code
CROSS JOIN statewide_avg AS s
WHERE d.Study_Area_Code = '180216' OR d.Study_Area_Code = '189039'
ORDER BY d.total_locations DESC;

---------FINAL FINAL FINAL-----------------
--Summary: Maryland broadband deployments by ZIP for 2022-2024 and state census data


-- Total cumulative Connect American Funds disbursed per study area and provider holding company
WITH caf_summary AS (
    SELECT 
        Study_Area_Code,
        Holding_Company,
        FORMAT(SUM(Support_Disbursed_Cumulative), 'C0') AS total_disbursed
    FROM CAF_sample
    GROUP BY Study_Area_Code, Holding_Company
),

-- Count of deployments by ZIP 
deployment_summary AS (
    SELECT 
        Study_Area_Code,
        Deployment_ZIP_Code,
        COUNT(*) AS total_locations
    FROM speedandlocation
    WHERE Filing_Year >= 2022
    GROUP BY Study_Area_Code, Deployment_ZIP_Code
),

-- Maryland census demographics based on zip code tabulated area
census_data AS (
    SELECT 
        ZCTA5N AS zip_code,
        POP100 AS population_total,
        HU100 AS housing_units,
        VACNS AS vacant_units,
        POP65 AS population_65plus,
        ROUND(MEDAGE,0) AS median_age,
        ROUND(PHOWN, 2) AS ownership_rate
    FROM md_zcta
)

-- Identify most funded study area
SELECT
    d.Deployment_ZIP_Code AS zip_code,
    d.total_locations,
    c.Study_Area_Code,
    c.Holding_Company,
    c.total_disbursed,
    cen.population_total,
    cen.housing_units,
    cen.vacant_units,
    cen.population_65plus,
    cen.median_age,
    cen.ownership_rate,

--  Including rate of depolyments per households  
CASE WHEN cen.housing_units > 0 
        THEN ROUND((CAST(d.total_locations AS FLOAT) / cen.housing_units) * 100, 2)
    ELSE NULL
END AS deployment_rate_pct

FROM deployment_summary AS d
LEFT JOIN caf_summary AS c
    ON c.Study_Area_Code = d.Study_Area_Code
LEFT JOIN census_data AS cen
    ON cen.zip_code = d.Deployment_ZIP_Code
WHERE d.Study_Area_Code = '180216' OR d.Study_Area_Code = '189039'
ORDER BY d.total_locations DESC;

