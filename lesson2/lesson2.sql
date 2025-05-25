-- 1. Найдите все отряды, у которых нет лидера.
SELECT 
    S.name AS SquadName,
    S.leader_id AS Leader
FROM
    Squads S LEFT JOIN Dwarves D
    ON S.leader_id = D.dwarf_id
WHERE
    S.leader_id IS NULL;

-- 2. Получите список всех гномов старше 150 лет, 
-- у которых профессия "Warrior".
SELECT
    name,
    age,
    profession
FROM
    Dwarves
WHERE 
    age > 150
AND
    profession = 'Warrior';

-- 3. Найдите гномов, у которых есть 
-- хотя бы один предмет типа "weapon".
SELECT
    D.name AS DwarfName,
    D.age AS DwarfAge,
    I.type AS ItemType
FROM
    Dwarves D JOIN Items I
    ON D.dwarf_id = I.owner_id
WHERE
    I.type = 'weapon';

-- 4. Получите количество задач для каждого гнома, 
-- сгруппировав их по статусу.
SELECT 
    D.dwarf_id,
    D.name AS DwarfName,
    T.status AS TaskStatus,
    COUNT(T.task_id) AS CountTasks
FROM
    Dwarves D LEFT JOIN Tasks T
    ON D.dwarf_id = T.assigned_to
GROUP BY D.dwarf_id, D.name, T.status;

-- 5. Найдите все задачи, которые были назначены гномам 
-- из отряда с именем "Guardians".
SELECT
    D.name AS DwarfName,
    T.description AS TaskDescription
FROM
    Dwarves D JOIN Tasks T
    ON D.dwarf_id = T.assigned_to
WHERE 
    D.squad_id IN (
        SELECT squad_id FROM SquadID
        WHERE name = 'Guardians'
    );

-- 6. Выведите всех гномов и их ближайших родственников, 
-- указав тип родственных отношений.
SELECT
    FirstD.name AS FirstDwarfName,
    SecondD.name AS SecondDwarfName,
    R.relationship AS Relation
FROM
    Dwarves SecondD JOIN (
        Dwarves FirstD JOIN Relationships R 
        ON FirstD.dwarf_id = Relationships.dwarf_id
    ) ON SecondD.dwarf_id = R.related_to;