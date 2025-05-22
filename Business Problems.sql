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

-- Answer: Endeavor Air Inc. had the best on time performance in all 3 months for Q4.

-- 2. How much do arrival and departure delays vary across different airports compared to the national average?

-- Finds standard deviation for departure and arrival delays by airport
WITH airport_stddev AS (
		SELECT
			a2.airport_name AS origin_airport,
			STDDEV(f.dep_delay_minutes) AS stddev_dep_delay_per_airport,
			a.airport_name AS dest_airport,
			STDDEV(f.arr_delay_minutes) AS stddev_arrival_delay_per_airport
		FROM flights f
			INNER JOIN airports a2 ON f.origin_airport_id = a2.code
			INNER JOIN airports a ON f.dest_airport_id = a.code
		GROUP BY 1, 3
	),
	national_stddev AS (
		SELECT
			STDDEV(departure_delay) AS natl_stddev_departure_delay,
			AVG(arrival_delay) AS natl_stddev_arrival_delay
		FROM
			flights
	)
SELECT
	ad.origin_airport,
	ad.stddev_departure_delay_per_airport,
	nd.natl_stddev_departure_delay,
	ad.destination_airport,
	ad.stddev_arrival_delay_per_airport,
	nd.natl_stddev_arrival_delay
FROM
	airport_stddev ad
	CROSS JOIN national_stddev nd;

-- 3. How much cumulative delay time is each airline responsible for, and what portion is due to controllable vs. uncontrollable reasons (e.g., airline vs. weather)?  

-- Assumed for controllable: air system delay, airline delay
-- Assumed for uncontrollable: security delay, weather delay, late aircraft delay

with delayed_categorized as(
	select
		a.airline_name,
		sum(f.air_system_delay + f.airline_delay) as controllable,
		sum(f.security_delay + f.weather_delay + f.late_aircraft_delay) as uncontrollable
	from flights f
	inner join airline a
	on f.airline_code = a.iata_code
	group by 1
)
select
	*,
	(controllable * 1 / sum(controllable + uncontrollable)) * 100 as controllable_pct,
	(uncontrollable * 1 / sum(controllable + uncontrollable)) * 100 as uncontrollable_pct
from delayed_categorized
group by 1,2,3;

-- 4. How do delay patterns change with longer flights vs shorter flights?

-- Categorizes flight times into short, medium, and long flights
with flight_categories as(
	select
		case
			when air_time <= 120 then 'Short'
			when air_time between 121 and 240 then 'Medium'
			else 'Long'
		end as flight_type,
	arrival_delay
	from flights
)
-- Finds avg delay, standard deviation, and percentage of delayed flights per flight type
select
	flight_type,
	count(*) as total_flights,
	avg(arrival_delay) as avg_arrival_delay,
	stddev(arrival_delay) as delay_stddev,
	100.0 * sum(case when arrival_delay > 0 then 1 else 0 end)/ count(*) as pct_delayed
from flight_categories
group by 1
order by 2 desc;

/*
Answer:
The average delays for these flight groups range from approximately 2 to 5 minutes. However, the significantly
higher standard deviation indicates considerable variability in the delays, suggesting the presence of numerous
instances with substantial outliers and longer delays. These outliers likely result from factors
such as severe weather conditions or exceptional circumstances that cause significant delays on certain flights.
 */

-- 5. How does the % of delayed flights vary throughout the year? What about for flights leaving from Boston (BOS) specifically?  

-- Finds total and delayed flights for Boston and all other airports
with monthly_flights as (
	select
		month,
		count(*) filter(where origin_airport != 'BOS') as total_other,
		count(*) filter(where origin_airport = 'BOS') as boston_total,
		count(*) filter (where departure_delay>0 and origin_airport != 'BOS') as all_other_delays,
		count(*) filter(where departure_delay>0 and origin_airport = 'BOS') as boston_delays
	from flights
	group by month
),
-- Calculates the % of delayed flights for Boston and all other airports
pct_delayed as(
	select
		month,
		-- Dataset shows 0 flights from Boston in October, replacing 0 with NULL to avoid division by zero error
		(nullif(boston_delays,0) * 1.0 / nullif(boston_total,0)) * 100 as pct_delayed_boston,
		(all_other_delays * 1.0 / total_other) * 100 as pct_delayed_other
	from monthly_flights
)
-- Finds the variance of delayed flights from Boston vs all other airports
select
	*,
	pct_delayed_boston - pct_delayed_other as boston_vs_all_else
from pct_delayed;

/*
Answer:
Boston did not have any delayed flights in October. Overall, Boston exhibited better on-time performance
compared to other airports for most months, except for February, August, and September. Notably,
February saw the highest proportion of delays for flights departing from Boston.
*/

-- 6. Which routes have the highest flight volume, and what are the top five based on total flights?

select
	-- combines origin and destination locations to assign as route
	a.city || ', ' || a.state || ' - ' || a2.city || ', ' || a2.state as route, 
	count(*) as total_flights
from flights f
inner join airport a
on f.origin_airport = a.iata_code
inner join airport a2 
on f.destination_airport = a2.iata_code
group by 1
order by 2 desc
limit 5;

-- Answer: SF-LA, LA-SF, NY-CHI, CHI-NY, BOS-NY 

-- 7. Which five cities serve as the most popular hubs based on flight frequency?

select
	city,
	count(*)
from(
	select a.city
	from flights f
	inner join airport a
	on f.origin_airport = a.iata_code
	union all 
	select a2.city
	from flights f
	inner join airport a2
	on f.destination_airport = a2.iata_code
)
group by 1
order by 2 desc
limit 5;

-- Answer: Chicago, Atlanta, Dallas-Fort Worth, Denver

-- 8. What are the key drivers of flight cancellations across the industry?

select
	c.description,
	count(f.cancelled) as total_cancelled_per,
	100 * count(f.cancelled) / sum(count(f.cancelled)) over() as pct_of_total
from flights f
inner join cancellation_codes c
on f.cancellation_reason = c.code
inner join airline a
on f.airline_code = a.iata_code
where f.cancelled = 'True'
group by 1
order by 3 desc;

/*
Answer:
Weather is the leading cause of flight cancellations, followed by issues related to the
airline or carrier, the national air system, with security concerns contributing the least.
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

select corr(distance, arrival_delay)
from flights
where arrival_delay is not null;

-- Answer: Result of -0.02 indicates virtually no correlation between flight distance and arrival delay.




