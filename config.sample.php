<?php
// Copy this file to config.php and fill in your details.
return [
    // MySQL database (create it in cPanel > MySQL Databases)
    'db_host'    => 'localhost',
    'db_name'    => 'cpaneluser_quiz',
    'db_user'    => 'cpaneluser_quiz',
    'db_pass'    => 'CHANGE_ME',

    // Admin password for /admin.
    // Either a plain password, or (better) a bcrypt hash made with
    //   php -r "echo password_hash('your-password', PASSWORD_DEFAULT);"
    // A value starting with $2y$ is treated as a hash.
    'admin_password' => 'CHANGE_ME_TO_A_LONG_PASSWORD',

    // Site title shown in the header
    'site_name' => 'Our Quiz',

    // Debug suffix: /join/{token}/Dbg1357 and /quiz/{token}/Dbg1357 show the
    // partner's answers highlighted. Set to false to switch it off in production.
    'debug_suffix_enabled' => true,
    'debug_suffix'         => 'Dbg1357',

    // Leave empty to auto-detect. Set to e.g. '/quiz' if auto-detection fails
    // when the app lives in a subfolder.
    'base_path' => '',
];
