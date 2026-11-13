<?php
if ($method !== 'POST') {
    redirect('');
}
csrf_check();
$link = (string)($_POST['link'] ?? '');
if (!preg_match('/[a-f0-9]{64}/i', $link, $m)) {
    flash('That does not look like a quiz link. Copy the whole link and try again.');
    redirect('');
}
$token = strtolower($m[0]);
$found = find_by_token($token);
if (!$found) {
    flash('We could not find that link. Check you copied it completely.');
    redirect('');
}
[$p, $partner] = $found;
if (!$p['intro_done_at']) {
    redirect('join/' . $token);
}
if ($p['main_done_at'] && $partner && $partner['main_done_at']) {
    redirect('results/' . $token);
}
redirect('quiz/' . $token);
