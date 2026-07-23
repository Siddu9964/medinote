<?php
include 'db_config.php';
header('Content-Type: application/json');

$sql = "SELECT * FROM appointments";
try {
    $result = $conn->query($sql);
    $appointments = [];
    while ($row = $result->fetch_assoc()) {
        $appointments[] = $row;
    }
    echo json_encode($appointments, JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
$conn->close();
?>
