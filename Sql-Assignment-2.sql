-- 5.1 Shipping Addresses for October 2023 Orders
-- Business Problem:
-- Customer Service might need to verify addresses for orders placed or completed in October 2023. This helps ensure shipments are delivered correctly and prevents address-related issues.

-- Fields to Retrieve:

-- ORDER_ID
-- PARTY_ID (Customer ID)
-- CUSTOMER_NAME (or FIRST_NAME / LAST_NAME)
-- STREET_ADDRESS
-- CITY
-- STATE_PROVINCE
-- POSTAL_CODE
-- COUNTRY_CODE
-- ORDER_STATUS
-- ORDER_DATE




 SELECT 
	pr.PARTY_ID,
	concat(pr.FIRST_NAME," ",pr.LAST_NAME) as CUSTOMER_NAME,
	oh.ORDER_ID,
	ps.ADDRESS1 as STREET_ADDRESS, 
        ps.CITY, ps.STATE_PROVINCE_GEO_ID as STATE_PROVINCE, 
    	ps.POSTAL_CODE, 
    	ps.COUNTRY_GEO_ID as COUNTRY_CODE, 
    	oh.STATUS_ID,
    	oh.ORDER_DATE 
 FROM
	order_header oh
 join
	order_contact_mech ocm
 ON 
	oh.ORDER_ID=ocm.ORDER_ID
 JOIN	
	party_contact_mech pcm 
 ON 
	pcm.CONTACT_MECH_ID =ocm.CONTACT_MECH_ID
 JOIN 
 	person pr 
 ON 
	pr.PARTY_ID=pcm.PARTY_ID
 JOIN 
	postal_address ps 
 ON 
	ps.CONTACT_MECH_ID=ocm.CONTACT_MECH_ID
 WHERE
	CONTACT_MECH_PURPOSE_TYPE_ID='SHIPPING_LOCATION'
 AND
	oh.ORDER_DATE>='2023-10-01' 
 AND
	oh.ORDER_DATE<'2024-01-01';
 
 
 
 Query Cost =20965.3
 
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  -- 5.2 Orders from New York
-- Business Problem:
-- Companies often want region-specific analysis to plan local marketing, staffing, or promotions in certain areas—here, specifically, New York.

-- Fields to Retrieve:

-- ORDER_ID
-- CUSTOMER_NAME
-- STREET_ADDRESS (or shipping address detail)
-- CITY
-- STATE_PROVINCE
-- POSTAL_CODE
-- TOTAL_AMOUNT
-- ORDER_DATE
-- ORDER_STATUS



 
 
 
 
 
 SELECT 
	concat(pr.FIRST_NAME," ",pr.LAST_NAME) as CUSTOMER_NAME,
	oh.ORDER_ID,
	ps.ADDRESS1 as STREET_ADDRESS, 
    ps.CITY,
    ps.STATE_PROVINCE_GEO_ID as STATE_PROVINCE, 
    ps.POSTAL_CODE, 
    ps.COUNTRY_GEO_ID as COUNTRY_CODE, 
    oh.STATUS_ID,
    oh.ORDER_DATE 
 FROM
	order_header oh
 join
	order_contact_mech ocm
 ON 
	oh.ORDER_ID=ocm.ORDER_ID
 JOIN	
	party_contact_mech pcm 
 ON 
	pcm.CONTACT_MECH_ID =ocm.CONTACT_MECH_ID
 JOIN 
        person pr 
 ON 
        pr.PARTY_ID=pcm.PARTY_ID
 JOIN 
	postal_address ps 
 ON 
	ps.CONTACT_MECH_ID=ocm.CONTACT_MECH_ID
 WHERE
	CONTACT_MECH_PURPOSE_TYPE_ID='SHIPPING_LOCATION'
 AND
	ps.STATE_PROVINCE_GEO_ID='NY';
	
Query Cost = 15311.99

 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5.3 Top-Selling Product in New York
-- Business Problem:
-- Merchandising teams need to identify the best-selling product(s) in a specific region (New York) for targeted restocking or promotions.

-- Fields to Retrieve:

-- PRODUCT_ID
-- INTERNAL_NAME
-- TOTAL_QUANTITY_SOLD
-- CITY / STATE (within New York region)
-- REVENUE (optionally, total sales amount)




SELECT 
	p.product_id,
	p.INTERNAL_NAME, 
	count(oi.QUANTITY) as TOTAL_QUANTITY_SOLD, 
        pa.CITY as CITY, 
        sum(oh.grand_Total) as REVENUE 
FROM 
	order_header oh 
JOIN
	order_item oi on oh.ORDER_ID=oi.ORDER_ID 
JOIN 
	product p on p.PRODUCT_ID =oi.PRODUCT_ID
JOIN 
	order_contact_mech ocm on oh.ORDER_ID=ocm.ORDER_ID
JOIN
	postal_address pa on pa.CONTACT_MECH_ID=ocm.CONTACT_MECH_ID 
WHERE
	pa.STATE_PROVINCE_GEO_ID='NY' 
AND 
	pa.CITY='NEW YORK'
AND 
        oh.STATUS_ID='ORDER_COMPLETED'
GROUP BY
	p.PRODUCT_ID
ORDER BY 
	TOTAL_QUANTITY_SOLD desc; 

 


Query Cost=8823.77


 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



 
 -- 7.3 Store-Specific (Facility-Wise) Revenue
-- Business Problem:
-- Different physical or online stores (facilities) may have varying levels of performance. The business wants to compare revenue across facilities for sales planning and budgeting.

-- Fields to Retrieve:

-- FACILITY_ID
-- FACILITY_NAME
-- TOTAL_ORDERS
-- TOTAL_REVENUE
-- DATE_RANGE




SELECT 
	f.FACILITY_ID, 
        f.FACILITY_NAME, 
        sum(oi.QUANTITY), 
	sum(oh.grand_Total) as REVENUE, 
	MIN(oh.ORDER_DATE) AS START_DATE, 
        MAX(oh.ORDER_DATE) AS END_DATE
FROM
	order_item oi 
JOIN
	order_item_ship_group oisg on oi.ORDER_ID=oisg.ORDER_ID 
JOIN
	facility f on f.FACILITY_ID=oisg.FACILITY_ID
JOIN
	order_header oh on oh.ORDER_ID=oi.ORDER_ID 
GROUP BY f.FACILITY_ID ;


 Query Cost =281220.32
 
 
 
 
 
 
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 

-- 8.1 Lost and Damaged Inventory
-- Business Problem:
-- Warehouse managers need to track “shrinkage” such as lost or damaged inventory to reconcile physical vs. system counts.

-- Fields to Retrieve:

-- INVENTORY_ITEM_ID
-- PRODUCT_ID
-- FACILITY_ID
-- QUANTITY_LOST_OR_DAMAGED
-- REASON_CODE (Lost, Damaged, Expired, etc.)
-- TRANSACTION_DATE

SELECT
    iid.inventory_item_id,
    ii.product_id,
    ii.facility_id,
    iid.quantity_on_hand_diff AS quantity_lost_or_damaged,
    iid.reason_enum_id AS reason_code,
    iid.effective_date AS transaction_date
FROM
    Inventory_Item_Detail iid
JOIN
    Inventory_Item ii ON iid.inventory_item_id = ii.inventory_item_id
WHERE
    iid.reason_enum_id IN ('VAR_DAMAGED', 'VAR_LOST');


Query Cost=599398.00




 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 8.3 Retrieve the Current Facility (Physical or Virtual) of Open Orders
-- Business Problem:
-- The business wants to know where open orders are currently assigned, whether in a physical store or a virtual facility (e.g., a distribution center or online fulfillment location).

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_STATUS
-- FACILITY_ID
-- FACILITY_NAME
-- FACILITY_TYPE_ID
SELECT
    oh.order_id,
    oh.status_id AS order_status,
    f.facility_id,
    f.facility_name,
    f.facility_type_id
FROM
    Order_Header oh
JOIN
    Facility f ON oh.origin_Facility_Id = f.facility_id 
WHERE
    oh.status_id NOT IN ('ORDER_COMPLETED', 'ORDER_CANCELLED', 'ORDER_REJECTED') ;


Query Cost=25762.45
    
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    
-- 8.6 Total Orders by Sales Channel
-- Business Problem:
-- Marketing and sales teams want to see how many orders come from each channel (e.g., web, mobile app, in-store POS, marketplace) to allocate resources effectively.

-- Fields to Retrieve:

-- SALES_CHANNEL
-- TOTAL_ORDERS
-- TOTAL_REVENUE
-- REPORTING_PERIOD


SELECT
    sales_channel_enum_id AS sales_channel,
    COUNT(order_id) AS total_orders,
    SUM(grand_total) AS total_revenue,
    date_format(ORDER_DATE , "%Y") AS reporting_period  
FROM
    order_header
GROUP BY
    sales_channel_enum_id, reporting_period;

Query Cost=9200.80

   
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 


    

