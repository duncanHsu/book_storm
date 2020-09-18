/*
列出價格範圍內書數超過或少於x的所有書店
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_list_for_book_price`(`p_min_quantity` INT(3) UNSIGNED, `p_max_quantity` INT(3) UNSIGNED, `p_min_price` DOUBLE(10,2) UNSIGNED, `p_max_price` DOUBLE(10,2) UNSIGNED) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '列出價格範圍內書數超過或少於x的所有書店'
BEGIN
    IF ISNULL(p_min_quantity)
    || ISNULL(p_max_quantity)
    || ISNULL(p_min_price)
    || ISNULL(p_max_price) THEN
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
                WHERE _quantity >= p_min_quantity
                AND _quantity <= p_max_quantity
                AND _price >= p_min_price
                AND _price <= p_max_price
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;