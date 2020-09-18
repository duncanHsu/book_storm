/*
列出所有擁有多於或少於x本書數量的書店
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_list_for_book_quantity`(`p_min` INT(3) UNSIGNED, `p_max` INT(3) UNSIGNED) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '列出所有擁有多於或少於x本書數量的書店'
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
                '"_store":"', _store, '",',
                '"_quantity":', _quantity,
                '}'
            ) FROM (
                SELECT * FROM (
                    SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._name _store, COUNT(*) _quantity
                    FROM tb_book tb, tb_store ts
                    WHERE ts._id = tb._store
                    GROUP BY ts._id ASC
                ) tb
                WHERE _quantity >= p_min
                AND _quantity <= p_max
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;