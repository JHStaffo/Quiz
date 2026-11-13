<?php
$body = '<section class="hero card">
  <h1>Discover what you both want</h1>
  <p>A private quiz for couples. Each of you answers on your own. At the end you only see the things you <b>both</b> said yes to. Anything one of you is not into stays hidden forever.</p>
  <ul class="ticks">
    <li>No accounts, no emails, no passwords</li>
    <li>Your private link is your key, so keep it safe</li>
    <li>Answers are only revealed where you match</li>
  </ul>
  <a class="btn big" href="' . e(url('start')) . '">Start a new quiz</a>
</section>
<section class="card">
  <h2>I have a link</h2>
  <p>Paste the link (or code) you received from your partner, or your own private link to continue.</p>
  <form method="post" action="' . e(url('go')) . '" class="row">' . csrf_field() . '
    <input type="text" name="link" placeholder="https://.../join/..." required autocomplete="off">
    <button class="btn" type="submit">Open</button>
  </form>
</section>';
render_page('Welcome', $body);
