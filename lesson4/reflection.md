# Рефлексия

**Задача 2: Получение данных о гноме с навыками и назначениями**

Создайте запрос, который возвращает информацию о гноме, включая идентификаторы всех его навыков, текущих назначений, принадлежности к отрядам и используемого снаряжения.

```sql
SELECT 
    d.dwarf_id,
    d.name,
    d.age,
    d.profession,
    JSON_OBJECT(
        'skill_ids', (
            SELECT JSON_ARRAYAGG(ds.skill_id)
            FROM dwarf_skills ds
            WHERE ds.dwarf_id = d.dwarf_id
        ),
        'assignment_ids', (
            SELECT JSON_ARRAYAGG(da.assignment_id)
            FROM dwarf_assignments da
            WHERE da.dwarf_id = d.dwarf_id
        ),
        'squad_ids', (
            SELECT JSON_ARRAYAGG(sm.squad_id)
            FROM squad_members sm
            WHERE sm.dwarf_id = d.dwarf_id
        ),
        'equipment_ids', (
            SELECT JSON_ARRAYAGG(de.equipment_id)
            FROM dwarf_equipment de
            WHERE de.dwarf_id = d.dwarf_id
        )
    ) AS related_entities
FROM 
    dwarves d;
```

При анализе условно эталонного решения ошибок в моем решении не обнаружено. За исключением названия таблиц, но для меня было непонятно, как именно писать их названия, поскольку видел три варианта (Dwarves, DWARVES, dwarves), решил брать первый.

Решение после рефлексии:

```sql
SELECT

    D.dwarf_id,

    D.name AS DwarfName,

    D.age AS DwarfAge

    D.profession AS DwarfProfession,

    JSON_OBJECT(

        ('skill_ids', (

            SELECT JSON_ARRAYGG(DS.skill_id) FROM Dwarf_Skills DS

            WHERE DS.dwarf_id = D.dwarf_id

        )),

        ('assignment_ids', (

            SELECT JSON_ARRAYGG(DA.assignment_id) FROM Dwarf_Assigments DA

            WHERE DA.dwarf_id = D.dwarf_id

        )),

        ('squad_ids', (

            SELECT JSON_ARRAYGG(SM.squad_id) FROM Squad_Members SM

            WHERE SM.dwarf_id = D.dwarf_id

        )),

        ('equipment_ids', (

            SELECT JSON_ARRAYGG(DE.equipment_id) FROM Dwarf_Equipment DE

            WHERE DE.dwarf_id = D.dwarf_id

        ))

    ) as related_entities

FROM Dwarves D;
```

**Задача 3: Данные о мастерской с назначенными рабочими и проектами**

Напишите запрос для получения информации о мастерской, включая идентификаторы назначенных ремесленников, текущих проектов, используемых и производимых ресурсов.

```sql
SELECT 
    w.workshop_id,
    w.name,
    w.type,
    w.quality,
    JSON_OBJECT(
        'craftsdwarf_ids', (
            SELECT JSON_ARRAYAGG(wc.dwarf_id)
            FROM workshop_craftsdwarves wc
            WHERE wc.workshop_id = w.workshop_id
        ),
        'project_ids', (
            SELECT JSON_ARRAYAGG(p.project_id)
            FROM projects p
            WHERE p.workshop_id = w.workshop_id
        ),
        'input_material_ids', (
            SELECT JSON_ARRAYAGG(wm.material_id)
            FROM workshop_materials wm
            WHERE wm.workshop_id = w.workshop_id AND wm.is_input = TRUE
        ),
        'output_product_ids', (
            SELECT JSON_ARRAYAGG(wp.product_id)
            FROM workshop_products wp
            WHERE wp.workshop_id = w.workshop_id
        )
    ) AS related_entities
FROM 
    workshops w;
```

При анализе условно эталонного решения ошибок в моем решении не обнаружено. За исключением названия таблиц, но для меня было непонятно, как именно писать их названия, поскольку видел три варианта (Dwarves, DWARVES, dwarves), решил брать первый. Также была допущена ошибка при фильтрации данных по условию, поскольку по невнимательности я не учел состояние `is_input` у материалов, ведь данный атрибут говорит о используемости материала, а мой запрос выводит все виды материалов, те которые и используются и не используются.  

Решение после рефлексии:

```sql
SELECT

    W.workshop_id,

    W.name AS WorkshopName,

    W.type AS WorkshopType  

    W.quality AS WorkshopQuality,

    JSON_OBJECT(

        ('craftsdwarf_ids', (

            SELECT JSON_ARRAYGG(WC.dwarf_id) FROM Workshop_Craftdwarves WC

            WHERE WC.workshop_id = W.workshop_id

        )),

        ('project_ids', (

            SELECT JSON_ARRAYGG(P.project_id) FROM Projects P

            WHERE P.workshop_id = W.workshop_id

        )),

        ('input_material_ids', (

            SELECT JSON_ARRAYGG(WM.material_id) FROM Workshop_Materials WM

            WHERE WM.workshop_id = W.workshop_id AND WM.is_input = TRUE

        )),

        ('output_product_ids', (

            SELECT JSON_ARRAYGG(WP.product_id) FROM Workshop_Products WP

            WHERE WP.workshop_id = W.workshop_id

        ))

    ) as related_entities

FROM Workshops W;
```

**Задача 4: Данные о военном отряде с составом и операциями**

```sql
SELECT 
    s.squad_id,
    s.name,
    s.formation_type,
    s.leader_id,
    JSON_OBJECT(
        'member_ids', (
            SELECT JSON_ARRAYAGG(sm.dwarf_id)
            FROM squad_members sm
            WHERE sm.squad_id = s.squad_id
        ),
        'equipment_ids', (
            SELECT JSON_ARRAYAGG(se.equipment_id)
            FROM squad_equipment se
            WHERE se.squad_id = s.squad_id
        ),
        'operation_ids', (
            SELECT JSON_ARRAYAGG(so.operation_id)
            FROM squad_operations so
            WHERE so.squad_id = s.squad_id
        ),
        'training_schedule_ids', (
            SELECT JSON_ARRAYAGG(st.schedule_id)
            FROM squad_training st
            WHERE st.squad_id = s.squad_id
        ),
        'battle_report_ids', (
            SELECT JSON_ARRAYAGG(sb.report_id)
            FROM squad_battles sb
            WHERE sb.squad_id = s.squad_id
        )
    ) AS related_entities
FROM 
    military_squads s;
```

При анализе условно эталонного решения ошибок в моем решении не обнаружено. За исключением названия таблиц, но для меня было непонятно, как именно писать их названия, поскольку видел три варианта (Dwarves, DWARVES, dwarves), решил брать первый.

Решение после рефлексии:

```sql
SELECT

    MS.squad_id,

    MS.name AS SquadName,

    MS.formation_type AS SquadFormationType  

    MS.leader_id AS SquadLeader,

    JSON_OBJECT(

        ('member_ids', (

            SELECT JSON_ARRAYGG(SM.dwarf_id) FROM Squad_Members SM

            WHERE SM.squad_id = MS.squad_id

        )),

        ('equipment_ids', (

            SELECT JSON_ARRAYGG(SE.equipment_id) FROM Squad_Equipment SE

            WHERE SE.squad_id = MS.squad_id

        )),

        ('operation_ids', (

            SELECT JSON_ARRAYGG(SO.operation_id) FROM Squad_Operations SO

            WHERE SO.squad_id = MS.squad_id

        )),

        ('training_schedule_ids', (

            SELECT JSON_ARRAYGG(ST.schedule_id) FROM Squad_Training ST

            WHERE ST.squad_id = MS.squad_id

        )),

        ('battle_report_ids', (

            SELECT JSON_ARRAYGG(SB.report_id) FROM Squad_Battles SB

            WHERE SB.squad_id = MS.squad_id

        ))

    ) as related_entities

FROM Military_Squads MS;
```
