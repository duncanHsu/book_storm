/*
在一個日期範圍內發生的交易總數和美元價值
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_quantity_sum_for_date`(`p_str_date` DATE, `p_end_date` DATE) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '在一個日期範圍內發生的交易總數和美元價值'
BEGIN
    IF ISNULL(p_str_date)
    || ISNULL(p_end_date) THEN
        RETURN response_format(3, NULL);
    END IF;

    SET @endDate = CONCAT(p_end_date, ' 23:59:59');

    SET @json = (
        SELECT GROUP_CONCAT(
            DISTINCT
            '{',
            '"_quantity":', _quantity, ',',
            '"_sum":', _sum,
            '}'
        ) FROM (
            SELECT COUNT(*) _quantity, SUM(_price) _sum FROM tb_history 
            WHERE _date_time >= p_str_date
            AND _date_time <= @endDate
            LIMIT 1
        ) tb
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN 'null' ELSE @json END);
END$$
DELIMITER ;