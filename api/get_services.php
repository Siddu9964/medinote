<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require_once 'db_config.php';

try {
    // Combine from 3 tables: lab_services, radiology_services, other_services
    $query = "
        SELECT service_id, test_name AS service_name, 'Pathology' AS category FROM lab_services
        UNION ALL
        SELECT service_id, billing_name AS service_name, 'Radiology' AS category FROM radiology_services
        UNION ALL
        SELECT service_id, billing_name AS service_name, 'Other' AS category FROM other_services
        ORDER BY category, service_name
    ";

    $result = $conn->query($query);
    $services = [];
    
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $services[] = $row;
        }
    }

    echo json_encode([
        "status" => "success",
        "services" => $services
    ]);

} catch(\Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}
?>
