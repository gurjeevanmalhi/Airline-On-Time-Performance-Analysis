-- Business Problems

-- 1. Which airlines demonstrated the highest operational efficiency in 2015, and how did their on-time performance compare across different regions and quarters?  
-- (Use CTEs to segment data by region and time, window functions to rank performance.)

-- 2. What are the top 10 most heavily trafficked routes, and how do delay patterns and cancellation rates on these routes impact customer experience and airline reliability?  
-- (Use ROW_NUMBER or RANK, aggregate delay metrics by route.)

-- 3. How do average arrival delays vary by day of week and month, and what patterns or seasonality can be identified to inform future scheduling strategies?  
-- (GROUP BY with aggregates; CTEs to prep calendar metrics.)

-- 4. What are the key drivers of flight cancellations across the industry, and how do these reasons differ by airline, airport, and time of year?  
-- (Use JOINs on cancellation codes, filter with CASE WHEN logic.)

-- 5. Which airports consistently experience high weather-related delays, and how can these insights support strategic investment or scheduling decisions?  
-- (Aggregate weather delay time by airport; filter and rank.)

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

-- 11. How does the overall flight volume vary by month? By day of week?  
-- (GROUP BY month, day_of_week; COUNT(*))

select
month,
count(*) as total_flights,
count(*) - lag(count(*)) over(order by month) as variance
from flights
group by 1
order by 1 asc;

-- 12. What percentage of flights experienced a departure delay in 2015? Among those, what was the average delay time (in minutes)?  
-- (Use COUNT + AVG with a WHERE clause on `departure_delay > 0`.)

select
(count(*) filter(where departure_delay > 0))::decimal/ count(*) as delayed_flight_pct,
avg(departure_delay) filter(where departure_delay > 0) as avg_delay
from flights;

-- 13. How does the % of delayed flights vary throughout the year? What about for flights leaving from Boston (BOS) specifically?  
-- (Use CTE to calculate monthly delay %; add filter for BOS.)

-- 14. How many flights were cancelled in 2015? What % were due to weather vs. the airline?  
-- (Filter on `cancelled = 1`; GROUP BY `cancellation_reason`.)

select
	c.description,
	count(*) as total_cancellations_per,
	sum(count(*)) over() as total_cancellations_overall,
	(count(*) / sum(count(*)) over()) * 100 as pct_per
from flights f 
left join cancellation_codes c
on f.cancellation_reason = c.code
where f.cancelled = True
group by 1
order by 2;

-- 15. Which airlines seem to be most and least reliable in terms of on-time departure?  
-- (Aggregate delay counts per airline; order by average delay.)

-- 16. What percentage of flights were delayed, cancelled, or diverted overall and per airline?  
-- (Use CASE WHEN to tag status, then COUNT + GROUP BY airline.)

-- 17. Which airports had the highest average arrival and departure delays, and how do they compare nationally?  
-- (GROUP BY airport; AVG(arrival_delay), AVG(departure_delay).)

-- 18. What are the top 5 airlines with the best and worst average arrival delay times?  
-- (RANK or LIMIT by AVG(arrival_delay) per airline.)

-- 19. Which flight routes have the highest frequency of weather-related delays?  
-- (Filter by `weather_delay > 0`, GROUP BY origin + destination.)

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
