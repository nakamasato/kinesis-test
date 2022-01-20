-- CREATE a Stream to receive the query aggregation result
CREATE OR REPLACE STREAM "DESTINATION_SQL_STREAM"
(
  session_id VARCHAR(60),
  user_id INTEGER,
  device_id VARCHAR(10),
  timeagg timestamp,
  events INTEGER,
  beginnavigation VARCHAR(32),
  endnavigation VARCHAR(32),
  beginsession VARCHAR(25),
  endsession VARCHAR(25),
  duration_sec INTEGER
);

-- Create the PUMP
CREATE OR REPLACE PUMP "WINDOW_PUMP_SEC" AS INSERT INTO "DESTINATION_SQL_STREAM"
-- Insert as Select
    SELECT  STREAM
-- Make the Session ID using user_ID+device_ID and Timestamp
    UPPER(cast("user_id" as VARCHAR(3))|| '_' ||SUBSTRING("device_id",1,3)
    ||cast( UNIX_TIMESTAMP(STEP("client_timestamp" by interval '30' second))/1000 as VARCHAR(20))) as session_id,
    "user_id" , "device_id",
-- create a common rounded STEP timestamp for this session
    STEP("client_timestamp" by interval '30' second),
-- Count the number of client events , clicks on this session
    COUNT("client_event") events,
-- What was the first navigation action
    first_value("client_event") as beginnavigation,
-- what was the last navigation action
    last_value("client_event") as endnavigation,
-- begining minute and second
    SUBSTRING(cast(min("client_timestamp") AS VARCHAR(25)),15,19) as beginsession,
-- ending minute and second
    SUBSTRING(cast(max("client_timestamp") AS VARCHAR(25)),15,19) as endsession,
-- session duration
    TSDIFF(max("client_timestamp"),min("client_timestamp"))/1000 as duration_sec
-- from the source stream
    FROM "SOURCE_SQL_STREAM_001"
-- using stagger window , with STEP to Seconds, for Seconds intervals
    WINDOWED BY STAGGER (
                PARTITION BY "user_id", "device_id", STEP("client_timestamp" by interval '30' second)
                RANGE INTERVAL '30' SECOND );
