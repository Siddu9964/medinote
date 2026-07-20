<?php
// get_appointments.php - BUILD VERSION 1.06
include 'db_config.php';
header('Content-Type: application/json');

$doctor_id = $_GET['doctor_id'] ?? '';

if (empty($doctor_id)) {
    echo json_encode(["status" => "error", "message" => "Doctor ID is missing."]);
    exit;
}

// Corrected JOIN: Using 'doctors' table for name and 'patient' for clinical data
$sql = "SELECT 
            a.*, 
            a.phone AS phone_number, 
            a.appointment_status,
            p.age,
            p.birth_date, 
            p.blood_group, 
            p.sex AS patient_gender,
            d.full_name AS doctor_name,
            c.complaint,
            c.vital_signs
        FROM appointments a 
        LEFT JOIN patient p ON CONVERT(a.patient_id USING utf8mb4) = CONVERT(p.patient_id USING utf8mb4) 
        LEFT JOIN doctors d ON CONVERT(TRIM(a.doctor_id) USING utf8mb4) = CONVERT(TRIM(d.doctor_id) USING utf8mb4)
        LEFT JOIN consultations c ON CONVERT(a.appointment_id USING utf8mb4) = CONVERT(c.appointment_id USING utf8mb4)
        WHERE TRIM(a.doctor_id) = TRIM(?) 
        ORDER BY a.appointment_date ASC, a.appointment_time ASC";

try {
    $stmt = $conn->prepare($sql);
    if (!$stmt) throw new Exception($conn->error);
    
    $stmt->bind_param("s", $doctor_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $appointments = [];
    while ($row = $result->fetch_assoc()) {
        $appointments[] = $row;
    }

    echo json_encode(["status" => "success", "appointments" => $appointments]);
    $stmt->close();
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Sync Error: " . $e->getMessage()]);
}

$conn->close();
?>
