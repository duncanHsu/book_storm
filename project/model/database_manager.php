<?php

class DatabaseManager {

    private $serverName;
    private $userName;
    private $password;
    private $database;
    private $conect;

    public function __construct($serverName, $userName, $password, $database) {
        $this->serverName = $serverName;
        $this->userName = $userName;
        $this->password = $password;
        $this->database = $database;
    }

    // 連線
    public function conect() {
        $this->conect = mysqli_connect($this->serverName, $this->userName, $this->password, $this->database); // 登入
        if ($this->conect) { // 連線成功
            mysqli_set_charset($this->conect, "UTF8");
            return true;
        } else { // 連線失敗
            $this->disconect();
            return false;
        }
    }

    // 斷線
    public function disconect() {
        mysqli_close($this->conect);
    }

    public function runSql($sql) {
        return $this->conect->query($sql);
    }

    // 多重sql
    public function runManySql($sql) {
        return mysqli_multi_query($this->conect, $sql);
    }

    public function getServerName() {
        return $this->serverName;
    }

    public function getUserName() {
        return $this->userName;
    }

    public function getPassword() {
        return $this->password;
    }

    public function getDatabase() {
        return $this->database;
    }

    public function setDatabase($db) {
        $this->database = $db;
    }

    public function getConect() {
        return $this->conect;
    }

}

?>