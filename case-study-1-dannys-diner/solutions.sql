/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select
	s.customer_id,
    sum(price)
from sales s
join menu using(product_id)
group by s.customer_id
order by s.customer_id


-- 2. How many days has each customer visited the restaurant?
select
	s.customer_id,
    count(distinct order_date)
 from sales s
 group by s.customer_id

 
-- 3. What was the first item from the menu purchased by each customer?
with rank as(
  select
	s.customer_id,
    row_number() over(partition by s.customer_id order by  order_date) as first,
    m.product_name
 from sales s
 join menu m using(product_id)
)

select customer_id , product_name from rank where first = 1



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with rank as(
  select
	s.product_id,
    count(product_id)occurence
 from sales s
 group by s.product_id
)


select m.product_name,r.occurence from rank r join menu m using(product_id)


-- 5. Which item was the most popular for each customer?
with product_occurence as(
  select
	s.customer_id,
  product_id,
  	count(product_id)
 from sales s
 group by customer_id,product_id
  order by customer_id
),

rank as(
  select
  	p.*,
  m.product_name,
  rank() over(partition by p.customer_id order by p.count desc) as rnk
  from product_occurence p
  join menu m using(product_id)
)

select customer_id,product_name from rank
where rnk = 1
order by customer_id


-- 6. Which item was purchased first by the customer after they became a member?
with joined as(
  select
  	customer_id,
  	order_date,
  	product_id
  from sales
  join members using(customer_id)
  where sales.order_date >= members.join_date
  ),
  
  first_product as(
    select
    	j.customer_id,
    	row_number() over(partition by j.customer_id order by j.order_date) as rank,
    	m.product_name
   	from joined j join menu m using(product_id)
    )
  
  select customer_id,product_name from first_product
  where rank = 1

  
-- 7. Which item was purchased just before the customer became a member?
with joined_members as(
  select
  	sales.customer_id,
  members.join_date,
  	order_date,
  	product_id
  from sales
  join members on sales.customer_id=members.customer_id
  where sales.order_date<members.join_date
  ),
  
ranked as(
	select
    	joined_members.*,
    	menu.product_name,
    	row_number() over(partition by customer_id order by order_date desc) as rnk
    from joined_members
    join menu using(product_id)
)
  
 select * from ranked
 where rnk = 1

 
-- 8. What is the total items and amount spent for each member before they became a member?
with joined_members as(
  select
  	sales.customer_id,
  members.join_date,
  	order_date,
  	product_id
  from sales
  join members on sales.customer_id=members.customer_id
  where sales.order_date<members.join_date
  )
  
  select
  	j.customer_id,
    sum(m.price) as total_amount,
    count(j.product_id)
  from joined_members j
  join menu m
  using(product_id)
  group by j.customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points_customer as (select
	s.customer_id,
    m.product_name,
    case
    	when m.product_name = 'sushi' then m.price*20
        else m.price*10
    end as points
from sales s
join menu m 
using(product_id))

select
	customer_id,
    sum(points) as total_points
from points_customer
group by customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with joined_members as(
  select
  	sales.customer_id,
  members.join_date,
  	order_date,
  	sales.product_id,
  	menu.price,
  	case
            when order_date >= join_date
             and order_date < join_date + interval '7 day'
                then price * 20
            when product_name = 'sushi'
                then price * 20
            else price * 10
        end as points
  from sales
  join members on sales.customer_id=members.customer_id
  join menu using(product_id)
  ),
  

 filtered as(
   select * from joined_members
 where order_date <= '2021-01-31'
 )
 
  select customer_id,sum(points) from filtered
 group by customer_id