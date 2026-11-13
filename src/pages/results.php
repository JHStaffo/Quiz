<?php
/** Matched results: only items where both partners scored 2 or higher. */
$names = names_for($me);
touch_participant($me);
$body = '';
if (!$me['main_done_at']) {
    $body = '<div class="card"><h1>Not yet</h1><p>Finish your own quiz first, then your results will appear here.</p>'
        . '<a class="btn" href="' . e(url($me['intro_done_at'] ? 'quiz/' . $TOKEN : 'join/' . $TOKEN)) . '">Continue my quiz</a></div>';
    render_page('Results', $body);
    return;
}
if (!$partner || !$partner['main_done_at']) {
    $state = !$partner || !$partner['started_at'] ? 'has not opened their link yet'
        : (!$partner['intro_done_at'] ? 'is answering the private questions' : 'is working on the main quiz');
    $body = '<div class="card"><h1>Waiting for ' . e($names['partner']) . '</h1>'
        . '<p>You are done. ' . e($names['partner']) . ' ' . e($state) . '. Come back to this page once they finish.</p>';
    if ($me['role'] === 'A' && $partner) {
        $body .= '<p><a href="' . e(url('share/' . $TOKEN)) . '">Show the partner link again</a></p>';
    }
    $body .= '<p><a href="' . e(url('quiz/' . $TOKEN)) . '">Review my answers</a></p></div>';
    render_page('Results', $body);
    return;
}

[$pA, $pB] = $me['role'] === 'A' ? [$me, $partner] : [$partner, $me];
$groups = build_results($pA, $pB);
$count = 0;
$hearts = 0;
foreach ($groups as $g) {
    foreach ($g['items'] as $it) {
        $count++;
        $hearts += $it['mutual_heart'] ? 1 : 0;
    }
}
$verb = [2 => 'Try', 3 => 'Occasionally', 4 => 'Regularly'];
$body .= '<div class="card"><h1>Your matches</h1>'
    . '<p>' . e($names['me']) . ' and ' . e($names['partner']) . ' both said yes to <b>' . $count . '</b> thing' . ($count === 1 ? '' : 's')
    . ($hearts ? ', including <b>' . $hearts . '</b> you both ♥ hearted' : '') . '. Each item shows the level you both agree on (the lower of your two answers).</p>'
    . '<div class="levels"><span class="lvl l2">Try</span> at least one of you wants to try it '
    . '<span class="lvl l3">Occasionally</span> both want it now and then '
    . '<span class="lvl l4">Regularly</span> both want it often</div></div>';
if (!$count) {
    $body .= '<div class="card"><p>No matches this time. That is fine, talk about it and maybe retake the quiz later.</p></div>';
}
foreach ($groups as $g) {
    $body .= '<section class="cat results"><h2>' . e(fill_names($g['cat']['name'], $names)) . '</h2>';
    foreach ($g['items'] as $it) {
        $text = question_text($it['q'], $names);
        $body .= '<div class="match' . ($it['mutual_heart'] ? ' hearted' : '') . '">';
        if ($it['level'] !== null) {
            $body .= '<span class="lvl l' . $it['level'] . '">' . e($verb[$it['level']]) . '</span>';
        }
        $body .= '<div class="m-text">' . e($text);
        if ($it['shared']) {
            $body .= '<div class="shared">You both picked: ' . e(implode(', ', array_map(fn($o) => fill_names($o, $names), $it['shared']))) . '</div>';
        }
        $body .= '</div>' . ($it['mutual_heart'] ? '<span class="mh" title="You both hearted this">♥</span>' : '');
        foreach ($it['comments'] as $c) {
            $who = $c['who']['gender'] === 'male' ? $names['male'] : $names['female'];
            $body .= '<div class="comment"><b>' . e($who) . ':</b> ' . nl2br(e($c['text'])) . '</div>';
        }
        $body .= '</div>';
    }
    $body .= '</section>';
}
$body .= '<div class="card muted">Want to change an answer? <a href="' . e(url('quiz/' . $TOKEN)) . '">Edit my answers</a>. Results update straight away.</div>';
render_page('Results', $body);
