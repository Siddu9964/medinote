<?php
include 'db_config.php';
header('Content-Type: application/json');

$doctor_id = $_POST['doctor_id'] ?? '';
$full_name = $_POST['full_name'] ?? '';
$gender = $_POST['gender'] ?? '';
$mobile_number = $_POST['mobile_number'] ?? '';
$qualification = $_POST['qualification'] ?? '';
$specialization = $_POST['specialization'] ?? '';
$experience_years = $_POST['experience_years'] ?? '';
$available_days = $_POST['available_days'] ?? '';

if (empty($doctor_id)) {
    echo json_encode(["status" => "error", "message" => "Doctor ID is required."]);
    exit;
}

try {
    // Start Transaction to ensure data integrity
    $conn->begin_transaction();

    // 1. Update Doctors Table
    $sql_doc = "UPDATE doctors SET 
                full_name = ?, 
                gender = ?, 
                mobile_number = ?, 
                qualification = ?, 
                specialization = ?, 
                experience_years = ?, 
                available_days = ? 
                WHERE TRIM(doctor_id) = TRIM(?)";
    
    $stmt_doc = $conn->prepare($sql_doc);
    $stmt_doc->bind_param("ssssssss", 
        $full_name, 
        $gender, 
        $mobile_number, 
        $qualification, 
        $specialization, 
        $experience_years, 
        $available_days, 
        $doctor_id
    );
    $stmt_doc->execute();

    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Profile updated successfully!"]);

} catch (Exception $e) {
    if ($conn) $conn->rollback();
    echo json_encode(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
}

$conn->close();
?>
