CREATE DATABASE superstore_db;
USE superstore_db;

DESC superstore_raw 

-- =====================================
-- STEP 1: CREATE TABLES
-- =====================================

DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;

CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50)
);

CREATE TABLE products (
    product_id VARCHAR(50),
    product_name VARCHAR(255),
    category VARCHAR(100),
    sub_category VARCHAR(100)
);

CREATE TABLE orders (
    order_id VARCHAR(50),
    order_date VARCHAR(20),
    ship_date VARCHAR(20),
    customer_id VARCHAR(50),
    product_id VARCHAR(50),
    sales DECIMAL(10,2),
    quantity INT,
    profit DECIMAL(10,2)
);


INSERT INTO customers
SELECT DISTINCT
    `Customer ID`,
    `Customer Name`,
    Segment
FROM superstore_raw;

INSERT INTO products
SELECT DISTINCT
    `Product ID`,
    `Product Name`,
    Category,
    `Sub-Category`
FROM superstore_raw;

INSERT INTO orders
SELECT DISTINCT
    `Order ID`,
    `Order Date`,
    `Ship Date`,
    `Customer ID`,
    `Product ID`,
    Sales,
    Quantity,
    Profit
FROM superstore_raw;

-- SELECT COUNT(*) FROM orders;


-- 1. Find all orders where sales are greater than average sales (Subquery)
SELECT *
FROM orders
WHERE sales >
(
    SELECT AVG(sales)
    FROM orders
);

-- 2. Find the highest sales order for each customer (Subquery)
SELECT *
FROM orders o
WHERE sales =
(
    SELECT MAX(sales)
    FROM orders
    WHERE customer_id = o.customer_id
);
-- 3.Calculate total sales for each customer (CTE)
WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT *
FROM customer_sales;


-- 4.Find customers whose total sales are above average (CTE + Subquery)
WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT *
FROM customer_sales
WHERE total_sales >
(
    SELECT AVG(total_sales)
    FROM customer_sales
);

-- 5.Rank all customers based on total sales (Window Function)

WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_sales,
    RANK() OVER(ORDER BY total_sales DESC) AS sales_rank
FROM customer_sales;

-- 6.Assign row numbers to each order within a customer (Window Function + PARTITION BY)

SELECT
    order_id,
    customer_id,
    sales,
    ROW_NUMBER() OVER
    (
        PARTITION BY customer_id
        ORDER BY sales DESC
    ) AS row_num
FROM orders;

-- 7.Display top 3 customers based on total sales (Window Function)

WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
),
ranked_customers AS
(
    SELECT
        customer_id,
        total_sales,
        RANK() OVER(ORDER BY total_sales DESC) AS sales_rank
    FROM customer_sales
)
SELECT *
FROM ranked_customers
WHERE sales_rank <= 3;




/*
Question (FINAL COMBINED QUERY)

Using the customers and orders tables, write a SQL query to display:

Customer Name
-Total Sales made by each customer
-Sales Rank of each customer based on total sales (highest sales should get Rank 1)

Requirements:

-Use a CTE to calculate total sales for each customer.
-Use a JOIN to fetch customer names.
-Use a Window Function (RANK()) to rank customers by total sales.
-Display the results in descending order of sales rank.
*/
WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    cs.total_sales,
    RANK() OVER(ORDER BY cs.total_sales DESC) AS sales_rank
FROM customer_sales cs
JOIN customers c
    ON cs.customer_id = c.customer_id
ORDER BY sales_rank;



-- 1. Who are the Top 5 Customers?
WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    cs.total_sales
FROM customer_sales cs
JOIN customers c
    ON cs.customer_id = c.customer_id
ORDER BY cs.total_sales DESC
LIMIT 5;
/* 
Sean Miller	  |	25043.07
Tamara Chand  |	19017.85
Raymond Buch  |	15117.35
Tom Ashbrook  |	14595.62
Adrian Barton  |	14355.61
*/

-- 2. Who are the Bottom 5 Customers?
WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    cs.total_sales
FROM customer_sales cs
JOIN customers c
    ON cs.customer_id = c.customer_id
ORDER BY cs.total_sales ASC
LIMIT 5;

/*
Thais Sissman	4.84
Lela Donovan	5.30
Mitch Gastineau	12.32
Carl Jackson	16.52
Roy Skaria		22.33
*/

-- 3. Which Customers Made Only One Order?
SELECT
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) = 1;

/*
Anthony O'Donnell	1
Anemone Ratner		1
Carl Jackson		1
Jenna Caffey		1
Jocasta Rupert		1
Lela Donovan		1
Mitch Gastineau		1
Patricia Hirasaki	1
Ricardo Emerson		1
Roland Murray		1
Susan MacKendrick	1
Theresa Coyne		1
*/

-- 4. Which Customers Have Above-Average Sales?
WITH customer_sales AS
(
    SELECT
        customer_id,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    cs.total_sales
FROM customer_sales cs
JOIN customers c
    ON cs.customer_id = c.customer_id
WHERE cs.total_sales >
(
    SELECT AVG(total_sales)
    FROM customer_sales
);

/*
Brosina Hoffman	6255.34
Irene Maddox	4930.49
Pete Kriz		8158.65
....(More rows)
*/

-- 5. What is the Highest Order Value Per Customer?
SELECT
    c.customer_name,
    MAX(o.sales) AS highest_order_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY highest_order_value DESC;
/*
Sean Miller		22638.48
Tamara Chand	17499.95
Raymond Buch	13999.96
*/

