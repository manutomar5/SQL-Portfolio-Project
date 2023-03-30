drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


--Q1. How many rolls were ordered?

SELECT COUNT(roll_id) FROM customer_orders;


--Q2.How many Unique customer orders were made?

SELECT COUNT(DISTINCT customer_id) FROM customer_orders;


--Q3.How many successful orders were delivered by each driver?

SELECT driver_id, COUNT(DISTINCT order_id) FROM driver_order WHERE cancellation NOT IN ('cancellation', 'customer cancellation')
GROUP BY driver_id;


--Q4.How many of each type of role was delivered?

SELECT roll_id, COUNT(roll_id) AS cnt FROM customer_orders WHERE order_id IN(
SELECT order_id FROM
(SELECT *, CASE WHEN cancellation IN ('cancellation', 'customer cancellation') THEN 'c' ELSE 'nc' END AS order_cancel_details
FROM driver_order)a WHERE order_cancel_details='nc') GROUP BY roll_id;


--Q5. How many veg and non-veg rolls were ordered by each of the customer?

SELECT a.*, b.roll_name FROM
(SELECT customer_id, roll_id, COUNT(roll_id)cnt FROM customer_orders
GROUP BY customer_id, roll_id)a INNER JOIN rolls b ON a.roll_id=b.roll_id;


--Q6. What was the maximum number of rolls delivered in a single order?

SELECT d.* FROM
(SELECT c.*, RANK() OVER(ORDER BY cnt DESC) rnk FROM
(SELECT order_id, COUNT(roll_id) cnt FROM
(SELECT * FROM customer_orders WHERE order_id IN(
SELECT order_id FROM
(SELECT *, CASE WHEN cancellation IN ('cancellation', 'customer cancellation') THEN 'c' ELSE 'nc' END AS order_cancel_details
FROM driver_order)a WHERE order_cancel_details='nc'))b
GROUP BY order_id)c)d WHERE rnk=1;

--Q7.For each customer, how many delivered rolls had atleast 1 change and how many had no change?

With temp_customer_orders(order_id,customer_id,roll_id,new_not_include_items,new_extra_items_included,order_date) AS
(
SELECT order_id,customer_id,roll_id,
CASE WHEN not_include_items IS NULL OR not_include_items=' ' THEN '0' ELSE not_include_items END AS new_not_include_items, 
CASE WHEN extra_items_included IS NULL OR extra_items_included=' ' OR extra_items_included='NaN' THEN '0' ELSE extra_items_included END AS new_extra_items_included, order_date FROM customer_orders
)
,

temp_driver_order(order_id,driver_id,pickup_time,distance,duration,new_cancellation) AS
(
SELECT order_id,driver_id,pickup_time,distance,duration,
CASE WHEN cancellation IN ('cancellation', 'customer cancellation') THEN 0 ELSE 1 END AS new_cancellation
FROM driver_order
)
SELECT customer_id,chg_no_chg,COUNT(chg_no_chg) cnt_chg_no_chg FROM
(
SELECT *, CASE WHEN new_not_include_items='0' AND new_extra_items_included='0' THEN 'no change' ELSE 'change' END AS chg_no_chg 
FROM  temp_customer_orders WHERE order_id IN(
SELECT order_id FROM temp_driver_order WHERE new_cancellation != 0
))a
GROUP BY customer_id,chg_no_chg;

--Q8. How many rolls were delivered that had both exclusions and extra?

With temp_customer_orders(order_id,customer_id,roll_id,new_not_include_items,new_extra_items_included,order_date) AS
(
SELECT order_id,customer_id,roll_id,
CASE WHEN not_include_items IS NULL OR not_include_items=' ' THEN '0' ELSE not_include_items END AS new_not_include_items, 
CASE WHEN extra_items_included IS NULL OR extra_items_included=' ' OR extra_items_included='NaN' THEN '0' ELSE extra_items_included END AS new_extra_items_included, order_date FROM customer_orders
)
,

temp_driver_order(order_id,driver_id,pickup_time,distance,duration,new_cancellation) AS
(
SELECT order_id,driver_id,pickup_time,distance,duration,
CASE WHEN cancellation IN ('cancellation', 'customer cancellation') THEN 0 ELSE 1 END AS new_cancellation
FROM driver_order
)
SELECT chg_no_chg, COUNT(chg_no_chg) FROM
(
SELECT *, CASE WHEN new_not_include_items!='0' AND new_extra_items_included!='0' THEN 'both inc and exc' ELSE 'either 1 inc or exc' END AS chg_no_chg 
FROM  temp_customer_orders WHERE order_id IN(
SELECT order_id FROM temp_driver_order WHERE new_cancellation != 0
))a GROUP BY chg_no_chg;


--Q9. What was the total number of rolls ordered for each hour of the day?

SELECT hrs_bracket, COUNT(hrs_bracket) FROM
(
SELECT *, CONCAT(CAST(DATEPART(hour,order_date) AS varchar), '-', CAST(DATEPART(hour,order_date)+1 AS varchar)) hrs_bracket FROM customer_orders)a
GROUP BY hrs_bracket;



--Q10. What was total number of orders for each day of the week?

SELECT dow, COUNT(DISTINCT order_id) FROM
(SELECT *, DATENAME(dw, order_date) dow FROM customer_orders)a
GROUP BY dow;

UPDATE driver_order
SET pickup_time = '01-11-2021 18:50:20' WHERE order_id=10;

--Q11. What was the average time in mins it took for each driver to arrive at the faasos HQ to pickup the order?

SELECT driver_id, SUM(diff)/COUNT(order_id) avg_mins FROM
(SELECT * FROM
(SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY diff) rnk FROM
(SELECT a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date, 
b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation, DATEDIFF(minute,a.order_date,b.pickup_time) diff
FROM customer_orders a INNER JOIN driver_order b
ON a.order_id=b.order_id 
WHERE b.pickup_time IS NOT NULL)a) b WHERE rnk =1)c
GROUP BY driver_id;


--Q12. Is there any relationship between the number of rolls and how long the order takes to prepare?


SELECT order_id, COUNT(roll_id) num_of_rolls, SUM(diff)/COUNT(roll_id) order_time FROM
(SELECT a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date, 
b.driver_id, b.pickup_time, b.distance, b.duration, b.cancellation, DATEDIFF(minute,a.order_date,b.pickup_time) diff
FROM customer_orders a INNER JOIN driver_order b
ON a.order_id=b.order_id 
WHERE b.pickup_time IS NOT NULL)a
GROUP BY order_id;


--Q13. What was the average distance travelled for each customer?


SELECT customer_id, sum(distance)/COUNT(order_id) avg_distance FROM
(SELECT * FROM
(SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY diff) rnk FROM
(SELECT a.order_id, a.customer_id, a.roll_id, a.not_include_items, a.extra_items_included, a.order_date, 
b.driver_id, b.pickup_time,
CAST(TRIM(REPLACE(b.distance,'km','')) AS DECIMAL(4,2)) distance,
b.duration, b.cancellation, DATEDIFF(minute,a.order_date,b.pickup_time) diff
FROM customer_orders a INNER JOIN driver_order b
ON a.order_id=b.order_id 
WHERE b.pickup_time IS NOT NULL)a) b WHERE rnk =1)c
GROUP BY customer_id;

--Q14. What was the difference between the longest and shortest delivery times for all orders?


SELECT MAX(duration) - MIN(duration) dlvry_time_diff FROM
(SELECT CAST(CASE WHEN duration LIKE '%min%' THEN LEFT(duration,CHARINDEX('m',duration)-1) ELSE duration
END AS INTEGER) AS duration FROM driver_order WHERE duration IS NOT NULL)a;



--Q15. What was the average speed for each driver for each delivery and do you notice any trend for these values?


SELECT a.order_id, a.driver_id, (a.distance/a.duration)*60 speed_kmph,b.cnt FROM
(SELECT order_id, driver_id,
CAST(TRIM(REPLACE(distance,'km','')) AS DECIMAL(4,2)) distance, CAST(CASE WHEN duration LIKE '%min%' THEN LEFT(duration,CHARINDEX('m',duration)-1) ELSE duration
END AS INTEGER) AS duration FROM driver_order WHERE distance IS NOT NULL)a INNER JOIN 
(SELECT order_id, COUNT(roll_id) cnt FROM customer_orders GROUP BY order_id)b ON a.order_id=b.order_id;


--Q16. What is the successful delivery percentage for each driver?


SELECT driver_id, (s*1.0/t)*100 dlvry_successful_percentage FROM 
(SELECT driver_id, SUM(can_per) s, COUNT(driver_id) t FROM
(SELECT driver_id, CASE WHEN LOWER(cancellation) LIKE '%cancel%' THEN 0 ELSE 1 END AS can_per FROM driver_order)a
GROUP BY driver_id)b;