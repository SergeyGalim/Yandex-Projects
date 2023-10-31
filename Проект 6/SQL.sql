SELECT COUNT(id)
FROM company
WHERE status = 'closed';


SELECT funding_total
FROM company 
WHERE country_code = 'USA'
  AND category_code = 'news'
ORDER BY funding_total DESC;


SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
  AND EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN 2011 AND 2013;


SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%';


SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
  AND last_name LIKE 'K%';


SELECT country_code,
       SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC;


SELECT CAST(funded_at AS date),
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY CAST(funded_at AS date)
HAVING MIN(raised_amount) <> 0
   AND MIN(raised_amount) <> MAX(raised_amount)
ORDER BY  CAST(funded_at AS date);


SELECT *,
       CASE
           WHEN invested_companies >= 100 THEN 'high_activity'
           WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity' 
           ELSE 'low_activity'
       END
FROM fund;       


SELECT 
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds))
FROM fund
GROUP BY activity       
ORDER BY ROUND(AVG(investment_rounds));


SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING MIN(invested_companies) <> 0
ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10;


SELECT p.first_name,
       p.last_name,
       e.instituition
FROM people AS p 
LEFT JOIN education AS e ON e.person_id = p.id;


SELECT c.name,
       COUNT(DISTINCT(e.instituition))
FROM company AS c
INNER JOIN people AS p ON c.id = p.company_id
INNER JOIN education AS e ON e.person_id = p.id
GROUP BY c.name
ORDER BY COUNT(DISTINCT(e.instituition)) DESC
LIMIT 5;


SELECT DISTINCT(c.name)
FROM company AS c
LEFT JOIN funding_round AS fr ON fr.company_id = c.id
WHERE c.status = 'closed' 
  AND fr.is_first_round = 1
  AND fr.is_last_round = 1;


WITH 
i AS (SELECT c.id AS company_id
     FROM company AS c
     LEFT JOIN funding_round AS fr ON fr.company_id = c.id
     WHERE c.status = 'closed'
       AND fr.is_first_round = 1
       AND fr.is_last_round = 1)
    
SELECT DISTINCT(p.id)
FROM people AS p
INNER JOIN i ON i.company_id = p.company_id;


WITH 
c_id AS (SELECT c.id
         FROM company AS c
         LEFT JOIN funding_round AS fr ON fr.company_id = c.id
         WHERE c.status = 'closed'
           AND fr.is_first_round = 1
           AND fr.is_last_round = 1),
       
p_id AS (SELECT DISTINCT(p.id) AS customer_id
        FROM people AS p
        INNER JOIN c_id ON c_id.id = p.company_id)
        
SELECT p_id.customer_id,
       e.instituition
FROM p_id INNER JOIN education AS e ON p_id.customer_id = e.person_id;


WITH 
c_id AS (SELECT c.id
         FROM company AS c
         LEFT JOIN funding_round AS fr ON fr.company_id = c.id
         WHERE c.status = 'closed'
           AND fr.is_first_round = 1
           AND fr.is_last_round = 1),
       
p_id AS (SELECT DISTINCT(p.id) AS customer_id
        FROM people AS p
        INNER JOIN c_id ON c_id.id = p.company_id)
        
SELECT p_id.customer_id,
       COUNT(e.instituition)
FROM p_id INNER JOIN education AS e ON p_id.customer_id = e.person_id
GROUP BY p_id.customer_id;


WITH 
c_id AS (SELECT c.id
         FROM company AS c
         LEFT JOIN funding_round AS fr ON fr.company_id = c.id
         WHERE c.status = 'closed'
           AND fr.is_first_round = 1
           AND fr.is_last_round = 1),
       
p_id AS (SELECT DISTINCT(p.id) AS customer_id
        FROM people AS p
        INNER JOIN c_id ON c_id.id = p.company_id),
        
e_c AS (SELECT p_id.customer_id,
        COUNT(e.instituition)
        FROM p_id INNER JOIN education AS e ON p_id.customer_id = e.person_id
        GROUP BY p_id.customer_id)

SELECT AVG(e_c.COUNT)
FROM e_c;


WITH 
p_id AS (SELECT DISTINCT(p.id) AS customer_id
        FROM people AS p
        INNER JOIN company AS c ON c.id = p.company_id
        WHERE c.name = 'Facebook'),
        
e_c AS (SELECT p_id.customer_id,
               COUNT(e.instituition)
        FROM p_id INNER JOIN education AS e ON p_id.customer_id = e.person_id
        GROUP BY p_id.customer_id)

SELECT AVG(e_c.COUNT)
FROM e_c;


WITH 
i AS (SELECT f.name AS fund_name,
             c.name AS company_name,
             i.funding_round_id
      FROM fund AS f
      RIGHT JOIN investment AS i ON i.fund_id = f.id
      LEFT JOIN company AS c ON c.id = i.company_id
      WHERE c.milestones > 6)
      
SELECT i.fund_name AS name_of_fund,
       i.company_name AS name_of_company,
       fr.raised_amount AS amount
FROM funding_round AS fr
RIGHT JOIN i ON fr.id = i.funding_round_id
WHERE EXTRACT(YEAR FROM CAST(funded_at AS date)) BETWEEN 2012 AND 2013;


WITH 
f AS (SELECT acquiring_company_id,
             price_amount,
             acquired_company_id
      FROM acquisition
      WHERE price_amount <> 0), 

s AS (SELECT id,
             funding_total
      FROM company 
      WHERE funding_total <> 0)
      
SELECT c.name AS acquiring_company_name,
       f.price_amount,
       comp.name AS acquired_company_name,
       s.funding_total,
       ROUND(f.price_amount / s.funding_total)
FROM f LEFT JOIN company AS c ON f.acquiring_company_id = c.id
LEFT JOIN company AS comp ON f.acquired_company_id = comp.id
INNER JOIN s ON s.id = f.acquired_company_id
ORDER BY price_amount DESC, acquired_company_name
LIMIT 10;


SELECT c.name,
       EXTRACT(MONTH FROM CAST(fr.funded_at AS date))
FROM company AS c
RIGHT JOIN funding_round AS fr ON fr.company_id = c.id
WHERE c.category_code = 'social'
  AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013
  AND fr.raised_amount <> 0;


WITH 
i AS (SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS month,
             COUNT(DISTINCT(f.name))
      FROM fund AS f
      RIGHT JOIN investment AS i ON f.id = i.fund_id
      LEFT JOIN funding_round AS fr ON fr.id = i.funding_round_id
      WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013
        AND f.country_code = 'USA'
      GROUP BY EXTRACT(MONTH FROM CAST(fr.funded_at AS date))),

j AS (SELECT EXTRACT(MONTH FROM CAST(acquired_at AS date)) AS month,
             COUNT(acquiring_company_id),
             SUM(price_amount)
      FROM acquisition AS a
      WHERE EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN 2010 AND 2013
      GROUP BY EXTRACT(MONTH FROM CAST(acquired_at AS date)))
  
SELECT i.month,
       i.count AS count_of_funds,
       j.count AS count_of_acquiring_companies,
       j.sum AS total_price
FROM i FULL OUTER JOIN j ON i.month = j.month;


WITH 
t1 AS (SELECT c.country_code,
              AVG(c.funding_total)
       FROM company AS c
       WHERE EXTRACT(YEAR FROM CAST(c.founded_at AS date)) BETWEEN 2011 AND 2013
       GROUP BY c.country_code, EXTRACT(YEAR FROM CAST(c.founded_at AS date))
       HAVING EXTRACT(YEAR FROM CAST(c.founded_at AS date)) = 2011),
       
t2 AS (SELECT c.country_code,
              AVG(c.funding_total)
       FROM company AS c
       WHERE EXTRACT(YEAR FROM CAST(c.founded_at AS date)) BETWEEN 2011 AND 2013
       GROUP BY c.country_code, EXTRACT(YEAR FROM CAST(c.founded_at AS date))
      HAVING EXTRACT(YEAR FROM CAST(c.founded_at AS date)) = 2012),
       
t3 AS (SELECT c.country_code,
              AVG(c.funding_total)
       FROM company AS c
       WHERE EXTRACT(YEAR FROM CAST(c.founded_at AS date)) BETWEEN 2011 AND 2013
       GROUP BY c.country_code, EXTRACT(YEAR FROM CAST(c.founded_at AS date))
       HAVING EXTRACT(YEAR FROM CAST(c.founded_at AS date)) = 2013)

SELECT t1.country_code,
       t1.avg AS avg_funding_total_2011, 
       t2.avg AS avg_funding_total_2012,
       t3.avg AS avg_funding_total_2013
FROM t1 INNER JOIN t2 ON t1.country_code = t2.country_code
INNER JOIN t3 ON t1.country_code = t3.country_code
ORDER BY t1.avg DESC;


