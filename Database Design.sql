-- Creating Staging Tables
CREATE TABLE flights_staging(
    year VARCHAR(10),
    month VARCHAR(10),
    day VARCHAR(10),
    day_of_week VARCHAR(10),
    airline_code VARCHAR(20),
    flight_number VARCHAR(10),
    tail_number VARCHAR(20),
    origin_airport VARCHAR(20),
    destination_airport VARCHAR(20),
    scheduled_departure VARCHAR(20),
    departure_time VARCHAR(20),
    departure_delay VARCHAR(10),
    taxi_out VARCHAR(10),
    wheels_off VARCHAR(20),
    scheduled_time VARCHAR(10),
    elapsed_time VARCHAR(10),
    air_time VARCHAR(10),
    distance VARCHAR(10),
    wheels_on VARCHAR(20),
    taxi_in VARCHAR(10),
    scheduled_arrival VARCHAR(20),
    arrival_time VARCHAR(20),
    arrival_delay VARCHAR(10),
    diverted VARCHAR(10),
    cancelled VARCHAR(10),
    cancellation_reason VARCHAR(20),
    air_system_delay VARCHAR(10),
    security_delay VARCHAR(10),
    airline_delay VARCHAR(10),
    late_aircraft_delay VARCHAR(10),
    weather_delay VARCHAR(10)
);

-- Creating Tables
CREATE TABLE airline(
	IATA_code CHAR(2),
	airline_name VARCHAR(50)
);

CREATE TABLE airport(
	IATA_code CHAR(3),
	airport_name VARCHAR(100),
	city VARCHAR(50),
	state CHAR(2),
	country CHAR(3),
	latitude decimal,
	longitude decimal
);

CREATE TABLE cancellation_codes(
	code CHAR(1),
	description VARCHAR(20)
);

-- Created clean flights table with appropiate data types
-- Replaced '2400' with '000' to prevent time parsing erros
-- Time columns are converted from military time format
CREATE TABLE flights AS
SELECT 
    year::SMALLINT,
    month::SMALLINT,
    day::SMALLINT,
    day_of_week::SMALLINT,
    airline_code::CHAR(2),
    flight_number::INT,
    tail_number,
    origin_airport::CHAR(3),
    destination_airport::CHAR(3),
	TO_CHAR(TO_TIMESTAMP(LPAD(REPLACE(scheduled_departure, '2400', '0000'), 4, '0'), 'HH24MI'), 'HH24:MI:00')::TIME AS scheduled_departure,
    TO_CHAR(TO_TIMESTAMP(LPAD(REPLACE(departure_time, '2400', '0000'), 4, '0'), 'HH24MI'), 'HH24:MI:00')::TIME AS departure_time,
    departure_delay::INT,
    taxi_out::INT,
    TO_CHAR(TO_TIMESTAMP(LPAD(REPLACE(wheels_off, '2400', '0000'), 4, '0'), 'HH24MI'), 'HH24:MI:00')::TIME AS wheels_off,
    scheduled_time::INT,
    elapsed_time::INT,
    air_time::INT,
    distance::INT,
    TO_CHAR(TO_TIMESTAMP(LPAD(REPLACE(wheels_on, '2400', '0000'), 4, '0'), 'HH24MI'), 'HH24:MI:00')::TIME AS wheels_on,
    taxi_in::INT,
    TO_CHAR(TO_TIMESTAMP(LPAD(REPLACE(scheduled_arrival, '2400', '0000'), 4, '0'), 'HH24MI'), 'HH24:MI:00')::TIME AS scheduled_arrival,
    TO_CHAR(TO_TIMESTAMP(LPAD(REPLACE(arrival_time, '2400', '0000'), 4, '0'), 'HH24MI'), 'HH24:MI:00')::TIME AS arrival_time,
    arrival_delay::INT,
    diverted::BOOLEAN,
    cancelled::BOOLEAN,
    cancellation_reason,
    air_system_delay::INT,
    security_delay::INT,
    airline_delay::INT,
    late_aircraft_delay::INT,
    weather_delay::INT
FROM flights_staging;



