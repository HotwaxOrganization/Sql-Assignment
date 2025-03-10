-- SQL Assignment 1

-- 1 New Customers Acquired in June 2023
-- Business Problem:
-- The marketing team ran a campaign in June 2023 and wants to see how many new customers signed up during that period.

-- Fields to Retrieve:

-- PARTY_ID
-- FIRST_NAME
-- LAST_NAME
-- EMAIL
-- PHONE
-- ENTRY_DATE    
    
SELECT
    p.PARTY_ID,
    pr.FIRST_NAME,
    pr.LAST_NAME,
    cm.INFO_STRING as EMAIL,
    tm.CONTACT_NUMBER as PHONE,
    p.CREATED_DATE as ENTRY_DATE
FROM
    PARTY p
 JOIN
    PARTY_ROLE prl ON p.PARTY_ID = prl.PARTY_ID
 JOIN
    PERSON pr ON p.PARTY_ID = pr.PARTY_ID
 JOIN
    PARTY_CONTACT_MECH pcm ON p.PARTY_ID = pcm.PARTY_ID
JOIN
    CONTACT_MECH cm ON pcm.CONTACT_MECH_ID = cm.CONTACT_MECH_ID
JOIN 
    telecom_number tm oN tm.CONTACT_MECH_ID=cm.CONTACT_MECH_ID    
WHERE
    prl.ROLE_TYPE_ID = 'CUSTOMER'
    AND  p.CREATED_DATE >= '2023-06-01' 
    AND  p.CREATED_DATE <'2023-07-01';

Query cost=14990.80
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2 List All Active Physical Products
-- Business Problem:
-- Merchandising teams often need a list of all physical products to manage logistics, warehousing, and shipping.

-- Fields to Retrieve:

-- PRODUCT_ID
-- PRODUCT_TYPE_ID
-- INTERNAL_NAME


SELECT 
    p.PRODUCT_ID,
    p.PRODUCT_TYPE_ID,
    p.INTERNAL_NAME
FROM product p 
JOIN product_type  
USING(product_type_id) 
WHERE IS_PHYSICAL='Y'  ;

Query cost=115288.48

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3 Products Missing NetSuite ID
-- Business Problem:
-- A product cannot sync to NetSuite unless it has a valid NetSuite ID. The OMS needs a list of all products that still need to be created or updated in NetSuite.

-- Fields to Retrieve:

-- PRODUCT_ID
-- INTERNAL_NAME
-- PRODUCT_TYPE_ID
-- NETSUITE_ID (or similar field indicating the NetSuite ID; may be NULL or empty if missing)

//jinki erp_id type ho per uski value null or empty ho
   
   

SELECT
	p.PRODUCT_ID,
	p.INTERNAL_NAME,
	p.PRODUCT_TYPE_ID,
	gd.GOOD_IDENTIFICATION_TYPE_ID
FROM 
	product p 
LEFT JOIN  
	good_identification gd 
ON 
	p.PRODUCT_ID=gd.PRODUCT_ID 
WHERE 
	gd.GOOD_IDENTIFICATION_TYPE_ID='ERP_ID'
AND
	ID_VALUE is null 
OR      ID_VALUE ='';
	
	
	
Query cost =2.36	
	

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	
	
	
	   
-- 4 Product IDs Across Systems
-- Business Problem:
-- To sync an order or product across multiple systems (e.g., Shopify, HotWax, ERP/NetSuite), the OMS needs to know each system’s unique identifier for that product. This query retrieves the Shopify ID, HotWax ID, and ERP ID (NetSuite ID) for all products.
                                                             
-- Fields to Retrieve:

-- PRODUCT_ID (internal OMS ID)
-- SHOPIFY_ID     // SHOPIFY_PROD_ID
-- HOTWAX_ID      // HC_GOOD_ID_TYPE
-- ERP_ID or NETSUITE_ID (depending on naming)


 
SELECT
    PRODUCT_ID,
    (CASE WHEN GOOD_IDENTIFICATION_TYPE_ID = 'ERP_ID' THEN ID_VALUE  END) AS ERP_ID,
    (CASE WHEN GOOD_IDENTIFICATION_TYPE_ID = 'SHOPIFY_PROD_ID' THEN ID_VALUE  END) AS SHOPIFY_ID,
    (CASE WHEN GOOD_IDENTIFICATION_TYPE_ID = 'HC_GOOD_ID_TYPE' THEN ID_VALUE  END) AS HOTWAX_ID
FROM
    good_identification 
GROUP BY
    PRODUCT_ID;


Query cost = 282640.22
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    


    
-- 7 Newly Created Sales Orders and Payment Methods
-- Business Problem:
-- Finance teams need to see new orders and their payment methods for reconciliation and fraud checks.

-- Fields to Retrieve:

-- ORDER_ID
-- TOTAL_AMOUNT
-- PAYMENT_METHOD
-- Shopify Order ID (if applicable) //External_id


SELECT 
Order_id,
GRAND_TOTAL AS TOTAL_AMOUNT,
payment_method_type_id, 
EXTERNAL_ID AS Shopify_Order_ID 
FROM order_header  
JOIN Order_Payment_Preference 
USING (order_id) order by ORDER_DATE DESC ;

Query cost =52082.40 




---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 8 Payment Captured but Not Shipped
-- Business Problem:
-- Finance teams want to ensure revenue is recognized properly. If payment is captured but no shipment has occurred, it warrants further review.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_STATUS
-- PAYMENT_STATUS
-- SHIPMENT_STATUS


SELECT 
	oh.order_id,
	oh.status_id as ORDER_STATUS, 
    opp.status_id as PAYMENT_STATUS,
    s.STATUS_ID as SHIPMENT_STATUS   
FROM
	Order_header oh 
JOIN
	Order_Payment_Preference opp 
USING
	(order_id)  
JOIN
	order_shipment os 
ON 
	os.ORDER_ID=oh.order_id 
JOIN 
	shipment s 
ON 
	s.SHIPMENT_ID=os.SHIPMENT_ID   
WHERE 
	opp.status_id='PAYMENT_SETTLED' 
AND 
	s.STATUS_ID is null  ;



Query Cost=2.24


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 9 Orders Completed Hourly
-- Business Problem:
-- Operations teams may want to see how orders complete across the day to schedule staffing.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- HOUR


SELECT 
	count(*) as TOTAL_ORDERS, 
	HOUR(order_date) as HOUR  
FROM
	order_header 
WHERE 
	STATUS_ID='ORDER_COMPLETED' 
GROUP BY 
	Hour(order_date) ;


Query Cost=5382.90



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- 10 BOPIS Orders Revenue (Last Year)
-- Business Problem:
-- BOPIS (Buy Online, Pickup In Store) is a key retail strategy. Finance wants to know the revenue from BOPIS orders for the previous year.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- TOTAL REVENUE



SELECT  
	COUNT(oh.order_id) as TOTAL_ORDERS, 
        SUM(oh.grand_Total)  
FROM
	order_header oh  
JOIN
	order_shipment os 
USING
	(order_id) 
JOIN
	shipment s 
ON 
	os.SHIPMENT_ID=s.SHIPMENT_ID  
WHERE
	oh.SALES_CHANNEL_ENUM_ID='WEB_SALES_CHANNEL' 
AND 
	s.SHIPMENT_METHOD_TYPE_ID='STOREPICKUP' 
AND 
	oh.order_date >='2024-01-01' 
AND 
	oh.order_date <'2025-01-01';                 


Query Cost=10737.20

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 11 Canceled Orders (Last Month)
-- Business Problem:
-- The merchandising team needs to know how many orders were canceled in the previous month and their reasons.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- CANCELATION REASON    

SELECT  
	COUNT(oh.ORDER_ID) AS TOTAL_ORDERS, 
        os.CHANGE_REASON AS CANCELATION_REASON
FROM
	order_header oh 
JOIN
	Order_Status os ON oh.order_id= os.order_id 
WHERE
	os.status_id='ORDER_CANCELLED'  
AND	
	oh.order_date >'2024-12-01' 
AND	 
	oh.order_date <'2024-12-31'     
    
GROUP BY
	os.CHANGE_REASON;
    
    

Query Cost=20086.03



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


