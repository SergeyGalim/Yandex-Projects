SELECT COUNT(*)
FROM stackoverflow.posts
WHERE post_type_id = 1 
  AND (score > 300
   OR favorites_count >= 100);
----------------------------------------------------------------------------------
SELECT ROUND(AVG(count))
FROM
    (SELECT COUNT(*)
    FROM stackoverflow.posts
    WHERE post_type_id = 1
      AND DATE_TRUNC('day', creation_date)::date BETWEEN '2008-11-01' AND '2008-11-18'
    GROUP BY DATE_TRUNC('day', creation_date)::date) AS cnt_pday;
----------------------------------------------------------------------------------
SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.users AS u
JOIN stackoverflow.badges AS b ON b.user_id = u.id
WHERE b.creation_date::date = u.creation_date::date;
----------------------------------------------------------------------------------
SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON u.id = p.user_id
JOIN stackoverflow.votes AS v on V.post_id = p.id
WHERE u.display_name = 'Joel Coehoorn';
----------------------------------------------------------------------------------
SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id;
----------------------------------------------------------------------------------
SELECT DISTINCT v.user_id,
       COUNT(*)
FROM stackoverflow.votes AS v
JOIN stackoverflow.vote_types AS vt ON vt.id = v.vote_type_id
WHERE vt.name = 'Close'
GROUP BY v.user_id
ORDER BY count DESC,
         user_id DESC
LIMIT 10;         
----------------------------------------------------------------------------------
WITH badge_cnt AS 
   (SELECT user_id,
           COUNT(*) 
   FROM stackoverflow.badges
   WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
   GROUP BY user_id)
   
SELECT *,
       DENSE_RANK() OVER (ORDER BY count DESC) AS rating
FROM badge_cnt
ORDER BY count DESC,
         user_id
LIMIT 10;        
----------------------------------------------------------------------------------
SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title != '' 
  AND score != 0;
----------------------------------------------------------------------------------
WITH badge_cnt AS
   (SELECT user_id,
           COUNT(*)
    FROM stackoverflow.badges
    GROUP BY user_id)
    
SELECT p.title
FROM stackoverflow.posts AS p
JOIN badge_cnt AS b ON b.user_id = p.user_id
WHERE count > 1000
  AND title != '';
----------------------------------------------------------------------------------
SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views >= 100 AND views < 350 THEN 2
           ELSE 3
       END
FROM stackoverflow.users
WHERE location LIKE '%United States%'
  AND views != 0;
----------------------------------------------------------------------------------
WITH rank AS 
   (SELECT id,
           views,
           CASE
               WHEN views >= 350 THEN 1
               WHEN views >= 100 AND views < 350 THEN 2
               ELSE 3
           END AS group_views
    FROM stackoverflow.users
    WHERE location LIKE '%United States%'
      AND views != 0),

max_views_group AS 
   (SELECT DISTINCT group_views,
           MAX(views) OVER (PARTITION BY group_views)
    FROM rank)
    
SELECT r.id,
       r.group_views,
       m.max
FROM rank AS r
JOIN max_views_group AS m ON m.group_views = r.group_views
WHERE r.views = m.max
ORDER BY max DESC,
         r.id;
----------------------------------------------------------------------------------
WITH u_cnt_pday AS 
   (SELECT EXTRACT(DAY FROM creation_date::date) AS day,
           COUNT(*) AS users_cnt
    FROM stackoverflow.users
    WHERE DATE_TRUNC('month', creation_date) = '2008-11-01'
    GROUP BY EXTRACT(DAY FROM creation_date::date))
    
SELECT *,
       SUM(users_cnt) OVER (ORDER BY day)
FROM u_cnt_pday;
----------------------------------------------------------------------------------
SELECT DISTINCT u.id,
       MIN(p.creation_date) OVER (PARTITION BY p.user_id) - u.creation_date
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON p.user_id = u.id;
----------------------------------------------------------------------------------
SELECT DATE_TRUNC('month', creation_date)::date AS month,
       SUM(views_count) AS total_cnt
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date::date) = 2008
  AND views_count <> 0
GROUP BY month
ORDER BY total_cnt DESC;
----------------------------------------------------------------------------------
WITH creation_ses AS 
   (SELECT u.display_name,
           u.id,
           u.creation_date::date AS acc_creation_data,
           (u.creation_date + '1 month')::date AS acc_data_month,
           p.creation_date::date AS sess_data,
           p.post_type_id
    FROM stackoverflow.users AS u
    JOIN stackoverflow.posts AS p ON p.user_id = u.id
    WHERE p.post_type_id = 2
      AND p.creation_date::date <=  (u.creation_date + '1 month')::date),
    
session_date AS 
   (SELECT display_name,
           id,
           COUNT(post_type_id) OVER (PARTITION BY display_name) AS answ_cnt
    FROM creation_ses)

SELECT display_name,
       COUNT(DISTINCT id)
FROM session_date
WHERE answ_cnt > 100
GROUP BY display_name
ORDER BY display_name;
----------------------------------------------------------------------------------
WITH id_filtered AS 
   (SELECT u.id,
           DATE_TRUNC('month', p.creation_date)::date AS month
    FROM stackoverflow.users u
    JOIN stackoverflow.posts p ON p.user_id = u.id
    WHERE DATE_TRUNC('month', u.creation_date)::date = '2008-09-01'
      AND u.id IN (SELECT user_id
                  FROM stackoverflow.posts
                  WHERE DATE_TRUNC('month', creation_date)::date = '2008-12-01'))
                  
SELECT month,
       COUNT(*)
FROM id_filtered
GROUP BY month
ORDER BY month DESC;
----------------------------------------------------------------------------------
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts;
----------------------------------------------------------------------------------
SELECT ROUND(AVG(count))
FROM (SELECT user_id,
       COUNT(DISTINCT DATE_TRUNC('day', creation_date))
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
GROUP BY user_id) AS user_filtered;
----------------------------------------------------------------------------------
WITH count_current_month AS
   (SELECT EXTRACT(MONTH FROM creation_date) AS month,
           COUNT(*)
    FROM stackoverflow.posts     
    WHERE DATE_TRUNC('month', creation_date)::date BETWEEN '2008-09-01' AND '2008-12-01'
    GROUP BY month)
    
SELECT *,
       ROUND((count - LAG(count) OVER ())::numeric / LAG(count) OVER () * 100, 2) AS perc_diff
FROM count_current_month;     
----------------------------------------------------------------------------------
WITH top_user AS 
   (SELECT user_id,
           COUNT(*) AS posts_cnt
    FROM stackoverflow.posts
    GROUP BY user_id
    ORDER BY posts_cnt DESC
    LIMIT 1)

SELECT DISTINCT EXTRACT(WEEK FROM p.creation_date) n_week,
       MAX(p.creation_date) OVER (PARTITION BY EXTRACT(WEEK FROM p.creation_date)) AS last_post
FROM stackoverflow.posts AS p
JOIN top_user AS t ON t.user_id = p.user_id 
WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01';
