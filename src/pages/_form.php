<?php
/**
 * Shared helpers for the paged questionnaire (intro on /join, main on /quiz).
 */

function save_page(array $me, array $pageQuestions): array
{
    $missing = [];
    $posted = $_POST['a'] ?? [];
    foreach ($pageQuestions as $qq) {
        $data = $posted[$qq['id']] ?? [];
        save_answer((int)$me['id'], $qq, is_array($data) ? $data : []);
    }
    $ans = load_answers((int)$me['id']);
    foreach ($pageQuestions as $qq) {
        if ($qq['required'] && !answer_is_filled($qq, $ans[(int)$qq['id']] ?? null)) {
            $missing[] = (int)$qq['id'];
        }
    }
    touch_participant($me);
    return $missing;
}

function render_steps(int $current, int $total, string $baseUrl, int $first = 1): string
{
    if ($total <= 1) {
        return '';
    }
    $h = '<div class="steps"><div class="bar"><span style="width:' . round(($current - $first + 1) / ($total - $first + 1) * 100) . '%"></span></div>'
        . '<div class="steps-text">Page ' . ($current - $first + 1) . ' of ' . ($total - $first + 1) . '</div></div>';
    return $h;
}

function render_page_groups(array $page, array $answers, array $names, bool $debug, array $partnerAnswers, array $missing = []): string
{
    $h = '';
    foreach ($page as $g) {
        $h .= '<section class="cat"><h2>' . e(fill_names($g['cat']['name'], $names)) . ($g['continued'] ? ' <span class="cont">(continued)</span>' : '') . '</h2>';
        if (!$g['continued'] && !empty($g['cat']['description'])) {
            $h .= '<p class="cat-desc">' . e(fill_names($g['cat']['description'], $names)) . '</p>';
        }
        foreach ($g['questions'] as $qq) {
            $qid = (int)$qq['id'];
            $html = render_question($qq, $answers[$qid] ?? null, $names, $debug, $partnerAnswers[$qid] ?? null);
            if (in_array($qid, $missing, true)) {
                $html = preg_replace('/^<div class="q /', '<div class="q missing ', $html, 1);
            }
            $h .= $html;
        }
        $h .= '</section>';
    }
    return $h;
}
