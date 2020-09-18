<?php

header('Content-type:application/json;charset=utf-8');
//header("Content-Type:text/html; charset=utf-8");

include_once ("./model/config.php");
include_once ("./model/sql_process.php");

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
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

$strDate = $_GET[STR_DATE];
$endDate = $_GET[END_DATE];
$minPrice = $_GET[MIN_PRICE];
$maxPrice = $_GET[MAX_PRICE];

$sql = "SELECT get_user_quantity('$strDate', '$endDate', $minPrice, $maxPrice) " . JSON_VALUE;

(new SqlProcess())->printSearchData($sql);
?>