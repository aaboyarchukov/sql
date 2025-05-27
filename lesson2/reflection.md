# Рефлексия

1. Найдите все отряды, у которых нет лидера.

```sql
SELECT *
FROM Squads
WHERE leader_id IS NULL;
```

При анализе условно эталонного решения я допустил следующие недочеты:
- Перемудрил решение.
Сама задача была решена верно, но ее решение можно было сделать более лаконичным и простым, не используя конструкцию `JOIN`.

Решение после рефлексии:

```sql
SELECT
    *
FROM
    Squads
WHERE
    leader_id IS NULL;
```

2. Получите список всех гномов старше 150 лет, у которых профессия "Warrior".

```sql
SELECT *
FROM Dwarves
WHERE age > 150 AND profession = 'Warrior';
```

Данная задача решена верно, за исключением того, что я вывел не всю информацию, а конкретные атрибуты.

Решение после рефлексии:

```sql
SELECT
    *
FROM
    Dwarves
WHERE
    age > 150
AND
    profession = 'Warrior';
```

3. Найдите гномов, у которых есть хотя бы один предмет типа "weapon".

```sql
SELECT DISTINCT D.*
FROM Dwarves D
JOIN Items I ON D.dwarf_id = I.owner_id
WHERE I.type = 'weapon';
```

При анализе условно эталонного решения были допущены ошибки:
- Не использовал оператор `DISTINCT` - из-за этой ошибки гномы в моем запросе могут повторяться, что является неверным.
- Вывел конкретные атрибуты, а не все записи.

Решение после рефлексии:

```sql
SELECT DISTINCT
    D.*
FROM
    Dwarves D JOIN Items I
    ON D.dwarf_id = I.owner_id
WHERE
    I.type = 'weapon';
```

4. Получите количество задач для каждого гнома, сгруппировав их по статусу.

```sql
SELECT assigned_to, status, COUNT(*) AS task_count
FROM Tasks
GROUP BY assigned_to, status;
```

После анализа условно эталонного решения я пришел к выводу о том, что в данной задаче я допустил ошибку по невнимательности, так как посчитал, что необходимо вывести количество задач абсолютно для всех гномов, даже если у них нет задач, хотя достаточно было пройтись по всем задачам и вывести их количество по каждому назначенному к задаче гному.

Решение после рефлексии:

```sql
SELECT
    assigned_to,
    status,
    COUNT(Tasks.*) AS CountTasks
FROM
    Tasks
GROUP BY assigned_to, status;
```

5. Найдите все задачи, которые были назначены гномам из отряда с именем "Guardians".

```sql
SELECT T.*
FROM Tasks T
JOIN Dwarves D ON T.assigned_to = D.dwarf_id
JOIN Squads S ON D.squad_id = S.squad_id
WHERE S.name = 'Guardians';
```

С данной задачей я справился верно, но пошел другим путем использовав подзапросы, что также даст правильный ответ на задачу. Но сравнивая с эталонным решением - подход был разный. Также я снова вывел некоторые атрибуты, а не все записи.

Решение после рефлексии:

```sql
SELECT
    T.*
FROM
    Dwarves D JOIN Tasks T
    ON D.dwarf_id = T.assigned_to
WHERE
    D.squad_id IN (
        SELECT squad_id FROM SquadID
        WHERE name = 'Guardians'
    );
```

6. Выведите всех гномов и их ближайших родственников, указав тип родственных отношений.

```sql
SELECT D1.name AS dwarf_name, D2.name AS relative_name, R.relationship
FROM Relationships R
JOIN Dwarves D1 ON R.dwarf_id = D1.dwarf_id
JOIN Dwarves D2 ON R.related_to = D2.dwarf_id;
```

Решение абсолютно верное, за исключением того, что я для ясности и выразительности выделил выражения скобками.

Решение после рефлексии:

```sql
SELECT
    FirstD.name AS FirstDwarfName,
    SecondD.name AS SecondDwarfName,
    R.relationship AS Relation
FROM
    (
        Dwarves FirstD JOIN Relationships R
        ON FirstD.dwarf_id = Relationships.dwarf_id
    ) JOIN Dwarves SecondD
      ON SecondD.dwarf_id = R.related_to;
```

