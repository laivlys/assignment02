/*
 What are the top five neighborhoods according to your accessibility metric?
 */

SET search_path TO public, phl, septa, census;
WITH stop_accessibility AS (
    SELECT
        s.stop_id,
        s.geog,
        s.wheelchair_boarding
    FROM septa.bus_stops s
),
stops_by_neighborhood AS (
    SELECT
        n.name AS neighborhood_name,
        COUNT(DISTINCT s.stop_id) AS num_bus_stops,
        -- Count of fully accessible stops (wheelchair boarding = 1)
        COUNT(DISTINCT s.stop_id) FILTER (
            WHERE s.wheelchair_boarding = 1
        ) AS num_fully_accessible,
        -- Count of inaccessible stops (wheelchair boarding = 0 or 2)
        COUNT(DISTINCT s.stop_id) FILTER (
            WHERE s.wheelchair_boarding IN (0, 2)
        ) AS num_inaccessible,
        ST_Area(n.geog::geometry) / 1000000 AS area_sq_km
    FROM phl.neighborhoods n
    LEFT JOIN stop_accessibility s
        ON ST_Within(s.geog::geometry, n.geog::geometry)
    GROUP BY n.name, n.geog
),
scored_neighborhoods_by_stops AS (
    SELECT
        neighborhood_name,
        num_inaccessible,
        num_fully_accessible,
        COALESCE(
            ROUND(
                (num_fully_accessible::numeric / NULLIF(area_sq_km::numeric, 0)) *
                (num_fully_accessible::numeric / NULLIF(num_bus_stops::numeric, 0)),
                2 -- Round to 2 decimal places
            ),
            0
        ) AS accessibility_metric
    FROM stops_by_neighborhood
)
SELECT 
    neighborhood_name,
    accessibility_metric,
    num_fully_accessible::INTEGER AS num_bus_stop_accessible,
    num_inaccessible::INTEGER AS num_bus_stop_inaccessible
FROM scored_neighborhoods_by_stops
ORDER BY accessibility_metric DESC
LIMIT 5;