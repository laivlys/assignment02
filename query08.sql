/*
With a query, find out how many census block groups Penn's main campus fully contains. Discuss which dataset you chose for defining Penn's campus.
*/

/* 
I used the owner1 column in phl.pwd_parcels dataset to filter Penn's main campus and the census.blockgroups_2020 group dataset to find how many block groups Penn's main campus fully contains.
*/

SET search_path TO public, phl, septa, census;
WITH penn_campus AS (
    SELECT 
        geog
    FROM phl.pwd_parcels
    WHERE 
        owner1 LIKE '%TRUSTEES OF THE UNIVERSIT%' OR
        owner1 LIKE '%TRS UNIV OF PENN%' OR
        owner1 LIKE '%UNIV OF PENNSYLVANIA%' OR
        owner1 LIKE '%THE UNIVERSITY OF PENNA%'
),
block_groups AS (
    SELECT 
        bg.geoid,
        bg.geog,
        ST_Area(ST_Transform(bg.geog::geometry, 2272)) AS bg_area
    FROM census.blockgroups_2020 AS bg
    INNER JOIN penn_campus AS penn
    on ST_Contains(bg.geog::geometry, penn.geog::geometry)
    )
SELECT COUNT(*)::INTEGER AS count_block_groups
FROM block_groups
