<?php
declare(strict_types=1);

// ---------------------------------------------------------------------------
// Bootstrap: config, database, helpers, layout
// ---------------------------------------------------------------------------

$configFile = dirname(__DIR__) . '/config.php';
if (!is_file($configFile)) {
    http_response_code(500);
    exit('Missing config.php. Copy config.sample.php to config.php and fill in your database details.');
}
$CONFIG = require $configFile;

function cfg(string $key, $default = null)
{
    global $CONFIG;
    return $CONFIG[$key] ?? $default;
}

ini_set('session.cookie_httponly', '1');
ini_set('session.use_strict_mode', '1');
ini_set('session.cookie_samesite', 'Lax');
if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
    ini_set('session.cookie_secure', '1');
}
session_name('cqsess');
session_start();

header('X-Robots-Tag: noindex, nofollow');
header('Referrer-Policy: no-referrer');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $dsn = 'mysql:host=' . cfg('db_host') . ';dbname=' . cfg('db_name') . ';charset=utf8mb4';
        try {
            $pdo = new PDO($dsn, cfg('db_user'), cfg('db_pass'), [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            exit('Database connection failed. Check the settings in config.php.');
        }
    }
    return $pdo;
}

function q(string $sql, array $params = []): PDOStatement
{
    $st = db()->prepare($sql);
    $st->execute($params);
    return $st;
}

function e($s): string
{
    return htmlspecialchars((string)$s, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function base_path(): string
{
    static $bp = null;
    if ($bp === null) {
        $bp = rtrim((string)cfg('base_path', ''), '/');
        if ($bp === '') {
            $dir = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/'));
            $bp = rtrim($dir, '/');
        }
    }
    return $bp;
}

function url(string $path = ''): string
{
    return base_path() . '/' . ltrim($path, '/');
}

function full_url(string $path = ''): string
{
    $https = !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    return ($https ? 'https' : 'http') . '://' . $host . url($path);
}

function redirect(string $path): void
{
    header('Location: ' . url($path));
    exit;
}

function new_token(): string
{
    return bin2hex(random_bytes(32)); // 64 hex chars, 256 bits
}

function is_token(string $t): bool
{
    return (bool)preg_match('/^[a-f0-9]{64}$/', $t);
}

// --- CSRF -------------------------------------------------------------------
function csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="csrf" value="' . e(csrf_token()) . '">';
}

function csrf_check(): void
{
    $sent = $_POST['csrf'] ?? ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    if (!is_string($sent) || !hash_equals(csrf_token(), $sent)) {
        http_response_code(400);
        render_page('Session expired', '<div class="card"><h1>Session expired</h1><p>Your page was open too long or cookies are blocked. Go back, reload the page and try again. Answers already saved are safe.</p></div>');
        exit;
    }
}

function flash(?string $msg = null): ?string
{
    if ($msg !== null) {
        $_SESSION['flash'] = $msg;
        return null;
    }
    $m = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    return $m;
}

// --- Scale --------------------------------------------------------------------
const SCALE = [
    0 => ['short' => 'No way',   'long' => 'I would lose respect for or leave my partner if this happened'],
    1 => ['short' => 'Not into it', 'long' => 'Not interested'],
    2 => ['short' => 'Try',      'long' => 'I would like to try it'],
    3 => ['short' => 'Sometimes', 'long' => 'I would like to do it occasionally'],
    4 => ['short' => 'Regularly', 'long' => 'I want to do it regularly'],
];

const RESULT_LABEL = [2 => 'Try', 3 => 'Occasionally', 4 => 'Regularly'];

const QTYPES = [
    'scale'    => 'Scale 0-4 (main questions)',
    'single'   => 'Pick one option',
    'multi'    => 'Pick any options (checkboxes)',
    'text'     => 'Short text',
    'textarea' => 'Long text',
];

// --- Quiz sessions / participants -----------------------------------------
/**
 * Look up a participant by token. Returns [participant, partner, session] or null.
 */
function find_by_token(string $token): ?array
{
    if (!is_token($token)) {
        return null;
    }
    $p = q('SELECT * FROM participants WHERE token = ?', [$token])->fetch();
    if (!$p || !hash_equals($p['token'], $token)) {
        return null;
    }
    $partner = q('SELECT * FROM participants WHERE session_id = ? AND id <> ?', [$p['session_id'], $p['id']])->fetch() ?: null;
    $session = q('SELECT * FROM quiz_sessions WHERE id = ?', [$p['session_id']])->fetch();
    return [$p, $partner, $session];
}

/**
 * Replace $malepartner / $femalepartner (and $partner / $me) with names
 * from the viewpoint of the given participant.
 */
function names_for(?array $viewer, ?array $partner = null): array
{
    $male = 'him';
    $female = 'her';
    if ($viewer) {
        $self = trim((string)$viewer['self_name']);
        $other = trim((string)$viewer['partner_name']);
        if ($viewer['gender'] === 'male') {
            $male = $self !== '' ? $self : 'Him';
            $female = $other !== '' ? $other : 'Her';
        } else {
            $female = $self !== '' ? $self : 'Her';
            $male = $other !== '' ? $other : 'Him';
        }
    }
    return [
        'male' => $male,
        'female' => $female,
        'me' => $viewer['gender'] ?? '' ? ($viewer['gender'] === 'male' ? $male : $female) : 'me',
        'partner' => $viewer['gender'] ?? '' ? ($viewer['gender'] === 'male' ? $female : $male) : 'my partner',
    ];
}

function fill_names(string $text, array $names): string
{
    return strtr($text, [
        '$malepartner'   => $names['male'],
        '$femalepartner' => $names['female'],
        '$partner'       => $names['partner'],
        '$me'            => $names['me'],
    ]);
}

function question_options(array $q): array
{
    $lines = preg_split('/\r\n|\r|\n/', (string)$q['options']);
    return array_values(array_filter(array_map('trim', $lines), fn($l) => $l !== ''));
}

/**
 * Load questions for a section grouped by category.
 * @return array<int, array{cat: array, questions: array}>
 */
function load_questions(string $section, bool $activeOnly = true): array
{
    $sql = 'SELECT q.*, c.name AS cat_name, c.sort_order AS cat_sort, c.description AS cat_desc
            FROM questions q JOIN categories c ON c.id = q.category_id
            WHERE c.section = ?' . ($activeOnly ? ' AND q.active = 1' : '') . '
            ORDER BY c.sort_order, c.id, q.sort_order, q.id';
    $groups = [];
    foreach (q($sql, [$section])->fetchAll() as $row) {
        $cid = (int)$row['category_id'];
        if (!isset($groups[$cid])) {
            $groups[$cid] = ['cat' => ['id' => $cid, 'name' => $row['cat_name'], 'description' => $row['cat_desc']], 'questions' => []];
        }
        $groups[$cid]['questions'][] = $row;
    }
    return array_values($groups);
}

function load_answers(int $participantId): array
{
    $out = [];
    foreach (q('SELECT * FROM answers WHERE participant_id = ?', [$participantId])->fetchAll() as $a) {
        $out[(int)$a['question_id']] = $a;
    }
    return $out;
}

/**
 * Normalise and save one answer from POST-style data.
 */
function save_answer(int $participantId, array $question, array $data): void
{
    $type = $question['qtype'];
    $valueInt = null;
    $valueText = null;
    if ($type === 'scale') {
        $v = $data['v'] ?? '';
        if ($v !== '' && $v !== null && ctype_digit((string)$v) && (int)$v >= 0 && (int)$v <= 4) {
            $valueInt = (int)$v;
        }
    } elseif ($type === 'single') {
        $v = (string)($data['v'] ?? '');
        $valueText = in_array($v, question_options($question), true) ? $v : null;
    } elseif ($type === 'multi') {
        $v = $data['v'] ?? [];
        $v = is_array($v) ? $v : [];
        $opts = question_options($question);
        $picked = array_values(array_filter($v, fn($x) => in_array($x, $opts, true)));
        $valueText = $picked ? json_encode($picked, JSON_UNESCAPED_UNICODE) : null;
    } else {
        $v = trim((string)($data['v'] ?? ''));
        $valueText = $v !== '' ? mb_substr($v, 0, 5000) : null;
    }
    $comment = trim((string)($data['c'] ?? ''));
    $comment = $comment !== '' ? mb_substr($comment, 0, 2000) : null;
    $heart = !empty($data['h']) && $question['section'] === 'main' ? 1 : 0;

    q('INSERT INTO answers (participant_id, question_id, value_int, value_text, comment, heart, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())
       ON DUPLICATE KEY UPDATE value_int = VALUES(value_int), value_text = VALUES(value_text),
         comment = VALUES(comment), heart = VALUES(heart), updated_at = NOW()',
        [$participantId, (int)$question['id'], $valueInt, $valueText, $comment, $heart]);
}

function answer_is_filled(array $question, ?array $a): bool
{
    if (!$a) {
        return false;
    }
    if ($question['qtype'] === 'scale') {
        return $a['value_int'] !== null;
    }
    return $a['value_text'] !== null && $a['value_text'] !== '';
}

function answer_display(array $question, ?array $a, array $names): string
{
    if (!$a) {
        return '';
    }
    if ($question['qtype'] === 'scale') {
        return $a['value_int'] === null ? '' : $a['value_int'] . ' - ' . SCALE[(int)$a['value_int']]['long'];
    }
    if ($question['qtype'] === 'multi') {
        $arr = json_decode((string)$a['value_text'], true) ?: [];
        return implode(', ', array_map(fn($o) => fill_names($o, $names), $arr));
    }
    if ($question['qtype'] === 'single') {
        return fill_names((string)$a['value_text'], $names);
    }
    return (string)$a['value_text'];
}

// --- Matching ---------------------------------------------------------------
/**
 * Build the matched results for two participants.
 * Returns groups: [ ['cat'=>..., 'items'=>[ ['q'=>..,'level'=>2..4,'label'=>..,'mutual_heart'=>bool,'comments'=>[...], 'shared'=>[...]] ]] ]
 */
function build_results(array $pA, array $pB): array
{
    $aAns = load_answers((int)$pA['id']);
    $bAns = load_answers((int)$pB['id']);
    $out = [];
    foreach (load_questions('main') as $g) {
        $items = [];
        foreach ($g['questions'] as $qq) {
            $qid = (int)$qq['id'];
            $a = $aAns[$qid] ?? null;
            $b = $bAns[$qid] ?? null;
            if (!$a || !$b) {
                continue;
            }
            $item = ['q' => $qq, 'level' => null, 'label' => null, 'shared' => [],
                     'mutual_heart' => $a['heart'] && $b['heart'],
                     'comments' => []];
            if ($qq['qtype'] === 'scale') {
                if ($a['value_int'] === null || $b['value_int'] === null) {
                    continue;
                }
                $lvl = min((int)$a['value_int'], (int)$b['value_int']);
                if ($lvl < 2) {
                    continue;
                }
                $item['level'] = $lvl;
                $item['label'] = RESULT_LABEL[$lvl];
            } elseif ($qq['qtype'] === 'single' || $qq['qtype'] === 'multi') {
                $av = $qq['qtype'] === 'multi' ? (json_decode((string)$a['value_text'], true) ?: []) : [$a['value_text']];
                $bv = $qq['qtype'] === 'multi' ? (json_decode((string)$b['value_text'], true) ?: []) : [$b['value_text']];
                $shared = array_values(array_filter(array_intersect($av, $bv), fn($x) => $x !== null && $x !== ''));
                if (!$shared) {
                    continue;
                }
                $item['shared'] = $shared;
            } else {
                continue; // free-text main questions are never revealed
            }
            foreach ([[$pA, $a], [$pB, $b]] as [$p, $ans]) {
                if (!empty($ans['comment'])) {
                    $item['comments'][] = ['who' => $p, 'text' => $ans['comment']];
                }
            }
            $items[] = $item;
        }
        if ($items) {
            usort($items, fn($x, $y) => [$y['mutual_heart'], $y['level']] <=> [$x['mutual_heart'], $x['level']]);
            $out[] = ['cat' => $g['cat'], 'items' => $items];
        }
    }
    return $out;
}

// --- Layout -------------------------------------------------------------------
function render_page(string $title, string $body, array $opts = []): void
{
    $site = cfg('site_name', 'Our Quiz');
    $msg = flash();
    $nav = $opts['nav'] ?? '';
    $js = !empty($opts['js']) ? '<script src="' . e(url('assets/app.js')) . '?v=3"></script>' : '';
    echo '<!doctype html><html lang="en"><head><meta charset="utf-8">'
        . '<meta name="viewport" content="width=device-width, initial-scale=1">'
        . '<meta name="robots" content="noindex, nofollow">'
        . '<meta name="referrer" content="no-referrer">'
        . '<title>' . e($title) . ' · ' . e($site) . '</title>'
        . '<link rel="stylesheet" href="' . e(url('assets/style.css')) . '?v=3">'
        . '</head><body class="' . e($opts['body_class'] ?? '') . '">'
        . '<header class="top"><a class="brand" href="' . e(url('')) . '">♥ ' . e($site) . '</a>' . $nav . '</header>'
        . '<main class="wrap">'
        . ($msg ? '<div class="flash">' . e($msg) . '</div>' : '')
        . $body
        . '</main>'
        . '<footer class="foot">Private &amp; anonymous. Keep your links secret.</footer>'
        . $js
        . '</body></html>';
}

function not_found(): void
{
    http_response_code(404);
    render_page('Not found', '<div class="card"><h1>Link not found</h1><p>This link is not valid. Check that you copied the whole thing.</p><p><a class="btn" href="' . e(url('')) . '">Home</a></p></div>');
    exit;
}

/**
 * Render one question as form HTML.
 * $partnerAns is set only in debug mode.
 */
function render_question(array $qq, ?array $ans, array $names, bool $debug = false, ?array $partnerAns = null): string
{
    $qid = (int)$qq['id'];
    $type = $qq['qtype'];
    $base = 'a[' . $qid . ']';
    $text = fill_names($qq['text'], $names);
    $help = $qq['help'] ? '<div class="help">' . e(fill_names($qq['help'], $names)) . '</div>' : '';
    $filled = answer_is_filled($qq, $ans);
    $h = '<div class="q q-' . e($type) . ($filled ? ' answered' : '') . '" data-qid="' . $qid . '" data-type="' . e($type) . '"'
        . ($qq['required'] ? ' data-required="1"' : '') . '>';
    $h .= '<div class="q-text">' . e($text) . ($qq['required'] ? '' : ' <span class="opt">(optional)</span>') . '</div>' . $help;

    if ($type === 'scale') {
        $cur = $ans['value_int'] ?? null;
        $pv = $partnerAns['value_int'] ?? null;
        $h .= '<div class="scale" role="radiogroup">';
        foreach (SCALE as $v => $lab) {
            $isPartner = $debug && $pv !== null && (int)$pv === $v;
            $h .= '<label class="sc sc' . $v . ($isPartner ? ' dbg' : '') . '" title="' . e($lab['long']) . '">'
                . '<input type="radio" name="' . $base . '[v]" value="' . $v . '"' . ($cur !== null && (int)$cur === $v ? ' checked' : '') . '>'
                . '<span><b>' . $v . '</b><small>' . e($lab['short']) . '</small></span></label>';
        }
        $h .= '</div>';
    } elseif ($type === 'single' || $type === 'multi') {
        $cur = $type === 'multi' ? (json_decode((string)($ans['value_text'] ?? ''), true) ?: []) : [($ans['value_text'] ?? null)];
        $pv = [];
        if ($debug && $partnerAns) {
            $pv = $type === 'multi' ? (json_decode((string)$partnerAns['value_text'], true) ?: []) : [$partnerAns['value_text']];
        }
        $h .= '<div class="opts">';
        foreach (question_options($qq) as $opt) {
            $isPartner = in_array($opt, $pv, true);
            $inputType = $type === 'multi' ? 'checkbox' : 'radio';
            $name = $type === 'multi' ? $base . '[v][]' : $base . '[v]';
            $h .= '<label class="opt-item' . ($isPartner ? ' dbg' : '') . '"><input type="' . $inputType . '" name="' . $name . '" value="' . e($opt) . '"'
                . (in_array($opt, $cur, true) ? ' checked' : '') . '> <span>' . e(fill_names($opt, $names)) . '</span></label>';
        }
        $h .= '</div>';
    } else {
        $cur = (string)($ans['value_text'] ?? '');
        $dbgText = ($debug && $partnerAns && $partnerAns['value_text'] !== null)
            ? '<div class="dbg-text" title="Partner\'s answer">' . e($partnerAns['value_text']) . '</div>' : '';
        $h .= '<div class="text-row">' . $dbgText;
        if ($type === 'textarea') {
            $h .= '<textarea name="' . $base . '[v]" rows="3" maxlength="5000">' . e($cur) . '</textarea>';
        } else {
            $h .= '<input type="text" name="' . $base . '[v]" value="' . e($cur) . '" maxlength="500">';
        }
        $h .= '</div>';
    }

    if ($qq['section'] === 'main') {
        $heart = !empty($ans['heart']);
        $pHeart = $debug && !empty($partnerAns['heart']);
        $comment = (string)($ans['comment'] ?? '');
        $placeholder = ($debug && !empty($partnerAns['comment'])) ? $partnerAns['comment'] : 'Private note (optional, shown on results if you both match)';
        $h .= '<div class="extras">'
            . '<label class="heart' . ($pHeart ? ' dbg' : '') . '" title="I am extremely interested"><input type="checkbox" name="' . $base . '[h]" value="1"' . ($heart ? ' checked' : '') . '><span>♥</span></label>'
            . '<button type="button" class="note-toggle' . ($comment !== '' || ($debug && !empty($partnerAns['comment'])) ? ' has' : '') . '">Add note</button>'
            . '</div>'
            . '<textarea class="note' . ($comment !== '' || ($debug && !empty($partnerAns['comment'])) ? ' open' : '') . '" name="' . $base . '[c]" rows="2" maxlength="2000" placeholder="' . e($placeholder) . '">' . e($comment) . '</textarea>';
    }
    $h .= '</div>';
    return $h;
}

function scale_legend(): string
{
    $h = '<div class="legend">';
    foreach (SCALE as $v => $lab) {
        $h .= '<div><b class="sc' . $v . '">' . $v . '</b> ' . e($lab['long']) . '</div>';
    }
    $h .= '<div><b class="lg-heart">♥</b> I am extremely interested in this</div></div>';
    return $h;
}

// --- Settings & pagination ----------------------------------------------------
function setting(string $name, $default = null)
{
    static $cache = null;
    if ($cache === null) {
        $cache = [];
        foreach (q('SELECT name, value FROM settings')->fetchAll() as $r) {
            $cache[$r['name']] = $r['value'];
        }
    }
    return $cache[$name] ?? $default;
}

/**
 * Split category groups into pages, never exceeding the admin-set
 * max questions per page or max categories per page. A category that is
 * larger than one page is split across pages ("continued").
 * @return array<int, array> list of pages; each page is a list of groups
 */
function paginate_groups(array $groups): array
{
    $maxQ = max(1, (int)setting('max_questions_per_page', 15));
    $maxC = max(1, (int)setting('max_categories_per_page', 2));
    $pages = [];
    $cur = [];
    $curQ = 0;
    foreach ($groups as $g) {
        $rem = $g['questions'];
        $part = 0;
        while ($rem) {
            $space = $maxQ - $curQ;
            if ($cur && (count($cur) >= $maxC || $space <= 0 || (count($rem) > $space && count($rem) <= $maxQ))) {
                $pages[] = $cur;
                $cur = [];
                $curQ = 0;
                $space = $maxQ;
            }
            $take = min($space, count($rem));
            $cur[] = ['cat' => $g['cat'], 'questions' => array_slice($rem, 0, $take), 'continued' => $part > 0];
            $rem = array_slice($rem, $take);
            $curQ += $take;
            $part++;
        }
    }
    if ($cur) {
        $pages[] = $cur;
    }
    return $pages;
}

function page_questions(array $page): array
{
    $out = [];
    foreach ($page as $g) {
        foreach ($g['questions'] as $qq) {
            $out[] = $qq;
        }
    }
    return $out;
}

function touch_participant(array $p): void
{
    q('UPDATE participants SET last_seen_at = NOW(), started_at = COALESCE(started_at, NOW()) WHERE id = ?', [$p['id']]);
}
