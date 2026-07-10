-- =====================================================
-- Customer Satisfaction Analysis
-- =====================================================

-- Review score distribution
select 
    c.review_score,
    count(*) as review_count,
    round(count(*) * 100.0 / sum(count(*)) over(), 2) as percentage
from order_reviews c
group by c.review_score
order by c.review_score;

-- Delivery Performace
select
    r.review_score,
    round(avg(o.order_approved_at::date - o.order_purchase_timestamp::date), 2) as avg_approval_days,
    round(percentile_cont(0.5) within group (order by (o.order_approved_at::date - o.order_purchase_timestamp::date))::numeric, 2) as median_approval_days,

    round(avg(o.order_delivered_carrier_date::date - o.order_approved_at::date), 2) as avg_handling_days,
    round(percentile_cont(0.5) within group (order by (o.order_delivered_carrier_date::date - o.order_approved_at::date))::numeric, 2) as median_handling_days,

    round(avg(o.order_delivered_customer_date::date - o.order_purchase_timestamp::date), 2) as avg_delivery_days,
    round(percentile_cont(0.5) within group (order by (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date))::numeric, 2) as median_delivery_days,

    round(avg(o.order_estimated_delivery_date::date - o.order_delivered_customer_date::date), 2) as avg_delivery_vs_estimate_days,
    round(percentile_cont(0.5) within group (order by (o.order_estimated_delivery_date::date - o.order_delivered_customer_date::date))::numeric, 2) as median_delivery_vs_estimate_days,

    round(avg(case 
            when o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date > 0 
            then 1 
            else 0 
        end) * 100, 2) as percentage_delayed_orders
from orders o
join order_reviews r on o.order_id = r.order_id
where o.order_status = 'delivered' and
        o.order_approved_at is not null and
        o.order_delivered_carrier_date is not null and
        o.order_delivered_customer_date is not null and
        o.order_estimated_delivery_date is not null
group by r.review_score
order by r.review_score;

-- Delivery status analysis
select
    case 
        when o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date > 0 
        then 'Late' 
        else 'On Time' 
    end as delivery_status,
    round(avg(r.review_score), 2) as avg_review_score,
    count(o.order_id) as total_orders
from orders o
join order_reviews r on o.order_id = r.order_id
where o.order_status = 'delivered' and
        o.order_delivered_customer_date is not null and
        o.order_estimated_delivery_date is not null
group by delivery_status
order by delivery_status;

-- Delivery delay percentage
select 
    round(
        avg(
            case 
                when o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date > 0 
                then 1 
                else 0 
            end) * 100, 2) as percentage_delayed_orders
from orders o
where o.order_status = 'delivered' and
        o.order_delivered_customer_date is not null and
        o.order_estimated_delivery_date is not null;

-- Freight cost
with freight_ratio as(
    select 
        i.order_id,
        sum(freight_value) as total_freight_value,
        sum(i.freight_value) / sum(i.price + i.freight_value) as freight_rate
    from order_items i
    join orders o on i.order_id = o.order_id
    where o.order_status = 'delivered'
    group by i.order_id
)
select 
    r.review_score,
    round(avg(f.total_freight_value), 2) as avg_freight_value,
    round(avg(f.freight_rate), 3) as avg_freight_rate
from freight_ratio f
join orders o on f.order_id = o.order_id
join order_reviews r on o.order_id = r.order_id
where o.order_status = 'delivered'
group by r.review_score
order by r.review_score;

-- Seller performance
with seller_orders as(
    select 
        i.seller_id,
        count(distinct o.order_id) as total_orders
    from order_items i
    join orders o on i.order_id = o.order_id
    where o.order_status = 'delivered'  
    group by i.seller_id
), 
top_sellers as(
    select 
        s.seller_id,
        so.total_orders
    from sellers s
    join seller_orders so on s.seller_id = so.seller_id
    order by so.total_orders desc
    limit 10
)
select 
    case
        when i.seller_id in (select seller_id from top_sellers) then 'Top 10 Sellers'
        else 'Other Sellers'
    end as seller_category,
    count(*) as order_count,
    round(avg(r.review_score), 2) as avg_review_score,
    round(avg(o.order_delivered_customer_date::date - o.order_purchase_timestamp::date), 2) as avg_delivery_days,
    round(
        avg(
            case 
                when o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date > 0 
                then 1 else 0 
            end) * 100, 2) as percentage_delayed_orders
from order_items i
join orders o on i.order_id = o.order_id
join order_reviews r on o.order_id = r.order_id
where o.order_status = 'delivered'
group by seller_category;
