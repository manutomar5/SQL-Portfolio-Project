drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--Q1. What is the total amount each customer spent on Zomato?

SELECT s.userid,SUM(p.price) AS total_amount_spent
FROM sales s
INNER JOIN product p
ON s.product_id = p.product_id
GROUP BY s.userid

--Q2. How many days has each customer visited Zomato?

SELECT s.userid, COUNT(DISTINCT s.created_date) AS distinct_days
FROM sales s
GROUP BY s.userid

--Q3. What was the first product purchased by each customer?

SELECT * FROM
(SELECT *, RANK() OVER (PARTITION BY userid ORDER BY created_date) rnk 
FROM sales) A
WHERE rnk=1

--Q4. What was the most purchased item on the menu and how many times was it purchased by all customers?

SELECT userid, COUNT(product_id) cnt
FROM sales 
WHERE product_id =
(SELECT TOP 1 product_id
FROM SALES
GROUP BY product_id
ORDER BY COUNT(product_id) desc)
GROUP BY userid

--Q5. Which item was the most popular for each customer?

SELECT * FROM
(SELECT *, RANK() OVER(PARTITION BY userid order by cnt desc) rnk FROM
(SELECT userid,product_id,COUNT(product_id) cnt FROM sales GROUP BY userid,product_id) a) b
WHERE rnk = 1;

--Q6. Which item was purchased first by the cusomer after they became a member?

SELECT * FROM
(SELECT c.*,RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date FROM sales a INNER JOIN
goldusers_signup b ON a.userid=b.userid and created_date>=gold_signup_date) c)d WHERE rnk=1;

--Q7. Which item was purchased just before the customer became a member?

SELECT * FROM
(SELECT c.*,RANK() OVER(PARTITION BY userid ORDER BY created_date desc) rnk FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date FROM sales a INNER JOIN
goldusers_signup b ON a.userid=b.userid and created_date<=gold_signup_date) c)d WHERE rnk=1;

--Q8. What is the total orders and amount spent for each member before they became a member?

SELECT userid, COUNT(created_date) number_of_order_purchased, SUM(price) total_amount_spent FROM
(SELECT c.*, p.price FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date FROM sales a INNER JOIN
goldusers_signup b ON a.userid=b.userid and created_date<=gold_signup_date)c INNER JOIN 
product p ON c.product_id = p.product_id)d
GROUP BY userid;

--Q9. If buying each product generated points for eg 5rs-2 Zomato points and each product has different 
--    purchasing points for eg for p1 5rs-1 Zomato point, for p2 10rs-5 Zomato points and p3 5rs-1 Zomato
--	  point, Calculate points collected by each customer and for which product most points have been given
--	  till now?

SELECT userid, SUM(total_points) total_points_earned FROM
(SELECT e.*, total_amount_spent/amount_per_point AS total_points  FROM
(SELECT d.*, CASE WHEN product_id=1 THEN 5
				 WHEN product_id=2 THEN 2
				 WHEN product_id=3 THEN 5 ELSE 0 END AS amount_per_point FROM
(SELECT c.userid, c.product_id, SUM(price) total_amount_spent FROM
(SELECT a.*, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id)c
GROUP BY userid, product_id)d) e) f GROUP BY userid;

SELECT * FROM
(SELECT g.*, RANK() OVER( ORDER BY points_per_product desc) rnk FROM
(SELECT product_id, SUM(total_points) AS points_per_product FROM
(SELECT e.*, total_amount_spent/amount_per_point AS total_points  FROM
(SELECT d.*, CASE WHEN product_id=1 THEN 5
				 WHEN product_id=2 THEN 2
				 WHEN product_id=3 THEN 5 ELSE 0 END AS amount_per_point FROM
(SELECT c.userid, c.product_id, SUM(price) total_amount_spent FROM
(SELECT a.*, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id)c
GROUP BY userid, product_id)d) e) f GROUP BY product_id) g) h
WHERE rnk=1;

--Q10.In the first one year after a customer joins the Gold program (including their join date)
--    irrespective of what the customer has purchased they earn 5 Zomato points for every 10rs spent.
--	  Who earned more 1 or 3 and what was their points earnings in their first year?

SELECT c.*, d.price, d.price*0.5 total_points_earned FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date FROM sales a INNER JOIN
goldusers_signup b ON a.userid=b.userid and created_date>=gold_signup_date 
AND created_date<=DATEADD(year, 1, gold_signup_date))c
INNER JOIN product d ON c.product_id= d.product_id;


--Q11. Rank all the transactions of the customers

SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk FROM sales

--Q12. Rank all the transaction for each member when they are a Zomato gold member, for every non gold
--     member transaction mark as na

SELECT d.*, CASE WHEN rnk=0 then 'NA' ELSE rnk END AS rnkk FROM
(SELECT c.*,CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE RANK() OVER(PARTITION BY userid ORDER BY created_date DESC)END) AS varchar) AS rnk FROM
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date FROM sales a LEFT JOIN
goldusers_signup b ON a.userid=b.userid and created_date>=gold_signup_date) c)d;