select * from fact_stamps;
select * from dim_districts;

/* How does the revenue generated from document registration vary across districts in Telangana?
 List down the top 5 districts that showed the highest document registration revenue growth between 
 FY 2019 and 2022. */

select dist_code, district, sum(documents_registered_rev) as total_document_registration_revenue
from fact_stamps
join dim_districts
using(dist_code)
where month in (2019, 2020, 2021, 2022)
group by dist_code, district
order by total_document_registration_revenue desc
limit 5;

/* How does the revenue generated from document registration compare to the revenue generated from e-stamp challans
 across districts? List down the top 5 districts where e-stamps revenue contributes significantly more to the revenue 
 than the documents in FY 2022? */
 
 select dist_code, district, sum(documents_registered_rev) as total_document_registration_revenue,
	sum(estamps_challans_rev) as total_estamps_revenue
from fact_stamps
join dim_districts
using(dist_code)
where month in (2022)
group by dist_code, district
having total_estamps_revenue > total_document_registration_revenue
limit 5;

/* Categorize districts into three segments based on their stamp registration 
revenue generation during the fiscal year 2021 to 2022  */

select dist_code, district, sum(estamps_challans_rev) as total_estamps_revenue,
CASE
	when sum(estamps_challans_rev)  <900000000 then "Low Revenue"
    when sum(estamps_challans_rev)  >900000000 and sum(estamps_challans_rev)  <3000000000 then "Medium Revenue"
    else "High Revenue"
END as Revenue_segment
from fact_stamps
join dim_districts
using(dist_code)
where month in (2021,2022)
group by dist_code, district
order by total_estamps_revenue desc;
