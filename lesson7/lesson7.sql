-- Создайте запрос, оценивающий эффективность военных отрядов на основе:
-- - Результатов всех сражений (победы/поражения/потери)
-- - Соотношения побед к общему числу сражений
-- - Навыков членов отряда и их прогресса
-- - Качества экипировки
-- - Истории тренировок и их влияния на результаты
-- - Выживаемости членов отряда в долгосрочной перспективе

WITH squads_info AS (
    SELECT
        MS.squad_id, 
        MS.squad_name,
        MS.formation_type,
        D.name AS leader_name,
        COUNT(DISTINCT CASE WHEN  SM.join_date > SM.exit_date THEN SM.dwarf_id ELSE 0 END) AS current_members,
        COUNT(DISTINCT SM.dwarf_id) AS total_members_ever

    FROM Military_Squads MS 
    LEFT JOIN Dwarves D ON MS.leader_id = D.dwarf_id
    LEFT JOIN Squad_Members SM ON MS.squad_id = SM.squad_id

    GROUP BY MS.squad_id
),

battle_info AS (
    SELECT
        MS.squad_id,
        COUNT(SB.report_id) AS total_battles,
        COUNT(CASE WHEN SB.outcome = 'Victory' THEN SB.report_id ELSE 0) AS victories,
        COUNT(CASE WHEN SB.outcome = 'Lost' THEN SB.report_id ELSE 0) AS losses
        SUM(SB.casualties) AS casualties,
        SUM(SB.enemy_casualties) AS enemy_casualties

    FROM Military_Squads MS 
    LEFT JOIN Squad_Battles SB ON MS.squad_id = SB.squad_id

    GROUP BY MS.squad_id
), 

training_info AS (
    SELECT
        ST.squad_id,
        SUM(ST.schedule_id) AS total_training_sessions,
        AVG(ST.effectiveness) AS avg_training_effectiveness
    FROM Squad_Training ST

    GROUP BY ST.squad_id
), 

squads_equipment_info AS (
    SELECT
        MS.squad_id,
        AVG(E.quality) AS avg_equipment_quality,

    FROM Military_Squads MS 
    LEFT JOIN Squad_Equipment SE ON MS.squad_id = SE.squad_id
    JOIN Equipment E ON SE.equipment_id = E.equipment_id

    GROUP BY MS.squad_id
),

-- изменить нахождение среднего значения улучшения навыка (необходимо провести зависимость с тренировками, а точнее с датой их проведения) 
dawrves_skills_in_squad AS (
    SELECT
        SM.squad_id,
        AVG(MAX(DS.level) - MIN(DS.level)) AS avg_combat_skill_improvement,

    FROM Squad_Members SM 
    JOIN Dwarf_Skills DS ON SM.dwarf_id = DS.dwarf_id
    JOIN Skills S ON DS.skill_id = S.skill_id

    WHERE S.name = 'Combat'
    
    GROUP BY SM.squad_id
)

SELECT 
    si.squad_id,
    si.squad_name,
    si.formation_type,
    si.leader_name,
    bi.total_battles, 
    bi.victories,
    ROUND(( bi.victories :: DECIMAL / NULLIF(bi.total_battles :: DECIMAL, 0) ) * 100, 2)  AS victory_percentage, 
    ROUND(bi.casualties :: DECIMAL / NULLIF(bi.total_battles, 0), 2) AS casualty_rate,
    ROUND(bi.casualties :: DECIMAL / NULLIF(bi.enemy_casualties, 0), 2) AS casualty_exchange_ratio,
    si.current_members,
    si.total_members_ever,
    ROUND((si.current_members :: DECIMAL / NULLIF(si.total_members_ever, 0)) * 100, 2) AS retention_rate,
    sei.avg_equipment_quality,
    ti.total_training_sessions,
    ti.avg_training_effectiveness,
    CORR(ROUND(ti.avg_training_effectiveness * 100, 2), 
        ROUND(( bi.victories :: DECIMAL / NULLIF(bi.total_battles :: DECIMAL, 0) ) * 100, 2)
    ) AS training_battle_correlation,

    -- dsis.avg_combat_skill_improvement,
    -- AS overall_effectiveness_score,
    
    JSON_OBJECT(
        'member_ids', (
            SELECT JSON_ARRAYAGG(SM.dwarf_id)
            FROM Squad_Members SM 
            WHERE SM.squad_id = si.squad_id
        ),
        'equipment_ids', (
            SELECT JSON_ARRAYAGG(SE.equipment_id)
            FROM Squad_Equipment SE 
            WHERE SE.squad_id = si.squad_id
        ),
        'battle_report_ids', (
            SELECT JSON_ARRAYAGG(SB.report_id)
            FROM Squad_Battles SB 
            WHERE SB.squad_id = si.squad_id
        ),
        'training_ids', (
            SELECT JSON_ARRAYAGG(ST.schedule_id)
            FROM Squad_Training ST 
            WHERE ST.squad_id = si.squad_id
        ),
    ) AS related_entities

    FROM squads_info si
    JOIN battle_info bi ON si.squad_id = bi.squad_id
    JOIN training_info ON si.squad_id = ti.squad_ids
    JOIN squads_equipment_info sei ON si.squad_id = sei.squad_id
    JOIN dawrves_skills_in_squad dsis ON si.squad_id = dsis.squad_id 

    GROUP BY si.squad_id;