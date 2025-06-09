# Airline On-Time Performance Analysis

## Project Background

The U.S. Department of Transportation (DOT) oversees the performance and reliability of commercial airline operations across the country. As part of its mission to improve transportation efficiency and consumer satisfaction, the DOT collects and analyzes flight performance data from domestic airlines to monitor trends and identify areas for improvement.

This project focuses on analyzing commercial airline flight data from Q4 2024. The dataset includes detailed information on flight delays, cancellations, and route activity across major U.S. carriers and airports.

This analysis was conducted to uncover performance trends, evaluate airport and airline reliability, and provide data-driven recommendations to improve service quality and operational efficiency.

Stakeholders across the DOT, including regulatory teams, airport authorities, infrastructure planners, and policy makers, will use these insights to enhance airline compliance, improve airport operations, optimize route management, and guide policy decisions to boost overall air travel efficiency and passenger experience.

Insights and recommendations are provided on the following key areas:

- Airline Operational Performance: Which airlines consistently meet their schedules? Are certain carriers outperforming others in terms of cancellations and on-time arrivals?

- Airport & Route Analysis: Which airports experience the highest volumes of delayed or canceled flights? Are there specific routes that underperform or show operational challenges?

- Flight Delay Trends & Patterns: What are the most common causes of flight delays? Are there temporal or geographic patterns in delay occurrences?

The SQL queries used to inspect and clean the data for this analysis can be found [here](Database%Design.sql).

Targeted SQL queries regarding various business questions can be found [here](Business%20Problems.sql).

An interactive Power BI dashboard used to report and explore performance trends can be found [here](Dashboard.pbix).

## Data Structure & Initial Checks

The Department of Transportation’s main database structure for this analysis consists of 6 tables: flights, carriers, airports, cancel codes, markets, and world areas, with a total row count of approximately 1.8 million records. A description of each table is as follows:

- Flights: contains fact details for individual flights including flight ID, date and time, airline code, origin and destination airports, delay times, and cancellation status.

- Carriers: contains unique airline code and name of airline

- Airports: contains unique airport codes, airport name, city, and region

- Cancel Codes: contains unique cancellation codes and descriptions

- Markets: contains unique city-market ID, city name, and region

- World Areas: contains world area code and area name

![Entity Relationship Diagram](Entity%20Relationship%20Diagram.png)

## Executive Summary

### Overview of Findings
This analysis of U.S. commercial flight performance revealed key operational inefficiencies and delay patterns impacting both airlines and airports. Reporting airlines across the industry maintain a 84% on-time departure rate, with 16% of flights being delayed for 15 minutes or more. Flight cancellations should not pose a major concern for leadership, as cancellations only account for 1% of total flights. Major hubs like Atlanta, Chicago, and Dallas handled the highest volumes, often experiencing notable delay variability.

![Business Overview](Dashboard%20Image.jpg)

### Airline Operational Performance

- Endeavor Air Inc. consistently led all airlines in on-time arrival performance across Q4, ranking #1 each month. Their on-time rate exceeded 90%, significantly outperforming peers.

- Despite industry-wide delays, some airlines maintained low delay percentages. For example, top third of airlines in on-time departures had average departure delays under 30 minutes, compared to over an hour for the bottom third.

- Flight cancellations were overwhelmingly driven by weather conditions (77%), followed by carrier-related issues (14%). This shows that external factors dominate airline reliability, suggesting limited control over total disruptions.

- Controllable delays (carrier and national system-related) made up a significant share of total delays for certain airlines—up to 60%, indicating room for internal process improvements.

### Airport & Route Analysis

- Chicago, Atlanta, Dallas-Fort Worth, Denver, and New York were the top 5 flight hubs by volume. Chicago held the #1 position for overall flight traffic, making it a key operational and strategic hub.

- Flight routes between major metro pairs—Chicago–New York, New York–Boston, LA–SF—dominated traffic, collectively accounting for thousands of flights. These routes are prime targets for demand forecasting and dynamic pricing.

- Dallas/Fort Worth, O'Hare, and Denver experienced the most weather-related departure delays, with Dallas/Fort Worth accumulating the highest total. These insights can support airport-level planning and weather contingency strategies.

- Hartsfield–Jackson Atlanta International consistently ranked as the #1 airport for monthly flight volume, maintaining its dominance across all three months of Q4.

### Flight Delay Trends and Patterns

- Only 16.4% of all flights experienced delays of 15+ minutes. Among those, the average delay was 66–67 minutes, signaling that while delays are not extremely frequent, they are substantial when they occur.

- Medium-duration flights (2–4 hours) had the highest average departure delay at ~9 minutes, slightly higher than long and short flights. Delay time does not increase linearly with flight length, debunking common assumptions.

- There is no meaningful correlation (CORR = -0.01) between flight distance and arrival delay, indicating that other factors (weather, scheduling, volume) likely drive most delays.

- Monday at 7AM is the busiest flying time, while Wednesday at 4AM is the least busy. These patterns suggest opportunities for load balancing and passenger incentive strategies.

## Recommendations

Based on the insights and findings above, we would recommend the Operations and Strategy teams to consider the following:

- Endeavor Air consistently ranked highest in on-time performance across all months.
Recommendation: Use Endeavor’s scheduling and logistics practices as a benchmark for other carriers to improve operational efficiency.

- Airports like Dallas/Fort Worth and O’Hare experience the most weather-related delays.
Recommendation: Strengthen contingency planning and resource allocation for high-delay airports during adverse weather months.

- Medium-duration flights (121–240 mins) have the highest average departure delay.
Recommendation: Analyze turnaround processes and padding schedules for medium-length flights to reduce bottlenecks.

- 77% of cancellations were due to weather-related issues.
Recommendation: Collaborate with meteorological services for more accurate forecasting and proactive passenger communication strategies.

- Chicago, Atlanta, and Dallas serve as top flight hubs with high volume.
Recommendation: Prioritize infrastructure investment and staffing strategies in these cities to support efficient hub operations and reduce congestion.

## Technologies and Key Skills Used

- PostgreSQL
- Power BI
- Power Query
- DAX
- Excel
- Data Cleaning & Quality
- Data Modeling
- Data Visualization

## Dataset

- The dataset is sourced directly from the Department of Transportation and can be found [here](https://www.transtats.bts.gov/Fields.asp?gnoyr_VQ=FGJ).
