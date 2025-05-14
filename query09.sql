/*
With a query involving PWD parcels and census block groups, find the `geo_id` of the block group that contains Meyerson Hall. `ST_MakePoint()` and functions like that are not allowed.
*/

SET search_path TO public, phl, septa, census;
wITH meyerson_hall AS (
    SELECT 
    geog
    FROM phl.pwd_parcels
    WHERE address LIKE '%220-30 S 34TH ST%'
)
SELECT 
    cbg.geoid AS geoid
FROM meyerson_hall
LEFT JOIN census.blockgroups_2020 as cbg
    on ST_Contains(cbg.geog::geometry, meyerson_hall.geog::geometry);

