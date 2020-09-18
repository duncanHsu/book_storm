/*
在一個日期範圍內進行高於或低於$ v的交易的用戶總數
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_quantity`(`p_str_date` DATE, `p_end_date` DATE, `p_min_price` DOUBLE(10,2) UNSIGNED, `p_max_price` DOUBLE(10,2) UNSIGNED) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '在一個日期範圍內進行高於或低於$ v的交易的用戶總數'
BEGIN
    IF ISNULL(p_str_date)
    || ISNULL(p_end_date)
    || ISNULL(p_min_price)
    || ISNULL(p_max_price) THEN
        RETURN response_format(3, NULL);
    END IF;

    SET @endDate = CONCAT(p_end_date, ' 23:59:59');

    SET @json = (
        SELECT GROUP_CONCAT(
            DISTINCT
            '{',
            '"_quantity":', _quantity,
            '}'
        ) FROM (
            SELECT COUNT(*) _quantity FROM tb_user tu
            LEFT JOIN tb_history th
            ON tu._id = th._user
            WHERE th._date_time >= p_str_date
            AND th._date_time <= @endDate
            AND th._price >= p_min_price
            AND th._price <= p_max_price
        ) tb
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;