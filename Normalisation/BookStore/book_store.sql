-- 1. Create the Customers table (3NF)

CREATE TABLE customers(
	customer_id VARCHAR(3) PRIMARY KEY,
	customer_name VARCHAR(50) NOT NULL,
	customer_email VARCHAR(50) NOT NULL
);

-- 2. Create the Books table (3NF)

CREATE TABLE books(
	book_id VARCHAR(4) PRIMARY KEY,
	book_title VARCHAR(100) NOT NULL,
	price DECIMAL(10,2) NOT NULL
);

-- 3. Create the Orders table (3NF)
-- This table has a foreign key (FK) to Customers

CREATE TABLE orders(
	order_id INTEGER PRIMARY KEY,
	customer_id VARCHAR(3) NOT NULL,
	order_date DATE NOT NULL,
	CONSTRAINT fk_customer
		FOREIGN KEY (customer_id)
		REFERENCES customers(customer_id)
		ON DELETE CASCADE
);

-- 4. Create the Order_Items table (3NF)
-- This is a junction table with a composite PK and two FKs

CREATE TABLE order_items(
	order_id INT NOT NULL,
	book_id VARCHAR(4) NOT NULL,
	-- Define the composite primary key
	CONSTRAINT pk_order_items
		PRIMARY KEY (order_id, book_id),
	-- Define foreign key to the Orders table
	CONSTRAINT fk_order
		FOREIGN KEY (order_id)
		REFERENCES orders(order_id)
		ON DELETE CASCADE,
	-- Define foreign key to the Books table
	CONSTRAINT fk_book
		FOREIGN KEY (book_id)
		REFERENCES books(book_id)
		ON DELETE CASCADE
);

-- 1. Insert into Customers
INSERT INTO customers (customer_id, customer_name, customer_email)
VALUES
('C25', 'Alice Smith', 'alice.s@email.com'),
('C30', 'Bob Jones', 'bobjones@mail.com');

-- 2. Insert into Books
INSERT INTO books (book_id, book_title, price)
VALUES
('B101', 'The Alchemist', 15.99),
('B102', 'The Hobbit', 12.50),
('B105', 'Dune', 18.75),
('B110', '1984', 9.99),
('B125', 'The Great Gatsby', 14.95);

-- 3. Insert into Orders
INSERT INTO orders (order_id, customer_id, order_date)
VALUES
(101, 'C25', '2023-10-25'),
(102, 'C30', '2023-10-26'),
(103, 'C25', '2023-10-27');

-- 4. Insert into Order_Items
INSERT INTO order_items (order_id, book_id)
VALUES
(101, 'B101'),
(101, 'B102'),
(102, 'B105'),
(103, 'B110'),
(103, 'B125');

-- Let's run a query to reconstruct the original "flat" view and confirm everything is linked correctly.
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.customer_name,
    c.customer_email,
    b.book_id,
    b.book_title,
    b.price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN books b ON oi.book_id = b.book_id
ORDER BY o.order_id, b.book_id;



