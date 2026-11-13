<?php
/** Main questionnaire, paged. Works for either partner (detected by token). */
require __DIR__ . '/_form.php';

if (!$me['intro_done_at']) {
    redirect('join/' . $TOKEN . ($DEBUG ? '/' . cfg('debug_suffix', 'Dbg1357') : ''));
}
$suffix = $DEBUG ? '/' . cfg('debug_suffix', 'Dbg1357') : '';
$self = 'quiz/' . $TOKEN . $suffix;
$pages = paginate_groups(load_questions('main'));
$total = count($pages);
$p = max(1, min(max($total, 1), (int)($_GET['p'] ?? 1)));
$names = names_for($me);
$isAjax = ($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '') === 'fetch';

if ($method === 'POST') {
    csrf_check();
    if ($total > 0) {
        save_page($me, page_questions($pages[$p - 1]));
    }
    if ($isAjax) {
        header('Content-Type: application/json');
        echo json_encode(['ok' => true]);
        exit;
    }
    $nav = (string)($_POST['nav'] ?? 'next');
    if ($nav === 'prev') {
        redirect($self . '?p=' . max(1, $p - 1));
    }
    if (preg_match('/^goto(\d+)$/', $nav, $m)) {
        redirect($self . '?p=' . (int)$m[1]);
    }
    if ($nav === 'finish' || $p >= $total) {
        // Every required question on every page must be answered
        $ans = load_answers((int)$me['id']);
        foreach ($pages as $i => $pg) {
            $miss = [];
            foreach (page_questions($pg) as $qq) {
                if ($qq['required'] && !answer_is_filled($qq, $ans[(int)$qq['id']] ?? null)) {
                    $miss[] = (int)$qq['id'];
                }
            }
            if ($miss) {
                $_SESSION['missing'] = $miss;
                flash('A few questions still need an answer (highlighted below).');
                redirect($self . '?p=' . ($i + 1));
            }
        }
        if (!$me['main_done_at']) {
            q('UPDATE participants SET main_done_at = NOW() WHERE id = ?', [$me['id']]);
        }
        redirect('results/' . $TOKEN);
    }
    redirect($self . '?p=' . ($p + 1));
}

touch_participant($me);
$missing = $_SESSION['missing'] ?? [];
unset($_SESSION['missing']);
$partnerAnswers = ($DEBUG && $partner) ? load_answers((int)$partner['id']) : [];
$answers = load_answers((int)$me['id']);

// Which pages are complete (for the page picker)
$pageState = [];
foreach ($pages as $i => $pg) {
    $done = true;
    foreach (page_questions($pg) as $qq) {
        if ($qq['required'] && !answer_is_filled($qq, $answers[(int)$qq['id']] ?? null)) {
            $done = false;
            break;
        }
    }
    $pageState[$i + 1] = $done;
}

$body = '<form method="post" class="quiz autosave" action="' . e(url($self . '?p=' . $p)) . '">' . csrf_field();
if ($DEBUG) {
    $body .= '<div class="dbg-banner">Debug view: your partner\'s answers are highlighted in yellow.</div>';
}
$body .= '<div class="card"><h1>The quiz</h1>';
if ($me['main_done_at']) {
    $body .= '<p class="ok">You have finished. You can still change answers; results update automatically. <a href="' . e(url('results/' . $TOKEN)) . '">See results</a></p>';
}
$body .= '<p class="muted">Rate each item. Tap ♥ for things you are really excited about, and add a note if you like. Only matches are ever shown to ' . e($names['partner']) . '.</p>'
    . '<details class="legend-wrap"><summary>What do the numbers mean?</summary>' . scale_legend() . '</details>'
    . render_steps($p, $total, $self);
if ($total > 1) {
    $body .= '<div class="pager">';
    for ($i = 1; $i <= $total; $i++) {
        $body .= '<button class="pg' . ($i === $p ? ' cur' : '') . ($pageState[$i] ? ' done' : '') . '" name="nav" value="goto' . $i . '" formnovalidate>' . $i . '</button>';
    }
    $body .= '</div>';
}
$body .= '</div>';
if ($total === 0) {
    $body .= '<div class="card"><p>No questions have been set up yet.</p></div></form>';
    render_page('Quiz', $body);
    return;
}
$body .= render_page_groups($pages[$p - 1], $answers, $names, $DEBUG, $partnerAnswers, $missing);
$body .= '<div class="nav card">'
    . ($p > 1 ? '<button class="btn ghost" name="nav" value="prev" formnovalidate>Back</button>' : '<span></span>')
    . ($p < $total
        ? '<button class="btn" name="nav" value="next">Next page</button>'
        : '<button class="btn big" name="nav" value="finish">' . ($me['main_done_at'] ? 'Save and view results' : 'Finish quiz') . '</button>')
    . '</div><p class="saved-note muted" aria-live="polite"></p></form>';
render_page('Quiz', $body, ['js' => true]);
