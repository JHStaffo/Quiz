<?php
/** After person A finishes the intro: show the partner link and their own link. */
$mine = full_url('quiz/' . $TOKEN);
$body = '<div class="card">';
if ($me['role'] === 'A' && $partner) {
    $join = full_url('join/' . $partner['token']);
    $status = $partner['intro_done_at'] ? 'has started the quiz' : ($partner['started_at'] ? 'has opened the link' : 'has not opened the link yet');
    $body .= '<h1>Send this link to ' . e($me['partner_name']) . '</h1>
    <p>This is the private link for your partner. Send it by text or a messaging app. Anyone with it can answer as your partner, so only send it to them.</p>
    <div class="copy"><input type="text" readonly value="' . e($join) . '" id="joinlink"><button type="button" class="btn" data-copy="joinlink">Copy</button></div>
    <p class="muted">' . e($me['partner_name']) . ' ' . e($status) . '.</p>';
}
$body .= '<h2>Your own private link</h2>
<p class="warn">Save or bookmark this link now. It is the only way back to your answers and results.</p>
<div class="copy"><input type="text" readonly value="' . e($mine) . '" id="mylink"><button type="button" class="btn" data-copy="mylink">Copy</button></div>
<div class="nav"><span></span><a class="btn big" href="' . e(url('quiz/' . $TOKEN)) . '">Continue to the main quiz</a></div>
</div>';
render_page('Share', $body, ['js' => true]);
