-- Working with date fields 

SELECT 

-- Current date in AEST
CURRENT_DATE('Australia/Melbourne') AS current_date,

-- Current date in UTC
CURRENT_DATE() ,

CURRENT_TIMESTAMP() AS current_timestamp,

-- Converts string to a DATE field 
PARSE_DATE("%Y%m%d",'19940331') AS parse_date,

-- Unix/epoch/posix time in seconds since Jan 1st, 1970
-- Unix time is based in UTC /GMT timezone
UNIX_DATE('2022-01-01') AS unix_date,

-- Convert unix to a timestamp
TIMESTAMP_SECONDS(1661341947),

--Convert a timestamp from UTC to local timezone
DATETIME(TIMESTAMP_SECONDS(1661341947),"Australia/Melbourne"),

-- Difference between 2 dates
DATE_DIFF (CURRENT_DATE('Australia/Melbourne')+ 5 , CURRENT_DATE('Australia/Melbourne') , DAY ),
DATE_DIFF (CURRENT_DATE('Australia/Melbourne')+ 5 , CURRENT_DATE('Australia/Melbourne') , MONTH ),
DATE_DIFF (CURRENT_DATE('Australia/Melbourne')+ 5 , CURRENT_DATE('Australia/Melbourne') , YEAR ),

-- Difference between 2 timestamp
TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), SECOND),

-- Truncate date part of the day part 
-- MONTH : The first day of the month the date belongs
-- WEEK : The firts day of the week starts Sunday
DATE_TRUNC(CURRENT_DATE('Australia/Melbourne'),MONTH),
DATE_TRUNC(CURRENT_DATE('Australia/Melbourne'),WEEK(MONDAY))
