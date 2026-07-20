<?php
// PHP logic to handle profile photo update
include 'db_config.php';

header('Content-Type: application/json');

$doctorId = $_POST['doctor_id'] ?? '';
// The user specified this exact path for the images
$targetDir = "D:/xampp/htdocs/GM_HMS/assets/profile_photos/";

if (empty($doctorId)) {
    echo json_encode(["status" => "error", "message" => "Doctor ID is missing."]);
    exit;
}

if (!isset($_FILES['photo'])) {
    echo json_encode(["status" => "error", "message" => "No photo file uploaded."]);
    exit;
}

try {
    // 1. Create directory if it doesn't exist
    if (!file_exists($targetDir)) {
        mkdir($targetDir, 0777, true);
    }

    $file = $_FILES['photo'];
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    if (empty($extension)) $extension = 'png';
    
    // Naming pattern: follows the user's provided format: doctor_[ID]_[timestamp].[ext]
    $fileName = "doctor_" . $doctorId . "_" . time() . "." . $extension;
    $targetFile = $targetDir . $fileName;

    if (move_uploaded_file($file['tmp_name'], $targetFile)) {
        // 2. Update Database
        // We store the path starting with /GM_HMS as per user's latest verification
        $dbPath = "/GM_HMS/assets/profile_photos/" . $fileName;
        
        $sql = "UPDATE doctors SET photo = ? WHERE doctor_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ss", $dbPath, $doctorId);
        
        if ($stmt->execute()) {
             echo json_encode([
                "status" => "success", 
                "message" => "Profile photo updated successfully.",
                "photo_path" => $dbPath
            ]);
        } else {
             echo json_encode(["status" => "error", "message" => "Failed to update database: " . $stmt->error]);
        }
        $stmt->close();
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to move uploaded file to target directory."]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "Server error: " . $e->getMessage()]);
}

$conn->close();
?>
