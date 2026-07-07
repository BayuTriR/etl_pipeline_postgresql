-- ==============================================================================
-- 18. Ranking pickup zone berdasarkan total revenue. 
-- ==============================================================================

SELECT 
    DENSE_RANK() OVER (ORDER BY SUM(total_amount) DESC) AS rank,
    pickup_location_id AS zone_id,
    pickup_borough AS borough,
    pickup_zone AS zone_name,
    COUNT(*) AS total_trips,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue
FROM gold.vw_trip_enriched
WHERE pickup_location_id IS NOT NULL AND pickup_zone <> 'Unknown'
GROUP BY pickup_location_id, pickup_borough, pickup_zone
ORDER BY total_revenue DESC;

-- ==============================================================================
-- 19. Ranking pickup zone per borough.
-- ==============================================================================

WITH zone_revenue AS (
    SELECT 
        pickup_borough AS borough, 
        pickup_location_id AS zone_id,
        pickup_zone AS zone_name,
        COUNT(*) AS total_trips,
        ROUND(SUM(total_amount)::numeric, 2) AS total_revenue
    FROM gold.vw_trip_enriched
    WHERE pickup_borough IS NOT NULL AND pickup_borough <> 'Unknown'
    GROUP BY pickup_borough, pickup_location_id, pickup_zone
)
SELECT 
    DENSE_RANK() OVER (PARTITION BY borough ORDER BY total_revenue DESC) AS rank_in_borough,
    borough,
    zone_id,
    zone_name,
    total_trips,
    total_revenue
FROM zone_revenue
ORDER BY borough ASC, rank_in_borough ASC;