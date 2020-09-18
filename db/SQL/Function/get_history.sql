/*
Get History
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_history`(`p_id` INT(11) UNSIGNED) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT 'Get History'
BEGIN
    IF ISNULL(p_id) THEN
        RETURN response_format(3, NULL);
    END IF;

    IF ISNULL((SELECT 1 FROM tb_user WHERE _id = p_id LIMIT 1)) THEN
        RETURN response_format(5, NULL);
    END IF;

    SET @json = CONCAT(
        '[',
        (
            SELECT GROUP_CONCAT(
                DISTINCT
                '{',
                '"_id":', _id, ',',
                '"_name":"', _name, '",',
                '"_book":"', _book, '",',
                '"_price":', _price, ',',
                '"_date_time":"', _date_time, '"',
                '}'
                ORDER BY _date_time DESC
            ) FROM (
                SELECT tu._id, tu._name, th._book, th._price, th._date_time
                FROM tb_user tu, tb_history th
                WHERE tu._id = th._user
                AND tu._id = p_id
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;