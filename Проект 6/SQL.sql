1. Сколько компаний закрылось.
SELECT COUNT(id)
FROM company
WHERE status = 'closed';

