
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner; --WHENEVER YOU START UP PGADMIN BE SURE TO EXECUTE THIS LINE TO LET THE CODE KNOWS

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT * FROM menu; -- product_id, product_name,price
SELECT * FROM members; --customer_id, join_date
SELECT * FROM sales; --customer_id,order_date,product_id

--1.What is the total amount each customer spent at the restaurant?
SELECT s.customer_id,sum(m.price) total_amount_spent
FROM sales s JOIN menu m on m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id ASC;

--2.How many days has each customer visited the restaurant?
SELECT customer_id, count(DISTINCT(order_date)) total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

--3.What was the first item from the menu purchased by each customer?
SELECT s.customer_id,m.product_name
FROM sales s JOIN menu m on m.product_id = s.product_id
WHERE s.order_date = (SELECT MIN(order_date) FROM sales s2 WHERE s2.customer_id = s.customer_id)--could do subquery in where

--ANOTHER ANSWER BY USING CTE (line 77-84 is the CTE)
WITH ranked_orders AS (
  SELECT s.customer_id,m.product_name,
      DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
  FROM sales s
  JOIN menu m ON m.product_id = s.product_id
)
SELECT customer_id, product_name
FROM ranked_orders
WHERE rank = 1
GROUP BY customer_Id,product_name;

--4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, count(s.product_id) as most_purchased_item
FROM sales s JOIN menu m on s.product_ID = m.product_id
GROUP BY m.product_name
ORDER BY most_purchased_item desc
LIMIT 1;

--5.Which item was the most popular for each customer?
--this is a basic grouping of it but i want to make it so that it shows most popular one per customer rather then all products per customer
SELECT s.customer_id,m.product_name,count(s.product_id) AS order_count
FROM sales s JOIN menu m on s.product_ID = m.product_id
GROUP BY s.customer_id,m.product_name
ORDER BY s.customer_id,order_count DESC;

--Actual answer for 5
WITH most_popular AS (
	SELECT s.customer_id,m.product_name,COUNT(*) AS order_count,
	DENSE_RANK() OVER(
	PARTITION BY s.customer_id 
	ORDER BY count(*) DESC) AS rank
FROM sales s
JOIN menu m ON m.product_id = s.product_id
GROUP BY s.customer_id,m.product_name
)
SELECT customer_id,product_name,order_count
FROM most_popular
WHERE rank = 1;

--6.Which item was purchased first by the customer after they became a member?
--basic filtering
SELECT s.customer_id, m.join_date,s.order_date
FROM sales s join members m on s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date;

--ACTUAL ANSWER CTE
WITH first_purchase AS (
	SELECT s.customer_id, m.join_date,s.order_date,s.product_id,
	ROW_NUMBER() OVER(PARTITION BY s.customer_id
	ORDER BY s.order_date )AS rank
FROM sales s
JOIN members m ON s.customer_id = m.customer_id AND order_date > join_date
)
SELECT customer_id, join_date,order_date,product_name
FROM first_purchase
JOIN menu ON first_purchase.product_id = menu.product_id
WHERE rank = 1
ORDER BY customer_id;

--7.Which item was purchased just before the customer became a member?
--basic filtering
SELECT s.customer_id, m.join_date,s.order_date
FROM sales s join members m on s.customer_id = m.customer_id
WHERE s.order_date < m.join_date;

--ACTUAL ANSWER CTE
WITH first_purchase AS (
	SELECT s.customer_id, m.join_date,s.order_date,s.product_id,
	ROW_NUMBER() OVER(PARTITION BY s.customer_id
	ORDER BY s.order_date DESC)AS rank
FROM sales s
JOIN members m ON s.customer_id = m.customer_id AND order_date < join_date
)
SELECT customer_id, join_date,order_date,product_name
FROM first_purchase
JOIN menu ON first_purchase.product_id = menu.product_id
WHERE rank = 1
ORDER BY customer_id;

--8.What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, sum(me.price) as total_spent, count(s.product_id) as total_items
FROM sales s 
JOIN menu me ON s.product_id = me.product_id
JOIN members m ON s.customer_id = m.customer_Id AND s.order_date < m.join_date
GROUP BY s.customer_Id
ORDER BY s.customer_Id;

--9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_Id, sum(CASE WHEN me.product_id = 1 THEN me.price * 20 ELSE me.price *10 END) as total_points
FROM sales s
JOIN menu me ON s.product_id = me.product_id
GROUP BY s.customer_Id
ORDER BY s.customer_Id;

--CTE VERISON
WITH points_cte AS (
SELECT me.product_id,
CASE
	WHEN product_id = 1 THEN price * 20
	ELSE price * 10 END AS points
	FROM menu me
)

SELECT s.customer_Id,
SUM(points_cte.points) AS total_points
FROM sales s
JOIN points_cte ON s.product_Id = points_cte.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_Id, sum(CASE 
WHEN s.order_date BETWEEN m.join_date AND join_date + INTERVAL '6 days' THEN me.price * 20
WHEN me.product_id = 1 THEN me.price * 20 ELSE me.price * 10 END) as total_points
FROM sales s
JOIN menu me ON s.product_id = me.product_id
JOIN members m ON s.customer_id = m.customer_Id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_Id
ORDER BY s.customer_Id;

--CTE VERISON
WITH dates_cte AS (
  SELECT customer_id, join_date, join_date + INTERVAL '6 days' AS end_of_first_week
  FROM members
)

SELECT 
  s.customer_id, 
  SUM(
    CASE
      WHEN s.order_date BETWEEN d.join_date AND d.end_of_first_week THEN me.price * 20
      WHEN me.product_id = 1 THEN me.price * 20
      ELSE me.price * 10
    END
  ) AS total_points
FROM sales s
JOIN dates_cte d ON s.customer_id = d.customer_id
JOIN menu me ON s.product_id = me.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY s.customer_id;

--Bonus Question Join All The Things
SELECT s.customer_id,s.order_date,me.product_name,me.price, CASE 
WHEN m.customer_id = s.customer_id and s.order_date >= m.join_date THEN 'Y' ELSE 'N' END AS member

FROM sales s
LEFT JOIN menu me ON s.product_id = me.product_id
LEFT JOIN members m ON m.customer_id = s.customer_id
ORDER BY s.customer_id,member

--Bonus Question Rank All The Things
SELECT s.customer_id,s.order_date,me.product_name,me.price, CASE 
WHEN m.customer_id = s.customer_id and s.order_date >= m.join_date THEN 'Y' ELSE 'N' END AS member

FROM sales s
LEFT JOIN menu me ON s.product_id = me.product_id
LEFT JOIN members m ON m.customer_id = s.customer_id
ORDER BY s.customer_id,member
