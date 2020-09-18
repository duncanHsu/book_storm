/*
列出價格範圍內的所有書籍，按價格或字母順序排列
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_book_list_for_price`(`p_min` DOUBLE(10,2) UNSIGNED, `p_max` DOUBLE(10,2) UNSIGNED) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '列出價格範圍內的所有書籍，按價格或字母順序排列'
BEGIN
    IF ISNULL(p_min)
    || ISNULL(p_max) THEN
        RETURN response_format(3, NULL);
    END IF;

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
                ORDER BY _price ASC, _name ASC
            ) FROM (
                SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._name _store
                FROM tb_book tb, tb_store ts
                WHERE ts._id = tb._store
                AND tb._price >= p_min
                AND tb._price <= p_max
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;