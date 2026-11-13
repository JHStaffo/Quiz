<?php
$err = '';
if ($method === 'POST') {
    csrf_check();
    $gender = $_POST['gender'] ?? '';
    $self = trim((string)($_POST['self_name'] ?? ''));
    $other = trim((string)($_POST['partner_name'] ?? ''));
    if (!in_array($gender, ['male', 'female'], true) || $self === '' || $other === '') {
        $err = 'Please answer all three questions.';
    } else {
        $self = mb_substr($self, 0, 100);
        $other = mb_substr($other, 0, 100);
        $pdo = db();
        $pdo->beginTransaction();
        q('INSERT INTO quiz_sessions (created_at) VALUES (NOW())');
        $sid = (int)$pdo->lastInsertId();
        $tokA = new_token();
        $tokB = new_token();
        q('INSERT INTO participants (session_id, role, token, gender, self_name, partner_name, created_at, started_at, last_seen_at)
           VALUES (?, "A", ?, ?, ?, ?, NOW(), NOW(), NOW())', [$sid, $tokA, $gender, $self, $other]);
        // Partner B: opposite gender, names pre-filled from A's point of view (B can change them)
        q('INSERT INTO participants (session_id, role, token, gender, self_name, partner_name, created_at)
           VALUES (?, "B", ?, ?, ?, ?, NOW())', [$sid, $tokB, $gender === 'male' ? 'female' : 'male', $other, $self]);
        $pdo->commit();
        redirect('join/' . $tokA . '?p=1');
    }
}
$g = $_POST['gender'] ?? '';
$body = '<form method="post" class="card">' . csrf_field() . '
<h1>Let\'s get started</h1>
<p>First, a few details so the questions read naturally. Your partner will get their own private link next.</p>
' . ($err ? '<div class="error">' . e($err) . '</div>' : '') . '
<div class="q"><div class="q-text">I am...</div>
  <div class="opts two">
    <label class="opt-item"><input type="radio" name="gender" value="male" required' . ($g === 'male' ? ' checked' : '') . '> <span>The man</span></label>
    <label class="opt-item"><input type="radio" name="gender" value="female"' . ($g === 'female' ? ' checked' : '') . '> <span>The woman</span></label>
  </div></div>
<div class="q"><div class="q-text">What should the quiz call you?</div>
  <input type="text" name="self_name" maxlength="100" required value="' . e($_POST['self_name'] ?? '') . '" placeholder="Your name or nickname"></div>
<div class="q"><div class="q-text">What do you call your partner?</div>
  <input type="text" name="partner_name" maxlength="100" required value="' . e($_POST['partner_name'] ?? '') . '" placeholder="Their name or nickname"></div>
<div class="nav"><button class="btn big" type="submit">Continue</button></div>
</form>';
render_page('Start', $body);
