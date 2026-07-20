<?php
header('Content-Type: application/json');
include 'db_config.php';

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

$patient_id = $_GET['patient_id'] ?? '';

if (empty($patient_id)) {
    echo json_encode(["status" => "error", "message" => "Patient ID is required."]);
    exit;
}

$sql = "SELECT * FROM patient WHERE patient_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $patient_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode(["status" => "success", "patient_data" => $row]);
} else {
    echo json_encode(["status" => "error", "message" => "Patient not found."]);
}

$stmt->close();
$conn->close();
?>
