select * from customers;
select * from orders;
select * from order_items;
select * from products;

-- Customer Spending Rank: Rank customers based on their total lifetime spending (total_amount from orders). 
-- Use RANK(). Show customer name and rank.

SELECT
	c.customer_name,
	SUM(o.total_amount) as total_spending,
	RANK() OVER(ORDER BY SUM(o.total_amount) DESC) 
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
GROUP BY c.customer_name;

-- Dense City Rank: Use DENSE_RANK() to rank cities based on the number of customers signed up in each. Show city and rank.

SELECT
	city,
	COUNT(signup_date) AS total_customers,
	DENSE_RANK() OVER(ORDER BY COUNT(signup_date) DESC)
FROM customers
GROUP BY city;

-- Monthly Top Spender: For each month in 2023, rank customers based on their total spending in that month. Show month,
-- customer name, total spent, and rank.

WITH monthly_total AS(
	SELECT
		DATE_TRUNC('month', o.order_date) AS order_month,
		c.customer_name,
		SUM(o.total_amount) as monthly_total
	FROM orders o
	JOIN customers c ON o.customer_id=c.customer_id
	WHERE EXTRACT(YEAR FROM o.order_date) = 2023
	GROUP BY order_month, c.customer_name
)
SELECT TO_CHAR(order_month, 'YYYY-MM') AS month,
	customer_name,
	monthly_total,
	RANK() OVER (PARTITION BY order_month ORDER BY monthly_total DESC)
FROM monthly_total;

-- Product Popularity Contest: Rank products based on the total quantity sold. Use DENSE_RANK() to handle ties appropriately.
select * from order_items;
select * from products;

SELECT
	p.product_name,
	SUM(oi.quantity) AS total_quantity_sold,
	DENSE_RANK() OVER(ORDER BY SUM(oi.quantity) DESC)
FROM products p
JOIN order_items oi ON p.product_id=oi.product_id
GROUP BY p.product_name;

-- First Order Rank: For each customer, find the date of their first order. 
-- Then, rank customers based on how early their first order was (the earliest gets rank 1).

select * from orders;

SELECT
	c.customer_name,
	MIN(o.order_date) as early_order,
	RANK() OVER(ORDER BY MIN(o.order_date))
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
GROUP BY c.customer_name;
