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

## Data Structure & Initial Checks

The Department of Transportation’s main database structure for this analysis consists of four tables: flights, airlines, airports, and cancellations, with a total row count of approximately 1.8 million records.

A description of each table is as follows:

Flights: contains fact details for individual flights including flight ID, date and time, airline code, origin and destination airports, delay times, and cancellation status.
Carriers: contains unique airline code and name of airline
Airports: contains unique airport codes, airport name, city, and region
Cancel Codes: contains unique cancellation codes and descriptions
Markets: contains unique city-market ID, city name, and region
World Areas: contains world area code and area name

## Dataset

- The dataset is sourced directly from the Department of Transportation and can be found [here](https://www.transtats.bts.gov/Fields.asp?gnoyr_VQ=FGJ).


