/*
按名稱搜索書店或書籍，並按與搜索詞的相關性排序
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_book_list_for_keyword`(`p_keyword` VARCHAR(255) CHARSET utf8) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '按名稱搜索書店或書籍，並按與搜索詞的相關性排序'
BEGIN
    IF ISNULL(p_keyword) THEN
        RETURN response_format(3, NULL);
    END IF;

    SET @keyword = p_keyword COLLATE utf8_unicode_ci;

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
            ) FROM (
                SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._name _store
                FROM tb_book tb, tb_store ts
                WHERE ts._id = tb._store
                AND (tb._name LIKE CONCAT(@keyword, '%') OR ts._name LIKE CONCAT(@keyword, '%'))
                UNION
                SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._name _store
                FROM tb_book tb, tb_store ts
                WHERE ts._id = tb._store
                AND (tb._name LIKE CONCAT('%', @keyword, '%') OR ts._name LIKE CONCAT('%', @keyword, '%'))
                AND (tb._name NOT LIKE CONCAT(@keyword, '%') OR ts._name NOT LIKE CONCAT(@keyword, '%'))
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;