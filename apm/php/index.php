<?php
header('Content-Type: application/json');

// Check if APM extension is loaded
$apm_loaded = extension_loaded('elastic_apm');

$response = [
    'message' => 'PHP APM service active',
    'timestamp' => date('Y-m-d H:i:s'),
    'service' => 'php-app',
    'apm_extension_loaded' => $apm_loaded,
    'memory_usage' => memory_get_usage(true),
    'peak_memory' => memory_get_peak_usage(true),
    'php_version' => PHP_VERSION
];

if ($apm_loaded) {
    $response['apm_status'] = 'Active and monitoring';
} else {
    $response['apm_status'] = 'Extension not loaded';
}

echo json_encode($response, JSON_PRETTY_PRINT);
?>