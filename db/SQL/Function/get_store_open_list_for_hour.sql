/*
列出每天或每週營業超過或少於x小時的所有書店
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_open_list_for_hour`(`p_mode` ENUM('W','D') CHARSET utf8, `p_hour` INT(3) UNSIGNED) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '列出每天或每週營業超過或少於x小時的所有書店'
BEGIN
    IF ISNULL(p_mode)
    || ISNULL(p_hour) THEN
        RETURN response_format(3, NULL);
    END IF;

    IF p_mode = 'W' THEN
        SET @json = CONCAT(
            '[',
            (
                SELECT GROUP_CONCAT(
                    DISTINCT
                    '{',
                    '"_id":', _id, ',',
                    '"_name":"', _name, '",',
                    '"_mon":', CASE WHEN ISNULL(_mon) THEN 'null' ELSE CONCAT('"', _mon, '"') END, ',',
                    '"_tues":', CASE WHEN ISNULL(_tues) THEN 'null' ELSE CONCAT('"', _tues, '"') END, ',',
                    '"_wed":', CASE WHEN ISNULL(_wed) THEN 'null' ELSE CONCAT('"', _wed, '"') END, ',',
                    '"_thurs":', CASE WHEN ISNULL(_thurs) THEN 'null' ELSE CONCAT('"', _thurs, '"') END, ',',
                    '"_fri":', CASE WHEN ISNULL(_fri) THEN 'null' ELSE CONCAT('"', _fri, '"') END, ',',
                    '"_sat":', CASE WHEN ISNULL(_sat) THEN 'null' ELSE CONCAT('"', _sat, '"') END, ',',
                    '"_sun":', CASE WHEN ISNULL(_sun) THEN 'null' ELSE CONCAT('"', _sun, '"') END,
                    '}'
                ) FROM (
                    SELECT * FROM (
                        SELECT ts._id, ts._name,
                        CASE WHEN ISNULL(toh._mon_end) || ISNULL(toh._mon_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._mon_end, toh._mon_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._mon_end, toh._mon_str), '24:0:00')
                        ELSE TIMEDIFF(toh._mon_end, toh._mon_str) END _mon, 
                        CASE WHEN ISNULL(toh._tues_end) || ISNULL(toh._tues_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._tues_end, toh._tues_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._tues_end, toh._tues_str), '24:0:00')
                        ELSE TIMEDIFF(toh._tues_end, toh._tues_str) END _tues, 
                        CASE WHEN ISNULL(toh._wed_end) || ISNULL(toh._wed_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._wed_end, toh._wed_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._wed_end, toh._wed_str), '24:0:00')
                        ELSE TIMEDIFF(toh._wed_end, toh._wed_str) END _wed, 
                        CASE WHEN ISNULL(toh._thurs_end) || ISNULL(toh._thurs_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._thurs_end, toh._thurs_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._thurs_end, toh._thurs_str), '24:0:00')
                        ELSE TIMEDIFF(toh._thurs_end, toh._thurs_str) END _thurs, 
                        CASE WHEN ISNULL(toh._fri_end) || ISNULL(toh._fri_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._fri_end, toh._fri_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._fri_end, toh._fri_str), '24:0:00')
                        ELSE TIMEDIFF(toh._fri_end, toh._fri_str) END _fri, 
                        CASE WHEN ISNULL(toh._sat_end) || ISNULL(toh._sat_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._sat_end, toh._sat_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._sat_end, toh._sat_str), '24:0:00')
                        ELSE TIMEDIFF(toh._sat_end, toh._sat_str) END _sat, 
                        CASE WHEN ISNULL(toh._sun_end) || ISNULL(toh._sun_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._sun_end, toh._sun_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._sun_end, toh._sun_str), '24:0:00')
                        ELSE TIMEDIFF(toh._sun_end, toh._sun_str) END _sun
                        FROM tb_store ts, tb_opening_hours toh
                        WHERE ts._id = toh._store
                    ) tb
                    WHERE ADDTIME(
                        CASE WHEN ISNULL(_mon) THEN 0 ELSE _mon END,
                        ADDTIME(
                            CASE WHEN ISNULL(_tues) THEN 0 ELSE _tues END,
                            ADDTIME(
                                CASE WHEN ISNULL(_wed) THEN 0 ELSE _wed END,
                                ADDTIME(
                                    CASE WHEN ISNULL(_thurs) THEN 0 ELSE _thurs END,
                                    ADDTIME(
                                        CASE WHEN ISNULL(_fri) THEN 0 ELSE _fri END,
                                        ADDTIME(
                                            CASE WHEN ISNULL(_sat) THEN 0 ELSE _sat END,
                                            CASE WHEN ISNULL(_sun) THEN 0 ELSE _sun END
                                        )
                                    )
                                )
                            )
                        )
                    ) >= CONCAT(p_hour, ':00:00')
                ) tb
            ),
            ']'
        );
    ELSEIF p_mode = 'D' THEN
        SET @json = CONCAT(
            '[',
            (
                SELECT GROUP_CONCAT(
                    DISTINCT
                    '{',
                    '"_id":', _id, ',',
                    '"_name":"', _name, '",',
                    '"_mon":', CASE WHEN ISNULL(_mon) THEN 'null' ELSE CONCAT('"', _mon, '"') END, ',',
                    '"_tues":', CASE WHEN ISNULL(_tues) THEN 'null' ELSE CONCAT('"', _tues, '"') END, ',',
                    '"_wed":', CASE WHEN ISNULL(_wed) THEN 'null' ELSE CONCAT('"', _wed, '"') END, ',',
                    '"_thurs":', CASE WHEN ISNULL(_thurs) THEN 'null' ELSE CONCAT('"', _thurs, '"') END, ',',
                    '"_fri":', CASE WHEN ISNULL(_fri) THEN 'null' ELSE CONCAT('"', _fri, '"') END, ',',
                    '"_sat":', CASE WHEN ISNULL(_sat) THEN 'null' ELSE CONCAT('"', _sat, '"') END, ',',
                    '"_sun":', CASE WHEN ISNULL(_sun) THEN 'null' ELSE CONCAT('"', _sun, '"') END,
                    '}'
                ) FROM (
                    SELECT * FROM (
                        SELECT ts._id, ts._name,
                        CASE WHEN ISNULL(toh._mon_end) || ISNULL(toh._mon_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._mon_end, toh._mon_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._mon_end, toh._mon_str), '24:0:00')
                        ELSE TIMEDIFF(toh._mon_end, toh._mon_str) END _mon, 
                        CASE WHEN ISNULL(toh._tues_end) || ISNULL(toh._tues_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._tues_end, toh._tues_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._tues_end, toh._tues_str), '24:0:00')
                        ELSE TIMEDIFF(toh._tues_end, toh._tues_str) END _tues, 
                        CASE WHEN ISNULL(toh._wed_end) || ISNULL(toh._wed_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._wed_end, toh._wed_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._wed_end, toh._wed_str), '24:0:00')
                        ELSE TIMEDIFF(toh._wed_end, toh._wed_str) END _wed, 
                        CASE WHEN ISNULL(toh._thurs_end) || ISNULL(toh._thurs_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._thurs_end, toh._thurs_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._thurs_end, toh._thurs_str), '24:0:00')
                        ELSE TIMEDIFF(toh._thurs_end, toh._thurs_str) END _thurs, 
                        CASE WHEN ISNULL(toh._fri_end) || ISNULL(toh._fri_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._fri_end, toh._fri_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._fri_end, toh._fri_str), '24:0:00')
                        ELSE TIMEDIFF(toh._fri_end, toh._fri_str) END _fri, 
                        CASE WHEN ISNULL(toh._sat_end) || ISNULL(toh._sat_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._sat_end, toh._sat_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._sat_end, toh._sat_str), '24:0:00')
                        ELSE TIMEDIFF(toh._sat_end, toh._sat_str) END _sat, 
                        CASE WHEN ISNULL(toh._sun_end) || ISNULL(toh._sun_str) THEN
                            NULL
                        WHEN TIMEDIFF(toh._sun_end, toh._sun_str) < 0 THEN
                            ADDTIME(TIMEDIFF(toh._sun_end, toh._sun_str), '24:0:00')
                        ELSE TIMEDIFF(toh._sun_end, toh._sun_str) END _sun
                        FROM tb_store ts, tb_opening_hours toh
                        WHERE ts._id = toh._store
                    ) tb
                    WHERE NOT ISNULL(_mon)
                    AND NOT ISNULL(_tues)
                    AND NOT ISNULL(_wed)
                    AND NOT ISNULL(_thurs)
                    AND NOT ISNULL(_fri)
                    AND NOT ISNULL(_sat)
                    AND NOT ISNULL(_sun)
                    AND _mon >= CONCAT(p_hour, ':00:00')
                    AND _tues >= CONCAT(p_hour, ':00:00')
                    AND _wed >= CONCAT(p_hour, ':00:00')
                    AND _thurs >= CONCAT(p_hour, ':00:00')
                    AND _fri >= CONCAT(p_hour, ':00:00')
                    AND _sat >= CONCAT(p_hour, ':00:00')
                    AND _sun >= CONCAT(p_hour, ':00:00')
                ) tb
            ),
            ']'
        );
    END IF;

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;