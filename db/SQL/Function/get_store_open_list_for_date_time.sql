/*
列出在特定日期時間開放的所有書店
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_open_list_for_date_time`(`p_date_time` DATETIME) RETURNS mediumtext CHARSET utf8
    NO SQL
    COMMENT '列出在特定日期時間開放的所有書店'
BEGIN
    IF ISNULL(p_date_time) THEN
        RETURN response_format(3, NULL);
    END IF;

    SET @week = DATE_FORMAT(p_date_time, '%w');

    IF ISNULL(@week) THEN
        RETURN response_format(8, NULL);
    END IF;

    SET @time = TIME(p_date_time);

    SET @json = CONCAT(
        '[',
        (
            SELECT GROUP_CONCAT(
                DISTINCT
                '{',
                '"_id":', _id, ',',
                '"_name":"', _name, '",',
                '"_mon":"Mon ', _mon_str,' - ', 
                    CASE WHEN TIMEDIFF(_mon_str, _mon_end) < 0 THEN 'Mon ' ELSE 'Tues ' END, 
                    _mon_end ,'",',
                '"_tues":"Tues ', _tues_str,' - ', 
                    CASE WHEN TIMEDIFF(_tues_str, _tues_end) < 0 THEN 'Tues ' ELSE 'Wed ' END, 
                    _tues_end ,'",',
                '"_wed":"Wed ', _wed_str,' - ', 
                    CASE WHEN TIMEDIFF(_wed_str, _wed_end) < 0 THEN 'Wed ' ELSE 'Thurs ' END, 
                    _wed_end ,'",',
                '"_thurs":"Thurs ', _thurs_str,' - ', 
                    CASE WHEN TIMEDIFF(_thurs_str, _thurs_end) < 0 THEN 'Thurs ' ELSE 'Fri ' END, 
                    _thurs_end ,'",',
                '"_fri":"Fri ', _fri_str,' - ', 
                    CASE WHEN TIMEDIFF(_fri_str, _fri_end) < 0 THEN 'Fri ' ELSE 'Sat ' END, 
                    _fri_end ,'",',
                '"_sat":"Sat ', _sat_str,' - ', 
                    CASE WHEN TIMEDIFF(_sat_str, _sat_end) < 0 THEN 'Sat ' ELSE 'Sun ' END, 
                    _sat_end ,'",',
                '"_sun":"Sun ', _sun_end,' - ', 
                    CASE WHEN TIMEDIFF(_sun_str, _sun_end) < 0 THEN 'Sun ' ELSE 'Mon ' END, 
                    _sun_end ,'"',
                '}'
            ) FROM (
                SELECT ts._id, ts._name, toh._mon_str, toh._mon_end, toh._tues_str, toh._tues_end, toh._wed_str, toh._wed_end, toh._thurs_str, toh._thurs_end, toh._fri_str, toh._fri_end, toh._sat_str, toh._sat_end, toh._sun_str, toh._sun_end
                FROM tb_store ts, tb_opening_hours toh
                WHERE ts._id = toh._store
                AND (CASE 
                    WHEN @week = 1 THEN toh._sat_str
                    WHEN @week = 2 THEN toh._tues_str
                    WHEN @week = 3 THEN toh._wed_str
                    WHEN @week = 4 THEN toh._thurs_str
                    WHEN @week = 5 THEN toh._fri_str
                    WHEN @week = 6 THEN toh._sat_str
                    WHEN @week = 0 THEN toh._sun_str
                    END) <= @time
                AND (CASE 
                    WHEN @week = 1 THEN toh._sat_end
                    WHEN @week = 2 THEN toh._tues_end
                    WHEN @week = 3 THEN toh._wed_end
                    WHEN @week = 4 THEN toh._thurs_end
                    WHEN @week = 5 THEN toh._fri_end
                    WHEN @week = 6 THEN toh._sat_end
                    WHEN @week = 0 THEN toh._sun_end
                END) >= @time
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$
DELIMITER ;