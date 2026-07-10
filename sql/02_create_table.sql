create database olist_e_commerce;

create table geolocation (
    geolocation_zip_code_prefix int primary key,
    geolocation_lat numeric,
    geolocation_lng numeric,
    geolocation_city varchar,
    geolocation_state varchar
);

create table product_category_name_translation (
    product_category_name varchar primary key,
    product_category_name_english varchar
);

create table customers (
    customer_id varchar primary key,
    customer_unique_id varchar,
    customer_zip_code_prefix int,
    customer_city varchar,
    customer_state varchar
);

create table sellers (
    seller_id varchar primary key,
    seller_zip_code_prefix int,
    seller_city varchar,
    seller_state varchar
);

create table products (
    product_id varchar primary key,
    product_category_name varchar,
    product_name_length int, 
    product_description_length int,
    product_photos_qty int,
    product_weight_g int,
    product_length_cm int,
    product_height_cm int,
    product_width_cm int
);

create table orders (
    order_id varchar primary key,
    customer_id varchar references customers(customer_id),
    order_status varchar,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);

create table order_reviews (
    review_id varchar,
    order_id varchar references orders(order_id),
    review_score int,
    review_comment_title text,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp
);

create table order_payments (
    order_id varchar references orders(order_id),
    payment_sequential int,
    payment_type varchar,
    payment_installments int,
    payment_value numeric,
    primary key(order_id, payment_sequential)
);

create table order_items (
    order_id varchar references orders(order_id),
    order_item_id int,
    product_id varchar references products(product_id),
    seller_id varchar references sellers(seller_id),
    shipping_limit_date timestamp,
    price numeric,
    freight_value numeric,
    primary key(order_id, order_item_id)
);

copy geolocation from 'C:\olist_e-commerce\data\cleaned\olist_geolocation_clean.csv' delimiter ',' csv header;
copy product_category_name_translation from 'C:\olist_e-commerce\data\cleaned\olist_translation_clean.csv' delimiter ',' csv header;
copy customers from 'C:\olist_e-commerce\data\cleaned\olist_customers_clean.csv' delimiter ',' csv header;
copy sellers from 'C:\olist_e-commerce\data\cleaned\olist_sellers_clean.csv' delimiter ',' csv header;
copy products from 'C:\olist_e-commerce\data\cleaned\olist_products_clean.csv' delimiter ',' csv header;
copy orders from 'C:\olist_e-commerce\data\cleaned\olist_orders_clean.csv' delimiter ',' csv header;
copy order_reviews from 'C:\olist_e-commerce\data\cleaned\olist_order_reviews_clean.csv' delimiter ',' csv header;
copy order_payments from 'C:\olist_e-commerce\data\cleaned\olist_order_payments_clean.csv' delimiter ',' csv header;
copy order_items from 'C:\olist_e-commerce\data\cleaned\olist_order_items_clean.csv' delimiter ',' csv header;
