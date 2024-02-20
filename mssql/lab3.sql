use SALON;

ALTER TABLE CLIENTS
ADD hierarchyNode HIERARCHYID;

CREATE OR ALTER PROCEDURE dbo.GetSubordinatesHierarchy
    @Node HIERARCHYID
AS
BEGIN
    SET NOCOUNT ON;

    WITH SubordinatesCTE AS (
        SELECT
            clientID,
            name,
            hierarchyNode.GetLevel() AS HierarchyLevel
        FROM
            CLIENTS
        WHERE
            hierarchyNode.GetAncestor(1) = @Node -- ѕолучаем все дочерние узлы дл€ указанного узла
        UNION ALL
        SELECT
            c.clientID,
            c.name,
            c.hierarchyNode.GetLevel() AS HierarchyLevel
        FROM
            CLIENTS AS c
        INNER JOIN
            SubordinatesCTE AS s ON c.hierarchyNode.GetAncestor(1) = s.hierarchyNode
    )

    SELECT
        clientID,
        name,
        HierarchyLevel
    FROM
        SubordinatesCTE;
END;
