-- 1. Получить информацию о всех гномах, 
-- которые входят в какой-либо отряд, 
-- вместе с информацией об их отрядах.
SELECT dwarves.*, squads.* FROM dwarves
    JOIN squads ON dwarves.squad_id = squads.squad_id;

-- after reflection
SELECT 
    D.name AS DwarfName, 
    D.age AS DwarfAge, 
    D.profession AS DwarfProfession, 
    S.name AS SquadName,
    S.mission AS SquadMission, 
        FROM Dwarves D JOIN Squads S 
        ON D.squad_id = S.squad_id;

-- 2. Найти всех гномов с профессией "miner", 
-- которые не состоят ни в одном отряде.
SELECT * FROM dwarves
    WHERE dwarves.squad_id IS NULL AND dwarves.profession = 'miner';

-- after reflection
SELECT name, age FROM Dwarves
    WHERE squad_id IS NULL AND profession = 'miner';

-- 3. Получить все задачи с наивысшим приоритетом, 
-- которые находятся в статусе "pending".
SELECT * FROM tasks
    WHERE tasks.status = 'pending'
        AND tasks.priority = (SELECT MAX(tasks.priority) FROM tasks);

-- after reflection
SELECT task_id, description, assigned_to FROM Tasks
    WHERE priority = (
        SELECT MAX(priority) FROM Tasks
        WHERE status = 'pending'
    ) AND status = 'pending';

-- 4. Для каждого гнома, который владеет хотя бы одним предметом, 
-- получить количество предметов, которыми он владеет.
SELECT dwarves.dwarf_id, COUNT(items.item_id) FROM dwarves
    JOIN items ON dwarves.dwarf_id = items.owner_id;

-- after reflection
SELECT 
    D.name AS DwarfName, 
    D.profession AS DwarfProfession, 
    COUNT(I.item_id) AS ItemsCount 
FROM
    Dwarves D JOIN Items I 
    ON D.dwarf_id = I.owner_id
    GROUP BY D.name, D.profession;

-- 5. Получить список всех отрядов и количество гномов в каждом отряде. 
-- Также включите в выдачу отряды без гномов. 
SELECT squads.squad_id, COUNT(dwarves.dwarf_id) FROM squads
    LEFT JOIN dwarves ON squads.squad_id = dwarves.squad_id;

-- after reflection
SELECT
    S.squad_id AS SquadID,
    S.name AS SquadName,
    COUNT(D.dwarf_id) AS CountDwarfs
FROM 
    Squad S LEFT JOIN Dwarves D
    ON D.squad_id = S.squad_id
GROUP BY S.squad_id, S.name; 

-- 6. Получить список профессий с наибольшим количеством 
-- незавершённых задач ("pending" и "in_progress") у гномов этих профессий.
SELECT professions_and_tasks.profession FROM (
    SELECT dwarves.profession AS profession, COUNT(tasks.*) as count_tasks FROM dwarves
    JOIN tasks ON dwarves.dwarf_id = tasks.assigned_to
    WHERE tasks.status IN ('pending', 'in_progress')
) AS professions_and_tasks
    WHERE professions_and_tasks.count_tasks = (
        SELECT MAX(professions_and_tasks.count_tasks) FROM professions_and_tasks);

-- after reflection
SELECT 
    D.profession AS DwarfProfession,
    COUNT(T.task_id) AS CountUnfinishedTasks
FROM 
    Dwarves D JOIN Tasks T 
    ON D.dwarf_id = T.assigned_to
WHERE 
    T.status IN ('pending', 'in_progress')
GROUP BY D.profession
ORDER BY CountUnfinishedTasks DESC;

-- 7. Для каждого типа предметов узнать средний возраст гномов, 
-- владеющих этими предметами.
SELECT items.item_id, AVG(dwarves.age) FROM dwarves
    JOIN items ON dwarves.dwarf_id = items.owner_id;

-- after reflection
SELECT 
    I.type AS ItemType,
    AVG(D.age) AS AverageDwarfsAge
FROM 
    Dwarves D JOIN Items I
    ON D.dwarf_id = I.owner_id
GROUP BY I.type;

-- 8. Найти всех гномов старше среднего возраста (по всем гномам в базе), 
-- которые не владеют никакими предметами.
SELECT dwarves.* FROM dwarves
    LEFT JOIN items ON dwarves.dwarf_id = items.owner_id
    WHERE items.owner_id IS NULL
    AND dwarves.age > (
        SELECT AVG(dwarves.age) FROM dwarves
    );
    -- OR
    -- GROUP BY dwarves.age
    -- HAVING dwarves.age > (
    --     SELECT AVG(dwarves.age) FROM dwarves
    -- );

-- after reflection

SELECT 
    D.name, 
    D.age,
    D.profession
FROM
    Dwarves D
WHERE 
    D.age > (
        SELECT AVG(age) FROM Dwarves 
    )
AND D.dwarf_id NOT IN (
    SELECT owner_id FROM Items
);