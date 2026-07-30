-- ============================================================
-- Northwind Business Status Dashboard — Week 4
-- SQL Data Analytics Bootcamp
-- Reference date: 2021-09-19 (last available order date)
-- Reporting window: trailing 12 months (2020-10 ~ 2021-09)
-- ============================================================


-- ------------------------------------------------------------
-- Step 0: Confirm data range (used to set the reference point)
-- ------------------------------------------------------------
SELECT 
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM Orders;


-- ============================================================
-- SECTION 1: Sales
-- ============================================================

-- Chart 1: Monthly revenue trend (last 12 months)
SELECT 
    DATE_FORMAT(o.OrderDate, '%Y-%m') AS OrderMonth,
    SUM(od.UnitPrice * od.Quantity) AS MonthlyRevenue
FROM Orders o
INNER JOIN OrderDetail od ON o.Id = od.OrderId
WHERE o.OrderDate >= '2020-10-01' AND o.OrderDate <= '2021-09-19'
GROUP BY OrderMonth
ORDER BY OrderMonth;


-- Chart 2: Month-over-month revenue growth (%) — complete months only
-- Split into Growth_Up / Growth_Down so the dashboard can color-code
-- increases vs. decreases (this MySQL version has no window functions,
-- so a self-join is used to look up the previous month's revenue).
SELECT 
    t1.OrderMonth,
    CASE WHEN MoMGrowthPct >= 0 THEN MoMGrowthPct ELSE NULL END AS Growth_Up,
    CASE WHEN MoMGrowthPct < 0 THEN MoMGrowthPct ELSE NULL END AS Growth_Down
FROM (
    SELECT 
        t1.OrderMonth,
        ROUND(100.0 * (t1.MonthlyRevenue - t2.MonthlyRevenue) / t2.MonthlyRevenue, 1) AS MoMGrowthPct
    FROM (
        SELECT 
            DATE_FORMAT(o.OrderDate, '%Y-%m') AS OrderMonth,
            SUM(od.UnitPrice * od.Quantity) AS MonthlyRevenue
        FROM Orders o
        INNER JOIN OrderDetail od ON o.Id = od.OrderId
        GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
    ) t1
    LEFT JOIN (
        SELECT 
            DATE_FORMAT(o.OrderDate, '%Y-%m') AS OrderMonth,
            SUM(od.UnitPrice * od.Quantity) AS MonthlyRevenue
        FROM Orders o
        INNER JOIN OrderDetail od ON o.Id = od.OrderId
        GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
    ) t2 
        ON t2.OrderMonth = DATE_FORMAT(
            DATE_SUB(STR_TO_DATE(CONCAT(t1.OrderMonth, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), 
            '%Y-%m'
        )
    -- 2021-09 excluded: it's a partial month (19 days) and would distort
    -- the growth calculation against a full prior month.
    WHERE t1.OrderMonth BETWEEN '2020-10' AND '2021-08'
) t1
ORDER BY t1.OrderMonth;


-- ============================================================
-- SECTION 2: Orders & Shipping
-- ============================================================

-- Chart 3: Monthly order volume trend (last 12 months)
SELECT 
    DATE_FORMAT(OrderDate, '%Y-%m') AS OrderMonth,
    COUNT(DISTINCT Id) AS OrderCount
FROM Orders
WHERE OrderDate >= '2020-10-01' AND OrderDate <= '2021-09-19'
GROUP BY DATE_FORMAT(OrderDate, '%Y-%m')
ORDER BY OrderMonth;


-- Chart 4: Shipping status breakdown (ShippedDate vs. RequiredDate)
SELECT 
    CASE 
        WHEN ShippedDate IS NULL THEN 'Not Shipped'
        WHEN ShippedDate <= RequiredDate THEN 'On Time'
        ELSE 'Delayed'
    END AS ShippingStatus,
    COUNT(*) AS OrderCount
FROM Orders
WHERE OrderDate >= '2020-10-01' AND OrderDate <= '2021-09-19'
GROUP BY ShippingStatus;


-- ============================================================
-- SECTION 3: Category Mix
-- ============================================================

-- Chart 5: Revenue share by category (last 12 months)
-- ORDER BY ASC because Redash's pie chart renders counter-clockwise
-- by default; ascending order makes it read as descending when viewed
-- clockwise from 12 o'clock (Direction is also set to "Clockwise" in
-- the visualization editor).
SELECT 
    cat.CategoryName,
    SUM(od.UnitPrice * od.Quantity) AS CategoryRevenue
FROM OrderDetail od
INNER JOIN Orders o ON od.OrderId = o.Id
INNER JOIN Product p ON od.ProductId = p.Id
INNER JOIN Category cat ON p.CategoryId = cat.Id
WHERE o.OrderDate >= '2020-10-01' AND o.OrderDate <= '2021-09-19'
GROUP BY cat.CategoryName
ORDER BY CategoryRevenue ASC;


-- ============================================================
-- SECTION 4: Inventory
-- ============================================================

-- Chart 6: Products at or below reorder level (active products only)
SELECT 
    p.ProductName,
    cat.CategoryName,
    p.UnitsInStock,
    p.UnitsOnOrder,
    p.ReorderLevel
FROM Product p
INNER JOIN Category cat ON p.CategoryId = cat.Id
WHERE p.Discontinued = 0
  AND p.UnitsInStock <= p.ReorderLevel
ORDER BY p.UnitsInStock ASC;


-- ============================================================
-- SECTION 5: Customers
-- ============================================================

-- Chart 7: Revenue distribution by country (last 12 months)
SELECT 
    c.Country,
    COUNT(DISTINCT c.Id) AS CustomerCount,
    SUM(od.UnitPrice * od.Quantity) AS Revenue
FROM Customer c
INNER JOIN Orders o ON c.Id = o.CustomerId
INNER JOIN OrderDetail od ON o.Id = od.OrderId
WHERE o.OrderDate >= '2020-10-01' AND o.OrderDate <= '2021-09-19'
GROUP BY c.Country
ORDER BY Revenue DESC;


-- Chart 8: Active vs. dormant customers
-- "Active" = placed at least one order within the trailing 12 months.
SELECT
    CASE 
        WHEN LastOrderDate >= '2020-10-01' THEN 'Active'
        ELSE 'Dormant'
    END AS CustomerStatus,
    COUNT(*) AS CustomerCount
FROM (
    SELECT 
        CustomerId,
        MAX(OrderDate) AS LastOrderDate
    FROM Orders
    WHERE CustomerId IS NOT NULL
    GROUP BY CustomerId
) t
WHERE LastOrderDate <= '2021-09-19'
GROUP BY CustomerStatus;
