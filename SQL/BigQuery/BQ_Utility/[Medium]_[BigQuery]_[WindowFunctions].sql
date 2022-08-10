-- Window Functions
-- https://towardsdatascience.com/mastering-sql-window-functions-6cd17004dfe0
-- datset:https://www.kaggle.com/sudalairajkumar/daily-temperature-of-major-cities

-- Steps
-- Step-1 Split the data into groups 
-- Step-2 Perform aggregation/calculation across each group
-- Step-3 Combine data to the original dataset

-- Problem1 
--  Find the warmest day from each city over the entire dataset.
select *, 
row_number() over (partition by city order by temperature desc) as temperature_rank
from temperature_data.city_temperature
limit 5;

-- Problem2
-- For each day, find the difference between the temperature that day and the average temperature in that month for that city.
select *, avg(temperature) over (partition by city, month) as average_monthly_temperature
from temperature_data.city_temperature 
limit 5;

-- Problem3
-- Frame clause
-- For each record, find the average temperature over the past 5 days for that city.
select *, avg(temperature) over (partition by city order by year, month, day rows between 6 preceding and 1 preceding) as temp_rolling_5
from temperature_data.city_temperature
limit 10;

-- Tips
-- We can't put a window function in the WHERE caluse
