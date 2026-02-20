/* ============================================================
   INDIAN TOURISM ANALYSIS
   Author: Sampurna Kundu
   Tool: Oracle SQL
   Dataset: Indian Tourist Attractions

   Objective:
   To analyze Indian tourist destinations using engagement,
   pricing, geographic performance, historical classification,
   demand segmentation, and a weighted ranking model.
============================================================ */


/* ------------------------------------------------------------
   1. KPI DASHBOARD

   This query provides an overall performance snapshot of Indian
   tourist destinations including total places, geographic spread,
   engagement metrics, pricing levels, and visit duration.

------------------------------------------------------------ */
SELECT
    COUNT(Name) AS total_places,
    COUNT(DISTINCT STATE) AS total_states,
    ROUND(AVG(GOOGLE_REVIEW_RATING),2) AS avg_rating,
    ROUND(AVG(ENTRANCE_FEE_IN_INR),0) AS avg_entry_fee,
    ROUND(AVG(TIME_NEEDED_TO_VISIT_IN_HRS),2) AS avg_visit_time,
    ROUND(SUM(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS),2) AS total_reviews_lakhs
FROM travel;


/* ------------------------------------------------------------
   2. ZONE-WISE TOURISM PERFORMANCE

   This query compares tourism performance across geographic zones
   to identify high-demand regional clusters.

------------------------------------------------------------ */
SELECT
    ZONE,
    COUNT(*) AS total_places,
    ROUND(AVG(GOOGLE_REVIEW_RATING),2) AS avg_rating,
    ROUND(SUM(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS),2) AS total_reviews
FROM travel
GROUP BY ZONE
ORDER BY total_reviews DESC;


/* ------------------------------------------------------------
   3. STATE-WISE REVENUE POTENTIAL

   This query estimates revenue strength across states using
   aggregated entrance fee data.

------------------------------------------------------------ */
SELECT
    STATE,
    COUNT(*) AS total_places,
    ROUND(AVG(ENTRANCE_FEE_IN_INR),0) AS avg_fee,
    ROUND(SUM(ENTRANCE_FEE_IN_INR),0) AS total_fee
FROM travel
GROUP BY STATE
ORDER BY total_fee DESC;


/* ------------------------------------------------------------
   4. TOP 30 RATED PLACES

   This query identifies the highest-rated tourist destinations
   based purely on customer satisfaction scores.

------------------------------------------------------------ */
SELECT 
    Name, 
    City, 
    State, 
    ROUND(Google_review_rating, 2) AS Google_Review
FROM travel
ORDER BY Google_review_rating DESC
FETCH FIRST 30 ROWS ONLY;


/* ------------------------------------------------------------
   5. TOP 5 PLACES BY SEASON

   Purpose:
   This query identifies the top 5 destinations within each
   seasonal category based on review volume.
   RANK() is used with PARTITION BY BEST_TIME_TO_VISIT to rank
   places within each season, and LISTAGG consolidates the top
   five place names into a single row per season.

------------------------------------------------------------ */
SELECT
    BEST_TIME_TO_VISIT,
    LISTAGG(NAME, ', ') WITHIN GROUP (ORDER BY rnk) AS TOP_5_PLACES
FROM
(
    SELECT BEST_TIME_TO_VISIT, NAME,
           RANK() OVER (
               PARTITION BY BEST_TIME_TO_VISIT
               ORDER BY NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS DESC
           ) AS rnk
    FROM travel
)
WHERE rnk <= 5
GROUP BY BEST_TIME_TO_VISIT
ORDER BY BEST_TIME_TO_VISIT;


/* ------------------------------------------------------------
   6. PRICE SEGMENT ANALYSIS (Free vs Low Cost vs Premium)

   This query compares demand and rating performance across
   different pricing tiers.
   A CASE statement classifies attractions into Free, Low Cost,
   and Premium categories before aggregating performance metrics.

------------------------------------------------------------ */
SELECT
    CASE
        WHEN ENTRANCE_FEE_IN_INR = 0 THEN 'Free'
        WHEN ENTRANCE_FEE_IN_INR BETWEEN 1 AND 200 THEN 'Low Cost'
        ELSE 'Premium'
    END AS PRICE_SEGMENT,
    COUNT(*) AS TOTAL_PLACES,
    ROUND(AVG(GOOGLE_REVIEW_RATING),2) AS AVG_RATING,
    ROUND(AVG(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS),2) AS AVG_REVIEWS
FROM travel
GROUP BY
    CASE
        WHEN ENTRANCE_FEE_IN_INR = 0 THEN 'Free'
        WHEN ENTRANCE_FEE_IN_INR BETWEEN 1 AND 200 THEN 'Low Cost'
        ELSE 'Premium'
    END
ORDER BY AVG_REVIEWS DESC;


/* ------------------------------------------------------------
   7. HISTORICAL ERA ANALYSIS

   This query evaluates tourism performance across historical
   periods to understand era-based engagement trends.
   A CASE statement converts establishment years, including
   BC (negative values) and unknown (0), into categorized eras
   for structured comparison.

------------------------------------------------------------ */
SELECT 
    CASE 
        WHEN ESTABLISHMENT_YEAR < 0 THEN 'Ancient (BC)'
        WHEN ESTABLISHMENT_YEAR = 0 THEN 'Unknown / Prehistoric'
        WHEN ESTABLISHMENT_YEAR BETWEEN 1 AND 800 THEN 'Early Medieval'
        WHEN ESTABLISHMENT_YEAR BETWEEN 801 AND 1500 THEN 'Medieval'
        WHEN ESTABLISHMENT_YEAR BETWEEN 1501 AND 1800 THEN 'Pre-Colonial'
        WHEN ESTABLISHMENT_YEAR BETWEEN 1801 AND 1947 THEN 'Colonial'
        ELSE 'Modern India'
    END AS HISTORICAL_ERA,
    COUNT(*) AS TOTAL_PLACES,
    ROUND(AVG(GOOGLE_REVIEW_RATING),2) AS AVG_RATING,
    ROUND(AVG(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS),2) AS AVG_REVIEWS_LAKHS,
    ROUND(AVG(ENTRANCE_FEE_IN_INR),0) AS AVG_ENTRANCE_FEE
FROM TRAVEL
GROUP BY 
    CASE 
        WHEN ESTABLISHMENT_YEAR < 0 THEN 'Ancient (BC)'
        WHEN ESTABLISHMENT_YEAR = 0 THEN 'Unknown / Prehistoric'
        WHEN ESTABLISHMENT_YEAR BETWEEN 1 AND 800 THEN 'Early Medieval'
        WHEN ESTABLISHMENT_YEAR BETWEEN 801 AND 1500 THEN 'Medieval'
        WHEN ESTABLISHMENT_YEAR BETWEEN 1501 AND 1800 THEN 'Pre-Colonial'
        WHEN ESTABLISHMENT_YEAR BETWEEN 1801 AND 1947 THEN 'Colonial'
        ELSE 'Modern India'
    END
ORDER BY TOTAL_PLACES DESC;


/* ------------------------------------------------------------
   8. DEMAND BUCKET ANALYSIS

   This query segments attraction types into Low, Medium,
   and High demand categories based on average review volume.
   The inner query calculates average reviews per type,
   and the outer query aggregates results per demand bucket.

------------------------------------------------------------ */
SELECT
    DEMAND_BUCKET,
    COUNT(DISTINCT TYPE) AS TOTAL_TYPES,
    SUM(TOTAL_PLACES) AS TOTAL_PLACES,
    ROUND(AVG(AVG_REVIEWS),2) AS AVG_REVIEWS
FROM
(
    SELECT
        TYPE,
        COUNT(*) AS TOTAL_PLACES,
        AVG(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS) AS AVG_REVIEWS,
        CASE
            WHEN AVG(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS) < 0.3 THEN 'Low Demand'
            WHEN AVG(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS) < 0.6 THEN 'Medium Demand'
            ELSE 'High Demand'
        END AS DEMAND_BUCKET
    FROM travel
    GROUP BY TYPE
)
GROUP BY DEMAND_BUCKET
ORDER BY AVG_REVIEWS DESC;


/* ------------------------------------------------------------
   9. MULTI-FACTOR DESTINATION RANKING

   This query ranks the top 10 tourist destinations using a
   weighted composite scoring model.
   Review volume is normalized using MAX() OVER(),
   binary scoring is applied for airport access and DSLR allowance,
   entrance fee is inversely weighted, and a composite score is
   calculated before applying RANK() to determine the top 10.

------------------------------------------------------------ */
SELECT
    NAME, STATE, AIRPORT_WITH_50KM_RADIUS, DSLR_ALLOWED,
    NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS, ENTRANCE_FEE_IN_INR,
    final_score, rank_no
FROM (
    SELECT
        NAME, STATE, AIRPORT_WITH_50KM_RADIUS, DSLR_ALLOWED,
        NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS, ENTRANCE_FEE_IN_INR,
        ROUND(
            (NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS / max_reviews) * 0.5 +
            airport_score * 0.2 +
            dslr_score * 0.1 +
            (1 - (ENTRANCE_FEE_IN_INR / max_fee)) * 0.2
        ,3) AS final_score,
        RANK() OVER (
            ORDER BY
            (NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS / max_reviews) * 0.5 +
            airport_score * 0.2 +
            dslr_score * 0.1 +
            (1 - (ENTRANCE_FEE_IN_INR / max_fee)) * 0.2 DESC
        ) AS rank_no
    FROM (
        SELECT
            t.*,
            MAX(NUMBER_OF_GOOGLE_REVIEW_IN_LAKHS) OVER() AS max_reviews,
            MAX(ENTRANCE_FEE_IN_INR) OVER() AS max_fee,
            CASE WHEN AIRPORT_WITH_50KM_RADIUS = 'Yes' THEN 1 ELSE 0 END AS airport_score,
            CASE WHEN DSLR_ALLOWED = 'Yes' THEN 1 ELSE 0 END AS dslr_score
        FROM travel t
        WHERE ENTRANCE_FEE_IN_INR > 0
    )
)
WHERE rank_no <= 10
ORDER BY rank_no;