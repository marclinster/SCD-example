/* Detailed example of using Postgres 17 to model a SCD Type 6 */

--- add btree_gist extension to define rangetype constraint for product pricing
CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF ExISTS product_price_scd;

CREATE TABLE product_price_scd (
    id UUID PRIMARY KEY,
    product_id INTEGER NOT NULL,
    price NUMERIC DEFAULT 0 NOT NULL,
    validity DATERANGE,
    current BOOLEAN,
    --- Constraint makes sure that validity date ranges are unique for each product_id.
    --- the && operator tests for overlap of ranges, which would be a conflict
    EXCLUDE USING GIST (product_id WITH =, validity WITH &&) 
);

--- [ or ] indicates that the range boundary is included
--- ( or ) indicates that the range boundary is excluded
INSERT INTO product_price_scd 
    (id, product_id, price, validity, current)
    VALUES
    (
        gen_random_uuid (), 12345, 19.99, '[, 2025-02-01)', false
    ),
     (
        gen_random_uuid (), 12345, 12.99, '[2025-02-01, 2025-03-01)', false
    ),
     (
        gen_random_uuid (), 12345, 20.99, '[2025-03-01,]', true
    ),
    (
        gen_random_uuid (), 12346, 1.00, '[2025-01-01, 2025-01-31]', false
    ),
    (
        gen_random_uuid (), 12346, 2.00, '(2025-01-31, 2025-02-28]', false
    ),
    (
        gen_random_uuid (), 12346, 3.00, '[2025-03-01, 2025-03-31]', false
    ),
    (
        gen_random_uuid (), 12346, 4.00, '[2025-04-01, 2025-04-30]', false
    ),
    (
        gen_random_uuid (), 12346, 5.00, '[2025-05-01, 2025-05-31]', false
    ),
    (
        gen_random_uuid (), 12346, 6.00, '[2025-06-01, 2025-06-30]', false
    ),
    (
        gen_random_uuid (), 12346, 7.00, '[2025-07-01, 2025-07-30]', true
    ),
    (
        gen_random_uuid (), 12346, 8.00, '[2025-08-01,2025-08-30]', false
    ),
    --- this creates a gap
    (
        gen_random_uuid (), 12346, 10.00, '[2025-10-01,2025-10-30]', false
    )
    ;

--- print out the sample dataset

SELECT product_id, price, validity, current 
    FROM product_price_scd 
    ORDER BY product_id, lower(validity) 
    ASC NULLS FIRST;

--- find out what the product price was on a certain date

SELECT price FROM product_price_scd 
    WHERE validity @> '2025-06-18'::date 
    AND product_id = 12345;


--- this causes a conflict

INSERT INTO product_price_scd 
(
    id, product_id, price, validity, current
)
VALUES
(
    gen_random_uuid (), 12346, 100.00, '[2025-07-01,2025-07-02]', false
);

 --- this sets the 'current' flag based on today's date

BEGIN;
    UPDATE product_price_scd SET current = true 
        --- only change the flags that have to be changed to avoid unnecessary transactions
        WHERE validity @> current_date AND current = false;
    UPDATE product_price_scd SET current = false 
        --- only change the flags that have to be changed to to avoid unnecessary transactions
        WHERE NOT validity @> current_date AND current = true;
COMMIT;    

--- this identifies gaps in the dateranges for each product

WITH ordered_ranges AS (
  SELECT 
    product_id,
    validity,
    LAG(upper(validity)) OVER (ORDER BY lower(validity)) AS previous_range_end,
    lower(validity) AS current_range_start,
    upper(validity) AS current_range_end,
    LEAD(lower(validity)) OVER (ORDER BY lower(validity)) AS next_range_start
  FROM product_price_scd
),
gaps AS (
  SELECT
    product_id,
    previous_range_end AS gap_start,
    current_range_start AS gap_end,
    current_range_start - previous_range_end AS gap_duration
  FROM ordered_ranges
  WHERE previous_range_end IS NOT NULL 
    AND current_range_start > previous_range_end
)
SELECT 
    product_id,
  gap_start,
  gap_end,
  gap_duration
FROM gaps
ORDER BY product_id, gap_start;
