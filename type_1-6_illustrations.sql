DROP DATABASE IF EXISTS scd_example;

CREATE DATABASE scd_example;

\c scd_example;

--- Type 1 version

CREATE TABLE product_price_type_1 (
	product_id INTEGER,
	price NUMERIC,
	PRIMARY KEY (product_id)
);

INSERT INTO product_price_type_1 
    (product_id, price)    
    VALUES (12345, 20.99);

--- Type 2 version

CREATE TABLE product_price_type_2 (
	product_id INTEGER,
	price NUMERIC,
	start_date date, 
	end_date date, 
	--- SQL standard does not allow NULL values in columns that participate in a primary key
	UNIQUE (product_id,start_date, end_date)
);

INSERT INTO product_price_type_2 
    (product_id, price, start_date, end_date)
    VALUES 
    (12345, 19.99, '2025-01-01', '2025-01-31'),
    (12345, 20.99, '2025-02-01', NULL);

--- Type 3 version

CREATE TABLE product_price_type_3 (
	product_id INTEGER,
	price NUMERIC,
	last_update date,
	prior_price NUMERIC,
	PRIMARY KEY (product_id)
);    

INSERT INTO product_price_type_3 
    (product_id, price, last_update, prior_price)
    VALUES
    (12345, 20.99, '2025-02-01', 19.99);

--- Type 4 version   

CREATE TABLE product_price_type_4 (
	product_id INTEGER,
	price NUMERIC,
	effective_date date,
	PRIMARY KEY (product_id, effective_date)
);

INSERT INTO product_price_type_4
	(product_id, price, effective_date)
	VALUES
	(12345, 19.99, '2025-01-01'),
	(12345, 20.99, '2025-02-01');
	

--- Type 5 version	

CREATE TABLE product_price_type_5 (
	product_id INTEGER,
	price NUMERIC,
	PRIMARY KEY (product_id)
);

CREATE TABLE product_price_history_type_5 (
	product_id INTEGER,
	price NUMERIC,
	effective_date date,
	PRIMARY KEY (product_id, effective_date)
	);

INSERT INTO product_price_type_5 
    (product_id, price)    
    VALUES (12345, 20.99);

INSERT INTO product_price_history_type_5
	(product_id, price, effective_date)
	VALUES
	(12345, 19.99, '2025-01-01'),
	(12345, 20.99, '2025-02-01');

--- Type 6

CREATE TABLE product_price_type_6 (
	product_id INTEGER,
	price NUMERIC,
	start_date date, 
	end_date date, 
	current BOOLEAN,
	--- SQL standard does not allow NULL values in columns that participate in a primary key
	UNIQUE (product_id,start_date, end_date)
);

INSERT INTO product_price_type_6
	(product_id, price, start_date, end_date, current)
	VALUES
	(12345, 19.99, '2025-01-01', '2025-01-31', false),
	(12345, 20.99, '2025-02-01', NULL, true);

