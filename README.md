# Slowly Changing Dimensions Sample Code

Last updated: 2025-07-01

This repo contains the code that is used in the article **Slowly Changing Dimensions in Postgres**.

## How to use it

1. Run the file type_1-6_illustrations.sql first. Run it as a user who has the **create database privilege**.

   The script creates a separate database `scd-example` in which 6 tables will be created (one for each type of SCD), together with a short illustrative data set for each SCD.

2. Run the script    **type_6_detailed_example.sql** while connected to the database `scd-example` to create the table 'product_price_scd` and follow the examples in the article.

## Cleanup

Drop the database `scd-example`.
