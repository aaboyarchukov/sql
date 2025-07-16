# Рефлексия

Эталонное решение:

```sql
WITH workshop_activity AS (
    SELECT 
        w.workshop_id,
        w.name AS workshop_name,
        w.type AS workshop_type,
        COUNT(DISTINCT wc.dwarf_id) AS num_craftsdwarves,
        COUNT(DISTINCT wp.product_id) AS products_produced,
        SUM(wp.quantity) AS total_quantity_produced,
        SUM(p.value * wp.quantity) AS total_production_value,
        COUNT(DISTINCT wm.material_id) AS materials_used,
        SUM(wm.quantity) AS total_materials_consumed,
        MAX(wp.production_date) - MIN(wc.assignment_date) AS production_timespan,
        -- Days with production vs. total days active
        COUNT(DISTINCT wp.production_date) AS active_production_days,
        EXTRACT(DAY FROM (MAX(wp.production_date) - MIN(wc.assignment_date))) AS total_days
    FROM 
        workshops w
    LEFT JOIN 
        workshop_craftsdwarves wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN 
        workshop_products wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN 
        products p ON wp.product_id = p.product_id
    LEFT JOIN 
        workshop_materials wm ON w.workshop_id = wm.workshop_id AND wm.is_input = TRUE
    GROUP BY 
        w.workshop_id, w.name, w.type
),
craftsdwarf_productivity AS (
    SELECT 
        wc.workshop_id,
        wc.dwarf_id,
        COUNT(DISTINCT p.product_id) AS products_created,
        AVG(p.quality::INTEGER) AS avg_quality,
        SUM(p.value) AS total_value_created
    FROM 
        workshop_craftsdwarves wc
    JOIN 
        products p ON p.created_by = wc.dwarf_id
    GROUP BY 
        wc.workshop_id, wc.dwarf_id
),
craftsdwarf_skills AS (
    SELECT 
        wc.workshop_id,
        wc.dwarf_id,
        AVG(ds.level) AS avg_skill_level,
        MAX(ds.level) AS max_skill_level
    FROM 
        workshop_craftsdwarves wc
    JOIN 
        dwarf_skills ds ON wc.dwarf_id = ds.dwarf_id
    JOIN 
        skills s ON ds.skill_id = s.skill_id
    WHERE 
        s.category = 'Crafting'
    GROUP BY 
        wc.workshop_id, wc.dwarf_id
),
material_efficiency AS (
    SELECT 
        w.workshop_id,
        SUM(CASE WHEN wm.is_input = TRUE THEN wm.quantity ELSE 0 END) AS input_quantity,
        SUM(CASE WHEN wm.is_input = FALSE THEN wm.quantity ELSE 0 END) AS output_quantity,
        COUNT(DISTINCT CASE WHEN wm.is_input = TRUE THEN wm.material_id END) AS unique_inputs,
        COUNT(DISTINCT CASE WHEN wm.is_input = FALSE THEN wm.material_id END) AS unique_outputs
    FROM 
        workshops w
    LEFT JOIN 
        workshop_materials wm ON w.workshop_id = wm.workshop_id
    GROUP BY 
        w.workshop_id
)
SELECT 
    wa.workshop_id,
    wa.workshop_name,
    wa.workshop_type,
    wa.num_craftsdwarves,
    wa.total_quantity_produced,
    wa.total_production_value,
    
    -- Productivity metrics
    ROUND(wa.total_quantity_produced::DECIMAL / NULLIF(wa.total_days, 0), 2) AS daily_production_rate,
    ROUND(wa.total_production_value::DECIMAL / NULLIF(wa.total_materials_consumed, 0), 2) AS value_per_material_unit,
    ROUND((wa.active_production_days::DECIMAL / NULLIF(wa.total_days, 0)) * 100, 2) AS workshop_utilization_percent,
    
    -- Efficiency metrics
    ROUND(me.output_quantity::DECIMAL / NULLIF(me.input_quantity, 0), 2) AS material_conversion_ratio,
    
    -- Craftsdwarf skill influence
    ROUND(AVG(cs.avg_skill_level), 2) AS average_craftsdwarf_skill,
    
    -- Correlation between skill and productivity
    CORR(cs.avg_skill_level, cp.avg_quality) AS skill_quality_correlation,
    
    -- Related entities for REST API
    JSON_OBJECT(
        'craftsdwarf_ids', (
            SELECT JSON_ARRAYAGG(wc.dwarf_id)
            FROM workshop_craftsdwarves wc
            WHERE wc.workshop_id = wa.workshop_id
        ),
        'product_ids', (
            SELECT JSON_ARRAYAGG(DISTINCT wp.product_id)
            FROM workshop_products wp
            WHERE wp.workshop_id = wa.workshop_id
        ),
        'material_ids', (
            SELECT JSON_ARRAYAGG(DISTINCT wm.material_id)
            FROM workshop_materials wm
            WHERE wm.workshop_id = wa.workshop_id
        ),
        'project_ids', (
            SELECT JSON_ARRAYAGG(p.project_id)
            FROM projects p
            WHERE p.workshop_id = wa.workshop_id
        )
    ) AS related_entities
FROM 
    workshop_activity wa
LEFT JOIN 
    material_efficiency me ON wa.workshop_id = me.workshop_id
LEFT JOIN 
    craftsdwarf_skills cs ON wa.workshop_id = cs.workshop_id
LEFT JOIN 
    craftsdwarf_productivity cp ON wa.workshop_id = cp.workshop_id AND cs.dwarf_id = cp.dwarf_id
GROUP BY 
    wa.workshop_id, wa.workshop_name, wa.workshop_type, wa.num_craftsdwarves,
    wa.total_quantity_produced, wa.total_production_value, wa.total_days,
    wa.active_production_days, wa.total_materials_consumed,
    me.input_quantity, me.output_quantity, me.unique_inputs, me.unique_outputs
ORDER BY 
    (wa.total_production_value::DECIMAL / NULLIF(wa.total_materials_consumed, 0)) * 
    (wa.active_production_days::DECIMAL / NULLIF(wa.total_days, 0)) DESC;
```


Данное задание я решил неправильно в виду некоторых причин причин:

1. Неверно понял некоторые метрики и как их получать

В некоторых пунктах задания я думал, что необходимо самому высчитывать значение (как например, средневзвешенное или корреляция), хотя можно было обойтись агрегатными функциями

2. Я придумывал сам значение метрикам и пытался сопоставить с примером ответа выдачи, хотя необходимо было напрямую вывести то, что дается в выдачи
3. Также я не использовал некоторые конструкции, поскольку не учитывал то, как хранятся некоторые данные и какие имеют отношения между собой некоторые таблицы (например то, что какие-то гномы могли работать в одних мастерских, а потом их могли направить в другие мастерские, из-за этого я не использовал `DISTINCT`, также не учитывал определенную способность гномов, такую как: `Crafting`)
4. Из предыдущего пункта вытекает то, что я недостаточно внимателен к деталям и не сильно глубоко погружаюсь в контекст, хотя это необходимо для успешного выполнения задания
5. Также стоит отметить, что в моем решении при делении я не обрабатываю случай, когда число может оказаться 0

Разберем полностью задание подробно: 

В `workshop_activity` мы получаем данные об активности мастерских, а именно:
- Информация об мастерской
- Количество работающих гномов на мастерской
- Общее количество продуктов, произведенных в мастерской
- Общее количество экземпляров продукции, произведенных в мастерской
- Суммарное значение всех произведенных продуктов
- Общее количество видов материалов, которые использовались для производства
- Суммарное количество материалов, которое использовалось для производства
- Время, затраченное производство продукта (вычисляется как разница между последней датой окончания производства этого продукта и первой датой начало назначения гнома на производство в мастерской)
Также мы соединяем между собой отношения с помощью `LEFT JOIN` для того, чтобы обработать все мастерские, даже те, которые неактивны. И соответственно группируем по тем данным, которые не входили в агрегатные функции.

Далее в `craftsdwarf_productivity` мы получаем данные о продуктивности гномов, а именно:
- Мастерскую и самого гнома
- Количество уникальных продуктов, произведенных гномом
- Среднее значение качества произведенной продукции
- Суммарное значение произведенных продуктов

Также мы определяем способности гномов в `craftsdwarf_skills` по следующим характеристикам:
- Мастерскую и самого гнома
- Среднее значение уровня способностей гнома
- Максимальное значение уровня способностей гнома
Стоит заметить то, что мы фильтруем только по способности `Crafting`

И наконец - эффективность использования материалов - `material_efficiency`:
- Информация о мастерской
- Суммарное количество используемого материала
- Суммарное количество неиспользуемого материала
- Суммарное количество используемых типов материалов
- Суммарное количество неиспользуемых типов материалов

Ну, а итоговым запросом - агрегирование всех полученных подзапросов до этого:

- Вся информация о каждой мастерской, количестве рабочих и количестве произведенных продуктов 
- Далее идут метрики продуктивности гномов в мастерской, а именно:
	- Дневная норма производства
	- Ценность производимых продуктов на единицу используемого материала
	- Процент использования мастерской
		Также стоит заметить, что целые числа мы приводим к вещественным, а также используем функцию округления `ROUND` и функцию `NULLIF`, чтобы в случае количества дней равное 0, нам вернулось `NULL`
- Затем идет метрика эффективности, то есть сколько ушло материала на производство в отношении материала, который был в мастерской
- После этого идет влияние способностей гномов, здесь мы используем функцию `AVG` для нахождения среднего значения
- В продолжении мы находим корреляцию между уровнем способностей и качеством произведенной продукции
- В конце выводим остальные данные
		Также стоит заметить то, что снова используется `LEFT JOIN` для того, чтобы охватить все мастерские, даже те, которые не были активны. И в конце после группировки значений по нескольким параметрам - идет сортировка по ценности произведенного продукта на дни активной работы мастерских