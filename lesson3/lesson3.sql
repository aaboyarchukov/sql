SELECT 
    F.name AS FortressName,
    F.location AS FortressLocation,
    F.founded_year AS FortressFoundedYear,
    F.depth AS FortressDepth,
    F.population AS FortressPopulation,
    JSON_OBJECT(
        (
            SELECT JSON_ARRAYGG(dwarf_id) FROM Dwarves
            WHERE fortress_id = F.fortress_id
        ),
        (
            SELECT JSON_ARRAYGG(resource_id) FROM Fortress_Resources
            WHERE fortress_id = F.fortress_id
        ),
        (
            SELECT JSON_ARRAYGG(workshop_id) FROM Workshops
            WHERE fortress_id = F.fortress_id
        ),
        (
            SELECT JSON_ARRAYGG(squad_id) FROM Military_Squads
            WHERE fortress_id = F.fortress_id
        ),
    )
FROM 
    Fortresses F;