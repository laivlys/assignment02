/*
Using the `bus_shapes`, `bus_routes`, and `bus_trips` tables from GTFS bus feed, find the **two** routes with the longest trips.
*/

SET search_path TO public, phl, septa, census;
WITH shapes AS (
    SELECT
        bs.shape_id,
        ST_MakeLine(
            ARRAY_AGG(
                ST_SetSRID(ST_MakePoint(bs.shape_pt_lon, bs.shape_pt_lat), 4326)
                ORDER BY bs.shape_pt_sequence
            )
        ) AS shape_geom
    FROM septa.bus_shapes AS bs
    GROUP BY bs.shape_id
),
route_length AS (
    SELECT
        s.shape_id,
        s.shape_geom,
        ST_Length(s.shape_geom::geography) AS route_length_meters
    FROM shapes AS s
),
trip_shapes AS (
    SELECT
        bt.route_id,
        bt.shape_id,
        bt.trip_headsign,
        br.route_short_name,
        rl.shape_geom,
        rl.route_length_meters
    FROM septa.bus_trips AS bt
    JOIN route_length rl ON bt.shape_id = rl.shape_id
    JOIN septa.bus_routes br ON bt.route_id = br.route_id
),
ranked_routes AS (
    SELECT
        route_id,
        route_short_name,
        trip_headsign,
        shape_geom,
        ROUND(MAX(route_length_meters)) AS shape_length
    FROM trip_shapes
    GROUP BY route_id, route_short_name, trip_headsign, shape_geom
    ORDER BY shape_length DESC
    LIMIT 2
)
SELECT 
    route_short_name,
    trip_headsign,
    shape_geom::geography AS shape_geog,
    shape_length::NUMERIC
FROM ranked_routes;
