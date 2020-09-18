/*
按交易量（按交易次數或交易金額）最受歡迎的書店
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_list_for_rank`(`p_mode` ENUM('Q','S') CHARSET utf8) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '按交易量（按交易次數或交易金額）最受歡迎的書店'
BEGIN
    IF ISNULL(p_mode) THEN
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
                '"_quantity":', _quantity, ',',
                '"_sum":', _sum,
                '}'
                ORDER BY CASE 
                    WHEN p_mode = 'Q' THEN _quantity
                    WHEN p_mode = 'S' THEN _sum
                END DESC
            ) FROM (
                SELECT * FROM (
                    SELECT ts._id, ts._name, (
                        SELECT COUNT(*) _quantity
                        FROM tb_store ts3
                        LEFT JOIN tb_history th3
                        ON ts3._id = th3._store
                        WHERE ts3._id = ts._id
                        GROUP BY ts._id
                    ) _quantity, (
                        SELECT SUM(th2._price)
                        FROM tb_store ts2
                        LEFT JOIN tb_history th2
                        ON ts2._id = th2._store
                        WHERE ts2._id = ts._id
                    ) _sum
                    FROM tb_store ts
                    LEFT JOIN tb_history th
                    ON ts._id = th._store
                    GROUP BY ts._id ASC
                ) tb
            ) tb
        ),
        ']'
    );
    
    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN 'null' ELSE @json END);
END$$
DELIMITER ;