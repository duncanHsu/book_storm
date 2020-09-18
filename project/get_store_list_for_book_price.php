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

$minQuantity = $_GET[MIN_QUANTITY];
$maxQuantity = $_GET[MAX_QUANTITY];
$minPrice = $_GET[MIN_PRICE];
$maxPrice = $_GET[MAX_PRICE];

$sql = "SELECT get_store_list_for_book_price($minQuantity, $maxQuantity, $minPrice, $maxPrice) " . JSON_VALUE;

(new SqlProcess())->printSearchData($sql);
?>