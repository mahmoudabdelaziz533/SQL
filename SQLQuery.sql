--inspacting all data
select * 
from dbo.salesdata
--categrical values in column
select distinct status from salesdata
select distinct productline from salesdata
select distinct country from salesdata

--the higest production on sales 
select productline , sum(sales) as revenue
from salesdata
group by productline
order by 2 desc
-- the higst year in sales
select year_id ,sum(sales) as revenue
from salesdata
group by year_id
order by 2 desc

select distinct MONTH_ID 
from salesdata
where year_id = 2005

select dealsize ,sum(sales) as revenue
from salesdata
group by dealsize
order by 2 desc


select month_id ,sum(sales) as revenue ,count(QUANTITYORDERED) frequency
from salesdata
where year_id = 2003
group by month_id
order by 2 desc

select month_id ,productline,sum(sales) as revenue ,count(QUANTITYORDERED) frequency
from salesdata
where month_id = 11 and YEAR_ID = 2004
group by month_id,productline
order by 3 desc

-- who is the best customer RFM analysis 
drop table if exists #rfm
;with rfm as
(
select customername ,sum(sales) monetary ,count(QUANTITYORDERED) frequency,
 max(orderdate) last_purchase_date,
(select max(orderdate) from salesdata ) as last_date ,
DATEDIFF(dd,max(orderdate),(select max(orderdate) from salesdata)) resency 
from salesdata
group by customername

),
rfm_calc as
(
select * ,
 ntile(4) over(order by resency desc) as  rfm_resency,
 ntile(4) over(order by frequency ) as  rfm_frequency,
 ntile(4) over(order by monetary ) as  rfm_monetary
from rfm 
)
select *, rfm_resency+rfm_frequency+rfm_monetary rfm_sum ,
cast(rfm_resency as varchar) +cast(rfm_frequency as varchar) +cast(rfm_monetary as varchar) rfm_sum_string
into #rfm
from rfm_calc


select CUSTOMERNAME, rfm_resency,rfm_frequency,rfm_monetary,rfm_sum ,
case 
      when rfm_sum < 4 then 'lostcustomer'
	  when rfm_sum between 4 and 8 then 'newcustomer'
	  when rfm_sum between 8 and 10 then 'potiential_loyal'
	  when rfm_sum >10 then 'loyal_customer'
	  end customer_segment

from #rfm
order by rfm_sum desc

-- what products are most often by togeather:


select  distinct ordernumber, stuff(
	(select ',' + productcode  
		from salesdata p 
		where ORDERNUMBER in (
			select ordernumber
			from (
				select  ordernumber  ,count(*) n
				from salesdata
				where status = 'shipped' 
				group by ordernumber
				having count(*) = 3
			)m
		) and s.ORDERNUMBER = p.ORDERNUMBER
		for xml path(''))
		,1,1,(''))z
from salesdata	s
order by 2 desc