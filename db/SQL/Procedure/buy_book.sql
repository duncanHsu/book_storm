/*
處理用戶從書店購買書籍的過程，處理原子交易中的所有相關數據更改

1. insert history
2. edit user
3. edit store
*/

DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `buy_book`(IN `p_book` INT(11) UNSIGNED, IN `p_user` INT(11) UNSIGNED)
    NO SQL
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
DELIMITER ;