SELECT * FROM swiggy_data

--Data validation and Cleaning
--Null Check
SELECT
	SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
	SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
	SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
	SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
	SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
	SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
	SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;


-- Blank or Empty Strings

SELECT *
FROM swiggy_data
WHERE
State='' OR City='' OR Restaurant_Name=''OR Location='' OR Category='' OR Dish_Name=''
OR Price_INR='' OR Rating='' OR Rating_Count='';

-- Duplicate detection

SELECT 
	State, City, Order_date, Restaurant_Name, Location, Category, 
	Dish_Name, Price_INR,Rating, Rating_Count, COUNT (*) as CNT 
	FROM swiggy_data
	GROUP BY
	State, City,Order_Date, Restaurant_Name, Location,Category,
	Dish_Name, Price_INR,Rating, Rating_Count
	HAVING COUNT(*)>1


--Delete Duplication

WITH CTE AS (
SELECT *,ROW_NUMBER() OVER(
	PARTITION BY State, City, Order_date, Restaurant_Name, Location, Category, 
	Dish_Name, Price_INR,Rating, Rating_Count
	ORDER BY (SELECT NULL)
	) AS rn
	FROM swiggy_data
	)
	DELETE FROM CTE WHERE rn>1

--CREATING SCHEMA
--DIMENSION TABLES

--(i) DATE TABLE
CREATE TABLE dim_date (
	date_id INT IDENTITY (1,1) PRIMARY KEY,
	Full_Date DATE,
	Year INT,
	Month INT,
	Month_Name VARCHAR (20),
	Quarter INT,
	Day INT,
	Week INT
	)
	SELECT * FROM dim_date


--(ii) Location Table

CREATE TABLE dim_location(
	location_id INT IDENTITY (1,1) PRIMARY KEY,
	State VARCHAR (100),
	City VARCHAR (100),
	Location VARCHAR (200)
);

--(iii) Restaurant Table

CREATE TABLE dim_restaurant (
	restaurant_id INT IDENTITY (1,1) PRIMARY KEY,
	Restaurant_Name VARCHAR (200)
);

--(iv) Category Table

CREATE TABLE dim_category (
	category_id INT IDENTITY (1,1) PRIMARY KEY,
	Category VARCHAR (200)
);

--(v) Dish Table

CREATE TABLE dim_dish (
	dish_id INT IDENTITY (1,1) PRIMARY KEY,
	Dish_Name VARCHAR (200)
);


--CREATE FACT TABLE
CREATE TABLE fact_swiggy_orders(
	order_id INT IDENTITY (1,1) PRIMARY KEY,
	
	date_id INT,
	Price_INR DECIMAL (10,2),
	Rating DECIMAL (4,2),
	RatingCount INT,

	location_id INT,
	restaurant_id INT,
	category_id INT,
	dish_id INT,

	FOREIGN KEY (date_id) REFERENCES dim_date (date_id),
	FOREIGN KEY (location_id) REFERENCES dim_location (location_id),
	FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant (restaurant_id),
	FOREIGN KEY (category_id) REFERENCES dim_category (category_id),
	FOREIGN KEY (dish_id) REFERENCES dim_dish (dish_id)
);

--INSERT DATA TO ALL TABLES
--DIMENSIONS TABLE

--(i) dim-date
INSERT INTO dim_date(FULL_DATE, Year,Month,Month_Name,Quarter,Day,Week)
SELECT DISTINCT
	Order_Date,
	YEAR (Order_Date),
	MONTH(Order_Date),
	DATENAME(MONTH,Order_Date),
	DATEPART(QUARTER, Order_Date),
	DAY(Order_Date),
	DATEPART(WEEK, Order_Date)
FROM swiggy_data
WHERE Order_Date IS NOT NULL;

SELECT *FROM dim_date

--(ii) dim-location
INSERT INTO dim_location (State,City,Location)
SELECT DISTINCT
	State,
	City,
	Location
FROM swiggy_data;

SELECT * FROM dim_location

--(iii) dim_restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
	Restaurant_Name
FROM swiggy_data;

--(iv) dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT	
	Category
FROM swiggy_data;

--(dim_dish)
INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT	
	Dish_Name
FROM swiggy_data;


-- INSERT DATA TO FACT TABLE AS WELL
INSERT INTO fact_swiggy_orders
(
	date_id,
	Price_INR,
	Rating,
	RatingCount,
	location_id,
	restaurant_id,
	category_id,
	dish_id
)
SELECT 
	dd.date_id,
	s.Price_INR,
	s.Rating,
	s.Rating_Count,

	dl.location_id,
	dr.restaurant_id,
	dc.category_id,
	dsh.dish_id
FROM swiggy_data AS s

JOIN dim_date AS dd
	ON dd.FULL_DATE= s.Order_Date

JOIN dim_location AS dl
	ON dl.State= s.State
	AND dl.City = s.City
	AND dl.Location = s.Location

JOIN dim_restaurant AS dr
	ON dr.Restaurant_Name =s.Restaurant_Name

JOIN dim_category AS dc
	ON dc.Category = s.Category

JOIN dim_dish AS dsh
	ON dsh.Dish_Name= s.Dish_Name;

--GENERATING THE SCHEMA TO GENERATE BUSSINESS INSIGHTS
SELECT * FROM fact_swiggy_orders AS f
JOIN dim_date AS d
	ON f.date_id = d.date_id
JOIN dim_location AS l
	ON f.location_id = l.location_id
JOIN dim_restaurant AS r
	ON f.restaurant_id= r.restaurant_id
JOIN dim_category AS c 
	ON f.category_id=c.category_id
JOIN dim_dish AS dsh 
	ON f.dish_id = dsh.dish_id

--KPI's
-- Total Orders
SELECT COUNT (*) AS Total_Orders
FROM fact_swiggy_orders

--Total Revenue (INR Millions)
SELECT
FORMAT(SUM(CONVERT(FLOAT,Price_INR))/1000000,'N2') + ' INR Millions'
AS Total_Revenue
FROM fact_swiggy_orders

--Average Dish Price
SELECT
FORMAT(AVG(CONVERT(FLOAT,Price_INR)),'N2') + ' INR'
AS Total_Revenue
FROM fact_swiggy_orders

-- Average Rating
SELECT
AVG(Rating)
FROM fact_swiggy_orders

--DEEP-DIVE BUSSINESS ANALYSIS

-- Monthly Order Trends
SELECT
	d.Year,
	d.month,
	d.month_name,
	COUNT (*) AS Total_Orders -- // SUM(Price_INR) AS Total_Revenue
FROM fact_swiggy_orders AS f
JOIN dim_date d 
	ON f.date_id = d.date_id
	GROUP BY d.Year,
	d.Month,
	d.Month_Name
	ORDER BY COUNT(*) DESC --//ORDER BY SUM(Price_INR) DESC

--Quarterly Trend
SELECT
	d.Year,
	d.Quarter,
	COUNT (*) AS Total_Orders 
FROM fact_swiggy_orders AS f
JOIN dim_date d 
	ON f.date_id = d.date_id
	GROUP BY d.Year,
	d.Quarter
	ORDER BY COUNT(*) DESC 

--Yearly Trend
SELECT
	d.Year,
	COUNT (*) AS Total_Orders 
FROM fact_swiggy_orders AS f
JOIN dim_date d 
	ON f.date_id = d.date_id
	GROUP BY d.Year
	ORDER BY COUNT(*) DESC 

-- Orders by Day of Week (Mon-Sun)
SELECT
	DATENAME(WEEKDAY, d.Full_Date) AS Day_name,
	COUNT (*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id= d.date_id
GROUP BY DATENAME(WEEKDAY,D.Full_Date), DATEPART(WEEKDAY, d.Full_Date)
ORDER BY DATEPART (WEEKDAY, d.full_date);

--LOCATION ANALYSIS
--Top 10 Cities by order Volume
SELECT TOP 10
	l.City,
	COUNT (*) AS Total_Orders FROM fact_swiggy_orders f
JOIN dim_location l
	ON l.location_id=f.location_id
	GROUP BY l.City
	ORDER BY COUNT (*) DESC

--Revenue Contribution by States
SELECT TOP 10
	l.State,
	SUM(f.Price_INR)AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_location l
	ON l.location_id=f.location_id
	GROUP BY l.State
	ORDER BY COUNT (*) DESC

-- FOOD PERFORMANCE
--Top 10 restaurants by Order
SELECT TOP 10
	r.Restaurant_Name,
	SUM(f.Price_INR)AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_restaurant r
	ON r.Restaurant_id=f.Restaurant_id
	GROUP BY r.Restaurant_Name
	ORDER BY COUNT (*) DESC

--Top Categories By Order Volume (Based on the Swiggy App Users)
SELECT		-- //TOP 10
	c.Category,
	COUNT (*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_category c 
	ON f.Category_id = c.Category_id
	GROUP BY c.Category
	ORDER BY Total_Orders DESC;

--Most Ordered Dishes
SELECT		-- //TOP 10
	d.Dish_Name,
	COUNT (*) AS Order_Count
FROM fact_swiggy_orders f
JOIN dim_dish d
	ON f.Dish_id = d.dish_id
	GROUP BY d.Dish_Name
	ORDER BY Order_Count DESC;

--Cuisine Performance (Orders +Avg Rating)
SELECT
	c.Category,
	COUNT (*) AS Total_Orders,
	AVG (f.Rating) AS Avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id=c.category_id
GROUP BY c.category
ORDER BY Total_Orders DESC;

--CUSTOMER SPENDING INSIGHTS
--Total Orders by Price Range
SELECT
	CASE	
		WHEN CONVERT(FLOAT,Price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 300 AND 399 THEN '300-399'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 400 AND 499 THEN '400-499'
		ELSE '500+'
	END AS Price_Range,
	COUNT (*) AS Total_Orders
FROM fact_swiggy_orders
GROUP BY 
	CASE
		WHEN CONVERT(FLOAT,Price_INR) < 100 THEN 'Under 100'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 100 AND 199 THEN '100-199'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 200 AND 299 THEN '200-299'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 300 AND 399 THEN '300-399'
		WHEN CONVERT(FLOAT,Price_INR) BETWEEN 400 AND 499 THEN '400-499'
		ELSE '500+'
	END
ORDER BY Total_Orders DESC

-- Rating Count Distribution (1-5)
SELECT
	Rating,
	COUNT (*) AS Rating_Count
FROM fact_swiggy_orders
GROUP BY Rating
ORDER by COUNT (*) DESC;