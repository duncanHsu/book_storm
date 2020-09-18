<?php

include_once ("database_manager.php");
include_once ("response.php");
include_once ("config.php");

class SqlProcess {

    private $dbManager;

    public function __construct() {
        $this->dbManager = new DatabaseManager(SERVER_NAME, DB_USER_NAME, DB_PASSWORD, DATABASE);
    }

    /**
     * SQL Run
     * @param $sql String
     * @return array[[String]] Get SQL Array
     */
    public function runSql($sql): array {
        if (!$this->dbManager->conect()) {
            return [
                CONNECT_FAIL,
                null
            ];
        }

        $value = $this->dbManager->runSql($sql);

        $index = 0;
        // mysql_fetch_array 取得全部行
        while ($row = mysqli_fetch_array($value)) {
            $tableArray[$index] = array();

            foreach ($row as $key => $data) {
                if (is_int($key)) {
                    continue;
                }
                $tableArray[$index][$key] = $row[$key];
            }

            ++$index;
        }

        // get inserted ID
        $id = mysqli_insert_id($this->dbManager->getConect());

        // 釋放result函數資源
        mysqli_free_result($value);

        $this->dbManager->disconect();

        if ($id != 0) {
            return [
                SUCCESS,
                $id
            ];
        }

        if (empty($tableArray)) {
            return [
                NO_DATA,
                null
            ];
        }

        if (!empty($tableArray[0][JSON_VALUE])) {
            $tableArray = Response::decode($tableArray[0][JSON_VALUE]);
            return $tableArray;
        }

        return [
            SUCCESS,
            $tableArray
        ];
    }

    public function printSearchData($sql) {
        $dataArray = $this->runSql($sql);

        switch ($dataArray[0]) {
            case SUCCESS:
                echo Response::getResponseData(true, SUCCESS, $dataArray[1]);
                break;
            case CONNECT_FAIL:
                echo Response::getResponseData(false, CONNECT_FAIL, null);
                break;
            case NO_DATA:
                echo Response::getResponseData(false, NO_DATA, null);
                break;
            default:
                echo stripslashes(json_encode($dataArray, JSON_UNESCAPED_UNICODE));
                break;
        }
    }

    public function setDatabase($db): Search {
        $this->dbManager->setDatabase($db);
        return $this;
    }

}

?>