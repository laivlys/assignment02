/*

This file contains the SQL commands to prepare the database for your queries.
Before running this file, you should have created your database, created the
schemas (see below), and loaded your data into the database.

Creating your schemas
---------------------

You can create your schemas by running the following statements in PG Admin:

    create schema if not exists septa;
    create schema if not exists phl;
    create schema if not exists census;

Also, don't forget to enable PostGIS on your database:

    create extension if not exists postgis;

Loading your data

create extension if not exists postgis;

DROP TABLE IF EXISTS septa.bus_stops;

CREATE TABLE septa.bus_stops (
    stop_id TEXT,
    stop_name TEXT,
    stop_lat DOUBLE PRECISION,
    stop_lon DOUBLE PRECISION,
    location_type INTEGER,
    parent_station TEXT,
    zone_id TEXT,
    wheelchair_boarding INTEGER
);

copy septa.bus_stops
from 'C:/Users/lamsy/Desktop/UPenn/MUSA5090/Assignment02/gtfs_public/google_bus/stops.txt'
with (format csv, header true);

CREATE TABLE septa.bus_routes (
    route_id TEXT,
    route_short_name TEXT,
    route_long_name TEXT,
    route_type TEXT,
    route_color TEXT,
    route_text_color TEXT,
    route_url TEXT
);

copy septa.bus_routes
from 'C:/Users/lamsy/Desktop/UPenn/MUSA5090/Assignment02/gtfs_public/google_bus/routes.txt'
with (format csv, header true);

CREATE TABLE septa.bus_trips (
    route_id TEXT,
    service_id TEXT,
    trip_id TEXT,
    trip_headsign TEXT,
    block_id TEXT,
    direction_id TEXT,
    shape_id TEXT
);
copy septa.bus_trips
from 'C:/Users/lamsy/Desktop/UPenn/MUSA5090/Assignment02/gtfs_public/google_bus/trips.txt'
with (format csv, header true);

CREATE TABLE septa.bus_shapes (
    shape_id TEXT,
    shape_pt_lat DOUBLE PRECISION,
    shape_pt_lon DOUBLE PRECISION,
    shape_pt_sequence INTEGER,
);
copy septa.bus_shapes
from 'C:/Users/lamsy/Desktop/UPenn/MUSA5090/Assignment02/gtfs_public/google_bus/shapes.txt'
with (format csv, header true);

CREATE TABLE septa.rail_stops (
    stop_id TEXT,
    stop_name TEXT,
    stop_desc TEXT,
    stop_lat DOUBLE PRECISION,
    stop_lon DOUBLE PRECISION,
    zone_id TEXT,
    stop_url TEXT
);

copy septa.rail_stops
from 'C:/Users/lamsy/Desktop/UPenn/MUSA5090/Assignment02/gtfs_public/google_rail/stops.txt'
with (format csv, header true);

CREATE TABLE census.population_2020 (
    geoid TEXT,
    geoname TEXT,
    total INTEGER
);

copy census.population_2020
from 'C:/Users/lamsy/Desktop/UPenn/MUSA5090/Assignment02/pop2020.csv'
with (format csv, header true);
-----------------

After you've created the schemas, load your data into the database specified in
the assignment README.

Finally, you can run this file either by copying it all into PG Admin, or by
running the following command from the command line:

    psql -U postgres -d <YOUR_DATABASE_NAME> -f db_structure.sql

*/

-- Add a column to the septa.bus_stops table to store the geometry of each stop.
alter table septa.bus_stops
add column if not exists geog public.geography;

update septa.bus_stops
set geog = public.st_makepoint(stop_lon, stop_lat)::public.geography;

-- Create an index on the geog column.
create index if not exists septa_bus_stops__geog__idx
on septa.bus_stops using gist
(geog);
