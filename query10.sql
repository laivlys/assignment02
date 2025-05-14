/* 
You're tasked with giving more contextual information to rail stops to fill the `stop_desc` field in a GTFS feed. Using any of the data sets above, PostGIS functions (e.g., `ST_Distance`, `ST_Azimuth`, etc.), and PostgreSQL string functions, build a description (alias as `stop_desc`) for each stop. Feel free to supplement with other datasets (must provide link to data used so it's reproducible), and other methods of describing the relationships. SQL's `CASE` statements may be helpful for some operations.
*/

SET search_path TO public, phl, septa, census;
WITH nearest_bus_stop AS (
    SELECT
        rs.stop_id AS rail_stop_id,
        bs.stop_id AS bus_stop_id,
        bs.stop_name AS bus_stop_name,
        bs.stop_lat,
        bs.stop_lon,
        -- Calculate distance between rail stop and bus stop using lat/lon
        ST_Distance(
            ST_SetSRID(ST_MakePoint(rs.stop_lon, rs.stop_lat), 4326)::geography,
            ST_SetSRID(ST_MakePoint(bs.stop_lon, bs.stop_lat), 4326)::geography
        ) AS distance,
        -- Calculate the relative direction (angle) using lat/lon difference
        DEGREES(
            ATAN2(
                bs.stop_lat - rs.stop_lat,  -- Latitude difference (y-axis)
                bs.stop_lon - rs.stop_lon   -- Longitude difference (x-axis)
            )
        ) AS angle
    FROM septa.rail_stops rs
    JOIN septa.bus_stops bs
    ON ST_DWithin(
        ST_SetSRID(ST_MakePoint(rs.stop_lon, rs.stop_lat), 4326),
        ST_SetSRID(ST_MakePoint(bs.stop_lon, bs.stop_lat), 4326),
        5000  -- Limit to bus stops within 5 km
    )
),
direction_mapping AS (
    SELECT
        rail_stop_id,
        bus_stop_name,
        distance,
        angle,
        CASE
            WHEN angle >= -22.5 AND angle < 22.5 THEN 'East'
            WHEN angle >= 22.5 AND angle < 67.5 THEN 'Northeast'
            WHEN angle >= 67.5 AND angle < 112.5 THEN 'North'
            WHEN angle >= 112.5 AND angle < 157.5 THEN 'Northwest'
            WHEN angle >= 157.5 OR angle < -157.5 THEN 'West'
            WHEN angle >= -157.5 AND angle < -112.5 THEN 'Southwest'
            WHEN angle >= -112.5 AND angle < -67.5 THEN 'South'
            WHEN angle >= -67.5 AND angle < -22.5 THEN 'Southeast'
            ELSE 'Unknown'
        END AS direction
    FROM nearest_bus_stop
    WHERE (rail_stop_id, distance) IN (
        SELECT rail_stop_id, MIN(distance)
        FROM nearest_bus_stop
        GROUP BY rail_stop_id
    )
)
SELECT
    rs.stop_id::INTEGER AS stop_id,
    rs.stop_name,
    CONCAT('Nearest Bus Stop: ', cbs.bus_stop_name, ', Direction: ', cbs.direction) AS stop_desc,
    rs.stop_lon::DOUBLE PRECISION AS stop_lon,
    rs.stop_lat::DOUBLE PRECISION AS stop_lat
FROM septa.rail_stops rs
JOIN direction_mapping cbs
    ON rs.stop_id = cbs.rail_stop_id;
