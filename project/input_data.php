<?php

header('Content-type:application/json;charset=utf-8');
//header("Content-Type:text/html; charset=utf-8");

include_once ("./model/sql_process.php");
include_once ("./control/file_manager.php");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header("HTTP/1.0 405 Method Not Allowed");
    die();
}

if (!isset($_SERVER['PHP_AUTH_USER'])) {
    header('WWW-Authenticate: Basic realm="My Realm"');
    header('HTTP/1.0 401 Unauthorized');
    echo Response::getResponseData(false, 9, null);
    die();
}

if ($_SERVER["PHP_AUTH_USER"] !== AUTH_USER ||
        $_SERVER["PHP_AUTH_PW"] !== AUTH_PW) {
    echo Response::getResponseData(false, 9, null);
    die();
}

// 整理時間格式，加:00
function replaceHour($time): string {
    for ($index = 1; $index <= 12; $index++) {
        $time = preg_replace("/ $index am/", " $index:00 am", $time);
        $time = preg_replace("/ $index pm/", " $index:00 pm", $time);
    }

    $time = preg_replace("/am/", "AM", $time);
    $time = preg_replace("/pm/", "PM", $time);

    return $time;
}

function fixWeekArray($array, $week, $str, $end): array {
    switch ($week) {
        case MON:
            $array[MON_STR] = $str;
            $array[MON_END] = $end;
            break;
        case TUES:
            $array[TUES_STR] = $str;
            $array[TUES_END] = $end;
            break;
        case WED:
            $array[WED_STR] = $str;
            $array[WED_END] = $end;
            break;
        case THURS:
            $array[THURS_STR] = $str;
            $array[THURS_END] = $end;
            break;
        case FRI:
            $array[FRI_STR] = $str;
            $array[FRI_END] = $end;
            break;
        case SAT:
            $array[SAT_STR] = $str;
            $array[SAT_END] = $end;
            break;
        case SUN:
            $array[SUN_STR] = $str;
            $array[SUN_END] = $end;
            break;
    }

    return $array;
}

function createWeekArray($openingHours): array {
    $weekArray = array();

    foreach (explode(" / ", $openingHours) as $day) {
        if (preg_match("/, /", $day)) {
            $day = preg_replace("/,/", "", $day);
            $countArray = explode(" ", $day);
            $weekKeep = array();

            $index = 0;
            foreach ($countArray as $key => $value) {
                if (!preg_match("/[A-Za-z]+/", $value)) {
                    $index = $key;
                    break;
                }
                array_push($weekKeep, $value);
            }

            $str = $countArray[$index] . " " . $countArray[$index + 1];
            $end = $countArray[$index + 3] . " " . $countArray[$index + 4];

            foreach ($weekKeep as $week) {
                $weekArray = fixWeekArray($weekArray, $week, $str, $end);
            }
        } else if (preg_match("/[a-z]+ - [A-Za-z]+ \d+/", $day)) {
            $countArray = explode(" ", $day);

            $str = $countArray[3] . " " . $countArray[4];
            $end = $countArray[6] . " " . $countArray[7];

            $weekStrIndex = WEEK_ARRAY[$countArray[0]];
            $weekEndIndex = WEEK_ARRAY[$countArray[2]];

            for ($index = $weekStrIndex; $index <= $weekEndIndex; $index++) {
                foreach (WEEK_ARRAY as $key => $week) {
                    if ($index === $week) {
                        $weekArray = fixWeekArray($weekArray, $key, $str, $end);
                    }
                }
            }
        } else {
            $countArray = explode(" ", $day);
            $week = $countArray[0];
            $str = $countArray[1] . " " . $countArray[2];
            $end = explode(" - ", $day)[1];

            $weekArray = fixWeekArray($weekArray, $week, $str, $end);
        }
    }

    return $weekArray;
}

// Inser Store Date Time
function insertDateTime($id, $array) {
    $monStr = (empty($array[MON_STR])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[MON_STR] . "', '%l:%i %p'))";
    $monEnd = (empty($array[MON_END])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[MON_END] . "', '%l:%i %p'))";
    $tuesStr = (empty($array[TUES_STR])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[TUES_STR] . "', '%l:%i %p'))";
    $tuesEnd = (empty($array[TUES_END])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[TUES_END] . "', '%l:%i %p'))";
    $wedStr = (empty($array[WED_STR])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[WED_STR] . "', '%l:%i %p'))";
    $wedEnd = (empty($array[WED_END])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[WED_END] . "', '%l:%i %p'))";
    $thursStr = (empty($array[THURS_STR])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[THURS_STR] . "', '%l:%i %p'))";
    $thursEnd = (empty($array[THURS_END])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[THURS_END] . "', '%l:%i %p'))";
    $friStr = (empty($array[FRI_STR])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[FRI_STR] . "', '%l:%i %p'))";
    $firEnd = (empty($array[FRI_END])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[FRI_END] . "', '%l:%i %p'))";
    $satStr = (empty($array[SAT_STR])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[SAT_STR] . "', '%l:%i %p'))";
    $satEnd = (empty($array[SAT_END])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[SAT_END] . "', '%l:%i %p'))";
    $sunStr = (empty($array[SUN_STR])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[SUN_STR] . "', '%l:%i %p'))";
    $sunEnd = (empty($array[SUN_END])) ? "NULL" : "TIME(STR_TO_DATE('" . $array[SUN_END] . "', '%l:%i %p'))";

    $sql = "INSERT INTO " . TB_OPENING_HOURS . " (" . STORE . ", "
            . MON_STR . ", " . MON_END . ", "
            . TUES_STR . ", " . TUES_END . ", "
            . WED_STR . ", " . WED_END . ", "
            . THURS_STR . ", " . THURS_END . ", "
            . FRI_STR . ", " . FRI_END . ", "
            . SAT_STR . ", " . SAT_END . ", "
            . SUN_STR . ", " . SUN_END . ") VALUES ($id, "
            . "$monStr, $monEnd, "
            . "$tuesStr, $tuesEnd, "
            . "$wedStr, $wedEnd, "
            . "$thursStr, $thursEnd, "
            . "$friStr, $firEnd, "
            . "$satStr, $satEnd, "
            . "$sunStr, $sunEnd)";

    (new SqlProcess())->runSql($sql);
}

if (file_exists(STORE_DATA_PTH)) {
    $str = file_get_contents(STORE_DATA_PTH); //將整個檔案內容讀入到一個字串中
    $str = str_replace("\r\n", "<br />", $str);

    $array = Response::decode($str);

    foreach ($array as $store) {
        $storeName = $store["storeName"];
        $openingHours = $store["openingHours"];
        $cashBalance = $store["cashBalance"];
        $books = $store["books"];

        $sql = "INSERT INTO " . TB_STORE . " (" . NAME . ", " . CASH_BALANCE . ") VALUES ('$storeName', $cashBalance)";
        $dataArray = (new SqlProcess())->runSql($sql);
        if ($dataArray[0] === SUCCESS) {
            $id = $dataArray[1];

            insertDateTime($id, createWeekArray(replaceHour($openingHours)));

            foreach ($books as $book) {
                $bookName = preg_replace("/'/", "\'", $book["bookName"]);
                $price = $book["price"];

                $sql = "INSERT INTO " . TB_BOOK . " (" . NAME . ", " . PRICE . ", " . STORE . ") VALUES ('$bookName', $price, $id)";
                (new SqlProcess())->runSql($sql);
            }
        }
    }
}

if (file_exists(USER_DATA_PATH)) {
    $str = file_get_contents(USER_DATA_PATH); //將整個檔案內容讀入到一個字串中
    $str = str_replace("\r\n", "<br />", $str);
    $array = Response::decode($str);

    $sql = "SELECT " . ID . ", " . NAME . " FROM " . TB_STORE;
    $storeArray = (new SqlProcess())->runSql($sql);

    if ($storeArray[0] === SUCCESS) {
        $storeArray = $storeArray[1];
    } else {
        echo Response::getResponseData(false, 2, null);
        die();
    }

    $id0Flag = true;

    foreach ($array as $user) {
        $id = $user["id"];
        $name = $user["name"];
        $cashBalance = $user["cashBalance"];
        $historyArray = $user["purchaseHistory"];

        $sql = "INSERT INTO " . TB_USER . " (" . ID . ", " . NAME . ", " . CASH_BALANCE . ") VALUES ($id, '$name', $cashBalance)";

        $dataArray = (new SqlProcess())->runSql($sql);
        if ($dataArray[0] === SUCCESS) {
            if ($id0Flag && $id === 0) {
                $id0Flag = false;
                $sql = "UPDATE " . TB_USER . " SET " . ID . " = 0 WHERE " . ID . " = 1";
                (new SqlProcess())->runSql($sql);
                $fix = "ALTER TABLE tb_user AUTO_INCREMENT = 1";
                (new SqlProcess())->runSql($fix);
            }

            foreach ($historyArray as $history) {
                $bookName = preg_replace("/'/", "\'", $history["bookName"]);
                $storeName = $history["storeName"];

                $price = $history["transactionAmount"];
                $dateTime = "STR_TO_DATE('" . $history["transactionDate"] . "', '%m/%d/%Y %l:%i %p')";

                $storeId = 0;
                foreach ($storeArray as $store) {
                    if ($store[NAME] === $storeName) {
                        $storeId = $store[ID];
                        break;
                    }
                }

                $sql = "INSERT INTO " . TB_HISTORY . " ("
                        . USER . ", " . BOOK . ", " . STORE . ", " . PRICE . ", " . DATE_TIME
                        . ") VALUES ($id, '$bookName', $storeId, $price, $dateTime)";
                (new SqlProcess())->runSql($sql);
            }
        }
    }
}

echo Response::getResponseData(true, 1, null);
?>