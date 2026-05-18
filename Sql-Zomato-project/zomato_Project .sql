CREATE DATABASE zomato;

USE zomato;


drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


SELECT * FROM goldusers_signup;

SELECT * FROM product;

SELECT * FROM sales;

SELECT * FROM users;



-- 1.what is the total amount each customer spent on zomato 

SELECT 
a.userid,
SUM(b.price) AS amount_spent
FROM sales a
INNER JOIN product b
ON a.product_id=b.product_id
GROUP BY a.userid;



-- 2.how many days each customer visited zomato

SELECT 
userid,
COUNT(distinct created_date ) AS no_of_days
FROM sales 
GROUP BY userid;


-- 3.what was the first product purchased by each customer

SELECT userid,product_id
FROM(
SELECT *,
RANK() over(partition by userid OrdER bY created_date ) as rn
FROM sales) a 
WHERE rn =1;


-- 4.what was the most purchased item and how many times was it purchased by each customer

SELECT userid, count(*) AS cnt FROM sales 
WHERE product_id =(SELECT product_id
FROM sales
GROUP BY product_id
ORDER BY count(product_id) DESC
LIMIT 1)
GROUP BY userid;



-- 5. what was the most favourite product for each customer 

SELECT * from (
SELECT *,RANK() over(partition by userid order by cnt DESC) AS rnk
 FROM(
SELECT userid,product_id,count(*) AS cnt
FROM sales 
GROUP BY userid,product_id) a) b 
WHERE rnk = 1;


-- 6.which item was purchased by each customer after they become member 


WITH CTE AS (
SELECT 
a.userid,
b.product_id,
b.created_date,
a.gold_signup_date,
ROW_NUMBER() OVER(partition by a.userid ORDER BY b.created_date) AS rnk
FROM goldusers_signup a
INNER JOIN sales b
ON a.userid = b.userid
WHERE b.created_date >= a.gold_signup_date
)
SELECT * FROM CTE
WHERE rnk = 1;


-- 7.which item has purchased just become member 


WITH CTE AS (
SELECT 
a.userid,
b.product_id,
b.created_date,
a.gold_signup_date,
ROW_NUMBER() OVER(partition by a.userid ORDER BY b.created_date DESC) AS rnk
FROM goldusers_signup a
INNER JOIN sales b
ON a.userid = b.userid
WHERE b.created_date <= a.gold_signup_date
)
SELECT * FROM CTE
WHERE rnk = 1;



-- 8. what is the total orders and amount spent for each member before they become a member


SELECT 
a.userid,
COUNT(b.created_date) AS total_orders,
SUM(c.price)  AS total_spent 
FROM goldusers_signup a
INNER JOIN sales b
ON a.userid=b.userid
INNER JOIN product c
ON b.product_id = c.product_id

WHERE b.created_date <= a.gold_signup_date
GROUP BY a.userid;



-- 9.If buying each product generates points for eg 5rs-2 zomato point and each product has different purchasing points 
-- for eg for p1 5rs 1 zomato point, for pa 1ers szomato point and p3 5rs-1 zomato point I

-- calculate how many points collected by each customer and for which product most points have been given till now 


SELECT userid,points*2.5 AS cashback
FROM 
(SELECT
	s.userid,
	ROUND(SUM(CASE
		WHEN s.product_id =1 THEN p.price / 5
		WHEN s.product_id =2 THEN p.price / 2
        WHEN s.product_id =3 THEN p.price / 5
	END),0) AS points
FROM sales s
INNER JOIN product p 
ON s.product_id = p.product_id
GROUP BY s.userid) d;
        


SELECT
	s.product_id,
	ROUND(SUM(CASE
		WHEN s.product_id =1 THEN p.price / 5
		WHEN s.product_id =2 THEN p.price / 2
        WHEN s.product_id =3 THEN p.price / 5
	END),0) AS points
FROM sales s
INNER JOIN product p 
ON s.product_id = p.product_id
GROUP BY s.product_id
ORDER BY points DESC
LIMIT 1;



-- 10 In the first one year after a customer joins the gold program (including their join date) irrespective of 
-- what the customer has purchased they earn 5 zomato points for every 10 rs spent who earned more  1 or 3
-- and what was their points earnings in thier first yr?


SELECT 
    g.userid,
    SUM(p.price) AS total_spent,
    SUM(p.price) * 0.5 AS points_earned
FROM goldusers_signup g
INNER JOIN sales s
    ON g.userid = s.userid
INNER JOIN product p
    ON s.product_id = p.product_id
WHERE s.created_date 
BETWEEN g.gold_signup_date
AND DATE_ADD(g.gold_signup_date, INTERVAL 1 YEAR)
GROUP BY g.userid
ORDER BY SUM(p.price) * 0.5  DESC
LIMIT 1;


-- 11 rank all the transactions of each customer whenever they are a zomato gold member for every non gold member transaction mark 




SELECT f.*,
CASE 
WHEN f.gold_signup_date is NULL THEN 'NA'
ELSE
 CAST(RANK() over(partition by userid ORDER BY  f.created_date DESC) AS CHAR ) END AS rnk
 
FROM 

(SELECT s.userid,s.created_date,s.product_id,g.gold_signup_date 
FROM sales s 
LEFT JOIN goldusers_signup  g
ON s.userid = g.userid AND s.created_date >= g.gold_signup_date ) f;



