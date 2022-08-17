select * from dbo.sales_data

---Checking distinct values
select distinct STATUS from dbo.sales_data --PLOT
select distinct YEAR_ID from dbo.sales_data --2003-2005
select distinct PRODUCTLINE from dbo.sales_data -- 7 products
select distinct COUNTRY from dbo.sales_data --19, PLOT
select distinct DEALSIZE from dbo.sales_data --PLOT
select distinct TERRITORY from dbo.sales_data --PLOT

--Sum of sales by product line
select PRODUCTLINE, sum(sales) as Revenue
from dbo.sales_data
group by PRODUCTLINE
order by Revenue desc
--classic cars were best seller

--Checking revenue/sales by year
select YEAR_ID, sum(sales) as Revenue
from dbo.sales_data
group by YEAR_ID
order by Revenue desc
--2005 looks very low compared to the other years. going to check if it was recorded as a full sales year

select distinct MONTH_ID from dbo.sales_data 
where YEAR_ID = 2005
--only had 5 operating months in 2005 (explains drop in sales)
--checking 2004 and 2003

select distinct MONTH_ID from dbo.sales_data 
where YEAR_ID = 2003
order by MONTH_ID asc -- 12 operating months in 2003

select distinct MONTH_ID from dbo.sales_data 
where YEAR_ID = 2004
order by MONTH_ID asc --12 operating months

--Analyzing dealsize compared to sales revenue
select DEALSIZE, sum(sales) as Revenue
from dbo.sales_data
group by DEALSIZE
order by Revenue desc --medium size deals generated the most revenue

--What was the best month for sales in a given year? How much was generated in that month?
select MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from dbo.sales_data
where YEAR_ID = 2004 -- edit year to compare others
group by MONTH_ID
order by Revenue desc
--2003 best month was november by far. Nearly doubled revenue and order frequency from the net best month
--Novemeber again was by far the best month. Something worth looking into

--checking best seller in month of novemeber
select MONTH_ID, PRODUCTLINE, sum(sales) as Revenue, count(ORDERNUMBER)  as Orders
from dbo.sales_data
where YEAR_ID = 2004 and MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE
order by 3 desc
--classic cars lead the way substantially in both 2003 and 2004

--who is the best customer?(using rfm analysis)
--recency: last order date, Frequency: count of total orders, Monetary value: total spend
DROP TABLE IF EXISTS #rfm
;with rfm as
(
	select
		CUSTOMERNAME,
		sum(sales) as MonetaryValue, 
		avg(sales) as AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		 (select max(ORDERDATE) from dbo.sales_data) as Max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from dbo.sales_data)) Recency

	from PortfolioDataBase.dbo.sales_data
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from dbo.sales_data as p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM PortfolioDataBase.dbo.sales_data
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from dbo.sales_data as s
order by 2 desc


---Extra stuff that I am curious about

--What city has the highest number of sales in a specific country?
select city, sum (sales) Revenue
from PortfolioDataBase.dbo.sales_data
where country = 'USA' --can change to view other countries
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from PortfolioDataBase.dbo.sales_data
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc













