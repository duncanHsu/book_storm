/*
Response Format
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `response_format`(`p_message` INT(11) UNSIGNED, `p_value` MEDIUMTEXT CHARSET utf8) RETURNS mediumtext CHARSET utf8
    NO SQL
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