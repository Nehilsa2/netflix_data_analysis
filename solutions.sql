-- drop table IF EXISTS netflix;

-- Create table netflix(
-- show_id varchar(15) unique,
-- type varchar(20),
-- title varchar(150),
-- director varchar(250),
-- casts varchar(1000),
-- country varchar(150),
-- date_added varchar(50),
-- release_year int,
-- rating varchar(20),
-- duration varchar(15),
-- listed_in varchar(100),
-- description varchar(300)
-- );


SELECT * FROM NETFLIX ;

-- 1. count number of movies vs tv shows

select type,count(*) as count from netflix group by type;

-- 2. Find most common rating for movies anf tv shows

with cte as (select type ,rating,count(*) as count,dense_rank() over(partition by type order by count(*) desc) as ranking from netflix group by type,rating order by type, count desc)

select type ,rating from cte where ranking =1;

-- 3. List all movies released in a specific year(eg. 2020)

drop function if exists get_movies_from_year;

create or replace function get_movies_from_year(s_year int)
returns table (title TEXT,s_year int) AS $$
select title,s_year from netflix where type ilike 'movie'
and release_year = s_year;
$$ language sql stable;

select * from get_movies_from_year(2020);


-- 4.Find the top 5 countries with most content on netflix

select unnest(string_to_array(country,',')) as country , count(show_id ) as count from netflix group by 1 order by count desc limit 5 ;


-- 5.indetify the longest movie

SELECT title, duration
FROM netflix
WHERE type ILIKE 'movie'
and duration is not null
ORDER BY split_part(duration, ' ', 1)::int DESC
LIMIT 1;

-- 6.find content added in last 5 year

with cte as (select *,to_Date(date_Added,'month , dd, yyyy') as date from netflix)
select * from cte where date >= current_date - interval '5 years';


-- 7. Find all the movies / tv shows directed by 'rajiv chilaka'

select * from netflix where director ilike 'rajiv chilaka';

-- 8. find all tv shows which has more than 5 seasons

select * from netflix where type ilike 'tv show' and split_part(duration,' ',1)::int > 5;

-- 9.count number of content items in each genre

WITH cte AS (
    SELECT TRIM(unnest(string_to_array(listed_in, ','))) AS genre
    FROM netflix
)
SELECT genre, COUNT(*) AS total_content_per_genre
FROM cte
GROUP BY genre
ORDER BY total_content_per_genre DESC;


-- 10 Find the average release year for content produced in a specific country

with cte as (select release_year , unnest(string_to_array(country,','))::int as country  from netflix)

select country , round(avg(release_year),0) as avg_year from cte group by country;


-- 11. Find each year and the average numbers of content release by india on netflix return top 5 year with highest  avg content release

SELECT 
	country,
	release_year,
	COUNT(show_id) as total_release,
	ROUND(
		COUNT(show_id)::numeric/(SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100 ,2)
		as avg_release
FROM netflix
WHERE country = 'India' 
GROUP BY country, 2
ORDER BY avg_release DESC 
LIMIT 5

-- - 12. List all movies that are documentaries
SELECT * FROM netflix
WHERE listed_in LIKE '%Documentaries'



-- 13. Find all content without a director
SELECT * FROM netflix
WHERE director IS NULL


-- 14. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT * FROM netflix
WHERE 
	casts LIKE '%Salman Khan%'
	AND 
	release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10


-- 15. Find the top 10 actors who have appeared in the highest number of movies produced in India.



SELECT 
	UNNEST(STRING_TO_ARRAY(casts, ',')) as actor,
	COUNT(*)
FROM netflix
WHERE country = 'India'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

/*
Question 16:
Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category.
*/


SELECT 
    category,
	TYPE,
    COUNT(*) AS content_count
FROM (
    SELECT 
		*,
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY 1,2
ORDER BY 2


-- 17) Top 10 genres by number of titles (ranked)
WITH g AS (
  SELECT TRIM(unnest(string_to_array(listed_in, ','))) AS genre
  FROM netflix
)
SELECT genre, COUNT(*) AS cnt,
       DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
FROM g
GROUP BY genre
ORDER BY cnt DESC
LIMIT 10;

-- 18) Movies vs TV Shows per year (pivot with FILTER)
SELECT release_year,
       COUNT(*) FILTER (WHERE type ILIKE 'movie')    AS movies,
       COUNT(*) FILTER (WHERE type ILIKE 'tv show')  AS tv_shows
FROM netflix
GROUP BY release_year
ORDER BY release_year;

-- 19) Running cumulative count of Indian titles by year
WITH y AS (
  SELECT release_year, COUNT(*) AS cnt
  FROM netflix
  CROSS JOIN LATERAL unnest(string_to_array(country, ',')) c(ctry)
  WHERE TRIM(ctry) = 'India'
  GROUP BY release_year
)
SELECT release_year,
       cnt,
       SUM(cnt) OVER (ORDER BY release_year) AS cum_cnt
FROM y
ORDER BY release_year;

-- 20) Year-over-year growth in total titles
WITH y AS (
  SELECT release_year, COUNT(*) AS cnt
  FROM netflix
  GROUP BY release_year
)
SELECT release_year,
       cnt,
       cnt - LAG(cnt) OVER (ORDER BY release_year) AS yoy_growth
FROM y
ORDER BY release_year;

-- 21) Longest movie per year
WITH m AS (
  SELECT *,
         split_part(duration,' ',1)::int AS minutes
  FROM netflix
  WHERE type ILIKE 'movie' AND duration ~ '^[0-9]+'
)
SELECT release_year, title, minutes
FROM (
  SELECT release_year, title, minutes,
         ROW_NUMBER() OVER (PARTITION BY release_year ORDER BY minutes DESC) AS rn
  FROM m
) t
WHERE rn = 1
ORDER BY release_year;

-- 22) Directors with ≥5 titles and their average gap (years) between releases
WITH d AS (
  SELECT director, release_year
  FROM netflix
  WHERE director IS NOT NULL
),
gaps AS (
  SELECT director, release_year,
         release_year - LAG(release_year) OVER (PARTITION BY director ORDER BY release_year) AS gap
  FROM d
)
SELECT director,
       COUNT(*) AS titles,
       AVG(gap) FILTER (WHERE gap IS NOT NULL) AS avg_year_gap
FROM gaps
GROUP BY director
HAVING COUNT(*) >= 5
ORDER BY titles DESC;

-- 23) Top 15 actor pairs that co-starred the most
WITH c AS (
  SELECT show_id, TRIM(unnest(string_to_array(cast, ','))) AS actor
  FROM netflix
  WHERE cast IS NOT NULL
),
pairs AS (
  SELECT c1.actor AS a1, c2.actor AS a2
  FROM c c1
  JOIN c c2 USING (show_id)
  WHERE c1.actor < c2.actor
)
SELECT a1, a2, COUNT(*) AS together
FROM pairs
GROUP BY a1, a2
ORDER BY together DESC
LIMIT 15;

-- 24) 90th percentile movie duration (in minutes)
SELECT percentile_cont(0.9) WITHIN GROUP (ORDER BY split_part(duration,' ',1)::int)
FROM netflix
WHERE type ILIKE 'movie' AND duration ~ '^[0-9]+';

-- 25) Share of each country in total catalog (top 20)
WITH c AS (
  SELECT TRIM(unnest(string_to_array(country, ','))) AS country
  FROM netflix
  WHERE country IS NOT NULL
)
SELECT country,
       COUNT(*) AS titles,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM c
GROUP BY country
ORDER BY titles DESC
LIMIT 20;

-- 26) For each rating, ratio Movies : TV Shows
WITH r AS (
  SELECT rating,
         COUNT(*) FILTER (WHERE type ILIKE 'movie')   AS movies,
         COUNT(*) FILTER (WHERE type ILIKE 'tv show') AS tvshows
  FROM netflix
  GROUP BY rating
)
SELECT rating, movies, tvshows,
       CASE WHEN tvshows = 0 THEN NULL ELSE movies::numeric / tvshows END AS movie_tv_ratio
FROM r
ORDER BY movies DESC NULLS LAST;

-- 27) Use GROUPING SETS: counts by (type), (release_year), and (type, release_year)
SELECT type, release_year, COUNT(*)
FROM netflix
GROUP BY GROUPING SETS ((type), (release_year), (type, release_year))
ORDER BY type NULLS LAST, release_year NULLS LAST;

-- 28) First and last Netflix release year per director (with titles count)
SELECT director,
       MIN(release_year) AS first_year,
       MAX(release_year) AS last_year,
       COUNT(*) AS titles
FROM netflix
WHERE director IS NOT NULL
GROUP BY director
ORDER BY titles DESC;

-- 29) Top 10 most frequent 3-word phrases in descriptions
WITH tokens AS (
  SELECT regexp_split_to_array(lower(regexp_replace(description, '[^a-z ]','', 'g')), '\s+') AS words
  FROM netflix
  WHERE description IS NOT NULL
),
tri AS (
  SELECT (words[i]   || ' ' || words[i+1] || ' ' || words[i+2]) AS trigram
  FROM tokens, generate_subscripts(words, 1) AS i
  WHERE i+2 <= array_length(words,1)
)
SELECT trigram, COUNT(*) AS cnt
FROM tri
GROUP BY trigram
ORDER BY cnt DESC
LIMIT 10;

-- 30) For each year, the % of titles tagged “International TV Shows”
WITH g AS (
  SELECT release_year,
         (listed_in ILIKE '%International TV Shows%')::int AS flag
  FROM netflix
)
SELECT release_year,
       ROUND(100.0 * SUM(flag)::numeric / COUNT(*), 2) AS pct_international_tv
FROM g
GROUP BY release_year
ORDER BY release_year;

-- 31) Top 5 years with highest average monthly Indian releases
WITH m AS (
  SELECT release_year,
         date_part('month', to_date(date_added, 'Month DD, YYYY'))::int AS mth,
         COUNT(*) AS cnt
  FROM netflix
  CROSS JOIN LATERAL unnest(string_to_array(country, ',')) c(ctry)
  WHERE TRIM(ctry) = 'India' AND date_added IS NOT NULL
  GROUP BY release_year, mth
)
SELECT release_year, ROUND(AVG(cnt), 2) AS avg_monthly_cnt
FROM m
GROUP BY release_year
ORDER BY avg_monthly_cnt DESC
LIMIT 5;

-- 32) Titles that are both Movie and TV Show (same title across types)
SELECT title
FROM netflix
GROUP BY title
HAVING COUNT(DISTINCT type) > 1;

-- 33) Top 10 countries by distinct directors
WITH c AS (
  SELECT TRIM(unnest(string_to_array(country, ','))) AS country, director
  FROM netflix
  WHERE director IS NOT NULL AND country IS NOT NULL
)
SELECT country, COUNT(DISTINCT director) AS directors
FROM c
GROUP BY country
ORDER BY directors DESC
LIMIT 10;

-- 34) Rank years by #TV Shows, break ties by #Movies
WITH y AS (
  SELECT release_year,
         COUNT(*) FILTER (WHERE type ILIKE 'tv show') AS tv_cnt,
         COUNT(*) FILTER (WHERE type ILIKE 'movie')   AS mv_cnt
  FROM netflix
  GROUP BY release_year
)
SELECT release_year, tv_cnt, mv_cnt,
       RANK() OVER (ORDER BY tv_cnt DESC, mv_cnt DESC) AS rnk
FROM y
ORDER BY rnk;

-- 35) For each genre, top 3 most recent titles
WITH g AS (
  SELECT show_id, title, release_year,
         TRIM(unnest(string_to_array(listed_in, ','))) AS genre
  FROM netflix
),
r AS (
  SELECT genre, title, release_year,
         ROW_NUMBER() OVER (PARTITION BY genre ORDER BY release_year DESC, show_id DESC) AS rn
  FROM g
)
SELECT genre, title, release_year
FROM r
WHERE rn <= 3
ORDER BY genre, release_year DESC;

-- 36) Materialized view to speed up genre counts
CREATE MATERIALIZED VIEW genre_counts AS
SELECT TRIM(unnest(string_to_array(listed_in, ','))) AS genre,
       COUNT(*) AS cnt
FROM netflix
GROUP BY genre;





