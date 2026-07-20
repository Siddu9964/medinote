<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require_once 'db_config.php';

try {
    if (!isset($_GET['q']) || empty(trim($_GET['q']))) {
        echo json_encode(["status" => "success", "medicines" => []]);
        exit;
    }

    $q = trim($_GET['q']);
    $query = "SELECT product_name, strength FROM ph_product WHERE product_name LIKE ? LIMIT 15";
    $stmt = $conn->prepare($query);
    $searchTerm = "%{$q}%";
    $stmt->bind_param("s", $searchTerm);
    $stmt->execute();
    $result = $stmt->get_result();

    $medicines = [];
    while ($row = $result->fetch_assoc()) {
        $medicines[] = $row;
    }

    echo json_encode([
        "status" => "success",
        "medicines" => $medicines
    ]);

} catch(\Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
?>
