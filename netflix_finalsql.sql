


------------------ Count number of Movies vs TV Shows -------------------
SELECT type as Category,
		COUNT(*) as number_of_contents
FROM netflix
GROUP BY type;



----------------- most common rating for movies and TV shows
WITH cte_sub AS (
SELECT 
	type,
	rating,
	count(*) as content,
	DENSE_RANK() OVER(PARTITION BY type ORDER BY count(*) DESC) as ranking
FROM netflix

GROUP BY type, rating
ORDER BY type, count(*) DESC
)

SELECT type,rating
FROM cte_sub
WHERE ranking = 1;


-----------------3    List of movies relaesd in year 2020 --------------------
SELECT title as movie_released_on_2020
FROM netflix
WHERE type = 'Movie' AND release_year = 2020;

----------------4  TOP 5 countires with the most content on netflix

SELECT 
	UNNEST(STRING_TO_ARRAY(country,', ')) as country_extracted,
	COUNT(*) as total_content
	
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


------------  55 Indentify longest Moive --------------------
SELECT 
    title,
	CAST(SUBSTRING(duration FROM '^[0-9]+') AS INTEGER) as duration_in_min
FROM 
    netflix
WHERE 
    type = 'Movie' 
		AND duration IS NOT NULL
ORDER BY 
    CAST(SUBSTRING(duration FROM '^[0-9]+') AS INTEGER) DESC;    --extract only number from column

------------ 6. Content added in the last 5 years
--------- data set have mixed data type so CASE was used to extract date---------- 
SELECT *
FROM netflix
WHERE 
    (CASE 
        WHEN date_added ~ '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$' THEN TO_DATE(date_added, 'DD-Mon-YY')
        WHEN date_added ~ '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$' THEN TO_DATE(date_added, 'FMMonth DD, YYYY')
    END) >= CURRENT_DATE - INTERVAL '5 years'
ORDER BY show_id;
----------- 7. movie/TV show directed by 'Rajiv Chilaka' ------------------------
SELECT *
FROM netflix
WHERE director ILIKE '%Rajiv Chilaka%'



-------- INFO OF ANY Movie/TV show where 'Kimiko Glenn' is casted ----------
WITH cte_casted AS(
SELECT *,
	UNNEST(STRING_TO_ARRAY(casts,', ')) as casted
FROM netflix
)
	
SELECT *
FROM cte_casted
WHERE 
	'Kimiko Glenn' = casted;

------------ 8. All tv shows with more than 5 seasons
SELECT 
	*,
	SPLIT_PART(duration, ' ',1) AS seasons
FROM netflix
WHERE type = 'TV Show'
		AND CAST(SPLIT_PART(duration, ' ',1) AS INT) > 5;


----- 9. content in each genere
CREATE VIEW vw_genere AS
SELECT SPLIT_PART(listed_in, ',',1) AS category,
		count(*) as amount
FROM netflix
GROUP BY SPLIT_PART(listed_in, ',',1) 
ORDER BY count(*) DESC;

SELECT * 
FROM vw_genere

------ 10. content avg number of content realsed in UNITED STATES
CREATE VIEW difference  AS
SELECT 
	*,
	(CASE 
        WHEN date_added ~ '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$' THEN TO_DATE(date_added, 'DD-Mon-YY')
        WHEN date_added ~ '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$' THEN TO_DATE(date_added, 'FMMonth DD, YYYY')
    END) as added_date
FROM netflix
WHERE country ='United States';

SELECT * FROM difference;

----------------- HOW MUCH OF data exist on NETFLIX DATA SET by type/category ----------
CREATE TABLE category_detail AS(
SELECT
	n.type,
	g.category,
	count(*) as amount,
	RANK() OVER(PARTITION BY type ORDER BY count(*)DESC)
FROM 
    netflix n
JOIN 
    vw_genere g ON SPLIT_PART(n.listed_in, ',', 1) = g.category  
GROUP BY
    n.type, g.category
);

SELECT * FROM category_detail;
--------------- LIST OF MOIVE/TV SHOWS that were added AFTER 2 year of releasement -------
CREATE TABLE added_late AS(
SELECT
	n.type,
	n.title,
	CAST(EXTRACT(YEAR FROM d.added_date) as INT) as add_date,
	n.release_year,
	CAST(EXTRACT(YEAR FROM d.added_date) as INT) - n.release_year  as behind
FROM netflix n
	JOIN difference d ON n.show_id = d.show_id
);
SELECT *
FROM added_late
WHERE behind > 2
ORDER BY type,behind DESC;


-------------- AVG TIME THAT TAKES TO ADD on NETFLIX by TYPE -----------
SELECT type, ROUND(AVG(behind),2) || ' years' as average_duration_to_added
FROM added_late
WHERE behind>=0
GROUP BY type;


------------- Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in United States --------- 
SELECT 
    UNNEST(STRING_TO_ARRAY(casts, ',')) AS actor,
    COUNT(*)
FROM netflix
WHERE country = 'United States'
GROUP BY actor
ORDER BY COUNT(*) DESC
LIMIT 10;

------------ Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords -------------------


SELECT 
    category,
    COUNT(*) AS content_count
FROM (
    SELECT 
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY category;
