-- Business Questions

-- 1. Which airlines demonstrated the highest operational efficiency?

-- Finds total on time or early flights per airline in each quarter
WITH on_time_performance AS (
	SELECT
		f.flight_month,
		c.carrier_name,
		COUNT(*) AS total_flights,
		COUNT(*) FILTER(WHERE f.arr_delay <=0) AS total_not_delayed
	FROM flights f
	INNER JOIN carriers c ON f.airline_code = c.code
	GROUP BY 1,2
),
-- Finds on time % and ranks each airline accordingly per month
ranked AS(
	SELECT
		flight_month,
		carrier_name,
		total_not_delayed * 1.0 / total_flights * 100 AS on_time_pct,
		RANK() OVER(PARTITION BY flight_month ORDER BY total_not_delayed * 1.0 / total_flights * 100 DESC) AS ranked
	FROM on_time_performance
	ORDER BY flight_month, ranked ASC
)
-- Returns the best on time performing airline in each month
SELECT *
FROM ranked
WHERE ranked = 1;

-- Answer: Endeavor Air Inc. had the best on time performance % in all 3 months for Q4.

-- 2. How much do arrival and departure delays vary across different airports compared to the national average?

-- Calculates standard deviation for delays nationally
WITH national_avg AS(
	SELECT
		stddev(dep_delay) as natl_stddev_dep_delay,
		stddev(arr_delay) as natl_stddev_arr_delay
	FROM flights
),
-- Calculates standard deviation per airport
airport_stats AS(
	SELECT
		airport_id,
		STDDEV(dep_delay) AS stddev_dep_delay,
		STDDEV(arr_delay) AS stddev_arr_delay
	FROM(
		SELECT
			origin_airport_id AS airport_id,
			dep_delay,
			NULL::NUMERIC AS arr_delay
		FROM flights
		UNION ALL
		SELECT
			dest_airport_id AS airport_id,
			NULL::NUMERIC AS dep_delay,
			arr_delay
		FROM flights
		) AS combined
	GROUP BY airport_id
)
-- Finds variabilty for each airport between national average
SELECT
	ap.airport_name,
	a.stddev_dep_delay - n.natl_stddev_dep_delay AS dep_diff_from_avg,
	a.stddev_arr_delay - n.natl_stddev_arr_delay AS arr_diff_from_avg
FROM airport_stats a
JOIN airports ap ON a.airport_id = ap.code
CROSS JOIN national_avg n;

-- 3. How much cumulative delay time is each airline responsible for, and what portion is due to controllable vs. uncontrollable reasons?

-- Controllable: carrier delay, national air system
-- Uncontrollable: weather, late aircraft, security
-- Delay types can be categorized differently depending on context

-- Adds delay time per line and categorizes accordingly
WITH delay_categorized AS(
	SELECT
		c.carrier_name AS airline,
		SUM(f.carrier_delay + f.nas_delay) AS controllable,
		SUM(f.weather_delay + f.late_aircraft_delay + f.security_delay) AS uncontrollable,
		SUM(f.carrier_delay + f.nas_delay + f.weather_delay + f.late_aircraft_delay + f.security_delay) AS total_delay_per
	FROM flights f
	INNER JOIN carriers c ON f.airline_code = c.code
	GROUP BY 1
)
-- Calculates % per category and cumulatively 
SELECT
	airline,
	controllable * 1.0/total_delay_per * 100 AS controllable_pct,
	uncontrollable * 1.0 /total_delay_per * 100 AS uncontrollable_pct,
	total_delay_per/SUM(total_delay_per) OVER() * 100 AS airline_pct_of_total
FROM delay_categorized
ORDER BY 4 DESC;

-- 4. How do delay patterns change with longer flights vs shorter flights?

-- Groups flight times by category and calculates average delays per category
SELECT
	CASE
		WHEN crs_elapsed_time <= 120 THEN 'Short'
		WHEN crs_elapsed_time BETWEEN 121 AND 240 THEN 'Medium'
		ELSE 'Long'
		END AS duration_category,
		COUNT(*) AS flight_count,
		AVG(dep_delay) AS avg_dep_delay,
		AVG(arr_delay) AS avg_arr_delay
FROM flights
GROUP BY 1
ORDER BY 1 DESC;

/*
Answer: Medium-duration flights have the highest average departure delay at approximately 9 minutes,
followed by long flights at 8.7 minutes and short flights at 7.5 minutes. The variance in delays is relatively small.
Arrival delays also show minimal variation, with average delays across categories differing by only about 1.5 minutes.
*/


-- 5. Which routes have the highest flight volume, and what are the top five based on total flights?
select * from airports;
SELECT
	-- combines origin and destination locations to assign as route
	a.city || ', ' || a.region || ' - ' || a2.city || ', ' || a2.region AS route,
	COUNT(*) AS total_flights
FROM
	flights f
	INNER JOIN airports a ON f.origin_airport_id = a.code
	INNER JOIN airports a2 ON f.dest_airport_id = a2.code
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Answer: CHI-NY, NY-CHI, NY-BOS, BOS-NY, LA-SF

-- 6. Which five cities serve as the most popular hubs based on flight frequency?

SELECT
	city,
	COUNT(*) AS total_flights
FROM(
		SELECT a.city
		FROM flights f
		INNER JOIN airports a ON f.origin_airport_id = a.code
		UNION ALL
		SELECT a2.city
		FROM flights f
		INNER JOIN airports a2 ON f.dest_airport_id = a2.code
	)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Answer: Chicago, Atlanta, Dallas-Fort Worth, Denver, New York

-- 7. What are the key drivers of flight cancellations across the industry?

-- Counts cancellations across categories
WITH cancellations_categorized AS(
	SELECT
		c.description,
		COUNT(f.cancelled) FILTER(WHERE cancelled = 'true') AS total_cancelled
	FROM flights f
	INNER JOIN cancel_codes c ON f.cancellation_code = c.code
	GROUP BY 1
	ORDER BY 2 DESC
)
-- Calculates percent of total
SELECT
	*,
	ROUND((total_cancelled * 1 / SUM(total_cancelled) over() * 100),2) AS pct
FROM cancellations_categorized;

-- Answer: Weather - 77%, Carrier - 14%, National Air System - 8%, Security - 0.02%

-- 8. Which airports experience high weather-related delays for departures? 

SELECT
	a.airport_name,
	SUM(f.weather_delay) AS total_weather_delay
FROM
	flights f
	INNER JOIN airports a ON f.origin_airport_id = a.code
GROUP BY
	airport_name
HAVING
	SUM(f.weather_delay) IS NOT NULL
ORDER BY
	2 DESC
LIMIT 5;

-- Answer: Dallas/Fort Worth, O'Hare, Denver, San Diego, Charlotte Douglas are the top 5 airports that experience weather delays.

-- 9. What percentage of flights experienced a departure delay in 2015? Among those, what was the average delay time?

SELECT
	COUNT(*) FILTER (WHERE dep_del15 = 'true') * 1.0 / COUNT(*) * 100 AS pct_delayed,
	AVG(dep_delay_minutes) FILTER (WHERE dep_delay_minutes >= 15) AS avg_dep_delay
FROM flights;

-- Answer: 16.4% of flights were delayed for an average of 1 hour and 6 minutes.

-- 10. Which airlines seem are in the top and bottom 33% for on-time departure?

-- Splits airlines into thirds based on average departure delay
WITH thirds AS(
	SELECT
		 c.carrier_name,
		 AVG(dep_delay_minutes) AS avg_dep_delay,
		 NTILE(3) OVER(ORDER BY AVG(dep_delay_minutes) ASC) AS delay_group
	FROM flights f 
	INNER JOIN carriers c ON f.airline_code = c.code
	WHERE f.dep_del15 = 'true'
	GROUP BY 1
	)
-- Retrieves all airlines in the top and bottom third
SELECT *
FROM thirds
WHERE delay_group IN (1,3);

-- 11. What percentage of flights were delayed, cancelled, or diverted overall and per airline?  

-- Calculates total flights, cancellations, diverted flights per airline
WITH airline_stats AS(
	SELECT
		c.carrier_name AS airline,
		COUNT(*) AS total_flights,
		COUNT(DISTINCT(flight_date,airline_code,origin_airport_id,flight_number,crs_dep_time))
			FILTER (WHERE dep_del15 ='true' OR arr_del15 ='true') as total_delayed,
		COUNT(*) FILTER (WHERE cancelled ='true') as total_cancelled,
		COUNT(*) FILTER (WHERE diverted ='true') as total_diverted
	FROM flights f
	INNER JOIN carriers c ON f.airline_code = c.code
	GROUP BY 1
)
-- Calculates % for each category
SELECT
	airline,
	total_flights,
	total_delayed * 1.0 / total_flights * 100 AS pct_delayed,
	total_cancelled * 1.0 / total_flights * 100 AS pct_cancelled,
	total_diverted * 1.0 / total_flights * 100 AS pct_delayed
FROM airline_stats
ORDER BY 2 DESC;

-- 12. When is the least and most busiest time to fly for a passenger?
WITH flight_hours AS(
	SELECT
		day_of_week,
		EXTRACT(HOUR FROM crs_dep_time) AS dep_hour,
		COUNT(*) AS total_flights
	FROM flights
	GROUP BY 1,2
	ORDER BY 3 DESC
),
busiest AS(
	SELECT *
	FROM flight_hours
	ORDER BY total_flights DESC
	LIMIT 1
),
least_busiest AS(
	SELECT * 
	FROM flight_hours
	ORDER BY total_flights ASC
	LIMIT 1
)
SELECT *
FROM busiest
UNION ALL 
SELECT * 
FROM least_busiest;

-- Answer: Least busiest time to fly is Wednesday at 4 am. Busiest time is Monday at 7am.

-- 13. Is there a correlation between flight distance and arrival delay?  

SELECT CORR(distance, arr_delay_minutes)
FROM flights
WHERE arr_delay_minutes IS NOT NULL;

-- Answer: Result of -0.01 indicates virtually no correlation between flight distance and arrival delay.

-- 14. Which US airports had the highest flight volume month-over-month, and how did their ranks change throughout the year?

-- Calculates flight volume per airport for each month
WITH flight_volume AS(
	SELECT
	a.airport_name,
	f.flight_month,
	COUNT(*) AS total_flights
FROM flights f
INNER JOIN airports a ON f.origin_airport_id = a.code
GROUP BY 1, 2
),
-- Ranks each airport per month by the number of flights
ranked AS(
	SELECT
		*,
		DENSE_RANK() OVER(PARTITION BY flight_month ORDER BY total_flights DESC) AS ranking
	from flight_volume
)
-- Finds the airport with the highest number of flights in each airport
SELECT *
FROM ranked
WHERE ranking = 1;

-- Answer: Hartsfield-Jackson Atlanta International had the highest number of flights in each month.

-- 15. What is the average departure and arrival delay among all flights?

SELECT
	round(AVG(dep_delay_minutes) FILTER(WHERE dep_del15 = 'true'),2) AS avg_dep_delay,
	round(AVG(arr_delay_minutes) FILTER(WHERE arr_del15 = 'true'),2) AS avg_arr_delay
FROM flights;

-- Answer: 67 minutes for departures and 66 minutes for arrivals.
	

