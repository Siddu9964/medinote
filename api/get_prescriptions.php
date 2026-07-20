<?php
// get_prescriptions.php - REFACTORED BUILD 1.08
header('Content-Type: application/json');
include 'db_config.php';

error_reporting(E_ALL);
ini_set('display_errors', 1);

$appointment_id = $_GET['appointment_id'] ?? '';
$patient_id = $_GET['patient_id'] ?? '';
$doctor_id = $_GET['doctor_id'] ?? '';
$start_date = $_GET['start_date'] ?? '';
$end_date = $_GET['end_date'] ?? '';

$where_clauses = [];
$params = [];
$types = "";

if (!empty($appointment_id)) {
    $where_clauses[] = "TRIM(c.appointment_id) = TRIM(?)";
    $params[] = $appointment_id;
    $types .= "s";
}
if (!empty($patient_id)) {
    $where_clauses[] = "TRIM(c.patient_id) = TRIM(?)";
    $params[] = $patient_id;
    $types .= "s";
}
if (!empty($doctor_id)) {
    $where_clauses[] = "TRIM(c.doctor_id) = TRIM(?)";
    $params[] = $doctor_id;
    $types .= "s";
}
if (!empty($start_date) && !empty($end_date)) {
    $where_clauses[] = "c.consultation_date BETWEEN ? AND ?";
    $params[] = $start_date;
    $params[] = $end_date;
    $types .= "ss";
}

if (empty($where_clauses)) {
    echo json_encode(["status" => "error", "message" => "No search criteria provided."]);
    exit;
}

$where_sql = implode(" AND ", $where_clauses);

// Pre-load All Services for fast resolution
$all_services = [];
$res = $conn->query("SELECT service_id, test_name FROM lab_services");
if ($res) { while($r = $res->fetch_assoc()) $all_services[$r['service_id']] = $r['test_name']; }
$res = $conn->query("SELECT service_id, billing_name FROM radiology_services");
if ($res) { while($r = $res->fetch_assoc()) $all_services[$r['service_id']] = $r['billing_name']; }
$res = $conn->query("SELECT service_id, billing_name FROM other_services");
if ($res) { while($r = $res->fetch_assoc()) $all_services[$r['service_id']] = $r['billing_name']; }

// Main Query with Doctor and Patient Joins
$sql = "SELECT c.*, p.first_name, p.last_name, p.age, p.blood_group, d.full_name as doctor_name 
        FROM consultations c
        LEFT JOIN patient p ON TRIM(c.patient_id) = TRIM(p.patient_id)
        LEFT JOIN doctors d ON TRIM(c.doctor_id) = TRIM(d.doctor_id)
        WHERE $where_sql
        ORDER BY c.consultation_date DESC, c.consultation_time DESC";

try {
    $stmt = $conn->prepare($sql);
    if (!$stmt) throw new Exception($conn->error);
    if (!empty($params)) $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();

    $prescriptions = [];
    while ($row = $result->fetch_assoc()) {
        // Image Processing
        $images = json_decode($row['prescription_image'] ?? '[]', true);
        $image_urls = [];
        if (is_array($images)) {
            foreach ($images as $img) {
                if (stripos($img, 'htdocs') !== false) {
                    $parts = preg_split('/htdocs/i', $img);
                    $image_urls[] = isset($parts[1]) ? str_replace('\\', '/', $parts[1]) : $img;
                } else {
                    $image_urls[] = "/GM_HMS/assets/precision_data/" . basename($img);
                }
            }
        }
        $row['image_urls'] = $image_urls;

        // Lab Data Resolution
        $raw_objectives = $row['soap_objective'] ?? '';
        if (!empty($raw_objectives)) {
            $ids = array_unique(array_filter(array_map('trim', explode(',', $raw_objectives))));
            $resolved_names = [];
            foreach ($ids as $id) {
                $resolved_names[] = $all_services[$id] ?? $id;
            }
            $row['soap_objective'] = implode('|', $resolved_names);
        }
        
        $prescriptions[] = $row;
    }

    echo json_encode(["status" => "success", "prescriptions" => $prescriptions]);
    $stmt->close();
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "SQL Error: " . $e->getMessage()]);
}

$conn->close();
?>