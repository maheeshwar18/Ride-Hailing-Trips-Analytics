-- LAYER 2: SILVER
-- STEP 1: REMOVE DUPLICATES

CREATE OR REFRESH MATERIALIZED VIEW
silver_trips_deduplicated
AS

SELECT *
FROM bronze_ride_trips

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY trip_id
    ORDER BY loaded_at
) = 1;


-- STEP 2: CLEAN DATA

CREATE OR REFRESH MATERIALIZED VIEW
silver_trips_clean
AS

SELECT

    TRIM(trip_id) AS trip_id,

    NULLIF(TRIM(customer_id), '') AS customer_id,

    NULLIF(TRIM(driver_id), '') AS driver_id,

    TRY_CAST(trip_date AS DATE) AS trip_date,

    TRY_CAST(pickup_hour AS INT) AS pickup_hour,

    COALESCE(
        INITCAP(TRIM(city)),
        'Unknown'
    ) AS city,

    INITCAP(TRIM(pickup_zone)) AS pickup_zone,

    COALESCE(
        INITCAP(TRIM(region)),
        'Unknown'
    ) AS region,

    INITCAP(TRIM(vehicle_type)) AS vehicle_type,

    INITCAP(TRIM(booking_channel)) AS booking_channel,

    TRY_CAST(distance_km AS DOUBLE) AS distance_km,

    TRY_CAST(duration_min AS INT) AS duration_min,

    TRY_CAST(rate_per_km AS DOUBLE) AS rate_per_km,

    COALESCE(
        TRY_CAST(fare_amount AS DOUBLE),
        TRY_CAST(distance_km AS DOUBLE)
        * TRY_CAST(rate_per_km AS DOUBLE)
    ) AS fare_amount,

    COALESCE(
        TRY_CAST(discount_amount AS DOUBLE),
        0
    ) AS discount_amount,

    COALESCE(
        NULLIF(TRIM(payment_method), ''),
        'Unknown'
    ) AS payment_method,

    INITCAP(TRIM(payment_status)) AS payment_status,

    COALESCE(
        TRY_CAST(driver_payout AS DOUBLE),
        0
    ) AS driver_payout,

    TRY_CAST(customer_rating AS DOUBLE) AS customer_rating,

    INITCAP(TRIM(trip_type)) AS trip_type

FROM silver_trips_deduplicated

WHERE
    TRY_CAST(distance_km AS DOUBLE) > 0
    AND TRY_CAST(rate_per_km AS DOUBLE) >= 0;


-- STEP 3: REJECTED RECORDS

CREATE OR REFRESH MATERIALIZED VIEW
silver_trips_rejected
AS

SELECT

    *,

    CASE

        WHEN TRY_CAST(distance_km AS DOUBLE) IS NULL
            THEN 'Missing or invalid distance'

        WHEN TRY_CAST(distance_km AS DOUBLE) <= 0
            THEN 'Distance is zero or negative'

        WHEN TRY_CAST(rate_per_km AS DOUBLE) IS NULL
            THEN 'Missing or invalid rate'

        WHEN TRY_CAST(rate_per_km AS DOUBLE) < 0
            THEN 'Rate per km is negative'

    END AS reject_reason

FROM silver_trips_deduplicated

WHERE

    TRY_CAST(distance_km AS DOUBLE) IS NULL
    OR TRY_CAST(distance_km AS DOUBLE) <= 0

    OR TRY_CAST(rate_per_km AS DOUBLE) IS NULL
    OR TRY_CAST(rate_per_km AS DOUBLE) < 0;
