create database pizza_hut;

create table orders (
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id)
);

create table order_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key(order_details_id)
);


-- Retrieve the total number of orders placed.
select count(order_id)
from orders;

-- Calculate the total revenue generated from pizza sales.
select round(sum(pizzas.price * order_details.quantity),2) as total_revenue
from pizzas join order_details
on pizzas.pizza_id = order_details.pizza_id;

-- Identify the highest-priced pizza.
select pizza_types.name, pizzas.price
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
order by pizzas.price desc limit 1;


-- Identify the most common pizza size ordered.
select pizzas.size, count(order_details.quantity) as order_count
from pizzas join order_details
on pizzas.pizza_id = order_details.pizza_id
group by pizzas.size order by order_count desc;

-- List the top 5 most ordered pizza types along with their quantities.
select pizza_types.name, sum(order_details.quantity) as quantity
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.name order by quantity desc limit 5;


-- Join the necessary tables to find the total quantity of each pizza category ordered.
select pizza_types.category, sum(order_details.quantity) as quantity
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.category order by quantity desc;


-- Determine the distribution of orders by hour of the day.
select hour(order_time) as hour, count(order_id) as orders 
from orders
group by hour(order_time);

-- Join relevant tables to find the category-wise distribution of pizzas.
select category, count(name) as pizza_count
from pizza_types
group by category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
select round(avg(quantity),0) as avg_orders from 
(select orders.order_date, sum(order_details.quantity) as quantity
from orders join order_details
on orders.order_id = order_details.order_id
group by (orders.order_date)) as orders;

-- Determine the top 3 most ordered pizza types based on revenue.
select pizza_types.name, sum(pizzas.price * order_details.quantity) as revenue
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_details
on order_details.pizza_id = pizzas.pizza_id
group by pizza_types.name order by revenue desc limit 3;

-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
    pizza_types.category,
    ROUND(SUM(pizzas.price * order_details.quantity) / (SELECT 
                    ROUND(SUM(pizzas.price * order_details.quantity),
                                2) AS total_sales
                FROM
                    pizzas
                        JOIN
                    order_details ON pizzas.pizza_id = order_details.pizza_id) * 100,
            2) AS revenue
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;

-- Analyze the cumulative revenue generated over time.
SELECT order_date,
       round(SUM(revenue) OVER (ORDER BY order_date),2) AS cum_revenue
FROM
(
  SELECT orders.order_date,
         SUM(order_details.quantity * pizzas.price) AS revenue
  FROM order_details
  JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
  JOIN orders ON orders.order_id = order_details.order_id
  GROUP BY orders.order_date
) AS sales;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT category, name, revenue
FROM (
  SELECT category, name, revenue,
         RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
  FROM (
    SELECT pizza_types.category, pizza_types.name,
           SUM(order_details.quantity * pizzas.price) AS revenue
    FROM pizza_types
    JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
    JOIN order_details ON order_details.pizza_id = pizzas.pizza_id
    GROUP BY pizza_types.category, pizza_types.name
  ) AS a
) AS b
WHERE rn <= 3;

