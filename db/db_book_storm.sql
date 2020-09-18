-- phpMyAdmin SQL Dump
-- version 4.9.2
-- https://www.phpmyadmin.net/
--
-- 主機： 127.0.0.1
-- 產生時間： 2020 年 09 月 06 日 11:00
-- 伺服器版本： 10.4.10-MariaDB
-- PHP 版本： 7.3.9

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- 資料庫： `db_book_storm`
--

DELIMITER $$
--
-- 程序
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `buy_book` (IN `p_book` INT(11) UNSIGNED, IN `p_user` INT(11) UNSIGNED)  NO SQL
    COMMENT '處理用戶從書店購買書籍的過程，處理原子交易中的所有相關數據更改'
rootFlag: BEGIN
    IF ISNULL(p_book) 
    || ISNULL(p_user) THEN
        SELECT response_format(3, NULL) JSON_VALUE;
        LEAVE rootFlag;
    END IF;

    SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._cash_balance
    INTO @bookId, @name, @price, @storeId, @storeCashBalance
    FROM tb_book tb, tb_store ts
    WHERE tb._store = ts._id
    AND tb._id = p_book;

    SET @userCashBalance = (SELECT _cash_balance FROM tb_user WHERE _id = p_user);

    IF ISNULL(@bookId) || ISNULL(@userCashBalance) THEN
        SELECT response_format(5, NULL) JSON_VALUE;
        LEAVE rootFlag;
    END IF;

    IF @userCashBalance < @price THEN
        SELECT response_format(8, NULL) JSON_VALUE;
        LEAVE rootFlag;
    END IF;

    INSERT INTO tb_history(_user, _book, _store, _price) VALUES (p_user, @name, @bookId, @price);
    
    UPDATE tb_user SET _cash_balance = @userCashBalance - @price WHERE _id = p_user;

    UPDATE tb_store SET _cash_balance = @storeCashBalance + @price WHERE _id = @storeId;

    SELECT response_format(1, get_history(p_user)) JSON_VALUE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `edit_book` (IN `p_id` INT(11) UNSIGNED, IN `p_name` VARCHAR(255) CHARSET utf8)  NO SQL
    COMMENT 'Edit Book'
rootFlag: BEGIN
    IF ISNULL(p_id) 
    || ISNULL(p_name) THEN
        SELECT response_format(3, NULL) JSON_VALUE;
        LEAVE rootFlag;
    END IF;

    SET @name = p_name COLLATE utf8_unicode_ci;
    UPDATE tb_book SET _name = @name WHERE _id = p_id;

    SELECT response_format(1, get_book_list()) JSON_VALUE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `edit_store` (IN `p_id` INT(11) UNSIGNED, IN `p_name` VARCHAR(255) CHARSET utf8)  NO SQL
    COMMENT 'Edit Store'
rootFlag: BEGIN
    IF ISNULL(p_id) 
    || ISNULL(p_name) THEN
        SELECT response_format(3, NULL) JSON_VALUE;
        LEAVE rootFlag;
    END IF;

    SET @name = p_name COLLATE utf8_unicode_ci;
    UPDATE tb_store SET _name = @name WHERE _id = p_id;

    SELECT response_format(1, get_store_list()) JSON_VALUE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `edit_user` (IN `p_id` INT(11) UNSIGNED, IN `p_name` VARCHAR(255) CHARSET utf8)  NO SQL
    COMMENT 'Edit User Data'
rootFlag: BEGIN
    IF ISNULL(p_id) 
    || ISNULL(p_name) THEN
        SELECT response_format(3, NULL) JSON_VALUE;
        LEAVE rootFlag;
    END IF;

    SET @name = p_name COLLATE utf8_unicode_ci;
    UPDATE tb_user SET _name = @name WHERE _id = p_id;

    SELECT response_format(1, get_user_list()) JSON_VALUE;
END$$

--
-- 函式
--
CREATE DEFINER=`root`@`localhost` FUNCTION `get_book_list` () RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
    COMMENT 'Get Book List'
BEGIN
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
                ORDER BY _store_id ASC, _name ASC
            ) FROM (
                SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._name _store
                FROM tb_book tb, tb_store ts
                WHERE ts._id = tb._store
            ) tb
        ),
        ']'
    );

    RETURN CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_book_list_for_keyword` (`p_keyword` VARCHAR(255) CHARSET utf8) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_book_list_for_price` (`p_min` DOUBLE(10,2) UNSIGNED, `p_max` DOUBLE(10,2) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
    COMMENT '列出價格範圍內的所有書籍，按價格或字母順序排列'
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
                '"_store":"', _store, '"',
                '}'
            ) FROM (
                SELECT tb._id, tb._name, tb._price, ts._id _store_id, ts._name _store, COUNT(*)
                FROM tb_book tb, tb_store ts
                WHERE ts._id = tb._store
                AND tb._price >= p_min
                AND tb._price <= p_max
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_history` (`p_id` INT(11) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_quantity_sum_for_date` (`p_str_date` DATE, `p_end_date` DATE) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_list` () RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
    COMMENT 'Get Store List'
BEGIN
    SET @json = CONCAT(
        '[',
        (
            SELECT GROUP_CONCAT(
                DISTINCT
                '{',
                '"_id":', _id, ',',
                '"_name":"', _name, '",',
                '"_cash_balance":', _cash_balance,
                '}'
                ORDER BY _name ASC
            ) FROM (
                SELECT * FROM tb_store
            ) tb
        ),
        ']'
    );

    RETURN CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_list_for_book_price` (`p_min_quantity` INT(3) UNSIGNED, `p_max_quantity` INT(3) UNSIGNED, `p_min_price` DOUBLE(10,2) UNSIGNED, `p_max_price` DOUBLE(10,2) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_list_for_book_quantity` (`p_min` INT(3) UNSIGNED, `p_max` INT(3) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_list_for_rank` (`p_mode` ENUM('Q','S') CHARSET utf8) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_open_list_for_date_time` (`p_date_time` DATETIME) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_open_list_for_hour` (`p_mode` ENUM('W','D') CHARSET utf8, `p_hour` INT(3) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_store_open_list_for_week` (`p_week` INT(1) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
    COMMENT '列出一周中某一天營業的所有書店'
BEGIN
    IF ISNULL(p_week) THEN
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
                AND NOT ISNULL(toh._mon_str)
                AND NOT ISNULL(toh._mon_end)
                AND NOT ISNULL(CASE 
                    WHEN p_week = 1 THEN toh._sat_str
                    WHEN p_week = 2 THEN toh._tues_str
                    WHEN p_week = 3 THEN toh._wed_str
                    WHEN p_week = 4 THEN toh._thurs_str
                    WHEN p_week = 5 THEN toh._fri_str
                    WHEN p_week = 6 THEN toh._sat_str
                    WHEN p_week = 7 THEN toh._sun_str
                    END)
                AND NOT ISNULL(CASE 
                    WHEN p_week = 1 THEN toh._sat_end
                    WHEN p_week = 2 THEN toh._tues_end
                    WHEN p_week = 3 THEN toh._wed_end
                    WHEN p_week = 4 THEN toh._thurs_end
                    WHEN p_week = 5 THEN toh._fri_end
                    WHEN p_week = 6 THEN toh._sat_end
                    WHEN p_week = 7 THEN toh._sun_end
                END)
            ) tb
        ),
        ']'
    );

    RETURN response_format(1, CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_list` () RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
    COMMENT 'Get User List'
BEGIN
    SET @json = CONCAT(
        '[',
        (
            SELECT GROUP_CONCAT(
                DISTINCT
                '{',
                '"_id":', _id, ',',
                '"_name":"', _name, '",',
                '"_cash_balance":', _cash_balance,
                '}'
                ORDER BY _name ASC
            ) FROM (
                SELECT * FROM tb_user
            ) tb
        ),
        ']'
    );

    RETURN CASE WHEN ISNULL(@json) THEN '[]' ELSE @json END;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_list_for_date_time_sum` (`p_str_date` DATE, `p_end_date` DATE, `p_rank` INT(3) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `get_user_quantity` (`p_str_date` DATE, `p_end_date` DATE, `p_min_price` DOUBLE(10,2) UNSIGNED, `p_max_price` DOUBLE(10,2) UNSIGNED) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
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

CREATE DEFINER=`root`@`localhost` FUNCTION `response_format` (`p_message` INT(11) UNSIGNED, `p_value` MEDIUMTEXT CHARSET utf8) RETURNS MEDIUMTEXT CHARSET utf8 NO SQL
    COMMENT 'Response Format'
BEGIN
    SET @value = p_value COLLATE utf8_bin;
    IF ISNULL(p_message) THEN
        RETURN '{"status":false,"message":2,"value":null}';
    ELSE
        SET @value = IFNULL(@value, 'null');
        SET @status = IF(p_message = 1, 'true', 'false');
        RETURN CONCAT('{"status":', @status, ',"message":', p_message, ',"value":', @value, '}');
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- 資料表結構 `tb_book`
--

CREATE TABLE `tb_book` (
  `_id` int(11) UNSIGNED NOT NULL COMMENT 'ID',
  `_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Book Name',
  `_price` decimal(10,2) UNSIGNED NOT NULL COMMENT '金額',
  `_store` int(11) UNSIGNED NOT NULL COMMENT 'Store ID'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='Book';

--
-- 傾印資料表的資料 `tb_book`
--

INSERT INTO `tb_book` (`_id`, `_name`, `_price`, `_store`) VALUES
(1, 'Ruby: The Autobiography', '13.88', 1),
(2, 'Ruby!', '10.64', 1),
(3, 'Ruby, Ruby: A Murder Mystery', '12.45', 1),
(4, 'Ruby: Unexpected Love... (ruby Trilogy)', '10.59', 1),
(5, 'Where\'s Ruby? (max And Ruby)', '13.50', 1),
(6, 'Ruby: Learn Ruby In 24 Hours Or Less - A Beginner\'s Guide To Learning Ruby Programming Now (ruby, Ruby Programming, Ruby Course)', '13.50', 1),
(7, 'Refactoring: Ruby Edition: Ruby Edition (addison-wesley Professional Ruby Series)', '12.56', 1),
(8, 'Mama Ruby (a Mama Ruby Novel)', '12.38', 1),
(9, 'Ruby Red (the Ruby Red Trilogy)', '11.64', 1),
(10, 'Metaprogramming Ruby 2: Program Like The Ruby Pros (facets Of Ruby)', '10.51', 1),
(11, 'Ruby River', '10.20', 1),
(12, 'Ruby Holler', '14.00', 1),
(13, 'Ruby Phrasebook', '11.79', 1),
(14, 'Sandy Ruby', '10.15', 1),
(15, 'Elixir Saved (elixir Chronicles)', '13.57', 2),
(16, 'Elixir', '10.15', 2),
(17, 'Elixir: A History Of Water And Humankind', '10.25', 2),
(18, 'Elixir: A Covenant Novella', '11.15', 2),
(19, 'The Elixir', '10.25', 2),
(20, 'Elixir Institutorum', '10.35', 2),
(21, 'Elixir Cookbook', '12.34', 2),
(22, 'Elixir Refused', '11.09', 2),
(23, 'Devils Elixir', '12.00', 2),
(24, 'Dr.excite/elixir/', '13.86', 2),
(25, 'Jorge Galindo: Elixir', '10.25', 2),
(26, 'Devoted (elixir)', '10.10', 2),
(27, 'Mastering Elixir', '11.57', 3),
(28, 'Fatal Elixir', '9.15', 3),
(29, 'Portafolio Elixir', '12.25', 3),
(30, 'Learning Elixir', '6.15', 3),
(31, 'Golden Elixir', '9.25', 3),
(32, 'Poet\'s Elixir', '8.35', 3),
(33, 'Elixir Cookbook', '9.34', 3),
(34, 'Elixir Refused', '11.09', 3),
(35, 'Devils Elixir', '8.00', 3),
(36, 'Dr.excite/elixir/', '13.86', 3),
(37, 'Jorge Galindo: Elixir', '9.25', 3),
(38, 'Devoted (elixir)', '15.10', 3),
(39, 'Swift', '15.75', 4),
(40, 'Cypseloides: Black Swift, Chestnut-collared Swift, White-chinned Swift, Great Dusky Swift, White-fronted Swift, Rothschild\'s Swift,', '10.35', 4),
(41, 'Swift: Gulliver\'s Travels and Other Writings', '12.00', 4),
(42, 'Swift: The Mystery of His Life and Love', '12.06', 4),
(43, 'Pro Swift - Swift 4.1 Edition', '13.95', 4),
(44, 'Functional Swift: Updated For Swift 4', '13.64', 4),
(45, 'Beginning Xcode: Swift Edition: Swift Edition', '13.95', 4),
(46, 'Swift Run (Swift Investigations Series #3)', '10.75', 4),
(47, 'Swift Edge A Swift Investigation Mystery', '13.08', 4),
(48, 'Swift Essentials', '13.26', 4),
(49, 'Ios 11 Programming Fundamentals With Swift: Swift, Xcode, And Cocoa Basics', '10.25', 5),
(50, 'Ios 12 Programming Fundamentals With Swift: Swift, Xcode, And Cocoa Basics', '12.42', 5),
(51, 'Ios 13 Programming Fundamentals With Swift: Swift, Xcode, And Cocoa Basics', '10.50', 5),
(52, 'Beginner\'s Guide To Ios 12 App Development Using Swift 4: Xcode, Swift And App Design Fundamentals', '13.00', 5),
(53, 'Beginning Xcode', '11.14', 5),
(54, 'Xcode 3 Unleashed', '10.17', 5),
(55, 'Xcode 4 Cookbook', '10.40', 5),
(56, 'Learning Xcode 8', '10.75', 5),
(57, 'Beginning Ios 13 & Swift App Development: Develop Ios Apps With Xcode 11, Swift 5, Core Ml, Arkit And More', '13.89', 5),
(58, 'Mastering Ios 12 Programming: Build Professional-grade Ios Applications With Swift And Xcode 10, 3rd Edition', '10.24', 5),
(59, 'Beginning Ios Storyboarding: Using Xcode', '12.30', 5),
(60, 'Xcode 5 Start To Finish', '12.20', 5),
(61, 'Ios 13 Programming For Beginners: Get Started With Building Ios Apps With Swift 5 And Xcode 11, 4th Edition', '12.82', 5),
(62, 'Taylor Swift', '10.05', 5),
(63, 'Ruby For Rails: Ruby Techniques For Rails Developers', '10.75', 6),
(64, 'Rails Antipatterns: Best Practice Ruby On Rails Refactoring', '11.16', 6),
(65, 'Ruby On Rails Video: Learn Rails By Example', '10.29', 6),
(66, 'Ruby On Rails Essential Training', '11.58', 6),
(67, 'Ruby Beginner\'s Crash Course: Ruby For Beginner\'s Guide To Ruby Programming, Ruby On Rails & Rails Programming (ruby, Operating Systems, Programming) (volume 1)', '10.26', 6),
(68, 'Ruby On Rails Tutorial: Learn Web Development With Rails', '11.25', 6),
(69, 'Head First Rails: A Learner\'s Companion To Ruby On Rails', '10.09', 6),
(70, 'Ruby On Rails Tutorial: Learn Web Development With Rails (2nd Edition) (addison-wesley Professional Ruby)', '12.79', 6),
(71, 'Hacking With Ruby: Ruby And Rails For The Real World', '12.53', 6),
(72, 'The Phenix: A Collection Of Old And Rare Fragments (1835)', '11.51', 7),
(73, 'Phenix: Roman', '10.94', 7),
(74, 'Phenix N40 Fantasy', '13.94', 7),
(75, 'Le Phenix Exultant', '11.25', 7),
(76, 'Forêts (inactif- Phenix)', '11.97', 7),
(77, 'Tel Un Phenix', '10.06', 7),
(78, 'Le Tombeau Du Phenix', '11.48', 7),
(79, 'Go For Gin', '10.50', 8),
(80, 'Gin & Gin Drinks (Quamut)', '12.44', 8),
(81, 'Gin Rummy: Gin Lovers Playing Cards', '10.55', 8),
(82, 'Sister Gin', '10.45', 8),
(83, 'Gin Wigmore: Gin Wigmore Albums, Gin Wigmore Songs, Holy Smoke, Brother, Hey Ho, Oh My, I Do, Extended Play', '10.60', 8),
(84, 'Cloud Native Programming With Golang', '10.75', 9),
(85, 'Hands-on Software Architecture With Golang', '13.00', 9),
(86, 'Learn Data Structures And Algorithms With Golang', '11.10', 9),
(87, 'Sams Teach Yourself Go In 24 Hours: Next Generation Systems Programming With Golang: Next Generation Systems Programming With Golang', '10.15', 9),
(88, 'Hands-on Software Architecture With Golang: Design And Architect Highly Scalable And Robust Applications Using Go', '10.10', 9),
(89, 'Mastering Go: Create Golang Production Applications Using Network Libraries, Concurrency, And Advanced Go Data Structures', '12.98', 9),
(90, 'Cloud Native Programming With Golang: Develop Microservice-based High Performance Web Apps For The Cloud With Go', '11.85', 9),
(91, 'Building Restful Web Services With Go: Learn How To Build Powerful Restful Apis With Golang That Scale Gracefully', '16.00', 9),
(92, 'Computer Programming Python, Machine Learning, Javascript Swift, Golang: A Step By Step How To Guide For Beginners To Advanced From Baby To Bad Ass', '10.25', 9),
(93, 'Learn Data Structures And Algorithms With Golang: Level Up Your Go Programming Skills To Develop Faster And More Efficient Code', '10.95', 9),
(94, 'Go Standard Library Cookbook: Over 120 Specific Ways To Make Full Use Of The Standard Library Components In Golang', '11.97', 9),
(95, 'Framework Science', '12.47', 10),
(96, 'Framework : A Developer\'s Handbook with Framework I', '10.36', 10),
(97, 'Strategic Framework', '10.20', 10),
(98, 'Net Framework', '10.63', 10),
(99, 'Stripes (framework)', '10.56', 10),
(100, 'Leonardi Framework', '12.54', 10),
(101, 'Bistro Framework', '11.15', 10),
(102, 'Science Framework', '12.21', 10),
(103, 'Mogul Framework', '11.40', 10),
(104, 'Framework Applications', '10.51', 10),
(105, 'Javanet-framework', '10.30', 10),
(106, 'Net Framework: Mono, Visual T Sharp, C Sharp, Framework .net, Microsoft .net, Visual Basic .net, Visual Studio', '11.84', 10);

-- --------------------------------------------------------

--
-- 資料表結構 `tb_history`
--

CREATE TABLE `tb_history` (
  `_user` int(11) UNSIGNED NOT NULL COMMENT 'User ID',
  `_book` varchar(255) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Book Namw',
  `_store` int(11) UNSIGNED NOT NULL COMMENT 'Store ID',
  `_price` double(10,2) UNSIGNED NOT NULL COMMENT '金額',
  `_date_time` datetime NOT NULL DEFAULT current_timestamp() COMMENT '日期時間'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='User 購買紀錄';

--
-- 傾印資料表的資料 `tb_history`
--

INSERT INTO `tb_history` (`_user`, `_book`, `_store`, `_price`, `_date_time`) VALUES
(0, 'Ruby: The Autobiography', 1, 13.88, '2020-02-10 04:09:00'),
(0, 'Ruby, Ruby: A Murder Mystery', 1, 12.45, '2020-04-03 13:56:00'),
(0, 'Where\'s Ruby? (max And Ruby)', 1, 13.50, '2020-02-29 00:13:00'),
(0, 'Cypseloides: Black Swift, Chestnut-collared Swift, White-chinned Swift, Great Dusky Swift, White-fronted Swift, Rothschild\'s Swift,', 4, 10.35, '2018-05-13 18:02:00'),
(0, 'Beginning Xcode: Swift Edition: Swift Edition', 4, 13.95, '2018-11-16 06:49:00'),
(0, 'Swift Run (Swift Investigations Series #3)', 4, 10.75, '2019-09-20 22:18:00'),
(0, 'Swift Essentials', 4, 13.26, '2019-04-20 11:20:00'),
(1, 'Pro Swift - Swift 4.1 Edition', 4, 13.95, '2019-10-28 16:38:00'),
(1, 'Swift Run (Swift Investigations Series #3)', 4, 10.75, '2018-06-29 13:08:00'),
(1, 'Swift', 4, 15.75, '2019-09-08 11:11:00'),
(1, 'Taylor Swift', 5, 10.05, '2020-02-16 09:31:00'),
(1, 'Ios 13 Programming For Beginners: Get Started With Building Ios Apps With Swift 5 And Xcode 11, 4th Edition', 5, 12.82, '2018-06-21 19:57:00'),
(1, 'Mastering Ios 12 Programming: Build Professional-grade Ios Applications With Swift And Xcode 10, 3rd Edition', 5, 10.24, '2018-10-21 19:38:00'),
(1, 'Ruby River', 1, 10.20, '2019-04-16 06:46:00'),
(1, 'Ruby Red (the Ruby Red Trilogy)', 1, 11.64, '2020-02-24 19:52:00'),
(1, 'Ruby: Learn Ruby In 24 Hours Or Less - A Beginner\'s Guide To Learning Ruby Programming Now (ruby, Ruby Programming, Ruby Course)', 1, 13.50, '2018-07-29 07:25:00'),
(1, 'Sandy Ruby', 1, 10.15, '2018-05-18 10:39:00'),
(1, 'Ruby, Ruby: A Murder Mystery', 1, 12.45, '2019-12-12 19:34:00'),
(3, 'Ruby River', 1, 10.20, '2018-12-11 17:33:00'),
(3, 'Ruby On Rails Tutorial: Learn Web Development With Rails', 6, 11.25, '2019-02-19 04:20:00'),
(3, 'Ruby On Rails Tutorial: Learn Web Development With Rails (2nd Edition) (addison-wesley Professional Ruby)', 6, 12.79, '2018-09-19 19:41:00'),
(3, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2018-06-25 11:49:00'),
(4, 'Ruby For Rails: Ruby Techniques For Rails Developers', 6, 10.75, '2018-04-29 20:04:00'),
(5, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2018-02-23 02:22:00'),
(5, 'Le Phenix Exultant', 7, 11.25, '2018-02-06 22:50:00'),
(5, 'Tel Un Phenix', 7, 10.06, '2019-07-22 01:01:00'),
(5, 'Le Tombeau Du Phenix', 7, 11.48, '2018-12-14 16:47:00'),
(5, 'Sister Gin', 8, 10.45, '2019-05-18 04:39:00'),
(5, 'Go For Gin', 8, 10.50, '2018-04-01 07:56:00'),
(5, 'Gin Rummy: Gin Lovers Playing Cards', 8, 10.55, '2018-11-15 23:52:00'),
(5, 'Mastering Go: Create Golang Production Applications Using Network Libraries, Concurrency, And Advanced Go Data Structures', 9, 12.98, '2019-01-30 22:29:00'),
(5, 'Cloud Native Programming With Golang: Develop Microservice-based High Performance Web Apps For The Cloud With Go', 9, 11.85, '2018-01-08 14:17:00'),
(5, 'Learn Data Structures And Algorithms With Golang: Level Up Your Go Programming Skills To Develop Faster And More Efficient Code', 9, 10.95, '2020-01-22 16:32:00'),
(5, 'Stripes (framework)', 10, 10.56, '2019-11-02 18:48:00'),
(5, 'Leonardi Framework', 10, 12.54, '2020-05-02 17:06:00'),
(5, 'Science Framework', 10, 12.21, '2018-01-02 11:58:00'),
(5, 'Ruby River', 1, 8.00, '2018-07-18 16:15:00'),
(5, 'Ruby Holler', 1, 13.86, '2020-02-02 02:59:00'),
(5, 'Ruby Phrasebook', 1, 9.25, '2018-06-28 17:22:00'),
(5, 'Sandy Ruby', 1, 9.34, '2018-08-14 11:06:00'),
(6, 'Ruby On Rails Essential Training', 6, 11.58, '2020-02-16 01:42:00'),
(6, 'Ruby On Rails Video: Learn Rails By Example', 6, 10.29, '2019-03-26 10:13:00'),
(6, 'Ruby On Rails Tutorial: Learn Web Development With Rails', 6, 11.25, '2018-06-25 05:43:00'),
(6, 'Building Restful Web Services With Go: Learn How To Build Powerful Restful Apis With Golang That Scale Gracefully', 9, 16.00, '2020-04-25 00:17:00'),
(6, 'Javanet-framework', 10, 10.30, '2019-01-31 01:33:00'),
(6, 'Net Framework', 10, 10.63, '2020-02-11 04:35:00'),
(6, 'Framework Science', 10, 12.47, '2018-05-05 18:37:00'),
(6, 'Forêts (inactif- Phenix)', 7, 11.97, '2019-12-21 05:54:00'),
(6, 'Phenix N40 Fantasy', 7, 13.94, '2018-12-16 17:54:00'),
(6, 'Phenix: Roman', 7, 10.94, '2020-01-30 22:44:00'),
(6, 'Xcode 5 Start To Finish', 5, 11.25, '2020-04-07 11:19:00'),
(6, 'Xcode 3 Unleashed', 5, 13.10, '2019-04-27 06:59:00'),
(6, 'Learning Xcode 8', 5, 11.50, '2018-05-27 09:30:00'),
(6, 'Swift: Gulliver\'s Travels and Other Writings', 4, 12.00, '2020-03-14 15:08:00'),
(6, 'Swift Edge A Swift Investigation Mystery', 4, 13.08, '2020-02-11 11:49:00'),
(6, 'Swift Essentials', 4, 13.26, '2018-02-10 07:44:00'),
(7, 'Metaprogramming Ruby 2: Program Like The Ruby Pros (facets Of Ruby)', 1, 10.51, '2020-03-03 11:01:00'),
(7, 'Ruby River', 1, 10.20, '2019-02-04 16:02:00'),
(7, 'Rails Antipatterns: Best Practice Ruby On Rails Refactoring', 6, 11.16, '2019-07-24 12:20:00'),
(7, 'Ruby On Rails Tutorial: Learn Web Development With Rails', 6, 11.25, '2020-02-12 07:18:00'),
(7, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2019-04-20 20:57:00'),
(8, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2020-01-09 17:59:00'),
(8, 'Head First Rails: A Learner\'s Companion To Ruby On Rails', 6, 10.09, '2019-10-17 04:28:00'),
(8, 'Ruby On Rails Essential Training', 6, 11.58, '2018-12-15 12:53:00'),
(8, 'Sister Gin', 8, 10.45, '2019-04-22 03:39:00'),
(8, 'Gin Wigmore: Gin Wigmore Albums, Gin Wigmore Songs, Holy Smoke, Brother, Hey Ho, Oh My, I Do, Extended Play', 8, 10.60, '2018-06-16 18:34:00'),
(8, 'Go For Gin', 8, 10.50, '2019-09-11 08:14:00'),
(8, 'Go Standard Library Cookbook: Over 120 Specific Ways To Make Full Use Of The Standard Library Components In Golang', 9, 11.97, '2018-08-03 09:37:00'),
(8, 'Learn Data Structures And Algorithms With Golang: Level Up Your Go Programming Skills To Develop Faster And More Efficient Code', 9, 10.95, '2019-12-15 08:21:00'),
(8, 'Sams Teach Yourself Go In 24 Hours: Next Generation Systems Programming With Golang: Next Generation Systems Programming With Golang', 9, 10.15, '2019-12-30 08:51:00'),
(8, 'Bistro Framework', 10, 11.15, '2019-03-31 04:11:00'),
(8, 'Science Framework', 10, 12.21, '2018-08-22 06:08:00'),
(8, 'Framework Science', 10, 12.47, '2018-10-15 06:47:00'),
(8, 'Gin & Gin Drinks (Quamut)', 8, 12.44, '2019-07-05 19:06:00'),
(8, 'Gin Rummy: Gin Lovers Playing Cards', 8, 10.55, '2019-06-17 05:13:00'),
(8, 'Phenix N40 Fantasy', 7, 13.94, '2018-06-22 20:45:00'),
(8, 'Forêts (inactif- Phenix)', 7, 11.97, '2018-05-18 14:55:00'),
(9, 'Ruby Beginner\'s Crash Course: Ruby For Beginner\'s Guide To Ruby Programming, Ruby On Rails & Rails Programming (ruby, Operating Systems, Programming) (volume 1)', 6, 10.26, '2018-12-15 03:34:00'),
(9, 'Head First Rails: A Learner\'s Companion To Ruby On Rails', 6, 10.09, '2018-07-27 11:28:00'),
(9, 'Ruby For Rails: Ruby Techniques For Rails Developers', 6, 10.75, '2018-08-29 23:54:00'),
(9, 'Metaprogramming Ruby 2: Program Like The Ruby Pros (facets Of Ruby)', 1, 10.51, '2019-08-01 00:29:00'),
(9, 'Where\'s Ruby? (max And Ruby)', 1, 13.50, '2019-04-09 03:47:00'),
(9, 'Elixir Refused', 2, 11.66, '2019-05-21 04:03:00'),
(9, 'Devils Elixir', 2, 10.10, '2019-03-14 03:21:00'),
(9, 'Dr.excite/elixir/', 2, 15.50, '2018-12-17 15:38:00'),
(10, 'Mastering Elixir', 3, 11.57, '2019-12-06 11:47:00'),
(10, 'Fatal Elixir', 3, 9.15, '2018-07-05 16:17:00'),
(10, 'Portafolio Elixir', 3, 12.25, '2018-10-09 11:42:00'),
(10, 'Learning Elixir', 3, 6.15, '2019-06-29 13:13:00'),
(10, 'Golden Elixir', 3, 9.25, '2018-09-23 10:36:00'),
(10, 'Poet\'s Elixir', 3, 8.35, '2019-12-13 06:12:00'),
(10, 'Elixir Cookbook', 3, 9.34, '2018-06-06 16:10:00'),
(10, 'Ruby On Rails Tutorial: Learn Web Development With Rails', 6, 11.25, '2018-07-01 12:43:00'),
(10, 'Ruby On Rails Video: Learn Rails By Example', 6, 10.29, '2020-02-09 15:46:00'),
(12, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2018-01-18 06:09:00'),
(12, 'Ruby On Rails Tutorial: Learn Web Development With Rails', 6, 11.25, '2018-02-04 06:41:00'),
(12, 'Rails Antipatterns: Best Practice Ruby On Rails Refactoring', 6, 11.16, '2019-01-23 12:41:00'),
(12, 'Forêts (inactif- Phenix)', 7, 11.97, '2019-06-12 02:24:00'),
(12, 'Le Phenix Exultant', 7, 11.25, '2018-05-23 02:56:00'),
(12, 'Sister Gin', 8, 10.45, '2019-05-23 20:01:00'),
(12, 'Gin Wigmore: Gin Wigmore Albums, Gin Wigmore Songs, Holy Smoke, Brother, Hey Ho, Oh My, I Do, Extended Play', 8, 10.60, '2019-03-27 21:21:00'),
(13, 'Computer Programming Python, Machine Learning, Javascript Swift, Golang: A Step By Step How To Guide For Beginners To Advanced From Baby To Bad Ass', 9, 10.25, '2019-09-29 22:01:00'),
(13, 'Building Restful Web Services With Go: Learn How To Build Powerful Restful Apis With Golang That Scale Gracefully', 9, 16.00, '2018-12-31 06:49:00'),
(13, 'Mastering Go: Create Golang Production Applications Using Network Libraries, Concurrency, And Advanced Go Data Structures', 9, 12.98, '2018-05-26 16:06:00'),
(13, 'Framework : A Developer\'s Handbook with Framework I', 10, 10.36, '2019-02-03 20:55:00'),
(13, 'Strategic Framework', 10, 10.20, '2019-06-12 14:17:00'),
(13, 'Net Framework', 10, 10.63, '2018-05-18 20:13:00'),
(13, 'Beginning Ios Storyboarding: Using Xcode', 5, 12.30, '2020-04-24 09:29:00'),
(13, 'Xcode 5 Start To Finish', 5, 12.20, '2018-06-20 05:58:00'),
(13, 'Ios 13 Programming For Beginners: Get Started With Building Ios Apps With Swift 5 And Xcode 11, 4th Edition', 5, 12.82, '2018-01-05 13:52:00'),
(13, 'Swift Run (Swift Investigations Series #3)', 4, 12.28, '2018-09-12 20:11:00'),
(13, 'Pro Swift - Swift 4.1 Edition', 4, 11.68, '2019-07-11 22:13:00'),
(13, 'Devoted (elixir)', 3, 15.10, '2019-10-22 17:52:00'),
(13, 'Jorge Galindo: Elixir', 3, 9.25, '2018-07-12 05:34:00'),
(13, 'Elixir Institutorum', 2, 10.35, '2018-01-23 07:05:00'),
(13, 'Elixir: A Covenant Novella', 2, 11.15, '2019-10-08 09:58:00'),
(14, 'Functional Swift: Updated For Swift 4', 4, 13.64, '2018-03-06 06:24:00'),
(14, 'Pro Swift - Swift 4.1 Edition', 4, 13.95, '2018-11-29 08:53:00'),
(14, 'Swift: The Mystery of His Life and Love', 4, 12.06, '2018-12-22 00:15:00'),
(14, 'Beginning Xcode', 5, 11.14, '2018-06-12 00:05:00'),
(14, 'Ios 13 Programming Fundamentals With Swift: Swift, Xcode, And Cocoa Basics', 5, 10.50, '2019-08-14 02:31:00'),
(14, 'Beginner\'s Guide To Ios 12 App Development Using Swift 4: Xcode, Swift And App Design Fundamentals', 5, 13.00, '2019-06-22 16:07:00'),
(14, 'Rails Antipatterns: Best Practice Ruby On Rails Refactoring', 6, 11.16, '2020-05-02 15:47:00'),
(14, 'Ruby Beginner\'s Crash Course: Ruby For Beginner\'s Guide To Ruby Programming, Ruby On Rails & Rails Programming (ruby, Operating Systems, Programming) (volume 1)', 6, 10.26, '2019-11-18 22:43:00'),
(14, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2020-01-01 15:25:00'),
(14, 'Gin Wigmore: Gin Wigmore Albums, Gin Wigmore Songs, Holy Smoke, Brother, Hey Ho, Oh My, I Do, Extended Play', 8, 10.60, '2018-01-06 16:50:00'),
(14, 'Gin & Gin Drinks (Quamut)', 8, 12.44, '2018-06-23 17:55:00'),
(14, 'Hands-on Software Architecture With Golang: Design And Architect Highly Scalable And Robust Applications Using Go', 9, 10.10, '2019-10-22 17:46:00'),
(14, 'Computer Programming Python, Machine Learning, Javascript Swift, Golang: A Step By Step How To Guide For Beginners To Advanced From Baby To Bad Ass', 9, 10.25, '2018-05-29 08:51:00'),
(15, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2018-05-01 10:30:00'),
(15, 'Ruby On Rails Essential Training', 6, 11.58, '2018-05-29 12:39:00'),
(15, 'Ruby For Rails: Ruby Techniques For Rails Developers', 6, 10.75, '2018-05-31 08:48:00'),
(15, 'Tel Un Phenix', 7, 10.06, '2020-05-18 09:39:00'),
(15, 'Forêts (inactif- Phenix)', 7, 11.97, '2019-11-03 14:09:00'),
(15, 'Phenix N40 Fantasy', 7, 13.94, '2018-03-28 11:46:00'),
(16, 'Hacking With Ruby: Ruby And Rails For The Real World', 6, 12.53, '2019-08-09 08:12:00'),
(16, 'Head First Rails: A Learner\'s Companion To Ruby On Rails', 6, 10.09, '2018-12-04 20:13:00'),
(16, 'Ruby On Rails Essential Training', 6, 11.58, '2019-07-24 14:37:00'),
(16, 'Computer Programming Python, Machine Learning, Javascript Swift, Golang: A Step By Step How To Guide For Beginners To Advanced From Baby To Bad Ass', 9, 10.25, '2020-03-30 09:20:00'),
(16, 'Hands-on Software Architecture With Golang', 9, 13.00, '2019-01-21 13:41:00'),
(17, 'Ruby For Rails: Ruby Techniques For Rails Developers', 6, 10.75, '2018-07-12 14:58:00'),
(17, 'Rails Antipatterns: Best Practice Ruby On Rails Refactoring', 6, 11.16, '2019-09-28 16:26:00'),
(17, 'Ruby Beginner\'s Crash Course: Ruby For Beginner\'s Guide To Ruby Programming, Ruby On Rails & Rails Programming (ruby, Operating Systems, Programming) (volume 1)', 6, 10.26, '2020-05-24 18:42:00'),
(17, 'Ruby On Rails Tutorial: Learn Web Development With Rails (2nd Edition) (addison-wesley Professional Ruby)', 6, 12.79, '2019-08-18 20:08:00'),
(18, 'Sams Teach Yourself Go In 24 Hours: Next Generation Systems Programming With Golang: Next Generation Systems Programming With Golang', 9, 10.15, '2020-01-23 12:54:00'),
(18, 'Hands-on Software Architecture With Golang: Design And Architect Highly Scalable And Robust Applications Using Go', 9, 10.10, '2018-04-15 16:42:00'),
(18, 'Cloud Native Programming With Golang: Develop Microservice-based High Performance Web Apps For The Cloud With Go', 9, 11.85, '2018-10-16 19:22:00'),
(18, 'Net Framework', 10, 10.63, '2020-03-29 00:29:00'),
(18, 'Stripes (framework)', 10, 10.56, '2019-03-23 04:52:00'),
(18, 'Leonardi Framework', 10, 12.54, '2019-05-25 05:13:00'),
(18, 'Ruby On Rails Essential Training', 6, 11.28, '2018-04-12 04:05:00'),
(18, 'Ruby Beginner\'s Crash Course: Ruby For Beginner\'s Guide To Ruby Programming, Ruby On Rails & Rails Programming (ruby, Operating Systems, Programming) (volume 1)', 6, 17.50, '2019-08-13 23:43:00'),
(18, 'Head First Rails: A Learner\'s Companion To Ruby On Rails', 6, 11.58, '2018-09-23 22:07:00'),
(18, 'Metaprogramming Ruby 2: Program Like The Ruby Pros (facets Of Ruby)', 1, 10.57, '2019-09-21 22:49:00'),
(18, 'Ruby Red (the Ruby Red Trilogy)', 1, 13.68, '2019-04-30 04:28:00'),
(18, 'Dr.excite/elixir/', 2, 13.86, '2020-02-01 13:02:00'),
(18, 'Elixir Refused', 2, 11.09, '2019-03-19 01:31:00'),
(19, 'Swift', 4, 15.75, '2019-01-09 11:20:00'),
(19, 'Cypseloides: Black Swift, Chestnut-collared Swift, White-chinned Swift, Great Dusky Swift, White-fronted Swift, Rothschild\'s Swift,', 4, 10.35, '2018-06-13 10:21:00'),
(19, 'Swift: The Mystery of His Life and Love', 4, 12.06, '2018-01-19 18:15:00'),
(19, 'Golden Elixir', 3, 9.25, '2018-02-01 19:26:00'),
(19, 'Elixir Cookbook', 3, 9.34, '2018-04-13 23:40:00'),
(19, 'Jorge Galindo: Elixir', 3, 9.25, '2018-07-04 20:09:00'),
(19, 'Pro Swift - Swift 4.1 Edition', 4, 13.95, '2018-04-09 05:27:00'),
(19, 'Functional Swift: Updated For Swift 4', 4, 13.64, '2018-10-10 00:25:00'),
(19, 'Beginning Xcode: Swift Edition: Swift Edition', 4, 13.95, '2019-02-13 12:01:00'),
(19, 'Beginning Ios 13 & Swift App Development: Develop Ios Apps With Xcode 11, Swift 5, Core Ml, Arkit And More', 5, 13.35, '2018-06-20 03:57:00'),
(19, 'Beginning Xcode', 5, 11.14, '2018-12-22 15:12:00'),
(19, 'Xcode 3 Unleashed', 5, 10.17, '2020-04-26 02:43:00'),
(19, 'Cypseloides: Black Swift, Chestnut-collared Swift, White-chinned Swift, Great Dusky Swift, White-fronted Swift, Rothschild\'s Swift,', 4, 10.35, '2018-06-13 21:58:00'),
(19, 'Swift: The Mystery of His Life and Love', 4, 12.06, '2018-08-17 05:57:00'),
(19, 'Functional Swift: Updated For Swift 4', 4, 13.64, '2018-01-02 05:54:00'),
(19, 'Taylor Swift', 5, 10.05, '2019-04-28 03:38:00');

-- --------------------------------------------------------

--
-- 資料表結構 `tb_opening_hours`
--

CREATE TABLE `tb_opening_hours` (
  `_store` int(11) UNSIGNED NOT NULL COMMENT 'ID',
  `_mon_str` time DEFAULT NULL COMMENT '星期一開始時間',
  `_mon_end` time DEFAULT NULL COMMENT '星期一結束時間',
  `_tues_str` time DEFAULT NULL COMMENT '星期二開始時間',
  `_tues_end` time DEFAULT NULL COMMENT '星期二結束時間',
  `_wed_str` time DEFAULT NULL COMMENT '星期三開始時間',
  `_wed_end` time DEFAULT NULL COMMENT '星期三結束時間',
  `_thurs_str` time DEFAULT NULL COMMENT '星期四開始時間',
  `_thurs_end` time DEFAULT NULL COMMENT '星期四結束時間',
  `_fri_str` time DEFAULT NULL COMMENT '星期五開始時間',
  `_fri_end` time DEFAULT NULL COMMENT '星期五結束時間',
  `_sat_str` time DEFAULT NULL COMMENT '星期六開始時間',
  `_sat_end` time DEFAULT NULL COMMENT '星期六結束時間',
  `_sun_str` time DEFAULT NULL COMMENT '星期日開始時間',
  `_sun_end` time DEFAULT NULL COMMENT '星期日結束時間'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='店家營業時間';

--
-- 傾印資料表的資料 `tb_opening_hours`
--

INSERT INTO `tb_opening_hours` (`_store`, `_mon_str`, `_mon_end`, `_tues_str`, `_tues_end`, `_wed_str`, `_wed_end`, `_thurs_str`, `_thurs_end`, `_fri_str`, `_fri_end`, `_sat_str`, `_sat_end`, `_sun_str`, `_sun_end`) VALUES
(1, '14:30:00', '20:00:00', '11:00:00', '14:00:00', '13:15:00', '03:15:00', '10:00:00', '03:15:00', '14:30:00', '20:00:00', '05:00:00', '11:30:00', '10:45:00', '17:00:00'),
(2, '11:45:00', '16:45:00', '07:45:00', '02:00:00', '11:45:00', '16:45:00', '17:45:00', '00:00:00', '06:00:00', '21:00:00', '10:15:00', '21:00:00', '06:00:00', '21:00:00'),
(3, '11:45:00', '16:45:00', '07:45:00', '14:00:00', '07:00:00', '21:00:00', '17:45:00', '00:00:00', '07:00:00', '21:00:00', '10:15:00', '21:00:00', '07:00:00', '21:00:00'),
(4, '13:45:00', '15:00:00', '08:45:00', '02:15:00', '06:45:00', '10:45:00', '05:45:00', '11:15:00', '15:45:00', '02:30:00', '05:45:00', '11:15:00', '17:00:00', '03:45:00'),
(5, '17:00:00', '22:30:00', '17:00:00', '18:45:00', '15:15:00', '03:45:00', '15:15:00', '03:45:00', '09:15:00', '10:45:00', '17:00:00', '18:45:00', '10:45:00', '15:45:00'),
(6, '11:00:00', '21:00:00', '11:00:00', '21:00:00', '11:00:00', '21:00:00', '06:00:00', '21:00:00', '19:00:00', '07:00:00', '14:45:00', '01:30:00', '07:00:00', '16:15:00'),
(7, '06:00:00', '20:30:00', '06:45:00', '15:00:00', '06:45:00', '15:00:00', '06:15:00', '08:30:00', '16:00:00', '22:15:00', '13:30:00', '23:45:00', '06:30:00', '08:15:00'),
(8, '16:30:00', '23:15:00', '15:30:00', '17:00:00', '05:15:00', '21:30:00', '13:00:00', '14:15:00', '06:45:00', '07:45:00', '15:30:00', '17:00:00', '08:30:00', '02:00:00'),
(9, '10:30:00', '15:15:00', '07:15:00', '00:30:00', '07:15:00', '00:30:00', '06:45:00', '00:00:00', '05:00:00', '23:30:00', '05:30:00', '09:45:00', '05:30:00', '09:45:00'),
(10, '17:00:00', '02:00:00', '09:30:00', '20:00:00', '09:30:00', '20:00:00', '08:15:00', '23:00:00', '17:00:00', '22:15:00', '05:30:00', '17:00:00', '11:45:00', '18:00:00');

-- --------------------------------------------------------

--
-- 資料表結構 `tb_store`
--

CREATE TABLE `tb_store` (
  `_id` int(11) UNSIGNED NOT NULL COMMENT 'ID',
  `_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Store Name',
  `_cash_balance` double(10,2) UNSIGNED NOT NULL COMMENT '餘額'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='店家';

--
-- 傾印資料表的資料 `tb_store`
--

INSERT INTO `tb_store` (`_id`, `_name`, `_cash_balance`) VALUES
(1, 'Look Inna Book', 4483.84),
(2, 'The Book Basement', 4882.81),
(3, 'A Whole New World Bookstore', 5677.81),
(4, 'Downtown Books', 3478.03),
(5, 'Uptown Books', 960.20),
(6, 'Turn the Page', 4841.80),
(7, 'Author Attic', 3211.97),
(8, 'Undercover Books', 4260.93),
(9, 'Pick-a-Book', 416.69),
(10, 'Bookland', 940.01);

-- --------------------------------------------------------

--
-- 資料表結構 `tb_user`
--

CREATE TABLE `tb_user` (
  `_id` int(11) UNSIGNED NOT NULL COMMENT 'ID',
  `_name` varchar(255) COLLATE utf8_unicode_ci NOT NULL COMMENT 'User Name',
  `_cash_balance` double(10,2) UNSIGNED NOT NULL COMMENT '餘額'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='User';

--
-- 傾印資料表的資料 `tb_user`
--

INSERT INTO `tb_user` (`_id`, `_name`, `_cash_balance`) VALUES
(0, 'Edith Johnson', 700.70),
(1, 'Edward Gonzalez', 237.61),
(3, 'Heather Edwards', 277.18),
(4, 'Christopher Deisher', 997.73),
(5, 'Kasha Borda', 610.67),
(6, 'Coy Mincks', 863.35),
(7, 'Andrew Bidlack', 629.20),
(8, 'Gary Coffin', 144.12),
(9, 'Edna Johnson', 21.29),
(10, 'Judy Spease', 776.89),
(11, 'Kirsten Bostic', 638.26),
(12, 'Alma Meadows', 304.79),
(13, 'Mark Gregoire', 890.52),
(14, 'Phyllis Tennon', 257.36),
(15, 'Adele Smith', 60.98),
(16, 'Susan Maggio', 75.23),
(17, 'Gloria Kramer', 55.16),
(18, 'Darren Pedigo', 812.36),
(19, 'Beverly Corbin', 424.42);

--
-- 已傾印資料表的索引
--

--
-- 資料表索引 `tb_book`
--
ALTER TABLE `tb_book`
  ADD PRIMARY KEY (`_id`),
  ADD KEY `Store ID -> Book Store` (`_store`);

--
-- 資料表索引 `tb_history`
--
ALTER TABLE `tb_history`
  ADD KEY `Store ID -> History Store ID` (`_store`),
  ADD KEY `User ID -> History User` (`_user`);

--
-- 資料表索引 `tb_opening_hours`
--
ALTER TABLE `tb_opening_hours`
  ADD UNIQUE KEY `_store` (`_store`);

--
-- 資料表索引 `tb_store`
--
ALTER TABLE `tb_store`
  ADD PRIMARY KEY (`_id`);

--
-- 資料表索引 `tb_user`
--
ALTER TABLE `tb_user`
  ADD PRIMARY KEY (`_id`);

--
-- 在傾印的資料表使用自動遞增(AUTO_INCREMENT)
--

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `tb_book`
--
ALTER TABLE `tb_book`
  MODIFY `_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID', AUTO_INCREMENT=107;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `tb_store`
--
ALTER TABLE `tb_store`
  MODIFY `_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID', AUTO_INCREMENT=11;

--
-- 使用資料表自動遞增(AUTO_INCREMENT) `tb_user`
--
ALTER TABLE `tb_user`
  MODIFY `_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID', AUTO_INCREMENT=20;

--
-- 已傾印資料表的限制式
--

--
-- 資料表的限制式 `tb_book`
--
ALTER TABLE `tb_book`
  ADD CONSTRAINT `Store ID -> Book Store` FOREIGN KEY (`_store`) REFERENCES `tb_store` (`_id`);

--
-- 資料表的限制式 `tb_history`
--
ALTER TABLE `tb_history`
  ADD CONSTRAINT `Store ID -> History Store ID` FOREIGN KEY (`_store`) REFERENCES `tb_store` (`_id`),
  ADD CONSTRAINT `User ID -> History User` FOREIGN KEY (`_user`) REFERENCES `tb_user` (`_id`) ON DELETE CASCADE;

--
-- 資料表的限制式 `tb_opening_hours`
--
ALTER TABLE `tb_opening_hours`
  ADD CONSTRAINT `Store ID -> Opening Hours -> Store` FOREIGN KEY (`_store`) REFERENCES `tb_store` (`_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
