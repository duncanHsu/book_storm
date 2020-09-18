/*
在日期範圍內，按交易總額計的前x位用戶
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_list_for_date_time_sum`(`p_str_date` DATE, `p_end_date` DATE, `p_rank` INT(3) UNSIGNED) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '在日期範圍內，按交易總額計的前x位用戶'
BEGIN
    IF ISNULL(p_str_date)
    || ISNULL(p_end_date)
    || ISNULL(p_rank) THEN
        RETURN response_format(3, NULL);
    END IF;

    SET @endDate = CONCAT(p_end_date, ' 23:59:59');

    SET @json = CONCAT(
        '[',
        (
            SELECT GROUP_CONCAT(
                DISTINCT
                '{',
                '"_id":', _id, ',',
                '"_name":"', _name, '",',
                '"_sum":', _sum,
                '}'
            ) FROM (
                SELECT tu._id, tu._name, (
                    SELECT SUM(_price) FROM tb_history 
                    WHERE _user = tu._id
                    AND _date_time >= p_str_date
                    AND _date_time <= @endDate
                ) _sum
                FROM tb_user tu, tb_history th
                WHERE tu._id = th._user
                AND th._date_time >= p_str_date
                AND th._date_time <= @endDate
                GROUP BY _sum DESC
                LIMIT p_rank
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;