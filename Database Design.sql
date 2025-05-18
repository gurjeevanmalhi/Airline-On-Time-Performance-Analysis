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

CREATE TABLE city_markets_staging(
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

-- Transforming airport description into respective columns
ALTER TABLE airports_staging
ADD COLUMN airport_name VARCHAR(200),
ADD COLUMN city VARCHAR(200),
ADD COLUMN region VARCHAR(200);

UPDATE airports_staging
SET
	airport_name = SUBSTRING(
		description FROM STRPOS(description, ':') + 2),
	city = SUBSTRING(
		description
		FROM 1 FOR STRPOS(description, ',') -1),
	region = SUBSTRING(
		description FROM STRPOS(description, ',') + 2 FOR (STRPOS(description, ':') - STRPOS(description, ',') -2));

UPDATE airports
SELECT
	DISTINCT REGION,
	DEST_STATE_NAME
FROM AIRPORTS_STAGING A 
LEFT JOIN FLIGHTS_STAGING F
ON A.REGION = F.DEST_STATE
WHERE REGION SIMILAR TO '[A-Z]{2}'
ORDER BY REGION

select * from airports_staging;


