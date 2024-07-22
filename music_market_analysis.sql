select * from employee
select * from invoice
select * from customer
select * from genre
select * from track
select * from media_type
	
/* Easy */

/* Q1: Who is the senior most employee based on job title? */

select title,first_name,last_name
from employee
order by levels desc
limit 1

/* Q2: Which countries have the most Invoices? */

select billing_country,count(billing_country) as total_invoices
from invoice
group by billing_country
order by total_invoices desc


/* Q3: What are top 3 values of total invoice? */

select total
from invoice
order by total desc
limit 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city,sum(total) as invoice_total
from invoice
group by billing_city
order by invoice_total desc
limit 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select c.customer_id,c.first_name,c.last_name,sum(i.total) as invoice_total
from customer as c
join invoice as i
on c.customer_id=i.customer_id
group by c.customer_id,c.first_name,3
order by invoice_total desc 
limit 1

/* Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select distinct email,first_name,last_name
from customer as c
join invoice as i
on c.customer_id=i.customer_id
join invoice_line as il
on i.invoice_id=il.invoice_id
where track_id in(
	select track_id
    from track as t
    join genre as g
    on t.genre_id=g.genre_id
    where g.name like 'Rock'
    )
order by email

/* or */

select distinct c.email,c.first_name,c.last_name
from customer as c
join invoice as i on c.customer_id=i.customer_id
join invoice_line as il on i.invoice_id=il.invoice_id
join track as t on il.track_id=t.track_id
join genre as g on t.genre_id=g.genre_id
where g.name like 'Rock'
order by email

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select distinct ar.artist_id,ar.name,count(tr.track_id) as total_track
from artist as ar
join album as al on ar.artist_id=al.artist_id
join track as tr on al.album_id=tr.album_id
join genre as gn on tr.genre_id=gn.genre_id
where gn.name like 'Rock'
group by ar.artist_id,2
order by total_track desc
limit 10


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name,milliseconds
from track 
where milliseconds>(select avg(milliseconds) from track)
order by milliseconds desc

/* Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with most_sold_artist as(
	select artist.artist_id as artist_id,artist.name as artist_name,sum(invoice_line.unit_price*invoice_line.quantity) as total_sold
	from invoice_line
	join track on invoice_line.track_id=track.track_id
	join album on track.album_id=album.album_id
	join artist on album.artist_id=artist.artist_id
	group by 1,2
	order by 3 desc
	limit 1
)
select c.customer_id,c.first_name,c.last_name,most_sold_artist.artist_name,sum(invoice_line.unit_price*invoice_line.quantity) as amount_spent
from customer as c
join invoice on c.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
join track on invoice_line.track_id=track.track_id
join album on track.album_id=album.album_id
join most_sold_artist on album.artist_id=most_sold_artist.artist_id
group by 1,2,3,4
order by 5 desc


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1



/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */


WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1
