<?php
include 'db_config.php';

header('Content-Type: application/json');

$identifier = $_POST['identifier'] ?? ''; // Can be username or ID
$new_password = $_POST['new_password'] ?? '';

if (empty($identifier) || empty($new_password)) {
    echo json_encode(["success" => false, "error" => "Identifier or Password missing."]);
    exit;
}

try {
    // 1. Identify the user and doctor_id
    $sql_find = "SELECT id FROM `user` WHERE username = ? OR id = ? LIMIT 1";
    $stmt_find = $conn->prepare($sql_find);
    $stmt_find->bind_param("ss", $identifier, $identifier);
    $stmt_find->execute();
    $res_find = $stmt_find->get_result();

    if ($res_find->num_rows === 0) {
        echo json_encode(["success" => false, "error" => "Clinician not found."]);
        exit;
    }

    $row = $res_find->fetch_assoc();
    $userId = $row['id'];

    // 2. Encryption (BCrypt)
    $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);

    // 3. Update both tables in a Transaction
    $conn->begin_transaction();

    // Update User table
    $stmt_user = $conn->prepare("UPDATE `user` SET password = ? WHERE id = ?");
    $stmt_user->bind_param("ss", $hashed_password, $userId);
    $stmt_user->execute();

    // Update Doctors table (using doctor_id as the link)
    $stmt_doc = $conn->prepare("UPDATE doctors SET password = ? WHERE doctor_id = ?");
    $stmt_doc->bind_param("ss", $hashed_password, $userId);
    $stmt_doc->execute();

    $conn->commit();

    echo json_encode(["success" => true, "message" => "Password synchronized successfully across portal tables."]);

} catch (Exception $e) {
    if (isset($conn) && $conn->connect_errno === 0) $conn->rollback();
    echo json_encode(["success" => false, "error" => "Database error: " . $e->getMessage()]);
}

$conn->close();
?>
