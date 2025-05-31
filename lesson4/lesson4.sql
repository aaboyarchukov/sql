-- Создайте запрос, который возвращает информацию о гноме, 
-- включая идентификаторы всех его навыков, текущих назначений, 
-- принадлежности к отрядам и используемого снаряжения.

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

-- after reflection
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

-- Напишите запрос для получения информации о мастерской, 
-- включая идентификаторы назначенных ремесленников, 
-- текущих проектов, используемых и производимых ресурсов.
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
            WHERE WM.workshop_id = W.workshop_id
        )),
        ('output_product_ids', (
            SELECT JSON_ARRAYGG(WP.product_id) FROM Workshop_Products WP
            WHERE WP.workshop_id = W.workshop_id
        ))
    ) as related_entities
FROM Workshops W;

-- after reflection
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

-- Разработайте запрос, который возвращает информацию о военном отряде, 
-- включая идентификаторы всех членов отряда, используемого снаряжения, 
-- прошлых и текущих операций, тренировок.
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

-- after reflection
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