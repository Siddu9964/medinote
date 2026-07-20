<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

include 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $patient_id = $_POST['patient_id'] ?? '';
    
    if (empty($patient_id)) {
        echo json_encode(['status' => 'error', 'message' => 'Patient ID is required']);
        exit;
    }

    // Capture fields to update
    $first_name = $_POST['first_name'] ?? null;
    $last_name = $_POST['last_name'] ?? null;
    $phone = $_POST['phone'] ?? null;
    $age = $_POST['age'] ?? null;
    $blood_group = $_POST['blood_group'] ?? null;
    $address = $_POST['address'] ?? null;
    $sex = $_POST['sex'] ?? null;
    $title = $_POST['title'] ?? null;
    $aadhar = $_POST['aadhar'] ?? null;

    $update_fields = [];
    $params = [];
    $types = "";

    if ($first_name !== null) { $update_fields[] = "first_name = ?"; $params[] = $first_name; $types .= "s"; }
    if ($last_name !== null) { $update_fields[] = "last_name = ?"; $params[] = $last_name; $types .= "s"; }
    if ($phone !== null) { $update_fields[] = "phone = ?"; $params[] = $phone; $types .= "s"; }
    if ($age !== null) { $update_fields[] = "age = ?"; $params[] = $age; $types .= "i"; }
    if ($blood_group !== null) { $update_fields[] = "blood_group = ?"; $params[] = $blood_group; $types .= "s"; }
    if ($address !== null) { $update_fields[] = "address = ?"; $params[] = $address; $types .= "s"; }
    if ($sex !== null) { $update_fields[] = "sex = ?"; $params[] = $sex; $types .= "s"; }
    if ($title !== null) { $update_fields[] = "title = ?"; $params[] = $title; $types .= "s"; }
    if ($aadhar !== null) { $update_fields[] = "aadhar = ?"; $params[] = $aadhar; $types .= "s"; }

    if (empty($update_fields)) {
        echo json_encode(['status' => 'error', 'message' => 'No fields provided for update']);
        exit;
    }

    $query = "UPDATE patient SET " . implode(", ", $update_fields) . " WHERE patient_id = ?";
    $params[] = $patient_id;
    $types .= "s";

    $stmt = $conn->prepare($query);
    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Patient updated successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Database update failed: ' . $stmt->error]);
    }

    $stmt->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
}
$conn->close();
?>
