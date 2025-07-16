-- Разработайте запрос, который анализирует эффективность каждой мастерской, учитывая:
-- - Производительность каждого ремесленника (соотношение созданных продуктов к затраченному времени) (daily_production_rate + value_per_material_unit)
-- - Эффективность использования ресурсов (соотношение потребляемых ресурсов к производимым товарам) (material_conversion_ratio)
-- - Качество производимых товаров (средневзвешенное по ценности)
-- - Время простоя мастерской (workshop_utilization_percent)
-- - Влияние навыков ремесленников на качество товаров (skill_quality_correlation)

WITH efficiency_stat AS (
    SELECT 
        Pr.created_by AS worker, 
        Pr.workshop_id,
        Pr.product_id, 
        SUM(Pr.quality) as products_quality,
        ROUND(SUM(WshPr.quantity) / SUM(WshPr.production_date - WshCrf.assignment_date), 2)
        AS dwarf_efficiency,
        SUM(Pr.value) AS value,
        SUM(WshPr.quantity) AS weight 
    FROM Products Pr
    JOIN Workshop_Products WshPr ON Pr.product_id = WshPr.product_id
    JOIN Workshop_Craftsdwarves WshCrf ON Pr.workshop_id = WshCrf.workshop_id
    GROUP BY Pr.workshop_id, Pr.created_by, Pr.product_id
),
    products_materials AS (
    SELECT 
        Pr.product_id,
        SUM(WshPr.quantity) AS product_quantity,
        SUM(CASE WHEN WshM.is_input = TRUE THEN WshM.quantity ELSE 0 END) AS material_quantity
    FROM Products Pr
    JOIN Workshop_Products WshPr ON Pr.product_id = WshPr.product_id
    JOIN Workshop_Materials WshM ON Pr.material_id = WshM.material_id
    GROUP BY Pr.product_id
),
    workshop_stat AS (
    SELECT
        Wsh.workshop_id AS workshop_id,
        Wsh.name AS workshop_name, 
        Wsh.type AS workshop_type,
        COUNT(WshCrf.dwarf_id) AS num_craftsdwarves,
        SUM(WshPr.quantity) AS total_quantity_produced,
        SUM(Pr.value) AS total_production_value,
        AS daily_production_rate
    FROM Workshops Wsh
    JOIN Workshop_Craftsdwarves WshCrf ON Wsh.workshop_id = WshCrf.workshop_id
    JOIN Workshop_Products WshPr ON Wsh.workshop_id = WshPr.workshop_id
    JOIN Products Pr ON Wsh.workshop_id = Pr.workshop_id
    GROUP BY Wsh.workshop_id
), 
    workshop_production AS (
    SELECT 
        Wsh.workshop_id AS workshop_id,
        SUM(WshPr.quantity) AS products_quantity,
        SUM(WshPr.production_date - WshCrf.assignment_date) AS duration,
    FROM Workshops Wsh
    JOIN Workshop_Products WshPr ON Wsh.workshop_id = WshPr.workshop_id
    JOIN Workshop_Craftsdwarves WshCrf ON Wsh.workshop_id = WshCrf.workshop_id
)

SELECT 
    wsh_st.workshop_id AS workshop_id,
    wsh_st.name AS workshop_name, 
    wsh_st.type AS workshop_type,
    wsh_st.num_craftsdwarves AS num_craftsdwarves,
    wsh_st.total_quantity_produced AS total_quantity_produced,
    wsh_st.total_production_value AS total_production_value,
    wsh_st.daily_production_rate AS daily_production_rate,
    ROUND(SUM(es.value * es.weight) / SUM(es.weight), 2) AS value_per_material_unit,
    ROUND(wsh_p.products_quantity / wsh_p.duration, 2) AS workshop_utilization_percent,
    ROUND(pm.material_quantity / pm.product_quantity, 2) AS material_conversion_ratio,
    ROUND(SUM(es.dwarf_efficiency) / COUNT(es.worker), 2) AS average_craftsdwarf_skill,
    ROUND(SUM(es.dwarf_efficiency) / SUM(es.products_quality)) AS skill_quality_correlation,
    JSON_OBJECT(
        ('craftsdwarf_ids', (
            SELECT JSON_ARRAYGG(WshCrf.dwarf_id) FROM Workshop_Craftdwarves WshCrf
            WHERE WshCrf.workshop_id = wsh_st.workshop_id
        )),
        ('product_ids', (
            SELECT JSON_ARRAYGG(WshPr.product_id) FROM Workshop_Products WshPr
            WHERE WshPr.workshop_id = wsh_st.workshop_id
        )),
        ('material_ids', (
            SELECT JSON_ARRAYGG(WshM.material_id) FROM Workshop_Materials WshM
            WHERE WshM.workshop_id = wsh_st.workshop_id AND WshM.is_input = TRUE
        )),
        ('project_ids', (
            SELECT JSON_ARRAYGG(P.project_id) FROM Projects P
            WHERE P.workshop_id = wsh_st.workshop_id
        ))
    ) as related_entities
FROM efficiency_stat es
JOIN products_materials pm ON es.product_id = pm.product_id 
JOIN workshop_stat wsh_st ON es.workshop_id = wsh_st.workshop_id 
GROUP BY es.workshop_id;