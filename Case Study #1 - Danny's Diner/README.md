# Case Study #1: Danny's Diner 
<img src="https://user-images.githubusercontent.com/81607668/127727503-9d9e7a25-93cb-4f95-8bd0-20b87cb4b459.png" alt="Image" width="500" height="520">

## Table of Contents
- [Business Task](#business-task)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

All information regarding this case study has been sourced from: [here](https://8weeksqlchallenge.com/case-study-1/). 

***

## Business Task
Danny is looking to better understand his customers by analyzing data on their visit patterns, total spending, and favorite menu items.

***

## Entity Relationship Diagram

![image](https://user-images.githubusercontent.com/81607668/127271130-dca9aedd-4ca9-4ed8-b6ec-1e1920dca4a8.png)


***

## Questions and Solutions
1. What is the total amount each customer spent at the restaurant?
````
SELECT s.customer_id,sum(m.price) total_amount_spent
FROM sales s JOIN menu m on m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id ASC;
````
2. How many days has each customer visited the restaurant?
````
SELECT customer_id, count(DISTINCT(order_date)) total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id;
````
3. What was the first item from the menu purchased by each customer?
````
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
````
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
````
SELECT m.product_name, count(s.product_id) as most_purchased_item
FROM sales s JOIN menu m on s.product_ID = m.product_id
GROUP BY m.product_name
ORDER BY most_purchased_item desc
LIMIT 1;
````
5. Which item was the most popular for each customer?
````
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
````
6. Which item was purchased first by the customer after they became a member?
````
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
````
7. Which item was purchased just before the customer became a member?
````
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
````
8. What is the total items and amount spent for each member before they became a member?
````
SELECT s.customer_id, sum(me.price) as total_spent, count(s.product_id) as total_items
FROM sales s 
JOIN menu me ON s.product_id = me.product_id
JOIN members m ON s.customer_id = m.customer_Id AND s.order_date < m.join_date
GROUP BY s.customer_Id
ORDER BY s.customer_Id;
````
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
````
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
````
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
````
SELECT s.customer_id, sum(me.price) as total_spent, count(s.product_id) as total_items
FROM sales s 
JOIN menu me ON s.product_id = me.product_id
JOIN members m ON s.customer_id = m.customer_Id AND s.order_date < m.join_date
GROUP BY s.customer_Id
ORDER BY s.customer_Id;
````
## BONUS QUESTIONS
1. Join All The Things
Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
````
SELECT s.customer_id,s.order_date,me.product_name,me.price, 
CASE 
	WHEN s.order_date >= m.join_date THEN 'Y' ELSE 'N' END AS member
FROM sales s
LEFT JOIN menu me ON s.product_id = me.product_id
LEFT JOIN members m ON m.customer_id = s.customer_id
ORDER BY s.customer_id,member
````
2. Rank All The Things
Danny also requires further information about the ```ranking``` of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ```ranking``` values for the records when customers are not yet part of the loyalty program.
````
WITH member_cte AS (
SELECT s.customer_id,s.order_date,me.product_name,me.price, 
CASE 
	WHEN s.order_date >= m.join_date THEN 'Y' ELSE 'N' END AS member
FROM sales s
LEFT JOIN menu me ON s.product_id = me.product_id
LEFT JOIN members m ON m.customer_id = s.customer_id
)
SELECT *,
CASE 
	WHEN member = 'N' THEN NULL
	ELSE RANK() OVER(Partition BY customer_id,member ORDER BY order_date
	)END AS ranking
FROM member_cte
````
