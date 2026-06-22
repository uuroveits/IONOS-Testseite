<?php
declare(strict_types=1);

header('Content-Type: text/html; charset=utf-8');

function mask_key(string $key): string
{
    $len = strlen($key);
    if ($len <= 8) {
        return str_repeat('*', $len);
    }
    return substr($key, 0, 4) . str_repeat('*', $len - 8) . substr($key, -4);
}

$result = null;
$apiKeyInput = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $apiKeyInput = isset($_POST['api_key']) ? trim((string)$_POST['api_key']) : '';

    if ($apiKeyInput === '') {
        $result = [
            'ok' => false,
            'message' => 'API-Key fehlt.',
        ];
    } elseif (!function_exists('curl_init')) {
        $result = [
            'ok' => false,
            'message' => 'cURL ist auf dem Server nicht verfuegbar.',
        ];
    } else {
        $url = 'https://api.e-recht24.de/v1/clients';
        $ch = curl_init($url);

        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'cache-control: no-cache',
            'content-type: application/json',
            'eRecht24: ' . $apiKeyInput,
        ]);

        $body = curl_exec($ch);
        $curlError = curl_error($ch);
        $httpCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $bodyString = is_string($body) ? $body : '';
        $decoded = json_decode($bodyString, true);

        $result = [
            'ok' => ($curlError === '' && $httpCode === 200),
            'http_code' => $httpCode,
            'curl_error' => $curlError,
            'masked_key' => mask_key($apiKeyInput),
            'response_body' => $decoded !== null ? $decoded : $bodyString,
        ];
    }
}
?>
<!doctype html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>eRecht24 API-Key Check</title>
  <style>
    body { font-family: Arial, Helvetica, sans-serif; background: #f5f7fb; color: #1f2937; margin: 0; }
    .wrap { max-width: 840px; margin: 40px auto; background: #fff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 20px; }
    h1 { margin-top: 0; font-size: 1.4rem; }
    label { display: block; margin-bottom: 8px; font-weight: 600; }
    input[type="text"] { width: 100%; padding: 10px; border: 1px solid #d1d5db; border-radius: 8px; }
    button { margin-top: 12px; border: 0; background: #2563eb; color: #fff; padding: 10px 14px; border-radius: 8px; cursor: pointer; }
    .ok { margin-top: 16px; padding: 12px; border-radius: 8px; background: #ecfdf5; border: 1px solid #10b981; }
    .err { margin-top: 16px; padding: 12px; border-radius: 8px; background: #fef2f2; border: 1px solid #ef4444; }
    pre { margin-top: 10px; background: #111827; color: #e5e7eb; padding: 10px; border-radius: 8px; overflow: auto; }
    .muted { color: #6b7280; font-size: 0.95rem; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>eRecht24 API-Key Check</h1>
    <p class="muted">Prueft den API-Key online gegen <code>/v1/clients</code>.</p>

    <form method="post">
      <label for="api_key">API-Key</label>
      <input id="api_key" name="api_key" type="text" value="<?php echo htmlspecialchars($apiKeyInput, ENT_QUOTES, 'UTF-8'); ?>" required>
      <button type="submit">Jetzt pruefen</button>
    </form>

    <?php if ($result !== null): ?>
      <?php if (!empty($result['ok'])): ?>
        <div class="ok">
          <strong>Gueltig:</strong> Der API-Key wurde akzeptiert (HTTP 200).
          <div>Key: <?php echo htmlspecialchars((string)$result['masked_key'], ENT_QUOTES, 'UTF-8'); ?></div>
        </div>
      <?php else: ?>
        <div class="err">
          <strong>Ungueltig oder nicht erreichbar.</strong>
          <?php if (!empty($result['message'])): ?>
            <div><?php echo htmlspecialchars((string)$result['message'], ENT_QUOTES, 'UTF-8'); ?></div>
          <?php else: ?>
            <div>HTTP-Code: <?php echo htmlspecialchars((string)$result['http_code'], ENT_QUOTES, 'UTF-8'); ?></div>
            <div>Key: <?php echo htmlspecialchars((string)$result['masked_key'], ENT_QUOTES, 'UTF-8'); ?></div>
            <?php if (!empty($result['curl_error'])): ?>
              <div>cURL-Fehler: <?php echo htmlspecialchars((string)$result['curl_error'], ENT_QUOTES, 'UTF-8'); ?></div>
            <?php endif; ?>
          <?php endif; ?>
          <?php if (array_key_exists('response_body', $result)): ?>
            <pre><?php echo htmlspecialchars((string)json_encode($result['response_body'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE), ENT_QUOTES, 'UTF-8'); ?></pre>
          <?php endif; ?>
        </div>
      <?php endif; ?>
    <?php endif; ?>
  </div>
</body>
</html>
