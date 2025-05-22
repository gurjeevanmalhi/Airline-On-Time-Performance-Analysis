-- Created Staging Tables

CREATE TABLE airports_staging(
	code char(5),
	description varchar(200)
);

CREATE TABLE cancel_codes_staging(
	code char(1),
	description varchar(50)
);

CREATE TABLE carriers_staging(
	code varchar(10),
	description varchar(200)
);

CREATE TABLE markets_staging(
	code char(5),
	description varchar(200)
);

CREATE TABLE world_areas_staging(
	code int,
	description varchar(200)
);

CREATE TABLE flights_staging (
  flight_year VARCHAR(100),
  quarter VARCHAR(100),
  flight_month VARCHAR(100),
  day_of_month VARCHAR(100),
  day_of_week VARCHAR(100),
  flight_date VARCHAR(100),
  reporting_airline VARCHAR(100),
  dot_id_reporting_airline VARCHAR(100),
  iata_code_reporting_airline VARCHAR(100),
  tail_number VARCHAR(100),
  flight_number_reporting_airline VARCHAR(100),
  origin_airport_id VARCHAR(100),
  origin_airport_seq_id VARCHAR(100),
  origin_city_market_id VARCHAR(100),
  origin VARCHAR(100),
  origin_city_name VARCHAR(100),
  origin_state VARCHAR(100),
  origin_state_fips VARCHAR(100),
  origin_state_name VARCHAR(100),
  origin_wac VARCHAR(100),
  dest_airport_id VARCHAR(100),
  dest_airport_seq_id VARCHAR(100),
  dest_city_market_id VARCHAR(100),
  dest VARCHAR(100),
  dest_city_name VARCHAR(100),
  dest_state VARCHAR(100),
  dest_state_fips VARCHAR(100),
  dest_state_name VARCHAR(100),
  dest_wac VARCHAR(100),
  crs_dep_time VARCHAR(100),
  dep_time VARCHAR(100),
  dep_delay VARCHAR(100),
  dep_delay_minutes VARCHAR(100),
  dep_del15 VARCHAR(100),
  departure_delay_groups VARCHAR(100),
  dep_time_blk VARCHAR(100),
  taxi_out VARCHAR(100),
  wheels_off VARCHAR(100),
  wheels_on VARCHAR(100),
  taxi_in VARCHAR(100),
  crs_arr_time VARCHAR(100),
  arr_time VARCHAR(100),
  arr_delay VARCHAR(100),
  arr_delay_minutes VARCHAR(100),
  arr_del15 VARCHAR(100),
  arrival_delay_groups VARCHAR(100),
  arr_time_blk VARCHAR(100),
  cancelled VARCHAR(100),
  cancellation_code VARCHAR(100),
  diverted VARCHAR(100),
  crs_elapsed_time VARCHAR(100),
  actual_elapsed_time VARCHAR(100),
  air_time VARCHAR(100),
  flights VARCHAR(100),
  distance VARCHAR(100),
  distance_group VARCHAR(100),
  carrier_delay VARCHAR(100),
  weather_delay VARCHAR(100),
  nas_delay VARCHAR(100),
  security_delay VARCHAR(100),
  late_aircraft_delay VARCHAR(100)
);



-- Data Cleaning, Manipulation, and Transformation



-- Airports 

-- Identified total rows
SELECT COUNT(*)
FROM airports_staging;

-- Confirmed unique values
SELECT COUNT(DISTINCT code)
FROM airports_staging; -- 6,720 unique values

-- Confirmed 0 NULLs
SELECT
	COUNT(*) FILTER (WHERE code IS NULL), -- 0 nulls
	COUNT(*) FILTER (WHERE description IS NULL) -- 0 nulls
FROM airports_staging;

-- Identified code length
SELECT
	MIN(LENGTH(code)) AS min,
	MAX(LENGTH(code)) AS max
FROM airports_staging; -- code is 5 characters

-- Validated pattern match
SELECT DISTINCT code
FROM airports_staging
WHERE code NOT SIMILAR TO '\d\d\d\d\d'; -- all values match 5 digit pattern

-- Finding duplicates
SELECT*
FROM airports_staging
WHERE description IN(
		SELECT
			description
		FROM airports_staging
		GROUP BY 1
		HAVING COUNT(*) > 1
	)
ORDER BY description;
-- Found multiple airports with different codes.
-- Per DOT website, airport can change codes over time.
-- Will keep values for analysis.

-- Added new columns for transformation
ALTER TABLE airports_staging
ADD COLUMN airport_name VARCHAR(200),
ADD COLUMN city VARCHAR(200),
ADD COLUMN region VARCHAR(200);

-- Extracted substrings from description. Inserting into new columns
UPDATE airports_staging
SET
	airport_name = SUBSTRING(
		description FROM STRPOS(description, ':') + 2),
	city = SUBSTRING(
		description
		FROM 1 FOR STRPOS(description, ',') -1),
	region = SUBSTRING(
		description FROM STRPOS(description, ',') + 2 FOR (STRPOS(description, ':') - STRPOS(description, ',') -2));

-- Updated state long name
UPDATE airports_staging
SET region = 'Deleware'
WHERE region = 'DE';

-- Updated state long name
UPDATE airports_staging
SET region = 'District of Columbia'
WHERE region = 'DC';

-- Updated state long from flights table
UPDATE airports_staging a
SET region = f.dest_state_name
FROM(
	SELECT
		DISTINCT region,
		dest_state_name
	FROM airports_staging a
	LEFT JOIN flights_staging f
	ON a.region = f.dest_state
	WHERE region SIMILAR TO '[A-Z]{2}'
	ORDER BY region
) f 
WHERE a.region = f.region
AND a.region SIMILAR TO '[A-Z]{2}';

-- Dropped description column
ALTER TABLE airports_staging
DROP COLUMN description;


-- Created Airports table for clean data
CREATE TABLE airports(
	code CHAR(5) PRIMARY KEY,
	airport_name VARCHAR(75),
	city VARCHAR(50),
	region VARCHAR(75)
);

-- Inserted clean data
INSERT INTO airports(code,airport_name,city,region)
SELECT
	code,
	airport_name,
	city,
	region
FROM airports_staging;

-- Dropped staging table with raw data
DROP TABLE IF EXISTS airports_staging;



-- Carriers



-- Confirmed codes are unique
SELECT
	COUNT(*) AS total_rows,
	COUNT(DISTINCT code) unique_coces
FROM carriers_staging;

-- Confirmed 0 duplicates
SELECT
	code,
	description
FROM carriers_staging
GROUP BY 1,2
HAVING count(*) > 1;

-- Confirmed 0 NULLs
SELECT
	COUNT(*) FILTER(WHERE code IS NULL) AS total_null_codes,
	COUNT(*) FILTER(WHERE description IS NULL) AS total_null_description
FROM carriers_staging;

-- Found code lengths
SELECT
	MIN(LENGTH(code)) as min,
	MAX(LENGTH(code)) as max
FROM carriers_staging;

-- Found max description length
SELECT
	MAX(LENGTH(DESCRIPTION)) AS MAX
FROM CARRIERS_STAGING;

-- Created table to store validated data
CREATE TABLE carriers(
	code VARCHAR(10) PRIMARY KEY,
	carrier_name VARCHAR(100)	
);

-- Inserting validated data 
INSERT INTO carriers(code,carrier_name)
SELECT
	code,
	description
FROM carriers_staging;

-- Dropped staging table
DROP TABLE IF EXISTS carriers_staging;


-- Markets



-- Confirmed 0 NULLs
SELECT
	COUNT(*) FILTER(WHERE code IS NULL) AS total_null_codes,
	COUNT(*) FILTER(WHERE description IS NULL) AS total_null_description
FROM markets_staging;

-- Confirmed codes are unique
SELECT
	COUNT(*),
	COUNT(DISTINCT CODE)
FROM markets_staging;

-- Confirmed 0 duplicates
SELECT
	code,
	description
FROM markets_staging
GROUP BY 1,2
HAVING COUNT(*) > 1;

-- Identified code length
SELECT
	MIN(LENGTH(code)) as min,
	MAX(LENGTH(code)) as max
FROM markets_staging;

-- Identified code as 5 digit pattern
SELECT *
FROM markets_staging
WHERE code NOT SIMILAR TO '\d{5}';

-- Added columns to normalize data
ALTER TABLE markets_staging
ADD COLUMN city text,
ADD COLUMN region text;

-- Split description column into city and region
UPDATE markets_staging
SET
	city = split_part(description,',',1),
	region = split_part(description,', ',2);

-- Updated DE to Deleware, no available joins
SET region = 
	CASE
		WHEN region = 'DE' THEN 'Deleware'
		ELSE region
		END;

-- Updated all state abbreviations to full state names
UPDATE markets_staging m
SET region =
	CASE
		WHEN region SIMILAR TO '[A-Z]{2}' THEN f.dest_state_name
		ELSE m.region
		END
FROM flights_staging f
WHERE m.region = f.dest_state;

-- Created table for clean data
CREATE TABLE markets(
	code CHAR(5) PRIMARY KEY,
	city VARCHAR(50),
	region VARCHAR(75)
);

-- Updated new table with clean data
INSERT INTO markets(code,city,region)
SELECT
	code,
	city,
	region
FROM markets_staging;

-- Dropped staging table
DROP TABLE IF EXISTS markets_staging;


-- World Area Codes



-- Confirmed 0 nulls
SELECT
	COUNT(*) - COUNT(code) AS null_codes,
	COUNT(*) - COUNT(description) AS null_descriptions
FROM world_areas_staging;

-- Confirmed 0 duplicates
SELECT 
	code,
	description
FROM world_areas_staging
GROUP BY 1,2
HAVING COUNT(*) > 1;

-- Confirmed all codes are unique
SELECT
	COUNT(*) AS total_rows,
	COUNT(DISTINCT code) AS total_unique_codes
FROM world_areas_staging;

-- Found range for data type
SELECT
	MIN(code) AS min,
	MAX(code) AS max
FROM world_areas_staging;

-- Found range for data type
SELECT MAX(LENGTH(description)) AS max
FROM world_areas_staging;

-- Created table for clean data
CREATE TABLE world_areas (
	code SMALLINT PRIMARY KEY,
	area_name VARCHAR(75)
);

-- Inserted clean data
INSERT INTO world_areas(code,area_name)
SELECT 
	code,
	description
FROM world_areas_staging;

-- Dropped staging table
DROP TABLE IF EXISTS world_areas_staging;



-- Cancel Codes



-- No cleaning or transformation necessary
SELECT *
FROM cancel_codes_staging;

-- Created table for clean data
CREATE TABLE cancel_codes(
	code CHAR(1) PRIMARY KEY,
	description VARCHAR(25)
);

-- Inserting clean data
INSERT INTO cancel_codes
SELECT
	code,
	description
FROM
	cancel_codes_staging;
	
-- Dropped staging table
DROP TABLE IF EXISTS cancel_codes_staging;


-- Flights


-- Dropped columns, data has already been normalized in another table or not needed for analysis
ALTER TABLE flights_staging
DROP COLUMN dot_id_reporting_airline,
DROP COLUMN iata_code_reporting_airline,
DROP COLUMN tail_number,
DROP COLUMN origin_airport_seq_id,
DROP COLUMN origin_city_name,
DROP COLUMN origin_state,
DROP COLUMN origin_state_fips,
DROP COLUMN origin_state_name,
DROP COLUMN dest_airport_seq_id,
DROP COLUMN dest_city_name,
DROP COLUMN dest_state,
DROP COLUMN dest_state_fips,
DROP COLUMN dest_state_name,
DROP COLUMN departure_delay_groups,
DROP COLUMN dep_time_blk,
DROP COLUMN arrival_delay_groups,
DROP COLUMN arr_time_blk,
DROP COLUMN flights,
DROP COLUMN distance_group;

-- Identified NULL values in time columns
-- MNAR values, missingness is due to flight cancellations
SELECT
	COUNT(*) FILTER(WHERE flight_year IS NULL) AS flight_year,
	COUNT(*) FILTER(WHERE quarter IS NULL) AS quarter,
	COUNT(*) FILTER(WHERE flight_month IS NULL) AS flight_month,
	COUNT(*) FILTER(WHERE day_of_month IS NULL) AS day_of_month,
	COUNT(*) FILTER(WHERE day_of_week IS NULL) AS day_of_week,
	COUNT(*) FILTER(WHERE flight_date IS NULL) AS flight_date,
	COUNT(*) FILTER(WHERE reporting_airline IS NULL) AS reporting_airline,
	COUNT(*) FILTER(WHERE flight_number_reporting_airline IS NULL) AS flight_number_reporting_airline,
	COUNT(*) FILTER(WHERE origin_airport_id IS NULL) AS origin_airport_id,
	COUNT(*) FILTER(WHERE origin_city_market_id IS NULL) AS origin_city_market_id,
	COUNT(*) FILTER(WHERE origin IS NULL) AS origin,
	COUNT(*) FILTER(WHERE origin_wac IS NULL) AS origin_wac,
	COUNT(*) FILTER(WHERE dest_airport_id IS NULL) AS dest_airport_id,
	COUNT(*) FILTER(WHERE dest_city_market_id IS NULL) AS dest_city_market_id,
	COUNT(*) FILTER(WHERE dest IS NULL) AS dest,
	COUNT(*) FILTER(WHERE dest_wac IS NULL) AS dest_wac,
	COUNT(*) FILTER(WHERE crs_dep_time IS NULL) AS crs_dep_time,
	COUNT(*) FILTER(WHERE dep_time IS NULL) AS dep_time,
	COUNT(*) FILTER(WHERE dep_delay IS NULL) AS dep_delay,
	COUNT(*) FILTER(WHERE dep_delay_minutes IS NULL) AS dep_delay_minutes,
	COUNT(*) FILTER(WHERE dep_del15 IS NULL) AS dep_del15,
	COUNT(*) FILTER(WHERE taxi_out IS NULL) AS taxi_out,
	COUNT(*) FILTER(WHERE wheels_off IS NULL) AS wheels_off,
	COUNT(*) FILTER(WHERE wheels_on IS NULL) AS wheels_on,
	COUNT(*) FILTER(WHERE taxi_in IS NULL) AS taxi_in,
	COUNT(*) FILTER(WHERE crs_arr_time IS NULL) AS crs_arr_time,
	COUNT(*) FILTER(WHERE arr_time IS NULL) AS arr_time,
	COUNT(*) FILTER(WHERE arr_delay IS NULL) AS arr_delay,
	COUNT(*) FILTER(WHERE arr_delay_minutes IS NULL) AS arr_delay_minutes,
	COUNT(*) FILTER(WHERE arr_del15 IS NULL) AS arr_del15,
	COUNT(*) FILTER(WHERE cancelled IS NULL) AS cancelled,
	COUNT(*) FILTER(WHERE cancellation_code IS NULL) AS cancellation_code,
	COUNT(*) FILTER(WHERE diverted IS NULL) AS diverted,
	COUNT(*) FILTER(WHERE crs_elapsed_time IS NULL) AS crs_elapsed_time,
	COUNT(*) FILTER(WHERE actual_elapsed_time IS NULL) AS actual_elapsed_time,
	COUNT(*) FILTER(WHERE air_time IS NULL) AS air_time,
	COUNT(*) FILTER(WHERE distance IS NULL) AS distance,
	COUNT(*) FILTER(WHERE carrier_delay IS NULL) AS carrier_delay,
	COUNT(*) FILTER(WHERE weather_delay IS NULL) AS weather_delay,
	COUNT(*) FILTER(WHERE nas_delay IS NULL) AS nas_delay,
	COUNT(*) FILTER(WHERE security_delay IS NULL) AS security_delay,
	COUNT(*) FILTER(WHERE late_aircraft_delay IS NULL) AS late_aircraft_delay
FROM flights_staging;

-- Confirmed 0 Duplicates
SELECT 
  flight_year,
  quarter,
  flight_month,
  day_of_month,
  day_of_week,
  flight_date,
  reporting_airline,
  flight_number_reporting_airline,
  origin_airport_id,
  origin_city_market_id,
  origin,
  origin_wac,
  dest_airport_id,
  dest_city_market_id,
  dest,
  dest_wac,
  crs_dep_time,
  dep_time,
  dep_delay,
  dep_delay_minutes,
  dep_del15,
  taxi_out,
  wheels_off,
  wheels_on,
  taxi_in,
  crs_arr_time,
  arr_time,
  arr_delay,
  arr_delay_minutes,
  arr_del15,
  cancelled,
  cancellation_code,
  diverted,
  crs_elapsed_time,
  actual_elapsed_time,
  air_time,
  distance,
  carrier_delay,
  weather_delay,
  nas_delay,
  security_delay,
  late_aircraft_delay,
  COUNT(*) AS duplicate_count
FROM flights_staging
GROUP BY 
  flight_year,
  quarter,
  flight_month,
  day_of_month,
  day_of_week,
  flight_date,
  reporting_airline,
  flight_number_reporting_airline,
  origin_airport_id,
  origin_city_market_id,
  origin,
  origin_wac,
  dest_airport_id,
  dest_city_market_id,
  dest,
  dest_wac,
  crs_dep_time,
  dep_time,
  dep_delay,
  dep_delay_minutes,
  dep_del15,
  taxi_out,
  wheels_off,
  wheels_on,
  taxi_in,
  crs_arr_time,
  arr_time,
  arr_delay,
  arr_delay_minutes,
  arr_del15,
  cancelled,
  cancellation_code,
  diverted,
  crs_elapsed_time,
  actual_elapsed_time,
  air_time,
  distance,
  carrier_delay,
  weather_delay,
  nas_delay,
  security_delay,
  late_aircraft_delay
HAVING COUNT(*) > 1;

-- Replacing 2400 time values with 0000
UPDATE flights_staging
SET
	dep_time = REPLACE(dep_time, '2400', '0000'),
	arr_time = REPLACE(arr_time, '2400', '0000'),
	wheels_off = REPLACE(wheels_off, '2400', '0000'),
	wheels_on = REPLACE(wheels_on, '2400', '0000')
WHERE
	dep_time = '2400'
	OR arr_time = '2400'
	OR wheels_off = '2400'
	OR wheels_on = '2400';

-- Created table for clean data
CREATE TABLE flights (
	flight_year SMALLINT,
	quarter SMALLINT CHECK (quarter BETWEEN 1 AND 4),
	flight_month SMALLINT CHECK (flight_month BETWEEN 1 AND 12),
	day_of_month SMALLINT CHECK (day_of_month BETWEEN 1 AND 31),
	day_of_week SMALLINT CHECK (day_of_week BETWEEN 1 AND 7),
	flight_date date,
	airline_code VARCHAR(10),
	flight_number VARCHAR(10),
	origin_airport_id CHAR(5),
	origin_market_id CHAR(5),
	origin_iata_code CHAR(3),
	origin_wac SMALLINT,
	dest_airport_id CHAR(5),
	dest_market_id CHAR(5),
	dest_iata_code CHAR(3),
	dest_wac SMALLINT,
	crs_dep_time TIME,
	dep_time TIME,
	dep_delay SMALLINT,
	dep_delay_minutes SMALLINT,
	dep_del15 BOOLEAN,
	taxi_out SMALLINT,
	wheels_off TIME,
	wheels_on TIME,
	taxi_in SMALLINT,
	crs_arr_time TIME,
	arr_time TIME,
	arr_delay SMALLINT,
	arr_delay_minutes SMALLINT,
	arr_del15 BOOLEAN,
	cancelled BOOLEAN,
	cancellation_code CHAR(3),
	diverted BOOLEAN,
	crs_elapsed_time SMALLINT,
	actual_elapsed_time SMALLINT,
	air_time SMALLINT,
	distance SMALLINT,
	carrier_delay SMALLINT,
	weather_delay SMALLINT,
	nas_delay SMALLINT,
	security_delay SMALLINT,
	late_aircraft_delay SMALLINT
);

-- Inserting clean data
INSERT INTO flights (
    flight_year,
	quarter,
	flight_month,
	day_of_month,
	day_of_week,
	flight_date,
    airline_code,
	flight_number,
    origin_airport_id,
	origin_market_id,
	origin_iata_code,
	origin_wac,
    dest_airport_id,
	dest_market_id,
	dest_iata_code,
	dest_wac,
    crs_dep_time,
	dep_time,
	dep_delay,
	dep_delay_minutes,
	dep_del15,
    taxi_out,
	wheels_off,
	wheels_on,
	taxi_in,
    crs_arr_time,
	arr_time,
	arr_delay,
	arr_delay_minutes,
	arr_del15,
    cancelled,
	cancellation_code,
	diverted,
    crs_elapsed_time,
	actual_elapsed_time,
	air_time, distance,
    carrier_delay,
	weather_delay,
	nas_delay,
	security_delay,
	late_aircraft_delay
)
SELECT
    flight_year::smallint,
    quarter::smallint,
    flight_month::smallint,
    day_of_month::smallint,
    day_of_week::smallint,
    flight_date::date,
    reporting_airline::varchar,
    flight_number_reporting_airline::varchar,
    origin_airport_id::char(5),
    origin_city_market_id::char(5),
    origin::char(3),
    origin_wac::smallint,
    dest_airport_id::char(5),
    dest_city_market_id::char(5),
    dest::char(3),
    dest_wac::smallint,
    to_timestamp(lpad(crs_dep_time, 4, '0'), 'HH24MI')::time,
    to_timestamp(lpad(dep_time, 4, '0'), 'HH24MI')::time,
    dep_delay::smallint,
    dep_delay_minutes::smallint,
    dep_del15::boolean,
    taxi_out::smallint,
    to_timestamp(lpad(wheels_off, 4, '0'), 'HH24MI')::time,
    to_timestamp(lpad(wheels_on, 4, '0'), 'HH24MI')::time,
    taxi_in::smallint,
    to_timestamp(lpad(crs_arr_time, 4, '0'), 'HH24MI')::time,
    to_timestamp(lpad(arr_time, 4, '0'), 'HH24MI')::time,
    arr_delay::smallint,
    arr_delay_minutes::smallint,
    arr_del15::boolean,
    cancelled::boolean,
    cancellation_code::char(3),
    diverted::boolean,
    crs_elapsed_time::smallint,
    actual_elapsed_time::smallint,
    air_time::smallint,
    distance::smallint,
    carrier_delay::smallint,
    weather_delay::smallint,
    nas_delay::smallint,
    security_delay::smallint,
    late_aircraft_delay::smallint
FROM flights_staging;

-- Dropping staging table
DROP TABLE IF EXISTS flights_staging;








