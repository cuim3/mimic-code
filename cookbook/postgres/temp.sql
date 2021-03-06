-- --------------------------------------------------------
-- Title: Retrieves the temperature of adult patients
--        only for patients recorded with carevue
-- MIMIC version: MIMIC-III v1.3
-- Notes: this query does not specify a schema. To run it on your local
-- MIMIC schema, run the following command:
--  SET SEARCH_PATH TO mimiciii;
-- Where "mimiciii" is the name of your schema, and may be different.
-- --------------------------------------------------------

WITH agetbl AS
(
  SELECT ad.subject_id
  FROM admissions ad
  INNER JOIN patients p
  ON ad.subject_id = p.subject_id
  WHERE
  -- filter to only adults
  EXTRACT(EPOCH FROM (ad.admittime - p.dob))/60.0/60.0/24.0/365.242 > 15
  -- group by subject_id to ensure there is only 1 subject_id per row
  group by ad.subject_id
)

SELECT (bucket/10) + 30, count(*) FROM (
  SELECT width_bucket(
      CASE WHEN itemid IN (223762, 676) THEN valuenum -- celsius
           WHEN itemid IN (223761, 678) THEN (valuenum - 32) * 5 / 9 --fahrenheit
           END, 30, 45, 160) AS bucket
    FROM chartevents ce
    INNER JOIN agetbl
    ON ce.subject_id = agetbl.subject_id
    WHERE itemid IN (676, 677, 678, 679)
    ) AS temperature
    GROUP BY bucket
    ORDER BY bucket;
