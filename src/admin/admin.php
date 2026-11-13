<?php
/** Admin backend: login, usage, sessions, questions, categories, settings. */

$sub = $parts[1] ?? '';
$arg = $parts[2] ?? '';
$ip = substr((string)($_SERVER['REMOTE_ADDR'] ?? ''), 0, 64);

function admin_nav(): string
{
    return '<nav class="admin-nav">'
        . '<a href="' . e(url('admin')) . '">Usage</a>'
        . '<a href="' . e(url('admin/sessions')) . '">Surveys</a>'
        . '<a href="' . e(url('admin/questions')) . '">Questions</a>'
        . '<a href="' . e(url('admin/settings')) . '">Settings</a>'
        . '<form method="post" action="' . e(url('admin/logout')) . '">' . csrf_field() . '<button class="linkish">Log out</button></form>'
        . '</nav>';
}

function admin_page(string $title, string $body): void
{
    render_page($title, $body, ['nav' => admin_nav(), 'body_class' => 'admin', 'js' => true]);
}

function check_admin_password(string $given): bool
{
    $stored = (string)cfg('admin_password', '');
    if ($stored === '' || stripos($stored, 'CHANGE_ME') === 0) {
        return false; // refuse until a real password is configured
    }
    if (strpos($stored, '$2y$') === 0 || strpos($stored, '$argon2') === 0) {
        return password_verify($given, $stored);
    }
    return hash_equals($stored, $given);
}

// ---- Login / logout ----------------------------------------------------------
if ($sub === 'logout' && $method === 'POST') {
    csrf_check();
    unset($_SESSION['admin']);
    session_regenerate_id(true);
    redirect('admin');
}

if (empty($_SESSION['admin'])) {
    $err = '';
    if ($method === 'POST') {
        csrf_check();
        q('DELETE FROM admin_login_attempts WHERE attempted_at < NOW() - INTERVAL 1 DAY');
        $recent = (int)q('SELECT COUNT(*) FROM admin_login_attempts WHERE ip = ? AND attempted_at > NOW() - INTERVAL 15 MINUTE', [$ip])->fetchColumn();
        if ($recent >= 8) {
            $err = 'Too many attempts. Wait 15 minutes and try again.';
        } elseif (check_admin_password((string)($_POST['password'] ?? ''))) {
            session_regenerate_id(true);
            $_SESSION['admin'] = true;
            q('DELETE FROM admin_login_attempts WHERE ip = ?', [$ip]);
            redirect('admin');
        } else {
            q('INSERT INTO admin_login_attempts (ip, attempted_at) VALUES (?, NOW())', [$ip]);
            usleep(700000);
            $err = stripos((string)cfg('admin_password', ''), 'CHANGE_ME') === 0
                ? 'Set an admin password in config.php first.' : 'Wrong password.';
        }
    }
    render_page('Admin login', '<form method="post" class="card narrow">' . csrf_field()
        . '<h1>Admin</h1>' . ($err ? '<div class="error">' . e($err) . '</div>' : '')
        . '<input type="password" name="password" placeholder="Password" required autofocus>'
        . '<div class="nav"><span></span><button class="btn">Log in</button></div></form>', ['body_class' => 'admin']);
    return;
}

// ---- Helpers -----------------------------------------------------------------
function status_label(?array $p): string
{
    if (!$p) {
        return '-';
    }
    if ($p['main_done_at']) {
        return '<span class="pill done">Finished</span>';
    }
    if ($p['intro_done_at']) {
        return '<span class="pill mid">Main quiz</span>';
    }
    if ($p['started_at']) {
        return '<span class="pill start">Intro</span>';
    }
    return '<span class="pill none">Not opened</span>';
}

function fmt_dt(?string $d): string
{
    return $d ? e(date('j M Y H:i', strtotime($d))) : '-';
}

// ---- Routes ------------------------------------------------------------------
switch ($sub) {

case '': // usage dashboard
    $st = q('SELECT
        (SELECT COUNT(*) FROM quiz_sessions) AS sessions,
        (SELECT COUNT(*) FROM quiz_sessions WHERE created_at > NOW() - INTERVAL 7 DAY) AS s7,
        (SELECT COUNT(*) FROM quiz_sessions WHERE created_at > NOW() - INTERVAL 30 DAY) AS s30,
        (SELECT COUNT(*) FROM participants WHERE role = "B" AND started_at IS NOT NULL) AS joined,
        (SELECT COUNT(*) FROM participants WHERE main_done_at IS NOT NULL) AS finished_people,
        (SELECT COUNT(*) FROM quiz_sessions s WHERE (SELECT COUNT(*) FROM participants p WHERE p.session_id = s.id AND p.main_done_at IS NOT NULL) = 2) AS both_done,
        (SELECT COUNT(*) FROM questions WHERE section = "intro" AND active = 1) AS q_intro,
        (SELECT COUNT(*) FROM questions WHERE section = "main" AND active = 1) AS q_main')->fetch();
    $tiles = [
        ['Quizzes started', $st['sessions']], ['Last 7 days', $st['s7']], ['Last 30 days', $st['s30']],
        ['Partners joined', $st['joined']], ['People finished', $st['finished_people']], ['Couples with results', $st['both_done']],
        ['Active intro questions', $st['q_intro']], ['Active main questions', $st['q_main']],
    ];
    $h = '<div class="card"><h1>Usage</h1><div class="tiles">';
    foreach ($tiles as [$k, $v]) {
        $h .= '<div class="tile"><b>' . (int)$v . '</b><span>' . e($k) . '</span></div>';
    }
    $h .= '</div></div>';
    // Most popular matched items (both >= 2)
    $pop = q('SELECT qq.text, COUNT(*) AS n FROM answers a
        JOIN participants pa ON pa.id = a.participant_id AND pa.role = "A"
        JOIN participants pb ON pb.session_id = pa.session_id AND pb.role = "B"
        JOIN answers b ON b.participant_id = pb.id AND b.question_id = a.question_id
        JOIN questions qq ON qq.id = a.question_id
        WHERE qq.qtype = "scale" AND a.value_int >= 2 AND b.value_int >= 2
          AND pa.main_done_at IS NOT NULL AND pb.main_done_at IS NOT NULL
        GROUP BY qq.id, qq.text ORDER BY n DESC LIMIT 10')->fetchAll();
    if ($pop) {
        $names = ['male' => 'him', 'female' => 'her', 'me' => 'me', 'partner' => 'partner'];
        $h .= '<div class="card"><h2>Most common matches</h2><ol>';
        foreach ($pop as $r) {
            $h .= '<li>' . e(fill_names($r['text'], $names)) . ' <span class="muted">(' . (int)$r['n'] . ')</span></li>';
        }
        $h .= '</ol></div>';
    }
    admin_page('Admin', $h);
    break;

case 'sessions':
    $page = max(1, (int)($_GET['page'] ?? 1));
    $per = 50;
    $total = (int)q('SELECT COUNT(*) FROM quiz_sessions')->fetchColumn();
    $rows = q('SELECT s.id, s.created_at,
            a.self_name AS a_name, a.gender AS a_gender, a.started_at AS a_started, a.intro_done_at AS a_intro, a.main_done_at AS a_main, a.last_seen_at AS a_seen,
            b.self_name AS b_name, b.started_at AS b_started, b.intro_done_at AS b_intro, b.main_done_at AS b_main, b.last_seen_at AS b_seen
          FROM quiz_sessions s
          LEFT JOIN participants a ON a.session_id = s.id AND a.role = "A"
          LEFT JOIN participants b ON b.session_id = s.id AND b.role = "B"
          ORDER BY s.id DESC LIMIT ' . $per . ' OFFSET ' . (($page - 1) * $per))->fetchAll();
    $h = '<div class="card"><h1>Surveys</h1><p class="muted">' . $total . ' total. Names are what each person typed.</p><div class="tbl-wrap"><table class="tbl"><tr><th>#</th><th>Created</th><th>Person A</th><th>Person B</th><th>Last activity</th><th></th></tr>';
    foreach ($rows as $r) {
        $pa = ['started_at' => $r['a_started'], 'intro_done_at' => $r['a_intro'], 'main_done_at' => $r['a_main']];
        $pb = ['started_at' => $r['b_started'], 'intro_done_at' => $r['b_intro'], 'main_done_at' => $r['b_main']];
        $seen = max((string)$r['a_seen'], (string)$r['b_seen']);
        $h .= '<tr><td>' . (int)$r['id'] . '</td><td>' . fmt_dt($r['created_at']) . '</td>'
            . '<td>' . e($r['a_name']) . ' ' . status_label($pa) . '</td>'
            . '<td>' . e($r['b_name']) . ' ' . status_label($pb) . '</td>'
            . '<td>' . fmt_dt($seen ?: null) . '</td>'
            . '<td><a class="btn small" href="' . e(url('admin/session/' . (int)$r['id'])) . '">View</a></td></tr>';
    }
    $h .= '</table></div>';
    if ($total > $per) {
        $h .= '<div class="pager">';
        for ($i = 1; $i <= (int)ceil($total / $per); $i++) {
            $h .= '<a class="pg' . ($i === $page ? ' cur' : '') . '" href="' . e(url('admin/sessions?page=' . $i)) . '">' . $i . '</a>';
        }
        $h .= '</div>';
    }
    $h .= '</div>';
    admin_page('Surveys', $h);
    break;

case 'session':
    $sid = (int)$arg;
    $s = q('SELECT * FROM quiz_sessions WHERE id = ?', [$sid])->fetch();
    if (!$s) {
        not_found();
    }
    if ($method === 'POST' && ($_POST['action'] ?? '') === 'delete') {
        csrf_check();
        q('DELETE FROM quiz_sessions WHERE id = ?', [$sid]);
        flash('Survey #' . $sid . ' deleted.');
        redirect('admin/sessions');
    }
    $ps = q('SELECT * FROM participants WHERE session_id = ? ORDER BY role', [$sid])->fetchAll();
    $pA = $ps[0] ?? null;
    $pB = $ps[1] ?? null;
    // Use person A's naming for display
    $names = names_for($pA);
    $h = '<div class="card"><h1>Survey #' . $sid . '</h1><p class="muted">Created ' . fmt_dt($s['created_at']) . '</p><div class="tbl-wrap"><table class="tbl">'
        . '<tr><th></th><th>Person A</th><th>Person B</th></tr>';
    $rowsInfo = [
        'Name (self)' => fn($p) => e($p['self_name'] ?? ''),
        'Calls partner' => fn($p) => e($p['partner_name'] ?? ''),
        'Gender' => fn($p) => e($p['gender'] ?? ''),
        'Status' => fn($p) => status_label($p),
        'Opened' => fn($p) => fmt_dt($p['started_at'] ?? null),
        'Intro done' => fn($p) => fmt_dt($p['intro_done_at'] ?? null),
        'Main done' => fn($p) => fmt_dt($p['main_done_at'] ?? null),
        'Last seen' => fn($p) => fmt_dt($p['last_seen_at'] ?? null),
        'Private link' => fn($p) => $p ? '<a href="' . e(url(($p['intro_done_at'] ? 'quiz/' : 'join/') . $p['token'])) . '" target="_blank" rel="noopener">open</a>'
            . (cfg('debug_suffix_enabled', true) ? ' · <a href="' . e(url(($p['intro_done_at'] ? 'quiz/' : 'join/') . $p['token'] . '/' . cfg('debug_suffix', 'Dbg1357'))) . '" target="_blank" rel="noopener">debug</a>' : '') : '-',
    ];
    foreach ($rowsInfo as $label => $fn) {
        $h .= '<tr><th>' . e($label) . '</th><td>' . $fn($pA) . '</td><td>' . $fn($pB) . '</td></tr>';
    }
    $h .= '</table></div></div>';

    // Answers side by side
    $aAns = $pA ? load_answers((int)$pA['id']) : [];
    $bAns = $pB ? load_answers((int)$pB['id']) : [];
    foreach (['intro' => 'Private intro answers', 'main' => 'Main quiz answers'] as $sec => $title) {
        $h .= '<div class="card"><h2>' . e($title) . '</h2><div class="tbl-wrap"><table class="tbl answers"><tr><th>Question</th><th>A</th><th>B</th></tr>';
        foreach (load_questions($sec, false) as $g) {
            $h .= '<tr class="grp"><td colspan="3">' . e($g['cat']['name']) . '</td></tr>';
            foreach ($g['questions'] as $qq) {
                $qid = (int)$qq['id'];
                $cell = function (?array $a) use ($qq, $names) {
                    if (!$a) {
                        return '<span class="muted">-</span>';
                    }
                    $out = e(answer_display($qq, $a, $names));
                    if ($qq['qtype'] === 'scale' && $a['value_int'] !== null) {
                        $out = '<b class="sc' . (int)$a['value_int'] . '">' . (int)$a['value_int'] . '</b>';
                    }
                    if (!empty($a['heart'])) {
                        $out .= ' <span class="heart-on">♥</span>';
                    }
                    if (!empty($a['comment'])) {
                        $out .= '<div class="comment">' . nl2br(e($a['comment'])) . '</div>';
                    }
                    return $out;
                };
                $h .= '<tr><td>' . e(fill_names($qq['text'], $names)) . '</td><td>' . $cell($aAns[$qid] ?? null) . '</td><td>' . $cell($bAns[$qid] ?? null) . '</td></tr>';
            }
        }
        $h .= '</table></div></div>';
    }

    // Results
    if ($pA && $pB) {
        $h .= '<div class="card"><h2>Matched results</h2>';
        if (!$pA['main_done_at'] || !$pB['main_done_at']) {
            $h .= '<p class="muted">Not both finished yet. Preview of current matches:</p>';
        }
        $groups = build_results($pA, $pB);
        if (!$groups) {
            $h .= '<p>No matches.</p>';
        }
        foreach ($groups as $g) {
            $h .= '<h3>' . e($g['cat']['name']) . '</h3><ul class="plain">';
            foreach ($g['items'] as $it) {
                $h .= '<li>' . ($it['level'] ? '<span class="lvl l' . $it['level'] . '">' . e($it['label']) . '</span> ' : '')
                    . e(fill_names($it['q']['text'], $names))
                    . ($it['shared'] ? ': ' . e(implode(', ', $it['shared'])) : '')
                    . ($it['mutual_heart'] ? ' <span class="heart-on">♥♥</span>' : '') . '</li>';
            }
            $h .= '</ul>';
        }
        $h .= '</div>';
    }
    $h .= '<form method="post" class="card" onsubmit="return confirm(\'Delete this survey and all its answers permanently?\')">' . csrf_field()
        . '<input type="hidden" name="action" value="delete"><button class="btn danger">Delete this survey</button></form>';
    admin_page('Survey #' . $sid, $h);
    break;

case 'questions':
    $h = '<div class="card"><h1>Questions</h1>'
        . '<p class="muted">Placeholders: <code>$malepartner</code> and <code>$femalepartner</code> become the names each person gave. '
        . '<code>$me</code> and <code>$partner</code> are also available (the reader and their partner). Intro answers are private; main scale answers are matched on the results page.</p>'
        . '<p><a class="btn" href="' . e(url('admin/category/new')) . '">Add category</a> <a class="btn" href="' . e(url('admin/question/new')) . '">Add question</a></p></div>';
    foreach (['intro' => 'Intro (private) questions', 'main' => 'Main questionnaire'] as $sec => $title) {
        $cats = q('SELECT * FROM categories WHERE section = ? ORDER BY sort_order, id', [$sec])->fetchAll();
        $h .= '<div class="card"><h2>' . e($title) . '</h2>';
        foreach ($cats as $c) {
            $qs = q('SELECT * FROM questions WHERE category_id = ? ORDER BY sort_order, id', [$c['id']])->fetchAll();
            $h .= '<div class="adm-cat"><div class="adm-cat-head"><b>' . e($c['name']) . '</b> <span class="muted">order ' . (int)$c['sort_order'] . ' · ' . count($qs) . ' questions</span>'
                . ' <a class="btn small ghost" href="' . e(url('admin/category/' . $c['id'])) . '">Edit category</a>'
                . ' <a class="btn small ghost" href="' . e(url('admin/question/new?cat=' . $c['id'])) . '">+ Question</a></div><ol class="adm-qs">';
            foreach ($qs as $qq) {
                $h .= '<li class="' . ($qq['active'] ? '' : 'inactive') . '"><a href="' . e(url('admin/question/' . $qq['id'])) . '">' . e($qq['text']) . '</a>'
                    . ' <span class="tag">' . e($qq['qtype']) . '</span>' . ($qq['required'] ? '' : ' <span class="tag">optional</span>')
                    . ($qq['active'] ? '' : ' <span class="tag off">hidden</span>') . ' <span class="muted">#' . (int)$qq['sort_order'] . '</span></li>';
            }
            $h .= '</ol></div>';
        }
        $h .= '</div>';
    }
    admin_page('Questions', $h);
    break;

case 'category':
    $isNew = $arg === 'new';
    $c = $isNew ? ['id' => 0, 'section' => $_GET['section'] ?? 'main', 'name' => '', 'description' => '', 'sort_order' => 100]
        : q('SELECT * FROM categories WHERE id = ?', [(int)$arg])->fetch();
    if (!$c) {
        not_found();
    }
    if ($method === 'POST') {
        csrf_check();
        if (($_POST['action'] ?? '') === 'delete' && !$isNew) {
            q('DELETE FROM categories WHERE id = ?', [$c['id']]);
            flash('Category deleted along with its questions and answers.');
            redirect('admin/questions');
        }
        $sec = ($_POST['section'] ?? '') === 'intro' ? 'intro' : 'main';
        $name = trim((string)($_POST['name'] ?? ''));
        $desc = trim((string)($_POST['description'] ?? ''));
        $sort = (int)($_POST['sort_order'] ?? 0);
        if ($name === '') {
            flash('Name is required.');
            redirect('admin/category/' . $arg);
        }
        if ($isNew) {
            q('INSERT INTO categories (section, name, description, sort_order) VALUES (?, ?, ?, ?)', [$sec, $name, $desc ?: null, $sort]);
        } else {
            q('UPDATE categories SET section = ?, name = ?, description = ?, sort_order = ? WHERE id = ?', [$sec, $name, $desc ?: null, $sort, $c['id']]);
            q('UPDATE questions SET section = ? WHERE category_id = ?', [$sec, $c['id']]);
        }
        flash('Category saved.');
        redirect('admin/questions');
    }
    $h = '<form method="post" class="card">' . csrf_field() . '<h1>' . ($isNew ? 'New category' : 'Edit category') . '</h1>'
        . '<label class="fld">Section<select name="section"><option value="intro"' . ($c['section'] === 'intro' ? ' selected' : '') . '>Intro (private)</option>'
        . '<option value="main"' . ($c['section'] === 'main' ? ' selected' : '') . '>Main questionnaire</option></select></label>'
        . '<label class="fld">Name<input type="text" name="name" required maxlength="150" value="' . e($c['name']) . '"></label>'
        . '<label class="fld">Description (optional, shown under the heading)<input type="text" name="description" maxlength="500" value="' . e($c['description']) . '"></label>'
        . '<label class="fld">Sort order (lower comes first)<input type="number" name="sort_order" value="' . (int)$c['sort_order'] . '"></label>'
        . '<div class="nav"><a class="btn ghost" href="' . e(url('admin/questions')) . '">Cancel</a><button class="btn">Save</button></div></form>';
    if (!$isNew) {
        $h .= '<form method="post" class="card" onsubmit="return confirm(\'Delete this category, all its questions and every answer to them?\')">' . csrf_field()
            . '<input type="hidden" name="action" value="delete"><button class="btn danger">Delete category</button>'
            . ' <span class="muted">Tip: to hide questions without losing answers, untick "Active" on each question instead.</span></form>';
    }
    admin_page('Category', $h);
    break;

case 'question':
    $isNew = $arg === 'new';
    $qq = $isNew ? ['id' => 0, 'category_id' => (int)($_GET['cat'] ?? 0), 'qtype' => 'scale', 'text' => '', 'help' => '', 'options' => '', 'required' => 1, 'active' => 1, 'sort_order' => 100]
        : q('SELECT * FROM questions WHERE id = ?', [(int)$arg])->fetch();
    if (!$qq) {
        not_found();
    }
    $cats = q('SELECT * FROM categories ORDER BY section, sort_order, id')->fetchAll();
    if ($method === 'POST') {
        csrf_check();
        if (($_POST['action'] ?? '') === 'delete' && !$isNew) {
            q('DELETE FROM questions WHERE id = ?', [$qq['id']]);
            flash('Question deleted.');
            redirect('admin/questions');
        }
        $cat = null;
        foreach ($cats as $c) {
            if ((int)$c['id'] === (int)($_POST['category_id'] ?? 0)) {
                $cat = $c;
            }
        }
        $type = array_key_exists($_POST['qtype'] ?? '', QTYPES) ? $_POST['qtype'] : 'scale';
        $text = trim((string)($_POST['text'] ?? ''));
        if (!$cat || $text === '') {
            flash('Category and question text are required.');
            redirect('admin/question/' . $arg);
        }
        $opts = trim(str_replace("\r", '', (string)($_POST['options'] ?? '')));
        if (in_array($type, ['single', 'multi'], true) && $opts === '') {
            flash('Add at least one option (one per line) for this question type.');
            redirect('admin/question/' . $arg);
        }
        $vals = [(int)$cat['id'], $cat['section'], $type, mb_substr($text, 0, 1000), trim((string)($_POST['help'] ?? '')) ?: null,
                 $opts ?: null, empty($_POST['required']) ? 0 : 1, empty($_POST['active']) ? 0 : 1, (int)($_POST['sort_order'] ?? 0)];
        if ($isNew) {
            q('INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES (?,?,?,?,?,?,?,?,?)', $vals);
        } else {
            $vals[] = $qq['id'];
            q('UPDATE questions SET category_id=?, section=?, qtype=?, text=?, help=?, options=?, required=?, active=?, sort_order=? WHERE id=?', $vals);
        }
        flash('Question saved.');
        redirect('admin/questions');
    }
    $catOpts = '';
    foreach ($cats as $c) {
        $catOpts .= '<option value="' . (int)$c['id'] . '"' . ((int)$c['id'] === (int)$qq['category_id'] ? ' selected' : '') . '>'
            . ($c['section'] === 'intro' ? 'Intro: ' : 'Main: ') . e($c['name']) . '</option>';
    }
    $typeOpts = '';
    foreach (QTYPES as $k => $label) {
        $typeOpts .= '<option value="' . e($k) . '"' . ($qq['qtype'] === $k ? ' selected' : '') . '>' . e($label) . '</option>';
    }
    $answerCount = $isNew ? 0 : (int)q('SELECT COUNT(*) FROM answers WHERE question_id = ?', [$qq['id']])->fetchColumn();
    $h = '<form method="post" class="card">' . csrf_field() . '<h1>' . ($isNew ? 'New question' : 'Edit question') . '</h1>'
        . '<label class="fld">Category<select name="category_id" required><option value="">Choose...</option>' . $catOpts . '</select></label>'
        . '<label class="fld">Answer type<select name="qtype">' . $typeOpts . '</select></label>'
        . '<label class="fld">Question text<textarea name="text" rows="2" required maxlength="1000">' . e($qq['text']) . '</textarea>'
        . '<small class="muted">Use $malepartner, $femalepartner, $me, $partner. For main questions, write it as an activity (e.g. "$malepartner giving $femalepartner a massage") so results read as "Try ...", "Regularly ...".</small></label>'
        . '<label class="fld">Help text (optional)<input type="text" name="help" maxlength="1000" value="' . e($qq['help']) . '"></label>'
        . '<label class="fld">Options, one per line (only for "pick one" and "pick any")<textarea name="options" rows="5">' . e($qq['options']) . '</textarea></label>'
        . '<label class="fld">Sort order within category<input type="number" name="sort_order" value="' . (int)$qq['sort_order'] . '"></label>'
        . '<label class="chk"><input type="checkbox" name="required" value="1"' . ($qq['required'] ? ' checked' : '') . '> Required</label>'
        . '<label class="chk"><input type="checkbox" name="active" value="1"' . ($qq['active'] ? ' checked' : '') . '> Active (shown in the quiz)</label>'
        . '<div class="nav"><a class="btn ghost" href="' . e(url('admin/questions')) . '">Cancel</a><button class="btn">Save</button></div></form>';
    if (!$isNew) {
        $h .= '<form method="post" class="card" onsubmit="return confirm(\'Delete this question and its ' . $answerCount . ' answers?\')">' . csrf_field()
            . '<input type="hidden" name="action" value="delete"><button class="btn danger">Delete question</button> <span class="muted">' . $answerCount . ' saved answers. Untick Active to hide it but keep answers.</span></form>';
    }
    admin_page('Question', $h);
    break;

case 'settings':
    if ($method === 'POST') {
        csrf_check();
        $mq = max(1, min(200, (int)($_POST['max_questions_per_page'] ?? 15)));
        $mc = max(1, min(50, (int)($_POST['max_categories_per_page'] ?? 2)));
        foreach (['max_questions_per_page' => $mq, 'max_categories_per_page' => $mc] as $k => $v) {
            q('INSERT INTO settings (name, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value)', [$k, (string)$v]);
        }
        flash('Settings saved.');
        redirect('admin/settings');
    }
    $h = '<form method="post" class="card">' . csrf_field() . '<h1>Settings</h1>'
        . '<h2>Pages</h2><p class="muted">Questions are grouped by category. A page never shows more than these limits. A category bigger than one page is split across pages.</p>'
        . '<label class="fld">Max questions per page<input type="number" min="1" max="200" name="max_questions_per_page" value="' . (int)setting('max_questions_per_page', 15) . '"></label>'
        . '<label class="fld">Max categories per page<input type="number" min="1" max="50" name="max_categories_per_page" value="' . (int)setting('max_categories_per_page', 2) . '"></label>'
        . '<div class="nav"><span></span><button class="btn">Save</button></div></form>'
        . '<div class="card"><h2>Other settings</h2><p class="muted">Database details, the admin password, the site name and the debug suffix (currently <b>'
        . (cfg('debug_suffix_enabled', true) ? 'on' : 'off') . '</b>) are set in <code>config.php</code>.</p></div>';
    admin_page('Settings', $h);
    break;

default:
    not_found();
}
