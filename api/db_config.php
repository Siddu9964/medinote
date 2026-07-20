<?php
// Enable error reporting for debugging (Remove for production)
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Consolidate CORS headers in one place
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Branch-Name");

// Handle CORS Preflight (OPTIONS) requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = "localhost";
$user = "root";
$password = "";

// Start session to manage database state
session_start();

// Default database
$dbname = "hmsci";

// Stateless Dynamic Database Selection
$branch = null;

if (isset($_POST['branch']) && !empty($_POST['branch'])) {
    $branch = $_POST['branch'];
} else if (isset($_SERVER['HTTP_X_BRANCH_NAME']) && !empty($_SERVER['HTTP_X_BRANCH_NAME'])) {
    $branch = $_SERVER['HTTP_X_BRANCH_NAME'];
}

if ($branch === 'GM Hospital - Basaveshwaranagar') {
    $dbname = "hmsc_basaveshwranagara";
} else {
    $dbname = "hmsci"; // Default for Nagarabhavi or unknown
}

// Enable mysqli error reporting for catching exceptions
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli($host, $user, $password, $dbname);
    // Setting charset to utf8mb4 is recommended for global data compatibility
    $conn->set_charset("utf8mb4");
} catch (mysqli_sql_exception $e) {
    header('Content-Type: application/json');
    echo json_encode(["status" => "error", "message" => "Database connection failed: " . $e->getMessage()]);
    exit;
}
?>
