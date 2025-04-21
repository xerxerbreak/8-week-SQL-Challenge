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
## Answer:
| customer_id | total_amount_spent |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

***

2. How many days has each customer visited the restaurant?
````
SELECT customer_id, count(DISTINCT(order_date)) total_visits
FROM sales
GROUP BY customer_id
ORDER BY customer_id;
````
## Answer:
| customer_id | total_visits |
| ----------- | ----------- |
| A           | 4          |
| B           | 6          |
| C           | 2          |

***

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
#### Answer:
| customer_id | product_name | 
| ----------- | ----------- |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

  ***
  
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
````
SELECT m.product_name, count(s.product_id) as most_purchased_item
FROM sales s JOIN menu m on s.product_ID = m.product_id
GROUP BY m.product_name
ORDER BY most_purchased_item desc
LIMIT 1;
````

#### Answer:
| product_name | most_purchased_item | 
| ----------- | ----------- |
|ramen           |8       |

  ***
  
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

#### Answer:
| customer_id | product_name | order_count |
| ----------- | ---------- |------------  |
| A           | ramen        |  3   |
| B           | sushi        |  2   |
| B           | curry        |  2   |
| B           | ramen        |  2   |
| C           | ramen        |  3   |

***

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

#### Answer:
| customer_id | join_date | order_date | product_name |
| ----------- | ---------- | ---------- | ---------- |
| A           | 2021-01-07 | 2021-01-10| ramen        |
| B           | 2021-01-09 | 2021-01-11| sushi        |

***

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

#### Answer:
| customer_id | join_date | order_date | product_name |
| ----------- | ---------- | ---------- | ---------- |
| A           | 2021-01-07 | 2021-01-01| sushi        |
| B           | 2021-01-09 | 2021-01-04| sushi        |

***

8. What is the total items and amount spent for each member before they became a member?
````
SELECT s.customer_id, sum(me.price) as total_spent, count(s.product_id) as total_items
FROM sales s 
JOIN menu me ON s.product_id = me.product_id
JOIN members m ON s.customer_id = m.customer_Id AND s.order_date < m.join_date
GROUP BY s.customer_Id
ORDER BY s.customer_Id;
````
#### Answer:
| customer_id | total_spent | total_items |
| ----------- | ---------- |----------  |
| A           | 25 |  2       |
| B           | 40 |  3       |

***

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

#### Answer:
| customer_id | total_points |
| ----------- | ---------- |
| A           | 860 |
| B           | 940 |
| C           | 360 |

***

10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
````
SELECT s.customer_id, sum(me.price) as total_spent, count(s.product_id) as total_items
FROM sales s 
JOIN menu me ON s.product_id = me.product_id
JOIN members m ON s.customer_id = m.customer_Id AND s.order_date < m.join_date
GROUP BY s.customer_Id
ORDER BY s.customer_Id;
````

#### Answer:
| customer_id | total_points |
| ----------- | ---------- |
| A           | 1370 |
| B           | 820 |

***

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

#### Answer: 
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

***

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

#### Answer: 
| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL

***
