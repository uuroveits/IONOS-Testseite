<?php

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /index.html');
    exit;
}

function clean($value)
{
    return trim(str_replace(array("\r", "\n"), ' ', $value));
}

$name = isset($_POST['name']) ? clean($_POST['name']) : '';
$email = isset($_POST['email']) ? clean($_POST['email']) : '';
$betreff = isset($_POST['betreff']) ? clean($_POST['betreff']) : '';
$nachricht = isset($_POST['nachricht']) ? trim($_POST['nachricht']) : '';

$errors = array();

if ($name === '') {
    $errors[] = 'Bitte Name eingeben.';
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors[] = 'Bitte eine gueltige E-Mail eingeben.';
}

if ($betreff === '') {
    $errors[] = 'Bitte einen Betreff eingeben.';
}

if ($nachricht === '') {
    $errors[] = 'Bitte eine Nachricht eingeben.';
}

$messageLength = function_exists('mb_strlen') ? mb_strlen($nachricht, 'UTF-8') : strlen($nachricht);
if ($messageLength > 5000) {
    $errors[] = 'Die Nachricht ist zu lang (max. 5000 Zeichen).';
}

$to = 'dr@jochenschiffers.de';
$subject = '[Kontaktformular] ' . $betreff;
$body = "Neue Nachricht ueber das Kontaktformular\n\n";
$body .= "Name: " . $name . "\n";
$body .= "E-Mail: " . $email . "\n";
$body .= "Betreff: " . $betreff . "\n\n";
$body .= "Nachricht:\n" . $nachricht . "\n";

$headers = array();
$headers[] = 'From: noreply@urostatistix-bestellung.de';
$headers[] = 'Reply-To: ' . $email;
$headers[] = 'Content-Type: text/plain; charset=UTF-8';

$sent = false;
if (count($errors) === 0) {
    $sent = mail($to, $subject, $body, implode("\r\n", $headers));
    if (!$sent) {
        $errors[] = 'Der Versand ist fehlgeschlagen. Bitte spaeter erneut versuchen.';
    }
}
?>
<!doctype html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kontaktformular</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <main class="section">
    <div class="container">
      <h1>Kontaktformular</h1>
      <?php if (count($errors) > 0): ?>
        <div class="message error">
          <p>Die Nachricht konnte nicht versendet werden:</p>
          <ul>
            <?php foreach ($errors as $error): ?>
              <li><?php echo htmlspecialchars($error, ENT_QUOTES, 'UTF-8'); ?></li>
            <?php endforeach; ?>
          </ul>
        </div>
      <?php else: ?>
        <div class="message success">
          <p>Danke! Deine Nachricht wurde erfolgreich versendet.</p>
        </div>
      <?php endif; ?>

      <p><a class="button" href="/index.html#kontakt">Zurueck zur Webseite</a></p>
    </div>
  </main>
</body>
</html>
