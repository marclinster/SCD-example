/* Detailed example of using Postgres 17 to model a SCD Type 6 */

--- add btree_gist extension to define rangetype constraint for product pricing
CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF ExISTS product_price_scd;

CREATE TABLE product_price_scd (
    id UUID PRIMARY KEY,
    product_id INTEGER NOT NULL,
    price NUMERIC DEFAULT 0 NOT NULL,
    --- from when to when is a certain price valid. The lower bound will be excluded and the upper bound included
    validity DATERANGE,
    current BOOLEAN,
    --- Constraint makes sure that validity date ranges are unique for each product_id.
    --- && tests for overlap of ranges, which would be a conflict
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

 --- set the 'current' flag based on today's date

BEGIN;
    UPDATE product_price_scd SET current = true 
        WHERE validity @> current_date AND current = false;
    UPDATE product_price_scd SET current = false 
        WHERE NOT validity @> current_date AND current = true;
COMMIT;        

    --- causes a conflict
/*
    INSERT INTO product_price_scd 
    (id, product_id, price, validity, current)
    VALUES
    (
        gen_random_uuid (), 12346, 100.00, '[2025-07-01,2025-07-02]', false
    );

*/    

SELECT * FROM product_price_scd;

/*
select the row with the earliest start_date (or NULL)
UNION
the row that has a start date = prior row's end date

*/

WITH RECURSIVE find_gaps
AS 
    (
        SELECT  product_id, 
                MIN(lower(validity)) as lower_bound 
            FROM product_price_scd GROUP BY product_id
        UNION
        SELECT initialprice.product_id, lower(initialprice.validity) as lower_bound 
            FROM product_price_scd initialprice
            INNER JOIN product_price_scd nextprice
                ON 
                    upper(initialprice.validity) = lower(nextprice.validity)
                    AND initialprice.product_id = nextprice.product_id
    )
SELECT * FROM find_gaps ORDER BY product_id ASC, lower_bound ASC NULL FIRST;

