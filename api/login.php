<?php
// PHP logic starts here
include 'db_config.php'; // Already has CORS and error reporting set up

header('Content-Type: application/json');

$username = $_POST['username'] ?? '';
$password = $_POST['password'] ?? '';

function debug_log($msg) {
    file_put_contents('debug.txt', date('[Y-m-d H:i:s] ') . $msg . "\n", FILE_APPEND);
}

if (empty($username) || empty($password)) {
    echo json_encode(["status" => "error", "message" => "Fields are missing."]);
    exit;
}

try {
    // 1. Authenticate the User first
    $sql_user = "SELECT id, username, password, role FROM `user` WHERE TRIM(username) = TRIM(?) AND role = 'Doctor' LIMIT 1";
    $stmt_user = $conn->prepare($sql_user);
    $stmt_user->bind_param("s", $username);
    $stmt_user->execute();
    $result_user = $stmt_user->get_result();

    if ($result_user && $result_user->num_rows > 0) {
        $user_row = $result_user->fetch_assoc();

        if (password_verify($password, $user_row['password'])) {
            $userId = $user_row['id']; // e.g. 'DOC001'

            // 2. Fetch Doctor Metadata using a SECOND dedicated query
            // Added TRIM() to both sides to prevent hidden space mismatch
            $sql_doc = "SELECT full_name, gender, mobile_number, qualification, specialization, experience_years, available_days, photo 
                        FROM doctors WHERE TRIM(doctor_id) = TRIM(?)";
            $stmt_doc = $conn->prepare($sql_doc);
            $stmt_doc->bind_param("s", $userId);
            $stmt_doc->execute();
            $result_doc = $stmt_doc->get_result();

            // Default values if no profile row is found
            $doc_data = [
                "full_name" => $user_row['username'], 
                "specialization" => "Specialist",
                "photo" => null,
                "experience_years" => "0",
                "qualification" => "N/A",
                "mobile_number" => "N/A",
                "available_days" => "N/A",
                "gender" => "N/A"
            ];

            if ($result_doc && $result_doc->num_rows > 0) {
                $doc_data = $result_doc->fetch_assoc();
            } else {
                debug_log("Warning: No profile found in doctors table for ID: " . $userId);
            }

            echo json_encode(["status" => "success", "user" => [
                "id" => $userId,
                "username" => $user_row['username'],
                "role" => $user_row['role'],
                "full_name" => $doc_data['full_name'],
                "specialization" => $doc_data['specialization'],
                "photo" => $doc_data['photo'],
                "experience_years" => $doc_data['experience_years'],
                "qualification" => $doc_data['qualification'],
                "mobile_number" => $doc_data['mobile_number'],
                "available_days" => $doc_data['available_days'],
                "gender" => $doc_data['gender'],
                "branch_name" => $_POST['branch'] ?? 'GM Hospital - Nagarabhavi'
            ]]);
            $stmt_doc->close();
        } else {
            echo json_encode(["status" => "error", "message" => "Invalid password."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Account not found or not registered as a Doctor."]);
    }

    $stmt_user->close();
} catch (Exception $e) {
    debug_log("Critical error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "Server error: " . $e->getMessage()]);
}

$conn->close();
?>
