<?php
/** Intro (private baseline) questions for either partner. Page 0 = names. */
require __DIR__ . '/_form.php';

$suffix = $DEBUG ? '/' . cfg('debug_suffix', 'Dbg1357') : '';
$self = 'join/' . $TOKEN . $suffix;
$pages = paginate_groups(load_questions('intro'));
$total = count($pages);
$p = max(0, min($total, (int)($_GET['p'] ?? 0)));
$names = names_for($me);

$finishIntro = function () use ($me, $TOKEN) {
    if (!$me['intro_done_at']) {
        q('UPDATE participants SET intro_done_at = NOW() WHERE id = ?', [$me['id']]);
    }
    redirect($me['role'] === 'A' ? 'share/' . $TOKEN : 'quiz/' . $TOKEN);
};

if ($method === 'POST') {
    csrf_check();
    $nav = (string)($_POST['nav'] ?? 'next');
    if ($p === 0) {
        $sn = mb_substr(trim((string)($_POST['self_name'] ?? '')), 0, 100);
        $pn = mb_substr(trim((string)($_POST['partner_name'] ?? '')), 0, 100);
        if ($sn === '' || $pn === '') {
            flash('Please fill in both names.');
            redirect($self . '?p=0');
        }
        q('UPDATE participants SET self_name = ?, partner_name = ? WHERE id = ?', [$sn, $pn, $me['id']]);
        touch_participant($me);
        if ($total === 0) {
            $finishIntro();
        }
        redirect($self . '?p=1');
    }
    $missing = save_page($me, page_questions($pages[$p - 1]));
    if ($nav === 'prev') {
        redirect($self . '?p=' . ($p - 1));
    }
    if ($missing) {
        $_SESSION['missing'] = $missing;
        flash('Please answer the highlighted question' . (count($missing) > 1 ? 's' : '') . '.');
        redirect($self . '?p=' . $p);
    }
    if ($p >= $total) {
        $finishIntro();
    }
    redirect($self . '?p=' . ($p + 1));
}

touch_participant($me);
$missing = $_SESSION['missing'] ?? [];
unset($_SESSION['missing']);

$partnerAnswers = ($DEBUG && $partner) ? load_answers((int)$partner['id']) : [];

$body = '<form method="post" class="quiz" action="' . e(url($self . '?p=' . $p)) . '">' . csrf_field();
if ($DEBUG) {
    $body .= '<div class="dbg-banner">Debug view: your partner\'s answers are highlighted in yellow.</div>';
}
$body .= '<div class="card">';
if ($p === 0) {
    $body .= '<h1>' . ($me['role'] === 'B' ? 'Your partner invited you' : 'About you two') . '</h1>';
    if ($me['role'] === 'B') {
        $body .= '<p>' . e($me['partner_name'] ?: 'Your partner') . ' has started a private couples quiz and would like you to take it too. '
            . 'You each answer on your own. When you are both done, you will only see the things you <b>both</b> said yes to. Nothing else is ever shown.</p>'
            . '<p class="warn">This link is private to you. Bookmark it, it is the only way back to your answers.</p>';
    }
    $dbgSelf = ($DEBUG && $partner) ? '<div class="dbg-text">' . e($partner['partner_name']) . '</div>' : '';
    $dbgOther = ($DEBUG && $partner) ? '<div class="dbg-text">' . e($partner['self_name']) . '</div>' : '';
    $body .= '<div class="q"><div class="q-text">What should the quiz call you?</div><div class="text-row">' . $dbgSelf
        . '<input type="text" name="self_name" required maxlength="100" value="' . e($me['self_name']) . '"></div></div>'
        . '<div class="q"><div class="q-text">What do you call your partner?</div><div class="text-row">' . $dbgOther
        . '<input type="text" name="partner_name" required maxlength="100" value="' . e($me['partner_name']) . '"></div></div>';
    $body .= '<div class="nav"><span></span><button class="btn" name="nav" value="next">Continue</button></div></div></form>';
    render_page('Welcome', $body, ['js' => true]);
    return;
}

$body .= '<h1>Private questions</h1><p class="muted">These answers are stored privately and are <b>never</b> shown to your partner.</p>'
    . render_steps($p, $total, $self);
$body .= '</div>';
$body .= render_page_groups($pages[$p - 1], load_answers((int)$me['id']), $names, $DEBUG, $partnerAnswers, $missing);
$body .= '<div class="nav card">'
    . '<button class="btn ghost" name="nav" value="prev" formnovalidate>Back</button>'
    . '<button class="btn" name="nav" value="next">' . ($p >= $total ? ($me['role'] === 'A' ? 'Finish and get partner link' : 'Continue to the quiz') : 'Next') . '</button>'
    . '</div></form>';
render_page('Private questions', $body, ['js' => true]);
