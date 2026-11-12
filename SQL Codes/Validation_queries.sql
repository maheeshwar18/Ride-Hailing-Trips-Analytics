-- RIDE-HAILING TRIP ANALYTICS
-- VALIDATION QUERIES

-- Q1. Check row counts across all layers

SELECT 'Bronze' AS layer, COUNT(*) AS total_rows
FROM mobility_catalog.trips.bronze_ride_trips

UNION ALL

SELECT 'Silver Clean', COUNT(*)
FROM mobility_catalog.trips.silver_trips_clean

UNION ALL

SELECT 'Silver Rejected', COUNT(*)
FROM mobility_catalog.trips.silver_trips_rejected;


-- Q2. Check duplicate trip IDs in Bronze

SELECT
    COUNT(*) - COUNT(DISTINCT trip_id) AS duplicate_rows
FROM mobility_catalog.trips.bronze_ride_trips;


-- Q3. Check duplicate trip IDs in Silver Clean

SELECT
    COUNT(*) - COUNT(DISTINCT trip_id) AS duplicate_rows
FROM mobility_catalog.trips.silver_trips_clean;


-- Q4. Check invalid distances

SELECT COUNT(*) AS invalid_distance_rows
FROM mobility_catalog.trips.bronze_ride_trips
WHERE distance_km <= 0;


-- Q5. Check invalid rates

SELECT COUNT(*) AS invalid_rate_rows
FROM mobility_catalog.trips.bronze_ride_trips
WHERE rate_per_km < 0;


-- Q6. Check missing city values

SELECT COUNT(*) AS missing_city_rows
FROM mobility_catalog.trips.bronze_ride_trips
WHERE city IS NULL OR TRIM(city) = '';


-- Q7. Check missing payment methods

SELECT COUNT(*) AS missing_payment_rows
FROM mobility_catalog.trips.bronze_ride_trips
WHERE payment_method IS NULL OR TRIM(payment_method) = '';


-- Q8. Check missing fare amounts

SELECT COUNT(*) AS missing_fare_rows
FROM mobility_catalog.trips.bronze_ride_trips
WHERE fare_amount IS NULL;


-- Q9. Check missing customer ratings

SELECT COUNT(*) AS missing_rating_rows
FROM mobility_catalog.trips.bronze_ride_trips
WHERE customer_rating IS NULL;


-- Q10. Validate Silver Clean data

SELECT
    COUNT(*) AS total_clean_rows,
    COUNT(DISTINCT trip_id) AS unique_trips,
    SUM(CASE WHEN distance_km <= 0 THEN 1 ELSE 0 END)
        AS invalid_distance,
    SUM(CASE WHEN rate_per_km < 0 THEN 1 ELSE 0 END)
        AS invalid_rate
FROM mobility_catalog.trips.silver_trips_clean;


-- Q11. Validate Gold Monthly Trips

SELECT *
FROM mobility_catalog.trips.gold_monthly_trips
ORDER BY trip_month;


-- Q12. Validate Gold City Summary

SELECT *
FROM mobility_catalog.trips.gold_city_summary
ORDER BY net_revenue DESC;


-- Q13. Validate Gold Vehicle Summary

SELECT *
FROM mobility_catalog.trips.gold_vehicle_summary
ORDER BY trips DESC;


-- Q14. Validate Gold Payment Summary

SELECT *
FROM mobility_catalog.trips.gold_payment_summary
ORDER BY net_revenue DESC;


-- Q15. Validate Gold Data Quality

SELECT *
FROM mobility_catalog.trips.gold_data_quality;


-- Q16. Revenue reconciliation

SELECT
    SUM(fare_amount - discount_amount) AS calculated_net_revenue,
    SUM(driver_payout) AS total_driver_payout,
    SUM(fare_amount - discount_amount)
        - SUM(driver_payout) AS calculated_platform_earnings
FROM mobility_catalog.trips.silver_trips_clean;


-- Q17. Check Bronze to Silver reconciliation

SELECT
    (SELECT COUNT(*)
     FROM mobility_catalog.trips.bronze_ride_trips) AS bronze_rows,

    (SELECT COUNT(*)
     FROM mobility_catalog.trips.silver_trips_clean) AS clean_rows,

    (SELECT COUNT(*)
     FROM mobility_catalog.trips.silver_trips_rejected) AS rejected_rows,

    (SELECT COUNT(*) - COUNT(DISTINCT trip_id)
     FROM mobility_catalog.trips.bronze_ride_trips) AS duplicate_rows;


-- Q18. Verify Gold tables are populated

SELECT 'gold_monthly_trips' AS table_name, COUNT(*) AS rows
FROM mobility_catalog.trips.gold_monthly_trips

UNION ALL

SELECT 'gold_city_summary', COUNT(*)
FROM mobility_catalog.trips.gold_city_summary

UNION ALL

SELECT 'gold_vehicle_summary', COUNT(*)
FROM mobility_catalog.trips.gold_vehicle_summary

UNION ALL

SELECT 'gold_payment_summary', COUNT(*)
FROM mobility_catalog.trips.gold_payment_summary

UNION ALL

SELECT 'gold_data_quality', COUNT(*)
FROM mobility_catalog.trips.gold_data_quality;
