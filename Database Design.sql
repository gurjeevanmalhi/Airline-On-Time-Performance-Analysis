-- Creating Staging Tables

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


select count(*) 
from airports_staging;

-- Confirmed unique values
select count(distinct code)
from airports_staging; -- 6,720 unique values

-- Confirmed 0 NULLs
select
	count(*) filter(where code is null), -- 0 nulls
	count(*) filter(where description is null) -- 0 nulls
from airports_staging;

-- Identified code length
select
	min(length(code)) as min,
	max(length(code)) as max
from airports_staging; -- code is 5 characters

-- Validated pattern match
select distinct code
from airports_staging
where code not similar to '\d\d\d\d\d'; -- all values match 5 digit pattern

-- Finding duplicates
select *
from airports_staging
where description in(
		select
			description
		from airports_staging
		group by 1
		having count(*) > 1
	)
order by description;
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
	code CHAR(5) primary key,
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
	COUNT(*) FILTER(WHERE code is null) as total_null_codes,
	COUNT(*) FILTER(WHERE description is null) as total_null_description
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
	code VARCHAR(10) primary key,
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
	COUNT(*) FILTER(WHERE code is null) as total_null_codes,
	COUNT(*) FILTER(WHERE description is null) as total_null_description
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
WHERE code not similar to '\d{5}';

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
		else region
		end;

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
	code CHAR(5) primary key,
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
	count(*) - count(code) as null_codes,
	count(*) - count(description) as null_descriptions
from world_areas_staging;

-- Confirmed 0 duplicates
SELECT 
	code,
	description
FROM world_areas_staging
group by 1,2
having count(*) > 1;

-- Confirmed all codes are unique
SELECT
	count(*) as total_rows,
	count(distinct code) as total_unique_codes
from world_areas_staging;

-- Found range for data type
select
	min(code) as min,
	max(code) as max
from world_areas_staging;

-- Found range for data type
select
	max(length(description)) as max
from world_areas_staging;

-- Created table for clean data
create table world_areas(
	code smallint primary key,
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
	code CHAR(1) primary key,
	description VARCHAR(25)
);

-- Inserting clean data
INSERT INTO cancel_codes
select
	code,
	description
FROM cancel_codes_staging;

-- Dropped staging table
DROP TABLE IF EXISTS cancel_codes_staging;


-- Flights


select * from flights_staging limit 5;

-- DROPPED COLUMNS 