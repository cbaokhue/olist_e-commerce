-- =====================================================
-- Marketplace Overview
-- =====================================================

-- Order status distribution
select 
    order_status, 
    round(count(*) * 100.0 / sum(count(*)) over()) as percentage
from orders
group by order_status
order by percentage desc;

-- Overall KPIs
with order_value as(
    select 
        i.order_id,
        sum(i.price + i.freight_value) as total_value
    from order_items i
    inner join orders o on i.order_id = o.order_id
    where o.order_status = 'delivered'
    group by i.order_id 
),
review_per_order as (
    select 
        order_id,
        avg(review_score) as review_score
    from order_reviews
    group by order_id
)
select
    count(v.order_id) as total_delivered_orders,
    count(distinct c.customer_unique_id) as total_customers,
    (
        select 
            count(distinct seller_id)
        from order_items i
        inner join orders o on i.order_id = o.order_id
        where o.order_status = 'delivered'
    ) as total_sellers,
    sum(v.total_value) as total_GMV,
    round(avg(v.total_value), 2) as avg_order_value,
    round(avg(r.review_score), 2) as avg_review_score
from order_value v
join orders o on v.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
left join review_per_order r on v.order_id = r.order_id

-- Monthly marketplace activity
with months as(
    select generate_series(
        date_trunc('month', min(order_purchase_timestamp)),
        date_trunc('month', max(order_purchase_timestamp)),
        interval '1 month'
    ) as month
    from orders
),
order_value as(
    select 
        i.order_id,
        sum(i.price + i.freight_value) as total_value
    from order_items i
    inner join orders o on i.order_id = o.order_id
    where o.order_status = 'delivered'
    group by i.order_id 
),
monthly_activity as(
    select 
        date_trunc('month', o.order_purchase_timestamp) as purchase_month,
        count(distinct o.order_id) as total_orders,
        sum(v.total_value) as monthly_GMV,
        round(avg(v.total_value), 2) as avg_order_value
    from orders o
    join order_value v on o.order_id = v.order_id
    where o.order_status = 'delivered'
    group by purchase_month
)
select 
    m.month as purchase_month,
    coalesce(a.total_orders, 0) as total_orders,
    coalesce(a.monthly_GMV, 0) as monthly_GMV,
    coalesce(a.avg_order_value, 0) as avg_order_value
from months m
left join monthly_activity a on m.month = a.purchase_month
order by m.month;