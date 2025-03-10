-- 1 Completed Sales Orders (Physical Items)
-- Business Problem:
-- Merchants need to track only physical items (requiring shipping and fulfillment) for logistics and shipping-cost analysis.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_ITEM_SEQ_ID
-- PRODUCT_ID
-- PRODUCT_TYPE_ID
-- SALES_CHANNEL_ENUM_ID
-- ORDER_DATE
-- ENTRY_DATE
-- STATUS_ID
-- STATUS_DATETIME
-- ORDER_TYPE_ID
-- PRODUCT_STORE_ID


SELECT
    oi.order_id,
    oi.order_item_seq_id,
    oi.product_id,
    p.product_type_id,
    oh.sales_channel_enum_id,
    oh.order_date,
    oh.entry_date,
    oi.status_id,
	os.status_Datetime AS status_date_time,
    oh.order_type_id,
    oh.product_store_id
FROM
    order_item oi
JOIN
    order_header oh ON oi.order_id = oh.order_id AND 	oh.order_type_id='SALES_ORDER' and oh.status_id = 'ORDER_COMPLETED'
JOIN
    product p ON oi.product_id = p.product_id AND p.PRODUCT_TYPE_ID not in('DIGITAL_GOOD','DONATION','INSTALLATION_SERVICE','SERVICE')
 JOIN
    order_status os ON oi.order_id = os.order_id AND oi.order_item_seq_id = os.order_Item_Seq_Id;
	
 
Query Cost=56922.38

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- 2 Completed Return Items
-- Business Problem:
-- Customer service and finance often need insights into returned items to manage refunds, replacements, and inventory restocking.

-- Fields to Retrieve:

-- RETURN_ID
-- ORDER_ID
-- PRODUCT_STORE_ID
-- STATUS_DATETIME
-- ORDER_NAME
-- FROM_PARTY_ID
-- RETURN_DATE
-- ENTRY_DATE
-- RETURN_CHANNEL_ENUM_ID




SELECT
    RH.RETURN_ID AS RETURN_ID,
    OH.ORDER_ID AS ORDER_ID,
    PS.PRODUCT_STORE_ID AS PRODUCT_STORE_ID,
    OH.ORDER_NAME AS ORDER_NAME,
    RH.FROM_PARTY_ID AS FROM_PARTY_ID,
    RH.RETURN_DATE AS RETURN_DATE,
    RH.ENTRY_DATE AS ENTRY_DATE,
    RH.RETURN_CHANNEL_ENUM_ID AS RETURN_CHANNEL_ENUM_ID
FROM
    Return_Header RH
JOIN
    Return_Item RI ON RH.RETURN_ID = RI.RETURN_ID
JOIN
    Order_Item OI ON RI.ORDER_ITEM_SEQ_ID = OI.ORDER_ITEM_SEQ_ID AND RI.ORDER_ID = OI.ORDER_ID
JOIN
    Order_Header OH ON OI.ORDER_ID = OH.ORDER_ID
JOIN
    Product_Store PS ON OH.PRODUCT_STORE_ID = PS.PRODUCT_STORE_ID
WHERE RH.STATUS_ID = 'RETURN_COMPLETED';



Query Cost= 4651.57

_________________________________________________________________________________________________________________________________________________________________________________________________________________________



-- 3 Single-Return Orders (Last Month)
-- Business Problem:
-- The mechandising team needs a list of orders that only have one return.

-- Fields to Retrieve:

-- PARTY_ID
-- FIRST_NAME    

    
SELECT
    P.party_Id AS PARTY_ID,
    Pr.first_Name AS FIRST_NAME
FROM
    Return_Header RH
JOIN
    Return_Item RI ON RH.return_Id = RI.return_Id
JOIN
    Party P ON RH.from_Party_Id = P.party_Id
JOIN
    Person Pr ON P.party_Id = Pr.party_Id
WHERE
    RH.entry_Date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    AND RH.entry_Date < CURDATE()
GROUP BY
    P.party_Id,
    Pr.first_Name
HAVING
    COUNT(RI.return_Item_Seq_Id) = 1;


Query cost=1132.15


_________________________________________________________________________________________________________________________________________________________________________________________________________________________


-- 4 Returns and Appeasements
-- Business Problem:
-- The retailer needs the total amount of items, were returned as well as how many appeasements were issued.

-- Fields to Retrieve:

-- TOTAL RETURNS
-- RETURN $ TOTAL
-- TOTAL APPEASEMENTS
-- APPEASEMENTS $ TOTAL

SELECT
    SUM(RI.RETURN_QUANTITY) AS TOTAL_RETURNS,
    SUM(RI.RETURN_PRICE * RI.RETURN_QUANTITY) AS RETURN_TOTAL,
    COUNT(DISTINCT RA.RETURN_ADJUSTMENT_ID) AS TOTAL_APPEASEMENTS,
    SUM(RA.AMOUNT) AS APPEASEMENTS_TOTAL
FROM
    Return_Item RI
LEFT JOIN
    Return_Adjustment RA ON RI.RETURN_ID = RA.RETURN_ID AND RI.RETURN_ITEM_SEQ_ID = RA.RETURN_ITEM_SEQ_ID
WHERE
    RA.RETURN_ADJUSTMENT_TYPE_ID ='APPEASEMENT';



Query cost=243.30



_________________________________________________________________________________________________________________________________________________________________________________________________________________________


-- 5 Detailed Return Information
-- Business Problem:
-- Certain teams need granular return data (reason, date, refund amount) for analyzing return rates, identifying recurring issues, or updating policies.

-- Fields to Retrieve:

-- RETURN_ID
-- ENTRY_DATE
-- RETURN_ADJUSTMENT_TYPE_ID (refund type, store credit, etc.)
-- AMOUNT
-- COMMENTS
-- ORDER_ID
-- ORDER_DATE
-- RETURN_DATE
-- PRODUCT_STORE_ID

select
    rh.RETURN_ID,
    rh.ENTRY_DATE,
    ra.RETURN_ADJUSTMENT_TYPE_ID,
    ra.AMOUNT,
    ra.COMMENTS,
    ri.ORDER_ID,
    oh.ORDER_DATE,
    rh.RETURN_DATE,
    oh.PRODUCT_STORE_ID
FROM
	return_header rh 
JOIN
	return_item ri on rh.RETURN_ID=ri.RETURN_ID 
left JOIN
	return_adjustment ra on ra.RETURN_ID =ri.RETURN_ID and ra.RETURN_ITEM_SEQ_ID=ri.RETURN_ITEM_SEQ_ID
left JOIN
	order_header oh on oh.ORDER_ID=ri.ORDER_ID;



Query cost=5829.33




_________________________________________________________________________________________________________________________________________________________________________________________________________________________



-- 6 Orders with Multiple Returns

-- Business Problem:
-- Analyzing orders with multiple returns can identify potential fraud, chronic issues with certain items, or inconsistent shipping processes.

-- Fields to Retrieve:

-- ORDER_ID
-- RETURN_ID
-- RETURN_DATE
-- RETURN_REASON
-- RETURN_QUANTITY


SELECT
    ri.ORDER_ID,
    GROUP_CONCAT(DISTINCT ri.RETURN_ID) AS RETURN_IDS,
    MIN(rh.RETURN_DATE) AS EARLIEST_RETURN_DATE,
    GROUP_CONCAT(DISTINCT ri.RETURN_REASON_ID) AS RETURN_REASONS,
    SUM(ri.RETURN_QUANTITY) AS TOTAL_RETURN_QUANTITY
FROM
    return_item ri
JOIN
    return_header rh ON ri.RETURN_ID = rh.RETURN_ID
GROUP BY
    ri.ORDER_ID
HAVING
    COUNT(DISTINCT ri.RETURN_ID) > 1;


Query cost=6009.85


_________________________________________________________________________________________________________________________________________________________________________________________________________________________


-- 7 Store with Most One-Day Shipped Orders (Last Month)
-- Business Problem:
-- Identify which facility (store) handled the highest volume of “one-day shipping” orders in the previous month, useful for operational benchmarking.

-- Fields to Retrieve:

-- FACILITY_ID
-- FACILITY_NAME
-- TOTAL_ONE_DAY_SHIP_ORDERS
-- REPORTING_PERIOD

SELECT
    F.FACILITY_ID,
    F.FACILITY_NAME,
    COUNT(OH.order_id) AS TOTAL_ONE_DAY_SHIP_ORDERS,
	DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m') AS REPORTING_PERIOD
FROM
    Order_Header OH
JOIN
    Order_Item OI ON OI.ORDER_ID = OH.ORDER_ID
JOIN
    Facility F ON OH.origin_Facility_Id = F.FACILITY_ID
JOIN
    Shipment S ON OH.ORDER_ID = S.primary_Order_Id
WHERE
 	OH.order_date >= DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01') 
    AND OH.order_date < DATE_FORMAT(NOW(), '%Y-%m-01')
	AND S.shipment_Method_Type_Id = 'NEXT_DAY'  
GROUP BY
    F.FACILITY_ID,
    F.FACILITY_NAME
ORDER BY
    TOTAL_ONE_DAY_SHIP_ORDERS DESC
LIMIT 1;



Query cost=6078.70





_________________________________________________________________________________________________________________________________________________________________________________________________________________________


-- 8 List of Warehouse Pickers
-- Business Problem:
-- Warehouse managers need a list of employees responsible for picking and packing orders to manage shifts, productivity, and training needs.

-- Fields to Retrieve:

-- PARTY_ID (or Employee ID)
-- NAME (First/Last)
-- ROLE_TYPE_ID (e.g., “WAREHOUSE_PICKER”)
-- FACILITY_ID (assigned warehouse)
-- STATUS (active or inactive employee)



SELECT
    p.party_id as employee_id,
    per.first_name as name,
    pr.role_type_id,
    f.FACILITY_ID,
    p.STATUS_ID
FROM
    Party P
JOIN
    Party_Role PR ON P.PARTY_ID = PR.PARTY_ID
JOIN
    Facility F ON F.owner_Party_Id = P.PARTY_ID
LEFT JOIN
    Person per ON P.PARTY_ID = per.PARTY_ID
WHERE
    PR.ROLE_TYPE_ID = 'WAREHOUSE_PICKER'
AND 
    f.facility_type_id='WAREHOUSE';



Query cost=38.61


_________________________________________________________________________________________________________________________________________________________________________________________________________________________


-- 9 Total Facilities That Sell the Product
-- Business Problem:
-- Retailers want to see how many (and which) facilities (stores, warehouses, virtual sites) currently offer a product for sale.

-- Fields to Retrieve:

-- PRODUCT_ID
-- PRODUCT_NAME (or INTERNAL_NAME)
-- FACILITY_COUNT (number of facilities selling the product)
-- (Optionally) a list of FACILITY_IDs if more detail is needed


SELECT
    P.PRODUCT_ID,
    P.PRODUCT_NAME,
    COUNT(DISTINCT F.FACILITY_ID) AS FACILITY_COUNT
FROM
    Product P
JOIN
    Inventory_Item II ON P.PRODUCT_ID = II.PRODUCT_ID
JOIN
    Facility F ON II.FACILITY_ID = F.FACILITY_ID
GROUP BY
    P.PRODUCT_ID;
    
    


Query cost=3591411.53
    


_________________________________________________________________________________________________________________________________________________________________________________________________________________________


-- 10 Total Items in Various Virtual Facilities
-- Business Problem:
-- Virtual facilities (such as online-only fulfillment centers) handle a different inventory process. The company wants a snapshot of total stock across these virtual locations.

-- Fields to Retrieve:

-- PRODUCT_ID
-- FACILITY_ID
-- FACILITY_TYPE_ID
-- QOH (Quantity on Hand)
-- ATP (Available to Promise)
    


SELECT
    II.PRODUCT_ID,
    F.FACILITY_ID,
    F.FACILITY_TYPE_ID,
    II.QUANTITY_ON_HAND_TOTAL AS QOH,
    II.AVAILABLE_TO_PROMISE_TOTAL AS ATP
FROM
    Inventory_Item II
JOIN
    Facility F ON II.FACILITY_ID = F.FACILITY_ID
WHERE
    F.FACILITY_TYPE_ID = 'VIRTUAL_FACILITY';





Query cost=3749.93


_________________________________________________________________________________________________________________________________________________________________________________________________________________________


-- 12 Orders Without Picklist
-- Business Problem:
-- A picklist is necessary for warehouse staff to gather items. Orders missing a picklist might be delayed and need attention.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_DATE
-- ORDER_STATUS
-- FACILITY_ID
-- DURATION (How long has the order been assigned at the facility)
   



SELECT 
    oh.order_id AS ORDER_ID,
    oh.order_date AS ORDER_DATE,
    oh.status_id AS ORDER_STATUS,
    oh.origin_facility_id AS FACILITY_ID,
    DATEDIFF(CURRENT_DATE, oh.order_date) AS DURATION
FROM Order_Header oh
LEFT JOIN PickList_Item pi ON oh.order_id = pi.order_id
WHERE pi.order_id IS NULL;



Query Cost=111706.06

_________________________________________________________________________________________________________________________________________________________________________________________________________________________
