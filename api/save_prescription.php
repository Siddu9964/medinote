<?php
header('Content-Type: application/json');

// --- CRITICAL: Override PHP upload limits so large images do not fail ---
@ini_set('upload_max_filesize', '100M');
@ini_set('post_max_size',       '100M');
@ini_set('memory_limit',        '256M');

// Hide raw PHP errors from output so JSON doesn't break
error_reporting(E_ALL);
ini_set('display_errors', 0); 

include 'db_config.php';

$patient_id     = trim($_POST['patient_id']     ?? '');
$patient_name   = trim($_POST['patient_name']   ?? 'Patient');
$doctor_id      = trim($_POST['doctor_id']      ?? '');
$appointment_id = trim($_POST['appointment_id'] ?? '');

$vital_signs    = $_POST['vital_signs']    ?? '';
$clinical_notes = $_POST['clinical_notes'] ?? '';
$soap_objective = $_POST['lab_data']       ?? ''; // Map lab data to soap_objective
$soap_plan      = $_POST['rx_data']        ?? ''; // Map meds JSON to soap_plan

// ─── SERVER-SYNCED PATH RESOLUTION ───────────────────────────────────────────
// This ensures images are saved on the SAME DRIVE where Apache is serving files.
// If Apache is on D:, it saves to D:. If on C:, it saves to C:.
$doc_root = rtrim($_SERVER['DOCUMENT_ROOT'], '/\\');
$target_dir = $doc_root . DIRECTORY_SEPARATOR . "GM_HMS" . DIRECTORY_SEPARATOR . "assets" . DIRECTORY_SEPARATOR . "precision_data" . DIRECTORY_SEPARATOR;

// Ensure directory exists
if (!is_dir($target_dir)) {
    if (!@mkdir($target_dir, 0777, true)) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => "Could not create directory: $target_dir"]);
        exit;
    }
}

// ─── Validate inputs ─────────────────────────────────────────────────────────
if (empty($patient_id) || empty($doctor_id)) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Missing patient_id or doctor_id."]);
    exit;
}

if (!isset($_FILES['prescription_images']) || empty($_FILES['prescription_images']['name'][0])) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "No images received by server. Check upload size limits."]);
    exit;
}

// ─── Optional: Get appointment_id if missing ─────────────────────────────────
if (empty($appointment_id)) {
    $sf = $conn->prepare("SELECT appointment_id FROM appointments WHERE patient_id = ? AND appointment_status != 0 ORDER BY appointment_date DESC LIMIT 1");
    $sf->bind_param("s", $patient_id);
    $sf->execute();
    $rf = $sf->get_result();
    if ($row = $rf->fetch_assoc()) $appointment_id = $row['appointment_id'];
    $sf->close();
}

// ─── IDs & Upload ────────────────────────────────────────────────────────────
$consultation_id   = "CON-" . date("Ymd") . "-" . strtoupper(substr(md5(uniqid()), 0, 6));
$consultation_date = date("Y-m-d");
$consultation_time = date("H:i:s");

$files       = $_FILES['prescription_images'];
$count       = is_array($files['name']) ? count($files['name']) : 0;
$saved_files = [];
$fail_msgs   = [];
$clean_name  = preg_replace('/[^A-Za-z0-9_\-]/', '_', $patient_name);

for ($i = 0; $i < $count; $i++) {
    if ($files['error'][$i] === UPLOAD_ERR_OK) {
        $fname = "{$patient_id}_{$clean_name}_" . date("Ymd_His") . "_P" . ($i + 1) . ".png";
        $dest  = $target_dir . $fname;
        
        if (move_uploaded_file($files['tmp_name'][$i], $dest)) {
            // Save the EXACT full path to the database (as requested)
            $saved_files[] = $dest;
        } else {
            $fail_msgs[] = "Failed moving to $dest (is_writable: " . (is_writable($target_dir) ? 'Yes' : 'No') . ")";
        }
    } else {
        $fail_msgs[] = "Upload failed. PHP Error code: " . $files['error'][$i];
    }
}

// ─── Database Insert or Update ────────────────────────────────────────────────
if (!empty($saved_files)) {
    $image_json = json_encode($saved_files);
    
    // Status should be integer 1 as requested for 'Completed'
    $status_int = 1; 
    
    try {
        // 1. Get the appointment_date and appointment_time for this appointment_id
        $app_date = '';
        $app_time = '';
        if (!empty($appointment_id)) {
            $stmt_app = $conn->prepare("SELECT appointment_date, appointment_time FROM appointments WHERE appointment_id = ?");
            $stmt_app->bind_param("s", $appointment_id);
            $stmt_app->execute();
            $res_app = $stmt_app->get_result();
            if ($row_app = $res_app->fetch_assoc()) {
                $app_date = $row_app['appointment_date'];
                $app_time = $row_app['appointment_time'];
                
                // Override the server's current time with the actual appointment time!
                $consultation_date = $app_date;
                $consultation_time = $app_time;
            }
            $stmt_app->close();
        }

        // 2. Check if a consultation already exists for this patient at this exact appointment date & time
        $existing_sl_no = null;
        if (!empty($app_date) && !empty($app_time)) {
            $check_sql = "SELECT c.sl_no 
                          FROM consultations c 
                          JOIN appointments a ON CONVERT(c.appointment_id USING utf8mb4) = CONVERT(a.appointment_id USING utf8mb4) 
                          WHERE CONVERT(c.patient_id USING utf8mb4) = ? 
                            AND a.appointment_date = ? 
                            AND a.appointment_time = ?
                          LIMIT 1";
            $stmt_check = $conn->prepare($check_sql);
            if ($stmt_check) {
                $stmt_check->bind_param("sss", $patient_id, $app_date, $app_time);
                $stmt_check->execute();
                $res_check = $stmt_check->get_result();
                if ($row_check = $res_check->fetch_assoc()) {
                    $existing_sl_no = $row_check['sl_no'];
                }
                $stmt_check->close();
            }
        }

        // 3. Update if exists, otherwise Insert
        if ($existing_sl_no) {
            $update_sql = "UPDATE consultations 
                           SET doctor_id = ?, prescription_image = ?, clinical_notes = ?, 
                               soap_objective = ?, soap_plan = ?, status = ?
                           WHERE sl_no = ?";
            $stmt = $conn->prepare($update_sql);
            if (!$stmt) throw new Exception("DB Prepare Update failed: " . $conn->error);
            
            $stmt->bind_param("sssssii", $doctor_id, $image_json, $clinical_notes, $soap_objective, $soap_plan, $status_int, $existing_sl_no);
            if (!$stmt->execute()) {
                throw new Exception("DB Update failed: " . $stmt->error);
            }
        } else {
            $insert_sql = "INSERT INTO consultations
                        (consultation_id, patient_id, doctor_id, appointment_id,
                         consultation_date, consultation_time, prescription_image, 
                         vital_signs, clinical_notes, soap_objective, soap_plan, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                    
            $stmt = $conn->prepare($insert_sql);
            if (!$stmt) throw new Exception("DB Prepare Insert failed: " . $conn->error);
            
            $stmt->bind_param("sssssssssssi",
                $consultation_id, $patient_id, $doctor_id, $appointment_id,
                $consultation_date, $consultation_time, $image_json, 
                $vital_signs, $clinical_notes, $soap_objective, $soap_plan, $status_int
            );
            if (!$stmt->execute()) {
                throw new Exception("DB Insert failed: " . $stmt->error);
            }
        }
            if (!empty($appointment_id)) {
                $u = $conn->prepare("UPDATE appointments SET appointment_status = 0 WHERE appointment_id = ?");
                $u->bind_param("s", $appointment_id);
                $u->execute();
                $u->close();
            }
            
            // Construct URLs for Flutter
            $web_urls = [];
            if (is_array($saved_files)) {
                foreach ($saved_files as $img) {
                    // Find 'htdocs' in the path and get everything after it
                    // This ensures we get /GM_HMS/... regardless of the drive letter (C: or D:)
                    $parts = preg_split('/htdocs/i', $img);
                    if (count($parts) > 1) {
                        $web_urls[] = str_replace('\\', '/', $parts[1]);
                    } else {
                        // Fallback for partial filenames or old data
                        $web_urls[] = "/GM_HMS/assets/precision_data/" . basename($img);
                    }
                }
            }
            
            http_response_code(200);
            echo json_encode([
                "status"  => "success",
                "message" => "Prescription and consultation notes saved successfully.",
                "saved"   => $web_urls,
                "errors"  => $fail_msgs
            ]);
        $stmt->close();
   } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
} else {
    // If we reach here, no files uploaded successfully
    http_response_code(500);
    echo json_encode([
        "status"  => "error",
        "message" => "Images failed to save. " . implode(", ", $fail_msgs),
        "target"  => $target_dir
    ]);
}

$conn->close();
?>