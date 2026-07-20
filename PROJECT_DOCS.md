# Medinote Project Architecture & Documentation

## 1. Overview
Medinote is a clinical portal built for healthcare professionals. It consists of a **Flutter** frontend (mobile/web) and a **PHP/MySQL** backend. The system facilitates doctor authentication, appointment management, patient record handling, and a specialized digital prescription drawing interface.

## 2. Technology Stack
*   **Frontend**: Flutter (Dart)
*   **Backend**: PHP (7.x/8.x compatible)
*   **Database**: MySQL (`hmsci`)
*   **Server**: Hosted locally via XAMPP (Apache)

## 3. Backend Architecture & APIs (PHP)
The backend is located in the `api/` directory.

### 3.1 Core Configuration
*   **`db_config.php`**
    *   **Purpose**: Centralized database connection and CORS configuration.
    *   **Details**: Connects to the `hmsci` database using `mysqli`. Headers are set to allow multiple origins, including Flutter's local web server (`http://localhost:X`).

### 3.2 Authentication
*   **`login.php`**
    *   **Method**: `POST`
    *   **Parameters**: `username`, `password`
    *   **Description**: Validates doctor credentials against the `user` table (via password_verify for BCrypt hashes). If valid, it fetches doctor metadata from the `doctors` table based on the `username`.

*   **`update_password.php`**
    *   **Method**: `POST`
    *   **Parameters**: `doctor_id`, `new_password`
    *   **Description**: Updates passwords synchronously across both `user` and `doctors` tables using SQL transactions for data integrity.

### 3.3 Appointment Management
*   **`get_appointments.php`**
    *   **Method**: `GET`
    *   **Parameters**: `doctor_id`
    *   **Description**: Returns all appointments for a specific doctor. It uses an `INNER JOIN` between `appointments`, `patient`, and `doctors` to return comprehensive clinical data in a single payload.

### 3.4 Prescription & Clinical Records Engine
*   **`save_prescription.php`**
    *   **Method**: `POST` (multipart/form-data)
    *   **Parameters**: `doctor_id`, `patient_id`, `appointment_id`, `images[]`
    *   **Description**: Handles multi-part image uploads for drawn prescriptions. Saves files into the server's `uploads/prescriptions/` directory. Updates the `appointment` status parameter from `1` (Active) to `0` (Completed). Contains critical `ini_set` overrides for handling large files (`upload_max_filesize`, `post_max_size`, `memory_limit`).

*   **`get_prescriptions.php`**
    *   **Method**: `GET`
    *   **Parameters**: `doctor_id`, `patient_id` (optional), `start_date` (optional), `end_date` (optional)
    *   **Description**: A dynamic filtering endpoint that retrieves consultation history. It sanitizes database file paths into URLs for the Flutter clients and groups uploaded prescription images by consultation.

### 3.5 Patient & Doctor Profiles
*   **`update_doctor_profile.php`**
    *   **Method**: `POST`
    *   **Parameters**: `doctor_id`, `full_name`, `specialization`, `qualification`, `experience_years`, `phone_number`
    *   **Description**: Updates doctor profile metadata.

*   **`update_profile_photo.php`**
    *   **Method**: `POST` (multipart/form-data)
    *   **Parameters**: `doctor_id`, `photo`
    *   **Description**: Uploads a doctor's avatar image to `uploads/avatars/` and updates the `photo_path` in the `doctors` table.

*   **`get_patient_details.php`**
    *   **Method**: `GET`
    *   **Parameters**: `patient_id`
    *   **Description**: Fetches comprehensive demographic and clinical data for a patient.

*   **`update_patient.php`**
    *   **Method**: `POST`
    *   **Parameters**: `patient_id`, `first_name`, `last_name`, `age`, `blood_group`, `phone`, `aadhar`, `address`
    *   **Description**: Performs a dynamic update query on the `patient` table based on the provided fields.

### 3.6 Services
*   **`get_services.php`**
    *   **Method**: `GET`
    *   **Description**: Aggregates `laboratory`, `radiology`, and `other_services` tables into a unified JSON list using `UNION ALL`.

---

## 4. Frontend Architecture (Flutter)
The frontend (`lib/`) uses a modular structure heavily optimized for canvas performance and responsive clinical UI.

### 4.1 System Utilities (`lib/utils/`)
*   **`api_service.dart`**: The network manager.
    *   Uses `http` requests.
    *   `sanitizeImageUrl(String path)`: Converts backend-saved absolute paths (e.g., `C:\xampp\htdocs\medinote\...`) to functional web URLs (e.g., `http://192.168.1.X/medinote/...`) using the `ApiConfig.baseUrl`.
*   **`constants.dart`**: Houses `AppColors`, `AppStyles`, and `ApiConfig`. Defines the "Clinical Teal" aesthetic scheme.
*   **`responsive.dart`**: Manages breakpoints (Phone vs Tablet) to ensure clinical forms and canvases format cleanly across differing aspect ratios.
*   **`session_manager.dart`**: Integrates `shared_preferences` to persist authenticated session data locally on device.

### 4.2 Drawing Engine & Handwriting (`lib/drawing/`)
The drawing modules bypass standard Flutter rebuilding cycles to offer 120hz handwriting performance suitable for stylus hardware.
*   **`drawing_controller.dart`**: State manager for strokes. Tracks tool types (Pen vs Eraser), stroke weights, paths, and handles the `undo` stack mechanism.
*   **`drawing_canvas.dart`**: Uses a `CustomPaint` widget packed within a `RepaintBoundary`. Triggers UI refreshes exclusively through a `ChangeNotifier` (`repaintNotifier`) on pointer down/move/up events rather than using standard `setState()`. Employed memory-efficient strokes via `perfect_freehand` for pressure-simulated variable stroke widths.

### 4.3 Key Screens & Workflows (`lib/views/`)
*   **`login_screen.dart`**: Manages session onboarding, UI animations, and token handoffs.
*   **`main_navigation_container.dart`**: Floating navigation handler routing the user between Dashboard, Medical Notes, History, and Profile views.
*   **`doctor_detailed_dashboard.dart`**: The core portal. Offers multi-column responsive layout, daily appointment filtering, pending vs completed statistics, and robust search parameters.
*   **`history_screen.dart`**: Allows clinical timeline filtering using `showDateRangePicker`. Links records to historical digital prescriptions using `widgets/prescription_viewer.dart`.
*   **`widgets/prescription_viewer.dart`**: An `InteractiveViewer` gallery providing pan/zoom over historical patient prescription images.
*   **`pulse_hub_screen.dart`**: A vitals dashboard simulator rendering a pseudo-ECG painter using `math.sin` wave interpolation for heartbeats, designed for advanced IoT metric aggregation.

### 5. Application Configuration Specifics
*   **SSL Support (`main.dart`)**: Overrides basic `HttpOverrides` via a `MyHttpOverrides` implementation to allow the mobile emulator to successfully fetch from self-signed XAMPP localhost environments without certificate pinning errors.
*   **Paths**: All dynamic assets currently map to the static IP configured in `constants.dart -> ApiConfig.baseUrl`. Any physical network change requires redefining this endpoint to match the host PC's IP address.
