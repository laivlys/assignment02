/*
Using the Philadelphia Water Department Stormwater Billing Parcels dataset, 
pair each parcel with its closest bus stop. The final result should give the parcel address,
 bus stop name, and distance apart in meters, rounded to two decimals. Order by distance (largest on top).
*/

SET search_path TO public, phl, septa, census;
WITH closest_bus_stops AS (
    SELECT
        p.parcelid,
        p.address,
        b.stop_name,
        ROUND(ST_Distance(p.geog::geography, b.geog::geography)::numeric, 2) AS distance_meters
    FROM phl.pwd_parcels AS p
    JOIN LATERAL (
        SELECT 
            stop_name,
            geog
        FROM septa.bus_stops AS b
        ORDER BY p.geog <-> b.geog
        LIMIT 1
    ) AS b ON TRUE
)
SELECT
    cbs.address as parcel_address,
    cbs.stop_name,
    cbs.distance_meters::NUMERIC as distance
FROM closest_bus_stops AS cbs
ORDER BY cbs.distance_meters DESC;


