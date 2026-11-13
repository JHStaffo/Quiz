<?php
declare(strict_types=1);

require __DIR__ . '/src/bootstrap.php';

// Work out the path relative to the install folder
$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$bp = base_path();
if ($bp !== '' && strpos($uri, $bp) === 0) {
    $uri = substr($uri, strlen($bp));
}
$uri = '/' . trim(rawurldecode($uri), '/');
if ($uri === '/index.php') {
    $uri = '/';
}
$parts = $uri === '/' ? [] : explode('/', trim($uri, '/'));
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Debug suffix: /join/{token}/Dbg1357 and /quiz/{token}/Dbg1357
$DEBUG = false;
if (count($parts) === 3 && in_array($parts[0], ['join', 'quiz'], true)
    && cfg('debug_suffix_enabled', true) && $parts[2] === cfg('debug_suffix', 'Dbg1357')) {
    $DEBUG = true;
    array_pop($parts);
}

// The suffix is often typed after a page number, e.g. /quiz/{token}?p=2/Dbg1357.
// Move it into the path so the page opens in debug view.
$qs = (string)($_SERVER['QUERY_STRING'] ?? '');
$sfx = '/' . cfg('debug_suffix', 'Dbg1357');
if (!$DEBUG && $method === 'GET' && count($parts) === 2 && in_array($parts[0], ['join', 'quiz'], true)
    && cfg('debug_suffix_enabled', true) && $qs !== ''
    && substr(rawurldecode($qs), -strlen($sfx)) === $sfx) {
    $page = (int)($_GET['p'] ?? 0);
    redirect($parts[0] . '/' . $parts[1] . $sfx . ($page > 0 ? '?p=' . $page : ''));
}

$route = $parts[0] ?? '';

switch ($route) {
    case '':
        require __DIR__ . '/src/pages/home.php';
        break;
    case 'go':
        require __DIR__ . '/src/pages/go.php';
        break;
    case 'start':
        require __DIR__ . '/src/pages/start.php';
        break;
    case 'join':
    case 'quiz':
    case 'share':
    case 'results':
        if (count($parts) !== 2) {
            not_found();
        }
        $found = find_by_token($parts[1]);
        if (!$found) {
            not_found();
        }
        [$me, $partner, $session] = $found;
        $TOKEN = $parts[1];
        require __DIR__ . '/src/pages/' . $route . '.php';
        break;
    case 'admin':
        require __DIR__ . '/src/admin/admin.php';
        break;
    default:
        not_found();
}
