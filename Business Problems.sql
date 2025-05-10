-- Business Problems

-- 1. Which airlines demonstrated the highest operational efficiency in 2015, and how did their on-time performance compare across quarters throughout the year?  
-- (Use CTEs to segment data by region and time, window functions to rank performance.)

with on_time_performance as (
	select
		case
			when f.month in (1,2,3) then 'Q1'
			when f.month in (4,5,6) then 'Q2'
			when f.month in (7,8,9) then 'Q3'
			when f.month in (10,11,12) then 'Q4'
			end as quarter,
		a.airline_name,
		count(*) as total_flights,
		count(*) filter(where f.arrival_time - f.scheduled_arrival <= interval '0 minutes') as not_delayed
	from flights f
	inner join airline a
	on f.airline_code = a.iata_code
	group by 1,2
)
select
	quarter,
	airline_name,
	not_delayed * 1.0 / total_flights * 100 as on_time_pct,
	rank() over(partition by quarter order by not_delayed * 1.0 / total_flights * 100 desc) as rank
from on_time_performance
order by quarter, rank asc;

-- 2. What are the top 10 most heavily trafficked routes, and how do delay patterns and cancellation rates on these routes impact customer experience and airline reliability?  
-- (Use ROW_NUMBER or RANK, aggregate delay metrics by route.)

-- 3. How do average arrival delays vary by day of week and month, and what patterns or seasonality can be identified to inform future scheduling strategies?  
-- (GROUP BY with aggregates; CTEs to prep calendar metrics.)

-- 4. What are the key drivers of flight cancellations across the industry?
-- (Use JOINs on cancellation codes, filter with CASE WHEN logic.)

select
	c.description,
	count(cancelled) as total_cancelled
from flights f
inner join cancellation_codes c
on f.cancellation_reason = c.code
inner join airline a
on f.airline_code = a.iata_code
where f.cancelled = 'True'
group by 1
order by 2 desc;

-- 5. Which airports consistently experience high weather-related delays? 
-- (Aggregate weather delay time by airport; filter and rank.)

select
	a.airport_name,
	a.city || ', ' || a.state as location,
	sum(f.weather_delay) as total_weather_delay
from flights f
left join airport a
on f.origin_airport = a.iata_code
where a.airport_name is not null
group by airport_name,location
order by 3 desc
limit 10;

-- 6. How have airlines performed in terms of delay trends across different time periods, and which ones show continuous improvement or decline over the year?  
-- (Use window functions (LAG) to calculate trend deltas.)

-- 7. Where are systemic inefficiencies occurring in ground operations (taxi-in/out), and how do they affect turnaround time at the busiest airports?  
-- (Combine taxi_in/out with total delay; rank by airport volume.)

-- 8. How does aircraft reuse (tail numbers) contribute to compounding delays, and which carriers are most affected by late aircraft propagation?  
-- (Use window functions (LAG or LEAD) to trace delay propagation by tail_number.)

-- 9. Which origin airports contribute most to delays at major hub destinations, and what operational changes could reduce downstream delay impact?  
-- (Join flights by origin-destination; sum downstream arrival_delay.)

-- 10. How much cumulative delay time is each airline responsible for, and what portion is due to controllable vs. uncontrollable reasons (e.g., airline vs. weather)?  
-- (Use CASE WHEN logic to segment delay categories, aggregate per airline.)

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

-- 11. How does the overall flight volume vary by month? By day of week?  
-- (GROUP BY month, day_of_week; COUNT(*))

-- 12. What percentage of flights experienced a departure delay in 2015? Among those, what was the average delay time (in minutes)?  
-- (Use COUNT + AVG with a WHERE clause on `departure_delay > 0`.)

select
(count(*) filter(where departure_delay > 0))::decimal/ count(*) as delayed_flight_pct,
avg(departure_delay) filter(where departure_delay > 0) as avg_delay
from flights;

-- 13. How does the % of delayed flights vary throughout the year? What about for flights leaving from Boston (BOS) specifically?  
-- (Use CTE to calculate monthly delay %; add filter for BOS.)

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
pct_delayed as(
	select
		month,
		-- Dataset shows 0 flights from Boston in October, replacing 0 with NULL to avoid division by zero error
		(nullif(boston_delays,0) * 1.0 / nullif(boston_total,0)) * 100 as pct_delayed_boston,
		(all_other_delays * 1.0 / total_other) * 100 as pct_delayed_other
	from monthly_flights
)
select
	*,
	pct_delayed_boston - pct_delayed_other as boston_vs_all_else
from pct_delayed;

-- 14. How many flights were cancelled in 2015? What % were due to weather vs. the airline?  
-- (Filter on `cancelled = 1`; GROUP BY `cancellation_reason`.)

select
	c.description,
	count(*) as total_cancellations_per,
	(count(*) / sum(count(*)) over()) * 100 as pct_per
from flights f 
left join cancellation_codes c
on f.cancellation_reason = c.code
where f.cancelled = True
group by 1
order by 2;

-- 15. Which airlines seem to be most and least reliable in terms of on-time departure?  
-- (Aggregate delay counts per airline; order by average delay.)

select
	a.airline_name,
	avg(f.departure_delay) as avg_departure_delay
from flights f 
left join airline a
	on f.airline_code = a.iata_code
where departure_delay > 0
group by 1
order by 2 asc;

-- 16. What percentage of flights were delayed, cancelled, or diverted overall and per airline?  
-- (Use CASE WHEN to tag status, then COUNT + GROUP BY airline.)

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

-- 17. Which airports had the highest average arrival and departure delays, and how do they compare nationally?  
-- (GROUP BY airport; AVG(arrival_delay), AVG(departure_delay).)

-- 18. What are the top 5 airlines with the best and worst average arrival delay times?  
-- (RANK or LIMIT by AVG(arrival_delay) per airline.)

-- 19. Which flight routes have the highest frequency of weather-related delays?  
-- (Filter by `weather_delay > 0`, GROUP BY origin + destination.)

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
limit 10;

-- 20. Is there a correlation between flight distance and arrival delay?  
-- (Use correlation functions like `corr(distance, arrival_delay)`.)

select corr(distance, arrival_delay)
from flights
where arrival_delay is not null;

-- 21. How do delay reasons vary across airlines—do some experience more delays due to late aircraft, others due to weather?  
-- (GROUP BY airline; SUM delay categories.)

-- 22. What is the average delay for each airline by day of the week?  
-- (GROUP BY airline, day_of_week; use AVG(arrival_delay).)

-- 23. Which flights had the longest taxi-in and taxi-out times, and how does this affect overall delays?  
-- (ORDER BY taxi_in + taxi_out DESC; compare to delay.)

-- 24. Which months show the highest rate of cancellations and for what reasons?  
-- (GROUP BY month + cancellation_reason; COUNT + PERCENT.)

-- 25. What is the distribution of total delays by delay category (air system, security, airline, etc.) across all flights?  
-- (SUM each delay column; consider visualization like stacked bars.)
