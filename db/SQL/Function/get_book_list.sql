/*
Get Book List
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_book_list`() RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT 'Get Book List'
BEGIN
    SET @json = CONCAT(
        '[',
        (
            SELECT GROUP_CONCAT(
                DISTINCT
                '{',
                '"_id":', _id, ',',
                '"_name":"', _name, '",',
                '"_price":', _price, ',',
                '"_store_id":', _store_id, ',',
                '"_store":"', _store, '"',
                '}'
                ORDER BY _store_id ASC, _name ASC
            ) FROM (
                SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._name _store
                FROM tb_book tb, tb_store ts
                WHERE ts._id = tb._store
            ) tb
        ),
        ']'
    );

    RETURN CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END;
END$$
DELIMITER ;