-- LAYER 1: BRONZE

CREATE OR REFRESH STREAMING TABLE bronze_ride_trips
AS
SELECT
    *,
    _metadata.file_name AS source_file,
    CURRENT_TIMESTAMP() AS loaded_at

FROM STREAM READ_FILES(
    '/Volumes/mobility_catalog/default/mobility_volume',
    format => 'csv',
    header => true,
    inferColumnTypes => true
);
