/* Total Revenue , Average Units per order, Total discount given, Unique Orders
	Total Units Sold , Unique Customers 
*/

Select 
	ROUND( SUM((sod.OrderQTY*sod.UnitPrice)*(1-sod.UnitPriceDiscount)),
		  2) 
			as Total_Revenue, --- Total Revenue 109.846.381.40$
	ROUND(SUM(Orderqty)/COUNT(DISTINCT(sod.Salesorderid))::numeric(10,2),
		  2) 
		as Average_Units_per_order,  -- Average Units Per order = 8.74 
	ROUND(SUM(sod.Orderqty*sod.UnitPrice*sod.UnitPriceDiscount)::numeric(10,2),
		  2) 
		as Total_discount_given, --- Total discount given 527.507,91$
	COUNT(DISTINCT(sod.Salesorderid)) 
		as Unique_orders, --- Unique orders 31.465
	SUM(sod.OrderQty) 
		as Total_units_sold, ---Total Units Sold 274.914$
	Count(DISTINCT(c.customerid)) 
		as Unique_Customer --- Total Customers 19.119
FROM
	Sales.SalesorderDetail as sod 
LEFT Join 
	Sales.salesorderheader as soh 
		On sod.salesorderid = soh.salesorderid
LEFT JOIN 
	Sales.Customer as c 
		On soh.customerid = c.customerid
		
--- Total Revenue by Product Subcategory

Select 
		psc.Name  as SubCategory, /* Subcategory description*/
		ROUND(
			SUM((sod.OrderQTY*sod.UnitPrice)*(1-sod.UnitPriceDiscount)),
			2) as TotalRevenue
From 
	Sales.SalesorderDetail as sod 
	LEFT join Sales.SpecialOfferProduct as sop 
		on sod.productid = sop.productid and sop.specialofferid = sod.specialofferid
	LEFT join Production.ProductProductPhoto as ppp
		on sop.productid = ppp.productid
	LEFT join Production.Product as p 
		on p.productid = ppp.productid
	LEFT join Production.ProductSubCategory as psc
		on p.ProductSubCategoryID = psc.ProductSubCategoryID
GROUP BY 1
Order by 2 DESC


--- Total Revenue by Territory (%)

SELECT 
	st.Name 
		as Territory, 
	ROUND(Sum(subtotal),2) 
		as Total_Revenue_Per_Territory,
	ROUND(Sum(subtotal)/
		  (SELECT 
		   	Sum (Subtotal)
		   FROM 
		   	Sales.Salesorderheader)*100,2) 
				as percentage
FROM 
	Sales.Salesorderheader as soh
LEFT JOIN 
	sales.SalesTerritory as st
		On st.territoryid = soh.territoryid
GROUP BY 
	1
ORDER BY 
	2 Desc
	

--- Total Revenue by quarter

SELECT 
	Extract(year from soh.orderdate) as Year,
	Extract(Quarter from soh.orderdate) as Quarter,
	ROUND(Sum(subtotal),2) as Total_Revenue
FROM 
	Sales.SalesOrderheader as soh
GROUP BY 
	1,2
ORDER BY 
	1,2
	
--- Total Revenue vs Units Sold by category

SELECT 
	pc.Name 
		as Product_Category,
	ROUND(SUM((sod.OrderQTY*sod.UnitPrice)*(1-sod.UnitPriceDiscount)),
			2) as TotalRevenue,
	SUM(sod.OrderQty) 
		as Total_units_sold
FROM 
	Sales.SalesorderDetail as sod 
	LEFT join Sales.SpecialOfferProduct as sop 
		on sod.productid = sop.productid and sop.specialofferid = sod.specialofferid
	LEFT join Production.ProductProductPhoto as ppp
		on sop.productid = ppp.productid
	LEFT join Production.Product as p 
		on p.productid = ppp.productid
	LEFT join Production.ProductSubCategory as psc
		on p.ProductSubCategoryID = psc.ProductSubCategoryID
	LEFT join Production.ProductCategory as pc 
		on psc.productcategoryid = pc.productcategoryid
GROUP BY 1

--- Bikes Net Revelue by color

SELECT 
	p.Color as color,
	ROUND(SUM((sod.OrderQTY*sod.UnitPrice)*(1-sod.UnitPriceDiscount)),
			2) as Bike_Total_Revenue
FROM 
	Sales.SalesorderDetail as sod 
	LEFT join Sales.SpecialOfferProduct as sop 
		on sod.productid = sop.productid and sop.specialofferid = sod.specialofferid
	LEFT join Production.ProductProductPhoto as ppp
		on sop.productid = ppp.productid
	LEFT join Production.Product as p 
		on p.productid = ppp.productid
	LEFT join Production.ProductSubCategory as psc
		on p.ProductSubCategoryID = psc.ProductSubCategoryID
	LEFT join Production.ProductCategory as pc 
		on psc.productcategoryid = pc.productcategoryid
WHERE 
	pc.name = 'Bikes'
GROUP BY 1


--- % Online Sales vs Total Sales


with Online_Sales as (
	Select 
		extract(year from orderdate) as year , 
		ROUND(sum((sod.OrderQTY*sod.UnitPrice)*(1-sod.UnitPriceDiscount)),2) as Online_Sales 
	from 
		sales.salesorderdetail as sod
	LEFT JOIN 
		sales.salesorderheader as soh On soh.salesorderid= sod.salesorderid
	Where 
		Onlineorderflag = 'True' 
	GROUP BY 1
	), 
total_sales as (
	Select 
		Extract(year from orderdate) as year, 
		ROUND(sum((sod.OrderQTY*sod.UnitPrice)*(1-sod.UnitPriceDiscount)),2) as Total_Sales
	From 
		Sales.salesorderdetail as sod
	LEFT JOIN 
		sales.salesorderheader as soh On soh.salesorderid= sod.salesorderid
	GROUP BY 
		1)
Select 
	Total_Sales.year,
	Online_Sales,
	Total_Sales,
	ROUND((Online_Sales/Total_Sales) * 100,2) as Perc_Online_Sales,
	ROUND((100 -((Online_Sales/Total_Sales) * 100 )),2) as Perc_Physical_Sales
From 
	Online_sales
Left join Total_sales On total_sales.year = Online_Sales.year
	



--- Total Tax

with Reven_Tax_Freight as (
	Select 
		Extract(quarter from Orderdate) as Quarter,
		Extract(year from Orderdate) as Year,
		ROUND(Sum(Subtotal),2) as Total_Revenue,
		ROUND(SUM(TaxAmt) ,2) as Total_Tax,
		ROUND(SUM(Freight),2) as Total_Freight
	From 
		Sales.Salesorderheader as soh
	Group by 
		1,2) ,
 COGS as (
	Select
		Extract(quarter from Orderdate) as Quarter,
		Extract(year from orderdate) as year,
		ROUND(SUM(p.StandardCost * Orderqty),2) as COGS
	FROM 
		Sales.salesorderdetail as sod 
	LEFT JOIN 
		Sales.Salesorderheader as soh On soh.salesorderid = sod.salesorderid
	LEFT JOIN 
		Production.Product as p On p.productid = sod.productid
	GROUP BY 
		1,2
	ORDER BY 2,1
)
SELECT 
	Cogs.Year,
	COGS.Quarter, 
	Total_Revenue,
	COGS,
	Total_Tax,
	Total_Freight,
	Total_Revenue - COGS as GrossProfit,
	ROUND((Total_Revenue - COGS)/Total_Revenue ,2) as GrossProfit_perc,
	Total_Revenue - COGS - Total_Tax - Total_Freight as NetRevenue
FROM Reven_Tax_Freight
LEFT JOIN COGS ON COGS.quarter = Reven_Tax_Freight.quarter and cogs.year = Reven_Tax_Freight.year
ORDER BY 1,2

