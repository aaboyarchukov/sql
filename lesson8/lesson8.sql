-- Разработайте запрос, анализирующий торговые отношения со всеми цивилизациями, оценивая:
-- - Баланс торговли с каждой цивилизацией за все время
-- - Влияние товаров каждого типа на экономику крепости
-- - Корреляцию между торговлей и дипломатическими отношениями
-- - Эволюцию торговых отношений во времени
-- - Зависимость крепости от определенных импортируемых товаров
-- - Эффективность экспорта продукции мастерских

-- DIPLOMATIC_EVENTS, TRADE_TRANSACTIONS, DWARF_INTERESTS, CARAVAN_GOODS, CARAVANS, TRADERS,
-- FORTRESS_RESOURCES, RESOURCES, 

WITH trades_info AS (
    SELECT
        COUNT(DISTINCT TT.caravan_id) AS total_trading_partners,
        SUM(TT.value) AS all_time_trade_value,
        SUM(TT.balance_direction) AS all_time_trade_balance
    FROM
        Trade_Transactions TT
),  civilization_data AS (
    SELECT
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'civilization_type', (C.civilization_type),
                'total_caravans', (COUNT(C.caravan_id)),
                'total_trade_value', (SUM(TT.value)),
                'trade_balance', (SUM(TT.balance_direction)),
                'trade_relationship', (DE.relationship_change),
                'diplomatic_correlation', (CORR()),
                'caravan_ids', (JSON_ARRAYAGG(C.caravan_id)) 
            )
        ) AS civilization_trade_data

    FROM Caravans C 
    JOIN Trade_Transactions TT ON C.caravan_id = TT.caravan_id
    JOIN Diplomatic_Events DE ON C.caravan_id = DE.C.caravan_id
    
    GROUP BY C.civilization_type, DE.relationship_change 
),  critical_import_dependencies AS (
    SELECT 
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'material_type', (CG.material_type),
                'dependency_score', (),
                'total_imported', (SUM(CASE WHEN CG.goods_id IN TT.caravan_items THEN 1  ELSE 0 END)),
                'import_diversity', (COUNT(DISTINCT TT.caravan_id)),
                'resource_ids', (JSON_ARRAYAGG(DISTINCT R.resource_id))
            )
        ) AS resource_dependency
    FROM Caravan_Goods CG
    LEFT JOIN Trade_Transactions TT ON CG.caravan_id = TT.caravan_id AND CG.type = 'import'
    JOIN Resources R ON CS.material_type = R.type
    GROUP BY CG.material_type
), export_effectiveness AS (
    SELECT 
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'workshop_type', (W.type),
                'product_type', (P.type),
                'export_ratio', (ROUND(
                    SUM(CASE WHEN CG.goods_id IN TT.caravan_items THEN 1 ELSE 0 END) / 
                )),
                'avg_markup', (),
                'workshop_ids', (JSON_ARRAYAGG(DISTINCT W.workshop_id))
            )
        ) AS export_effectiveness
    FROM Caravan_Goods CG
    LEFT JOIN Trade_Transactions TT ON CG.caravan_id = TT.caravan_id AND CG.type = 'import'
    LEFT JOIN Caravans C ON CG.caravan_id = C.caravan_id
    LEFT JOIN Fortresses F ON C. fortress_id = F.fortress_id
    LEFT JOIN Workshops W ON F.workshop_id = W.workshop_id  
    LEFT JOIN Products P ON P.product_id = C.original_product_id

    GROUP BY W.type, P.type
), trade_timeline AS (
    SELECT
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'year', (EXTRACT(YEAR FROM TT.date)),
                'quarter', (QUARTER(TT.date)),
                'quarterly_value', (SUM(TT.value)),
                'quarterly_balance', (SUM(TT.balance_direction)),
                'trade_diversity', (JSON_ARRAYAGG(DISTINCT TT.caravan_id))
            )
        ) AS trade_growth
    FROM Trade_Transactions TT

    GROUP BY EXTRACT(YEAR FROM TT.date), QUARTER(TT.date)
)