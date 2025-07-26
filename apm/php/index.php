<?php
header('Content-Type: application/json');

// Check if APM extension is loaded
$apm_loaded = extension_loaded('elastic_apm');

// Generate some sample log entries
error_log("PHP application accessed at " . date('Y-m-d H:i:s'));

if (isset($_GET['error'])) {
    error_log("Test error generated for logging demonstration", 0);
    trigger_error("This is a test error for Logstash collection", E_USER_WARNING);
}

$response = [
    'message' => 'PHP APM service active',
    'timestamp' => date('Y-m-d H:i:s'),
    'service' => 'php-app',
    'apm_extension_loaded' => $apm_loaded,
    'memory_usage' => memory_get_usage(true),
    'peak_memory' => memory_get_peak_usage(true),
    'php_version' => PHP_VERSION,
    'logging_enabled' => ini_get('log_errors') ? 'Yes' : 'No',
    'log_file' => ini_get('error_log')
];

if ($apm_loaded) {
    $response['apm_status'] = 'Active and monitoring';
} else {
    $response['apm_status'] = 'Extension not loaded';
}

echo json_encode($response, JSON_PRETTY_PRINT);
?>