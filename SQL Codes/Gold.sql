-- LAYER 3: GOLD
-- STEP 1: MONTHLY ANALYSIS

CREATE OR REFRESH MATERIALIZED VIEW
gold_monthly_trips
AS

SELECT

    DATE_TRUNC('MONTH', trip_date) AS trip_month,

    COUNT(*) AS trips,

    SUM(distance_km) AS total_km,

    SUM(fare_amount - discount_amount)
        AS net_revenue,

    SUM(driver_payout) AS driver_payout,

    SUM(fare_amount - discount_amount)
        - SUM(driver_payout)
        AS platform_earnings

FROM silver_trips_clean

GROUP BY DATE_TRUNC('MONTH', trip_date);


-- STEP 2: CITY ANALYSIS

CREATE OR REFRESH MATERIALIZED VIEW
gold_city_summary
AS

SELECT

    region,

    city,

    COUNT(*) AS trips,

    SUM(fare_amount - discount_amount)
        AS net_revenue,

    AVG(fare_amount - discount_amount)
        AS avg_fare_per_trip

FROM silver_trips_clean

GROUP BY
    region,
    city;


-- STEP 3: VEHICLE ANALYSIS

CREATE OR REFRESH MATERIALIZED VIEW
gold_vehicle_summary
AS

SELECT

    vehicle_type,

    COUNT(*) AS trips,

    SUM(distance_km) AS total_km,

    SUM(fare_amount - discount_amount)
        AS net_revenue,

    AVG(customer_rating) AS avg_rating

FROM silver_trips_clean

GROUP BY vehicle_type;


-- STEP 4: PAYMENT ANALYSIS

CREATE OR REFRESH MATERIALIZED VIEW
gold_payment_summary
AS

SELECT

    payment_method,

    COUNT(*) AS trips,

    SUM(fare_amount - discount_amount)
        AS net_revenue,

    SUM(
        CASE
            WHEN LOWER(TRIM(payment_status)) = 'pending'
            THEN fare_amount - discount_amount
            ELSE 0
        END
    ) AS pending_amount

FROM silver_trips_clean

GROUP BY payment_method;


-- STEP 5: DATA QUALITY

CREATE OR REFRESH MATERIALIZED VIEW
gold_data_quality
AS

SELECT

    -- Total Bronze records
    (SELECT COUNT(*)
     FROM bronze_ride_trips) AS bronze_rows,

    -- Duplicate records removed
    (SELECT COUNT(*)
     FROM bronze_ride_trips)
    -
    (SELECT COUNT(*)
     FROM silver_trips_deduplicated)
    AS duplicate_rows,

    -- Invalid distance records
    (SELECT COUNT(*)
     FROM bronze_ride_trips
     WHERE TRY_CAST(distance_km AS DOUBLE) <= 0
        OR TRY_CAST(distance_km AS DOUBLE) IS NULL)
    AS invalid_distance_rows,

    -- Negative rate records
    (SELECT COUNT(*)
     FROM bronze_ride_trips
     WHERE TRY_CAST(rate_per_km AS DOUBLE) < 0)
    AS negative_rate_rows,

    -- Missing city
    (SELECT COUNT(*)
     FROM bronze_ride_trips
     WHERE city IS NULL OR TRIM(city) = '')
    AS missing_city_rows,

    -- Missing payment method
    (SELECT COUNT(*)
     FROM bronze_ride_trips
     WHERE payment_method IS NULL
        OR TRIM(payment_method) = '')
    AS missing_payment_rows,

    -- Missing customer ID
    (SELECT COUNT(*)
     FROM bronze_ride_trips
     WHERE customer_id IS NULL
        OR TRIM(customer_id) = '')
    AS missing_customer_id_rows,

    -- Missing fare
    (SELECT COUNT(*)
     FROM bronze_ride_trips
     WHERE fare_amount IS NULL)
    AS missing_fare_rows,

    -- Missing customer rating
    (SELECT COUNT(*)
     FROM bronze_ride_trips
     WHERE customer_rating IS NULL)
    AS missing_rating_rows,

    -- Clean records
    (SELECT COUNT(*)
     FROM silver_trips_clean)
    AS clean_rows,

    -- Rejected records
    (SELECT COUNT(*)
     FROM silver_trips_rejected)
    AS rejected_rows,

    -- Reconciliation
    (
        (SELECT COUNT(*) FROM bronze_ride_trips)
        =
        (SELECT COUNT(*) FROM silver_trips_clean)
        +
        (SELECT COUNT(*) FROM silver_trips_rejected)
        +
        (
            (SELECT COUNT(*) FROM bronze_ride_trips)
            -
            (SELECT COUNT(*) FROM silver_trips_deduplicated)
        )
    ) AS reconciliation_passed;
