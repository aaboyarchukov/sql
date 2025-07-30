-- Разработайте запрос, который комплексно анализирует безопасность крепости, учитывая:
-- - Историю всех атак существ и их исходов
-- - Эффективность защитных сооружений
-- - Соотношение между типами существ и результативностью обороны
-- - Оценку уязвимых зон на основе архитектуры крепости
-- - Корреляцию между сезонными факторами и частотой нападений
-- - Готовность военных отрядов и их расположение
-- - Эволюцию защитных способностей крепости со временем

-- в задании и базе данных не бла представлена эта таблица, поэтому создам
-- ее самостоятельно
CREATE TABLE IF NOT EXISTS weather_records (
    record_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    location_id INTEGER REFERENCES locations(location_id),
    temperature INTEGER,  -- в градусах
);

WITH attack_stats AS (
    SELECT
        COUNT(*) AS total_recorded_attacks,
        COUNT(DISTINCT creature_id) AS unique_attackers,
        ROUND(SUM(CASE WHEN outcome = 'DEFEATED' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS overall_defense_success_rate
    FROM creature_attacks
), current_threats AS (
    SELECT
        c.type AS creature_type,
        c.threat_level,
        MAX(cs.date) AS last_sighting_date,
        COUNT(DISTINCT c.creature_id) AS estimated_numbers,
        ARRAY_AGG(DISTINCT c.creature_id) AS creature_ids,
        ROUND(COUNT(DISTINCT cs.sighting_id) * 100 / 
              (SELECT COUNT(*) FROM creature_sightings WHERE creature_id = c.creature_id), 1) AS zone_coverage_percent
    FROM
        creatures c
    JOIN
        creature_sightings cs ON c.creature_id = cs.creature_id
    WHERE
        c.active = TRUE
    GROUP BY
        c.type, c.threat_level
), vulnerability_analysis AS (
    SELECT
        l.location_id AS zone_id,
        l.name AS zone_name,
        ROUND(
            (COUNT(ca.attack_id) * 0.4 + 
             (l.fortification_level) * 0.3 +
             AVG(ca.casualties) * 0.3 +
            ), 2
        ) AS vulnerability_score,
        COUNT(CASE WHEN ca.outcome = 'SUCCESS' THEN 1 END) AS historical_breaches,
        l.fortification_level,
        ROUND(AVG(ca.military_response_time_minutes)) AS military_response_time,
        JSON_ARRAYAGG(DISTINCT ds.structure_id) AS structure_ids,
        JSON_ARRAYAGG(
            SELECT DISTINCT sm.squad_id 
            FROM squad_members sm
            JOIN creature_attacks ca ON sm.dwarf_id = ca.military_response_dwarf_id
            WHERE ca.location_id = l.location_id
        ) AS squad_ids
    FROM
        locations l
    LEFT JOIN
        creature_attacks ca ON l.location_id = ca.location_id
    LEFT JOIN
        defense_structures ds ON l.location_id = ds.location_id AND ds.structure_id IS NOT NULL
    GROUP BY
        l.location_id, l.name, l.fortification_level, l.zone_type
    HAVING
        COUNT(ca.attack_id) > 0
    ORDER BY
        vulnerability_score DESC
), defense_effectiveness AS (
    SELECT
        ds.type AS defense_type,
        ROUND(SUM(CASE WHEN ca.outcome = 'DEFEATED' THEN 1 ELSE 0 END) * 100 / COUNT(ca.attack_id), 2) AS effectiveness_rate,
        ROUND(AVG(ca.enemy_casualties), 1) AS avg_enemy_casualties,
        ARRAY_AGG(DISTINCT ds.structure_id) AS structure_ids
    FROM
        defense_structures ds
    JOIN
        creature_attacks ca ON ds.location_id = ca.location_id
    GROUP BY
        ds.type
), military_readiness AS (
    SELECT
        ms.squad_id,
        ms.name AS squad_name,
        ROUND(
            (COALESCE(AVG(CASE WHEN sk.skill_type = 'COMBAT' THEN sk.level ELSE 0 END), 0) * 0.6 +
             COALESCE(SUM(CASE WHEN sb.outcome = 'victory' THEN 1 ELSE 0 END) / NULLIF(COUNT(sb.report_id), 0) * 0.4), 2
        ) AS readiness_score,
        COUNT(DISTINCT sm.dwarf_id) AS active_members,
        ROUND(AVG(CASE WHEN sk.skill_type = 'COMBAT' THEN sk.level ELSE NULL END), 1) AS avg_combat_skill,
        ROUND(SUM(CASE WHEN sb.outcome = 'victory' THEN 1 ELSE 0 END) / NULLIF(COUNT(sb.report_id), 0)::numeric, 2) AS combat_effectiveness,
        (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'zone_id', l.location_id,
                    'response_time', ROUND(AVG(ca.military_response_time_minutes))
                )
            )
            FROM 
                squad_members sm
            JOIN 
                creature_attacks ca ON sm.dwarf_id = ca.military_response_dwarf_id
            JOIN 
                locations l ON ca.location_id = l.location_id
            WHERE 
                sm.squad_id = ms.squad_id AND sm.exit_date IS NULL
            GROUP BY 
                l.location_id
        ) AS response_coverage
    FROM
        military_squads ms
    LEFT JOIN
        squad_members sm ON ms.squad_id = sm.squad_id AND sm.exit_date IS NULL
    LEFT JOIN
        dwarf_skills ds ON sm.dwarf_id = ds.dwarf_id
    LEFT JOIN
        skills sk ON ds.skill_id = sk.skill_id AND sk.skill_type = 'COMBAT'
    LEFT JOIN
        squad_battles sb ON ms.squad_id = sb.squad_id
    GROUP BY
        ms.squad_id, ms.name
    )
), security_evolution AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        ROUND(SUM(CASE WHEN outcome = 'DEFEATED' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS defense_success_rate,
        COUNT(*) AS total_attacks,
        SUM(casualties) AS casualties,
        ROUND(
            SUM(CASE WHEN outcome = 'DEFEATED' THEN 1 ELSE 0 END) * 100 / COUNT(*) - 
            LAG(SUM(CASE WHEN outcome = 'DEFEATED' THEN 1 ELSE 0 END) * 100 / COUNT(*)) OVER (ORDER BY EXTRACT(YEAR FROM date)),
            2
        ) AS year_over_year_improvement
    FROM
        creature_attacks
    GROUP BY
        EXTRACT(YEAR FROM date)
), seasonal_attack_patterns AS (
    SELECT
        EXTRACT(YEAR FROM ca.date) AS year,
        CASE 
            WHEN EXTRACT(MONTH FROM ca.date) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM ca.date) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM ca.date) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM ca.date) IN (9, 10, 11) THEN 'Autumn'
        END AS season,
        COUNT(*) AS attack_count,
        ROUND(AVG(ca.casualties), 1) AS avg_casualties,
        c.type AS most_common_creature,
        MAX(wr.temperature) AS max_temperature,
        MIN(wr.temperature) AS min_temperature,
    FROM
        creature_attacks ca
    JOIN
        creatures c ON ca.creature_id = c.creature_id
    LEFT JOIN
        weather_records wr ON ca.date = wr.date AND ca.location_id = wr.location_id
    GROUP BY
        EXTRACT(YEAR FROM ca.date),
        CASE 
            WHEN EXTRACT(MONTH FROM ca.date) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM ca.date) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM ca.date) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM ca.date) IN (9, 10, 11) THEN 'Autumn'
        END,
        c.type
)

SELECT
    JSON_OBJECT(
        'total_recorded_attacks', a.total_recorded_attacks,
        'unique_attackers', a.unique_attackers,
        'overall_defense_success_rate', a.overall_defense_success_rate,
        'security_analysis', JSON_OBJECT(
            'threat_assessment', JSON_OBJECT(
                'current_threat_level', CASE 
                    WHEN SUM(CASE WHEN ct.threat_level >= 4 THEN 1 ELSE 0 END) > 0 THEN 'High'
                    WHEN SUM(CASE WHEN ct.threat_level >= 2 THEN 1 ELSE 0 END) > 0 THEN 'Moderate'
                    ELSE 'Low'
                END,
                'active_threats', COALESCE(
                    JSON_ARRAYAGG(
                        JSON_OBJECT(
                            'creature_type', ct.creature_type,
                            'threat_level', ct.threat_level,
                            'last_sighting_date', ct.last_sighting_date,
                            'estimated_numbers', ct.estimated_numbers,
                            'zone_coverage_percent', ct.zone_coverage_percent,
                            'creature_ids', ct.creature_ids
                        )
                    ),
                    
                )
            ),
            'vulnerability_analysis', COALESCE(
                JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'zone_id', va.zone_id,
                        'zone_name', va.zone_name,
                        'vulnerability_score', va.vulnerability_score,
                        'historical_breaches', va.historical_breaches,
                        'fortification_level', va.fortification_level,
                        'military_response_time', va.military_response_time,
                        'defense_coverage', JSON_OBJECT(
                            'structure_ids', va.structure_ids,
                            'squad_ids', va.squad_ids
                        )
                    )
                ),
                
            ),
            'defense_effectiveness', COALESCE(
                JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'defense_type', de.defense_type,
                        'effectiveness_rate', de.effectiveness_rate,
                        'avg_enemy_casualties', de.avg_enemy_casualties,
                        'structure_ids', de.structure_ids
                    )
                ),
                
            ),
            'military_readiness_assessment', COALESCE(
                JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'squad_id', mr.squad_id,
                        'squad_name', mr.squad_name,
                        'readiness_score', mr.readiness_score,
                        'active_members', mr.active_members,
                        'avg_combat_skill', mr.avg_combat_skill,
                        'combat_effectiveness', mr.combat_effectiveness,
                        'response_coverage', mr.response_coverage
                    )
                ),
                
            ),
            'security_evolution', COALESCE(
                JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'year', se.year,
                        'defense_success_rate', se.defense_success_rate,
                        'total_attacks', se.total_attacks,
                        'casualties', se.casualties,
                        'year_over_year_improvement', se.year_over_year_improvement
                    )
                ),
                
            ),
        )
    ) AS fortress_security_report
FROM
    attack_stats a,
    current_threats ct,
    vulnerability_analysis va,
    defense_effectiveness de,
    military_readiness mr,
    security_evolution se
GROUP BY
    a.total_recorded_attacks, a.unique_attackers, a.overall_defense_success_rate;