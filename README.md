# Swiggy Sales Analysis: Data Analytics SQL Project

## Project Overview
This project analyzes a dataset of **197,430 food delivery records** from Swiggy, spanning states, cities, restaurants, categories, and dishes across India. 

**Key Performance Metrics**:
- **Total Orders**: 197,430
- **Total Revenue**: 53.01 Million INR
- **Average Dish Price**: 268.51 INR
- **Average Rating**: 4.34

The end-to-end workflow includes data cleaning and validation, dimensional modeling using a **Star Schema** for optimized analytics, and development of actionable KPIs and insights covering sales trends, location performance, food popularity, customer spending patterns, and rating distributions.

## Project Objectives
- Ensure high data quality through null checks, blank string detection, and duplicate removal
- Build a scalable **Star Schema** dimensional model for efficient querying and reporting
- Deliver core KPIs and deep-dive business analyses aligned with food delivery performance metrics

## Analytical Objectives
- Time-based trends (monthly, quarterly, yearly, day-of-week)
- Geographic insights (top cities, state revenue contribution)
- Food & restaurant performance (top restaurants, categories, dishes, cuisine ratings)
- Customer behavior (price range buckets)
- Customer satisfaction (rating distribution)

## Workflow
1. **Data Cleaning & Validation**  
2. **Star Schema Creation** (Dimensions + Fact Table)  
3. **Data Population**  
4. **KPI & Insight Queries**  
5. **Visualization Recommendations**

**Tech Stack**: SQL Server, Python (pandas, matplotlib for visualization), Jupyter Notebook

---

## Data Cleaning & Validation

### Null Check
```sql
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
```

### Blank/Empty String Check

```sql
SELECT * 
FROM swiggy_data 
WHERE State = '' OR City = '' OR Restaurant_Name = '' OR Location = '' 
   OR Category = '' OR Dish_Name = '' OR Price_INR = '' OR Rating = '' OR Rating_Count = '';
```
### Duplicate Detection
```sql
SELECT 
    State, City, Order_date, Restaurant_Name, Location, Category, Dish_Name, 
    Price_INR, Rating, Rating_Count, COUNT(*) AS CNT 
FROM swiggy_data 
GROUP BY 
    State, City, Order_Date, Restaurant_Name, Location, Category, Dish_Name, 
    Price_INR, Rating, Rating_Count 
HAVING COUNT(*) > 1;
```

### Duplicate Removal
```sql
WITH CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY State, City, Order_date, Restaurant_Name, Location, 
                            Category, Dish_Name, Price_INR, Rating, Rating_Count 
               ORDER BY (SELECT NULL)
           ) AS rn 
    FROM swiggy_data
)
DELETE FROM CTE WHERE rn > 1;
```

### Dimensional Modeling – Star Schema
#### Dimension Tables
- dim_date – `date_id`, `Full_Date`, `Year`, `Month`, `Month_Name`, `Quarter`, `Day`, `Week`
- dim_location – `location_id`, `State`, `City`, `Location`
- dim_restaurant – `restaurant_id`, `Restaurant_Name`
- dim_category – `category_id`, `Category`
- dim_dish – `dish_id`, `Dish_Name`

#### Fact Table

- fact_swiggy_orders – `order_id`, `foreign keys to all dimensions`,` Price_INR, Rating`, `RatingCount`

### Create Dimension Tables
```sql
CREATE TABLE dim_date (
    date_id INT IDENTITY(1,1) PRIMARY KEY,
    Full_Date DATE,
    Year INT, Month INT, Month_Name VARCHAR(20),
    Quarter INT, Day INT, Week INT
);

CREATE TABLE dim_location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    State VARCHAR(100), City VARCHAR(100), Location VARCHAR(200)
);

CREATE TABLE dim_restaurant (
    restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
);

CREATE TABLE dim_category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    Category VARCHAR(200)
);

CREATE TABLE dim_dish (
    dish_id INT IDENTITY(1,1) PRIMARY KEY,
    Dish_Name VARCHAR(200)
);
```

### Create Fact Table
```sql
CREATE TABLE fact_swiggy_orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    date_id INT,
    Price_INR DECIMAL(10,2),
    Rating DECIMAL(4,2),
    RatingCount INT,
    location_id INT, restaurant_id INT, category_id INT, dish_id INT,
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);
```

### Populate Dimensions
```sql
INSERT INTO dim_date (FULL_DATE, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT Order_Date, YEAR(Order_Date), MONTH(Order_Date), 
       DATENAME(MONTH, Order_Date), DATEPART(QUARTER, Order_Date), 
       DAY(Order_Date), DATEPART(WEEK, Order_Date) 
FROM swiggy_data WHERE Order_Date IS NOT NULL;

INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT State, City, Location FROM swiggy_data;

INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT Restaurant_Name FROM swiggy_data;

INSERT INTO dim_category (Category)
SELECT DISTINCT Category FROM swiggy_data;

INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT Dish_Name FROM swiggy_data;
```
### Populate Fact Table
```sql
INSERT INTO fact_swiggy_orders (date_id, Price_INR, Rating, RatingCount, 
                               location_id, restaurant_id, category_id, dish_id)
SELECT 
    dd.date_id, s.Price_INR, s.Rating, s.Rating_Count,
    dl.location_id, dr.restaurant_id, dc.category_id, dsh.dish_id 
FROM swiggy_data s
JOIN dim_date dd ON dd.FULL_DATE = s.Order_Date
JOIN dim_location dl ON dl.State = s.State AND dl.City = s.City AND dl.Location = s.Location
JOIN dim_restaurant dr ON dr.Restaurant_Name = s.Restaurant_Name
JOIN dim_category dc ON dc.Category = s.Category
JOIN dim_dish dsh ON dsh.Dish_Name = s.Dish_Name;
```
### Model:

<img width="819" height="775" alt="Swiggy_ERD" src="https://github.com/user-attachments/assets/2588f2ba-d047-4985-9d1f-04aad609f89a" />


### KPI Development & Insights
#### Basic KPIs

```sql
-- Total Orders
SELECT COUNT(*) AS Total_Orders FROM fact_swiggy_orders;

-- Total Revenue (Million INR)
SELECT FORMAT(SUM(CONVERT(FLOAT, Price_INR))/1000000, 'N2') + ' Million INR' AS Total_Revenue 
FROM fact_swiggy_orders;

-- Average Dish Price
SELECT FORMAT(AVG(CONVERT(FLOAT, Price_INR)), 'N2') + ' INR' AS Avg_Dish_Price 
FROM fact_swiggy_orders;

-- Average Rating
SELECT ROUND(AVG(Rating), 2) AS Avg_Rating FROM fact_swiggy_orders;
```
### Deep-Dive Analyses
#### Date-Based
```sql
-- Monthly Trends
SELECT d.Year, d.Month_Name, COUNT(*) AS Orders
FROM fact_swiggy_orders f JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year, d.Month, d.Month_Name ORDER BY COUNT(*) DESC;

-- Day of Week
SELECT DATENAME(WEEKDAY, d.Full_Date) AS Day_Name, COUNT(*) AS Orders
FROM fact_swiggy_orders f JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.Full_Date), DATEPART(WEEKDAY, d.Full_Date)
ORDER BY DATEPART(WEEKDAY, d.Full_Date);
```

#### Location-Based 
```sql
-- Top 10 Cities
SELECT TOP 10 l.City, COUNT(*) AS Orders
FROM fact_swiggy_orders f JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.City ORDER BY Orders DESC;

-- State Revenue
SELECT TOP 10 l.State, SUM(f.Price_INR) AS Revenue
FROM fact_swiggy_orders f JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.State ORDER BY Revenue DESC;
```

#### Food Performance
```sql
-- Top Categories
SELECT c.Category, COUNT(*) AS Orders
FROM fact_swiggy_orders f JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.Category ORDER BY Orders DESC;

-- Cuisine Performance
SELECT c.Category, COUNT(*) AS Orders, AVG(f.Rating) AS Avg_Rating
FROM fact_swiggy_orders f JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.Category ORDER BY Orders DESC;
```

#### Customer Spending
```sql
SELECT 
    CASE 
        WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 399 THEN '300-399'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 400 AND 499 THEN '400-499'
        ELSE '500+' 
    END AS Price_Range, 
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders
GROUP BY 
    CASE 
        WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100-199'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200-299'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 399 THEN '300-399'
        WHEN CONVERT(FLOAT, Price_INR) BETWEEN 400 AND 499 THEN '400-499'
        ELSE '500+' 
    END
ORDER BY Total_Orders DESC;
```

#### Ratings Distribution
```sql
SELECT Rating, COUNT(*) AS Rating_Count
FROM fact_swiggy_orders
GROUP BY Rating
ORDER BY Rating_Count DESC;
```
### Key Insights

#### Time Trends
- Peak months: June (highest), followed by May and July
- Strongest quarter: Q2 (highest orders)
- Busiest days: Fridays and Thursdays; Sundays lowest (~7% drop)

#### Location Performance
- Top cities by orders: Major metros dominate (led by high-volume urban centers)
- Revenue leaders: High-population states contribute disproportionately

#### Food & Restaurant Performance
- Top restaurants: Leading chains (McDonald's, KFC) drive significant order volume
- Top categories: Balanced distribution across Indian, Chinese, with similar volumes
- Most ordered dishes: Consistent popularity in core items
- Cuisine ratings: Uniform quality (averages close across categories)

#### Customer Spending
- Dominant price ranges: 100–199 and 200–299 (combined >50% of orders)
- Mid-range preference clear; lower volume in premium (500+) buckets

#### Ratings Distribution
- Overall average: ~4.34 with strong positive skew
- Majority ratings ≥4.3; minimal low ratings

### Recommendations
- **Capitalize on peaks**: Run promotions and increase capacity during Q2 and Thursdays/Fridays to capture 10–15% additional orders
- **Focus growth markets**: Prioritize marketing and partnerships in top cities and revenue-leading states
- **Leverage top performers**: Promote high-volume restaurants, categories, and dishes via bundles to drive upsell and loyalty
- **Shift spending upward**: Use combos and prompts to move 100–199 orders into 200–299 range, targeting +20–30 INR AOV increase
- **Sustain quality**: Monitor and improve any lower-rated categories/outlets to maintain/exceed 4.4 average

### Tech & Deliverables
- **Database**: SQL Server (cleaning scripts, Star Schema tables, KPI queries)
- **Notebook**: Jupyter Notebook with full execution, results, and visualization recommendations
- **Files Included**: `Swiggy_Data.csv`, SQL scripts, Jupyter notebook

**Skills Demonstrated**  
Advanced SQL • Data Cleaning • ETL • Dimensional Modeling • Business Analytics







