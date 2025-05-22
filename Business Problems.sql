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

SELECT distinct cancellation_code from flights;

WITH cancellations_categorized AS(
	SELECT
		c.description,
		COUNT(f.cancelled) FILTER(WHERE cancelled = 'true') AS total_cancelled
	FROM flights f
	INNER JOIN cancel_codes c ON f.cancellation_code = c.code
	GROUP BY 1
	ORDER BY 2 DESC
)
SELECT
	*,
	ROUND((total_cancelled * 1 / SUM(total_cancelled) over() * 100),2) AS pct
FROM cancellations_categorized;

/*
Answer: Weather is the leading cause of flight cancellations, accounting for 77% of cancellations.
Carrier related cancellations account for 14%, while delays attributed to national air systems represent 8%.
Security related cancellations are minimal, with just 0.02% of total.
*/

-- 9. Which airports consistently experience high weather-related delays? 

select
	a.airport_name,
	sum(f.weather_delay) as total_weather_delay
from flights f
left join airport a
on f.origin_airport = a.iata_code
where a.airport_name is not null
group by airport_name
order by 2 desc
limit 5;

-- Answer: O'Hare, Hartsfield-Jackson, Dallas-Forth Worth, Orlando Intl, JFK

-- 10. What percentage of flights experienced a departure delay in 2015? Among those, what was the average delay time (in minutes)?  

select
100 * (count(*) filter(where departure_delay > 0))::decimal/ count(*) as delayed_flight_pct,
avg(departure_delay) filter(where departure_delay > 0) as avg_delay
from flights;

-- Answer: 36% of flights experienced a delay for an average of 32 minutes.

-- 11. How many flights were cancelled in 2015? What % were due to weather vs. the airline?  

select
	c.description,
	count(*) as total_cancellations_per,
	sum(count(*)) over() as total_cancellations_2015,
	(count(*) / sum(count(*)) over()) * 100 as pct_per
from flights f 
left join cancellation_codes c
on f.cancellation_reason = c.code
where f.cancelled = True
group by 1
order by 2;

/*
Answer: 89,884 flights were cancelled in 2015. Weather accounted for 54% of delays,
followed by airline or carrier related factors which contributed to 28%
*/

-- 12. Which airlines seem to be most and least reliable in terms of on-time departure?  

select
	a.airline_name,
	avg(f.departure_delay) as avg_departure_delay
from flights f 
left join airline a
	on f.airline_code = a.iata_code
where departure_delay > 0
group by 1
order by 2 asc;

-- Answer: Hawaiian Airlines were the most reliable airline with Frontier being the least.

-- 13. What percentage of flights were delayed, cancelled, or diverted overall and per airline?  

with categorized as (
	select
		a.airline_name,
		count(*) as total_flights,
		count(cancelled) filter(where cancelled ='True') as total_cancelled,
		count(*) filter(where departure_delay > 0) as total_delays,
		count(*) filter(where diverted = 'True') as total_diverted
	from flights f
	inner join airline a
	on f.airline_code = a.iata_code
	group by 1
)
select
	airline_name,
	total_cancelled * 1.0 / total_flights * 100 as pct_cancelled,
	total_delays * 1.0 / total_flights * 100 as pct_delayed,
	total_diverted * 1.0 / total_flights * 100 as pct_diverted
from categorized;

-- 14. Which flight routes have the highest frequency of weather-related delays?  

select
	a.city || ', ' || a.state || ' - ' || a2.city || ', ' || a2.state as route,
	sum(coalesce(f.weather_delay,0)) as total_weather_delay
from flights f
inner join airport a
on f.origin_airport = a.iata_code
inner join airport a2
on f.destination_airport = a2.iata_code
group by 1
order by 2 desc
limit 3;

-- Answer: CHI-NY, ATL-NY, CHI- LA

-- 15. Is there a correlation between flight distance and arrival delay?  

SELECT CORR(distance, arr_delay_minutes)
FROM flights
WHERE arr_delay_minutes IS NOT nuLL;

-- Answer: Result of -0.01 indicates virtually no correlation between flight distance and arrival delay.




