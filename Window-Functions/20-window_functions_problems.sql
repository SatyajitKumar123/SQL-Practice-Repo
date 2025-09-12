select * from customers;
select * from orders;
select * from order_items;
select * from products;

-- 1. Customer Spending Rank: Rank customers based on their total lifetime spending (total_amount from orders). 
-- Use RANK(). Show customer name and rank.

SELECT
	c.customer_name,
	SUM(o.total_amount) as total_spending,
	RANK() OVER(ORDER BY SUM(o.total_amount) DESC) 
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
GROUP BY c.customer_name;

-- 2. Dense City Rank: Use DENSE_RANK() to rank cities based on the number of customers signed up in each. Show city and rank.

SELECT
	city,
	COUNT(signup_date) AS total_customers,
	DENSE_RANK() OVER(ORDER BY COUNT(signup_date) DESC)
FROM customers
GROUP BY city;

-- 3. Monthly Top Spender: For each month in 2023, rank customers based on their total spending in that month. Show month,
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

-- 4. Product Popularity Contest: Rank products based on the total quantity sold. Use DENSE_RANK() to handle ties appropriately.
select * from order_items;
select * from products;

SELECT
	p.product_name,
	SUM(oi.quantity) AS total_quantity_sold,
	DENSE_RANK() OVER(ORDER BY SUM(oi.quantity) DESC)
FROM products p
JOIN order_items oi ON p.product_id=oi.product_id
GROUP BY p.product_name;

-- 5. First Order Rank: For each customer, find the date of their first order. 
-- Then, rank customers based on how early their first order was (the earliest gets rank 1).

select * from orders;

SELECT
	c.customer_name,
	MIN(o.order_date) as early_order,
	RANK() OVER(ORDER BY MIN(o.order_date))
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
GROUP BY c.customer_name;



-- 6. Next Order Date: For each order a customer makes, show the date of their next order. Include customer name, 
-- current order date, and next order date.

SELECT
	c.customer_name,
	o.order_date,
	LEAD(o.order_date) OVER(PARTITION BY c.customer_name ORDER BY o.order_date) AS next_order_date
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id;

-- 7. Spending Growth: For each customer, show their total spending for each month. 
-- Calculate the month-over-month growth percentage in their spending.

WITH monthly_customer_spending AS(
	SELECT
		customer_id,
		DATE_TRUNC('month', order_date) AS month,
		SUM(total_amount) AS total_spent
	FROM orders
	GROUP BY customer_id, month
)
SELECT
	c.customer_name,
	TO_CHAR(mcs.month, 'YYYY-MM') AS month,
	mcs.total_spent,
	LAG(total_spent) OVER(PARTITION BY mcs.customer_id ORDER BY mcs.month) AS prev_month_spent,
	ROUND(
		((mcs.total_spent - LAG(total_spent) OVER(PARTITION BY mcs.customer_id ORDER BY mcs.month))
		/ LAG(total_spent) OVER(PARTITION BY mcs.customer_id ORDER BY mcs.month)) * 100, 2
	) || '%' AS growth_percentage
FROM monthly_customer_spending mcs
JOIN customers c ON mcs.customer_id=c.customer_id;

-- 8. Compare to Previous Order: For each order, show how much larger or smaller it is compared to the customer's previous order amount. 
-- Handle the first order for a customer by showing 0 difference.

WITH customer_order_sequence AS(
	SELECT
		customer_id,
		order_date,
		total_amount,
		LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_amount
	FROM orders
)
SELECT
	c.customer_name,
	cos.order_date,
	cos.total_amount,
	cos.prev_order_amount,
	COALESCE(cos.total_amount - cos.prev_order_amount, 0) AS difference_from_previous
FROM customer_order_sequence cos
JOIN customers c ON cos.customer_id=c.customer_id;

-- 9. Days Between Orders: Calculate the average number of days between consecutive orders for each customer.

WITH order_gaps AS(
	SELECT
		customer_id,
		order_date,
		order_date - LAG(order_date) OVER(PARTITION BY customer_id ORDER BY order_date) AS days_since_last_order
	FROM orders
)
SELECT
	c.customer_name,
	ROUND(AVG(og.days_since_last_order), 2) AS avg_days_between_orders
FROM order_gaps og
JOIN customers c ON og.customer_id=c.customer_id
WHERE og.days_since_last_order IS NOT NULL
GROUP BY c.customer_id;

-- 10. First and Last Purchase: For each customer, show their first and most recent order date in a single row

SELECT
	c.customer_name,
	MIN(o.order_date) AS first_order_date,
	MAX(o.order_date) AS last_order_date
FROM customers c
JOIN orders o ON c.customer_id=o.customer_id
GROUP BY c.customer_id;

-- Alternative using FIRST_VALUE/LAST_VALUE (less efficient for this, but demonstrates the function)
SELECT
	c.customer_name,
	FIRST_VALUE(o.order_date) OVER(PARTITION BY o.customer_id ORDER BY o.order_date) AS first_order_date,
	FIRST_VALUE(o.order_date) OVER(PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS last_order_date
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id;
