# Netflix Movies and TV Shows Data Analysis using SQL

![](https://github.com/newgjkk/NETFLIX_content_analysis/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- **Analyze the distribution of content types (movies vs. TV shows)**: Understand the proportion of movies and TV shows available on the platform, which can help in evaluating content diversity.
  
- **Identify the most prevalent ratings for movies and TV shows**: Assess which ratings are most common to better align content offerings with audience expectations and regulatory standards.

- **List and analyze content based on release years, countries, and durations**: Highlight trends over time and across different regions, allowing Netflix to tailor content acquisition strategies to different markets.

- **Explore and categorize content based on specific criteria and keywords**: Identify thematic elements and genres that resonate with viewers, which can guide future content creation and marketing efforts.

- **Evaluate audience engagement**: By analyzing viewership trends and ratings, we aim to recommend improvements in content strategy that align with viewer preferences.

- **Understand competitive positioning**: Compare Netflix's offerings with industry benchmarks to identify areas of strength and opportunities for growth.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/rahulvyasm/netflix-movies-and-tv-shows)

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
```

## Business Problems and Solutions

### Count number of Movies vs TV Shows

```sql
SELECT type as Category,
		COUNT(*) as number_of_contents
FROM netflix
GROUP BY type;

```


### Find the Most Common Rating for Movies and TV Shows

```sql
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
```


### List All Movies Released in year 2020

```sql
SELECT title as movie_released_on_2020
FROM netflix
WHERE type = 'Movie' AND release_year = 2020;
```



### TOP 5 countires with the most content on netflix

```sql
SELECT 
	UNNEST(STRING_TO_ARRAY(country,', ')) as country_extracted,
	COUNT(*) as total_content
	
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;
```



### Identify the Longest Movie

```sql
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

```



### Find Contents Added in the Last 5 Years

```sql
SELECT *
FROM netflix
WHERE 
    (CASE 
        WHEN date_added ~ '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$' THEN TO_DATE(date_added, 'DD-Mon-YY')
        WHEN date_added ~ '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$' THEN TO_DATE(date_added, 'FMMonth DD, YYYY')
    END) >= CURRENT_DATE - INTERVAL '5 years'
ORDER BY show_id;
```



### Movie/TV show directed by 'Rajiv Chilaka'

```sql
SELECT *
FROM netflix
WHERE director ILIKE '%Rajiv Chilaka%'
```

###  INFO OF ANY Movie/TV show where 'Kimiko Glenn' is casted

```sql
WITH cte_casted AS(
SELECT *,
	UNNEST(STRING_TO_ARRAY(casts,', ')) as casted
FROM netflix
)
	
SELECT *
FROM cte_casted
WHERE 
	'Kimiko Glenn' = casted;
```

### List All TV Shows with More Than 5 Seasons

```sql
SELECT 
	*,
	SPLIT_PART(duration, ' ',1) AS seasons
FROM netflix
WHERE type = 'TV Show'
		AND CAST(SPLIT_PART(duration, ' ',1) AS INT) > 5;
```

**Objective:** Identify TV shows with more than 5 seasons.

### Content in Each Genere

```sql
CREATE VIEW vw_genere AS
SELECT SPLIT_PART(listed_in, ',',1) AS category,
		count(*) as amount
FROM netflix
GROUP BY SPLIT_PART(listed_in, ',',1) 
ORDER BY count(*) DESC;

SELECT * 
FROM vw_genere
```

 
### Content AVG number of content realsed in UNITED STATES
return top 5 year with highest avg content release!

```sql
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
```



### Find Detail of NETFLIX DATA SET by type/category and EXTRACT 

```sql
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
```



### List of MOIVE/TV SHOWS that were added AFTER 2 year of releasement

```sql
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
```



### Average TIME That Takes to Added on NETFLIX by TYPE

```sql
SELECT type, ROUND(AVG(behind),2) || ' years' as average_duration_to_added
FROM added_late
WHERE behind>=0
GROUP BY type;
```



### Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in United States

```sql
SELECT 
    UNNEST(STRING_TO_ARRAY(casts, ',')) AS actor,
    COUNT(*)
FROM netflix
WHERE country = 'United States'
GROUP BY actor
ORDER BY COUNT(*) DESC
LIMIT 10;
```



### Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
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
```



## Findings

- **Content Addition Time**: Movies take an average of 6 years to be added to the database, while TV shows take approximately 2.12 years. This indicates that there is room for improvement in the content management and update processes for movies.

- **Violent Content Ratio**: Violent content accounts for 4% of the entire dataset. While this is a positive indicator of relatively safe content, there is a need to strengthen family-friendly offerings.

- **Genre Distribution**: Drama and comedy genres dominate the content available on Netflix, indicating that these genres are significantly popular among viewers.

- **Long-Running Content**: A total of 100 TV shows have been identified that have lasted for more than 5 seasons, demonstrating the successful engagement of long-term audiences.

- **Director and Actor Influence**: The impact of directors and actors is crucial for the success of content. Their reputation and experience can positively affect the viewership of titles.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.

## Conclusion
- **Need for Efficient Content Management**: The average addition time of 6 years for movies indicates the need for improved efficiency in the content review and approval processes. Streamlining these processes can lead to quicker updates and increased customer satisfaction.

- **Expansion of Family-Friendly Content**: While the 4% ratio of violent content is a positive indicator, it is important to enhance family-friendly offerings to attract a broader audience across different age groups.

- **Genre-Focused Content Strategy**: Leveraging the strengths of drama and comedy genres by acquiring more content in these categories and enhancing marketing efforts can help attract a larger viewership.

- **Utilization of Long-Running Content**: Promoting long-running TV shows can enhance viewer loyalty and engagement. Focusing marketing strategies around these titles can maximize their appeal.

- **Capitalizing on Popular Directors and Actors**: Collaborating with well-known directors and actors can improve content quality and provide opportunities to draw in their fan bases, leading to increased viewership.
## Suggestion

**Business Strategy and Direction Suggestions**
Revamping Content Management Processes: Redesign and automate content management processes to reduce the time taken for movies and TV shows to be added to the database.

Diversifying Content Offerings: Expand the range of family-friendly content to appeal to viewers of all ages.

Strengthening Genre-Specific Content: Develop targeted marketing strategies around drama and comedy genres to capture viewer interest effectively.

Marketing Long-Running Content: Utilize successful long-running TV shows to maintain popularity and viewer engagement through strategic promotions.

Star Casting Strategy: Enhance content quality by collaborating with popular directors and actors, leveraging their influence to attract more viewers.



