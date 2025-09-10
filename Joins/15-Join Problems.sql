-- Easy Problems
-- List all employees and their department names. Include employees even if they haven't been assigned a department.

SELECT
	e.first_name,
	e.last_name,
	d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id=d.department_id;

-- List all departments, even if they have no employees.

SELECT
	d.department_name,
	COUNT(e.employee_id) as total_employees
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name;

--Find all employees who are working on any project.

SELECT
	distinct e.first_name,
	e.last_name,
	p.project_name
FROM employees e
JOIN employee_projects ep ON e.employee_id=ep.employee_id
JOIN projects p ON ep.project_id=p.project_id;

-- List every possible combination of employee and project.

SELECT e.first_name, e.last_name, p.project_name
FROM employees e
CROSS JOIN projects p;

-- Find employees and their managers.

SELECT 
	e.first_name || ' ' || e.last_name AS employee_name,
	m.first_name || ' ' || m.last_name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id=m.employee_id;

-- Medium Problems
-- Calculate the total budget allocated to each department. (Hint: You need to connect projects to departments via employees and employee_projects).
SELECT
	d.department_name,
	SUM(p.budget * (ep.hours_logged / total_hours.total_project_hours)) as estimated_budget_share
FROM departments d
JOIN employees e ON d.department_id=e.department_id
JOIN employee_projects ep ON e.employee_id=ep.employee_id
JOIN projects p ON ep.project_id=p.project_id
JOIN (
	SELECT project_id, SUM(hours_logged) AS total_project_hours
	FROM employee_projects
	GROUP BY project_id
) total_hours ON p.project_id = total_hours.project_id
GROUP BY d.department_name
ORDER BY estimated_budget_share DESC;



-- Find the total number of hours logged per project. Show the project name and total hours, only for projects with more than 100 total hours.
SELECT
	p.project_name,
	SUM(ep.hours_logged) as total_hours
FROM projects p
JOIN employee_projects ep ON p.project_id=ep.project_id
GROUP BY p.project_name
HAVING SUM(ep.hours_logged) > 100;

-- List all employees who are not assigned to any project.

SELECT 
	e.first_name,
	e.last_name,
	ep.project_id
FROM employees e
LEFT JOIN employee_projects ep ON e.employee_id=ep.employee_id
WHERE ep.project_id IS NULL;

-- Find the average salary of employees in each department, but only include departments where the average salary is greater than 70,000.

SELECT
	d.department_name,
	ROUND(AVG(e.salary),2) AS avg_salary
FROM employees e 
JOIN departments d ON e.department_id=d.department_id
GROUP BY d.department_name
HAVING AVG(e.salary) > 70000;

-- Who is the employee with the highest total hours logged on projects? Show their name and the total hours.

SELECT
	e.first_name,
	e.last_name,
	SUM(ep.hours_logged) AS total_hours
FROM employees e
JOIN employee_projects ep ON e.employee_id=ep.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_hours DESC
LIMIT 1;

-- Difficult Problems
-- Rank employees within their department based on their salary. Use a window function to show the rank (e.g., 1, 2, 3) next to each employee.

SELECT
	d.department_name,
	e.first_name || ' ' || e.last_name AS employees_name,
	e.salary,
	RANK() OVER(PARTITION BY d.department_id ORDER BY e.salary DESC) AS RN
FROM employees e
JOIN departments d ON e.department_id=d.department_id;

-- Find all employees who are managers.

SELECT
	DISTINCT m.first_name || ' ' || m.last_name AS manager_name
FROM employees m
JOIN employees e ON m.employee_id = e.manager_id;

-- Generate a report showing each department, its total headcount, and its total salary expenditure.

SELECT 
	d.department_name,
	COUNT(e.employee_id) AS head_count,
	COALESCE(SUM(e.salary), 0) AS total_salary
FROM employees e
JOIN departments d ON e.department_id=d.department_id
GROUP BY d.department_name
ORDER BY total_salary DESC;

-- List all projects that are over budget. Assume the cost of a project is $150 * total_hours_logged.

SELECT
	p.project_name,
	p.budget,
	(150 * SUM(hours_logged)) as estimated_cost
FROM projects p
JOIN employee_projects ep ON p.project_id=ep.project_id
GROUP BY p.project_name, p.project_id, p.budget
HAVING ROUND(150 * SUM(hours_logged), 2) > p.budget;

-- Find the "most expensive" employee. Consider their salary plus the cost of the projects they work on 
-- (using the same $150 * hours_logged rate for their assigned projects).

WITH employee_costs AS(
	SELECT
		e.employee_id,
		e.first_name,
		e.last_name,
		e.salary,
		COALESCE(SUM(150 * ep.hours_logged), 0) AS project_costs
	FROM employees e
	LEFT JOIN employee_projects ep ON e.employee_id=ep.employee_id
	GROUP BY e.employee_id, e.first_name, e.last_name, e.salary
)
SELECT
	first_name,
	last_name,
	(salary + project_costs) as total_cost
FROM employee_costs
ORDER BY total_cost DESC
;


-- Sample Datasets I used.
-- Let's create three common, related tables found in almost every business: employees, departments, and projects.

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

INSERT INTO departments (department_name) VALUES
('Engineering'),
('Sales'),
('Marketing'),
('HR');

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    salary NUMERIC(10, 2),
    department_id INTEGER REFERENCES departments(department_id),
    manager_id INTEGER REFERENCES employees(employee_id) -- Self-referencing key for hierarchy
);

INSERT INTO employees (first_name, last_name, email, salary, department_id, manager_id) VALUES
('Alice', 'Smith', 'alice.smith@company.com', 90000, 1, NULL), -- Engineering, no manager (head of dept)
('Bob', 'Johnson', 'bob.johnson@company.com', 80000, 1, 1),
('Charlie', 'Williams', 'charlie.williams@company.com', 70000, 2, NULL), -- Sales, no manager
('David', 'Brown', 'david.brown@company.com', 65000, 2, 3),
('Eva', 'Jones', 'eva.jones@company.com', 75000, 3, NULL), -- Marketing, no manager
('Frank', 'Garcia', 'frank.garcia@company.com', 60000, 1, 2),
('Grace', 'Miller', 'grace.miller@company.com', 95000, 4, NULL); -- HR, no manager

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget NUMERIC(12, 2),
    start_date DATE,
    end_date DATE
);

CREATE TABLE employee_projects ( -- Junction table for Many-to-Many relationship
    employee_id INTEGER REFERENCES employees(employee_id),
    project_id INTEGER REFERENCES projects(project_id),
    hours_logged NUMERIC(5, 2) DEFAULT 0,
    PRIMARY KEY (employee_id, project_id)
);

INSERT INTO projects (project_name, budget, start_date, end_date) VALUES
('Build New API', 50000, '2023-01-15', '2023-06-30'),
('Website Redesign', 75000, '2023-02-01', NULL), -- Ongoing project
('Q3 Sales Campaign', 25000, '2023-07-01', '2023-09-30');

INSERT INTO employee_projects (employee_id, project_id, hours_logged) VALUES
(2, 1, 120.5), -- Bob on Build New API
(6, 1, 180.0), -- Frank on Build New API
(2, 2, 45.75), -- Bob also on Website Redesign
(4, 3, 110.00), -- David on Q3 Sales Campaign
(5, 2, 95.50); -- Eva on Website Redesign










