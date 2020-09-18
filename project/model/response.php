<?php

class Response {

    /**
     * Response JSON Format
     * 
     * @param string $status 狀態
     * @param string $message 狀態訊息
     * @param array $value json data array
     * @return array[[String]] Get JSON Text
     */
    public static function getResponseData($status, $message, $value): string {
        $responseJson = array("status" => $status, "message" => $message, "value" => $value);

        // 加 JSON_UNESCAPED_UNICODE，表示不被 UNICODE
        return stripslashes(json_encode($responseJson, JSON_UNESCAPED_UNICODE));
    }

    public static function decode($text): array {
        return json_decode($text, true);
    }

}

?>