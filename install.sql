-- Couples Quiz - database schema and starter questions
-- Import this file into your empty MySQL database (cPanel > phpMyAdmin > Import).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS answers;
DROP TABLE IF EXISTS participants;
DROP TABLE IF EXISTS quiz_sessions;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS settings;
DROP TABLE IF EXISTS admin_login_attempts;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE settings (
  name  VARCHAR(64) NOT NULL PRIMARY KEY,
  value VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  section     ENUM('intro','main') NOT NULL,
  name        VARCHAR(150) NOT NULL,
  description VARCHAR(500) NULL,
  sort_order  INT NOT NULL DEFAULT 0,
  KEY idx_section (section, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE questions (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  category_id INT UNSIGNED NOT NULL,
  section     ENUM('intro','main') NOT NULL,
  qtype       ENUM('scale','single','multi','text','textarea') NOT NULL DEFAULT 'scale',
  text        VARCHAR(1000) NOT NULL,
  help        VARCHAR(1000) NULL,
  options     TEXT NULL,
  required    TINYINT(1) NOT NULL DEFAULT 1,
  active      TINYINT(1) NOT NULL DEFAULT 1,
  sort_order  INT NOT NULL DEFAULT 0,
  KEY idx_cat (category_id, sort_order),
  CONSTRAINT fk_q_cat FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE quiz_sessions (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE participants (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  session_id    INT UNSIGNED NOT NULL,
  role          ENUM('A','B') NOT NULL,
  token         CHAR(64) NOT NULL,
  gender        ENUM('male','female') NOT NULL,
  self_name     VARCHAR(100) NULL,
  partner_name  VARCHAR(100) NULL,
  created_at    DATETIME NOT NULL,
  started_at    DATETIME NULL,
  intro_done_at DATETIME NULL,
  main_done_at  DATETIME NULL,
  last_seen_at  DATETIME NULL,
  UNIQUE KEY uq_token (token),
  UNIQUE KEY uq_session_role (session_id, role),
  CONSTRAINT fk_p_session FOREIGN KEY (session_id) REFERENCES quiz_sessions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE answers (
  participant_id INT UNSIGNED NOT NULL,
  question_id    INT UNSIGNED NOT NULL,
  value_int      TINYINT NULL,
  value_text     TEXT NULL,
  comment        TEXT NULL,
  heart          TINYINT(1) NOT NULL DEFAULT 0,
  updated_at     DATETIME NOT NULL,
  PRIMARY KEY (participant_id, question_id),
  KEY idx_q (question_id),
  CONSTRAINT fk_a_p FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE,
  CONSTRAINT fk_a_q FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE admin_login_attempts (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  ip           VARCHAR(64) NOT NULL,
  attempted_at DATETIME NOT NULL,
  KEY idx_ip (ip, attempted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO settings (name, value) VALUES
  ('max_questions_per_page', '15'),
  ('max_categories_per_page', '2');

-- Starter questions (edit everything from /admin)
INSERT INTO categories (id, section, name, description, sort_order) VALUES (1, 'intro', 'About you', 'A few private questions about you. Your partner never sees these answers.', 10);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (1, 'intro', 'single', 'How would you describe your sexual orientation?', NULL, 'Straight
Mostly straight
Bisexual
Mostly gay or lesbian
Prefer not to say', 1, 1, 10),
  (1, 'intro', 'single', 'How would you describe your sex drive?', NULL, 'Low
Medium
High
Very high', 1, 1, 20),
  (1, 'intro', 'single', 'How satisfied are you with your sex life with $partner right now?', NULL, 'Very unsatisfied
Somewhat unsatisfied
Neutral
Satisfied
Very satisfied', 1, 1, 30),
  (1, 'intro', 'single', 'Ideally, how often would you like to have sex?', NULL, 'Less than once a month
A few times a month
About once a week
A few times a week
Daily or more', 1, 1, 40);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (2, 'intro', 'What we do now', 'About your sex life together today.', 20);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (2, 'intro', 'single', 'How often do $malepartner and $femalepartner have sex at the moment?', NULL, 'Rarely or never
About once a month
A few times a month
About once a week
A few times a week
Daily or more', 1, 1, 10),
  (2, 'intro', 'multi', 'Which of these do $malepartner and $femalepartner currently do together?', 'Tick all that apply.', 'Kissing and making out
Massage
Oral sex
Intercourse
Using toys
Watching porn together
Sexting or sending photos
Light kink (spanking, blindfolds and so on)
Roleplay', 0, 1, 20);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (3, 'intro', 'What we used to do', 'Things from earlier in your relationship.', 30);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (3, 'intro', 'multi', 'Which of these have $malepartner and $femalepartner done in the past but rarely do now?', 'Tick all that apply.', 'Long make-out sessions
Sex in different rooms or places
Oral sex
Trying new positions
Sexy texting
Dressing up or lingerie
Spontaneous quickies
Weekends away', 0, 1, 10),
  (3, 'intro', 'textarea', 'Is there anything you miss from earlier in the relationship?', NULL, NULL, 0, 1, 20);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (4, 'intro', 'Wishes', 'What you would like more of.', 40);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (4, 'intro', 'textarea', 'Something I wish $partner and I did more often:', NULL, NULL, 0, 1, 10),
  (4, 'intro', 'textarea', 'Something I have wanted to try but never said out loud:', NULL, NULL, 0, 1, 20);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (5, 'intro', 'My history', 'Background about you. Private to you.', 50);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (5, 'intro', 'single', 'Roughly how many sexual partners did you have before $partner?', NULL, 'None
1 to 2
3 to 5
6 to 10
11 to 20
More than 20
Prefer not to say', 1, 1, 10),
  (5, 'intro', 'single', 'Have you explored kink or BDSM before this relationship?', NULL, 'No
A little
Quite a bit
Yes, a lot', 1, 1, 20),
  (5, 'intro', 'textarea', 'Anything from your past you would like to note?', NULL, NULL, 0, 1, 30);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (6, 'intro', 'Honesty and permission', 'Ground rules before the main quiz.', 60);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (6, 'intro', 'single', 'I promise to answer honestly, even if it feels awkward.', NULL, 'Yes, I promise
I will do my best', 1, 1, 10),
  (6, 'intro', 'single', 'When we see our matches, how would you like to talk about them?', NULL, 'Bring it up anytime
Let me bring it up first
Let us agree on a time to talk', 1, 1, 20),
  (6, 'intro', 'single', 'If we both say yes to something, I would rather...', NULL, 'Talk it through first
Let it happen when the moment feels right
Plan it together', 1, 1, 30),
  (6, 'intro', 'textarea', 'Any hard limits you want to state up front?', NULL, NULL, 0, 1, 40);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (7, 'main', 'Romance and connection', NULL, 10);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (7, 'main', 'scale', 'Long, slow make-out sessions', NULL, NULL, 1, 1, 10),
  (7, 'main', 'scale', '$malepartner giving $femalepartner a full-body massage', NULL, NULL, 1, 1, 20),
  (7, 'main', 'scale', '$femalepartner giving $malepartner a full-body massage', NULL, NULL, 1, 1, 30),
  (7, 'main', 'scale', 'Showering or bathing together', NULL, NULL, 1, 1, 40),
  (7, 'main', 'scale', 'Planning a sexy date night or weekend away', NULL, NULL, 1, 1, 50),
  (7, 'main', 'scale', 'Sleeping naked together', NULL, NULL, 1, 1, 60),
  (7, 'main', 'scale', 'Sending flirty or sexy texts during the day', NULL, NULL, 1, 1, 70),
  (7, 'main', 'multi', 'Best times of day for sex', 'Pick any. Results show the times you both picked.', 'Mornings
Afternoons
Evenings
Late at night', 0, 1, 80);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (8, 'main', 'Oral and touch', NULL, 20);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (8, 'main', 'scale', '$malepartner going down on $femalepartner', NULL, NULL, 1, 1, 10),
  (8, 'main', 'scale', '$femalepartner going down on $malepartner', NULL, NULL, 1, 1, 20),
  (8, 'main', 'scale', '69', NULL, NULL, 1, 1, 30),
  (8, 'main', 'scale', '$femalepartner swallowing', NULL, NULL, 1, 1, 40),
  (8, 'main', 'scale', 'Mutual masturbation in front of each other', NULL, NULL, 1, 1, 50),
  (8, 'main', 'scale', '$femalepartner touching herself while $malepartner watches', NULL, NULL, 1, 1, 60),
  (8, 'main', 'scale', '$malepartner touching himself while $femalepartner watches', NULL, NULL, 1, 1, 70);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (9, 'main', 'Positions and places', NULL, 30);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (9, 'main', 'scale', 'Trying new positions', NULL, NULL, 1, 1, 10),
  (9, 'main', 'scale', '$femalepartner on top', NULL, NULL, 1, 1, 20),
  (9, 'main', 'scale', 'From behind', NULL, NULL, 1, 1, 30),
  (9, 'main', 'scale', 'Sex in a room other than the bedroom', NULL, NULL, 1, 1, 40),
  (9, 'main', 'scale', 'Sex outdoors somewhere private', NULL, NULL, 1, 1, 50),
  (9, 'main', 'scale', 'Morning sex', NULL, NULL, 1, 1, 60),
  (9, 'main', 'scale', 'Quickies', NULL, NULL, 1, 1, 70),
  (9, 'main', 'scale', 'A hotel getaway just for sex', NULL, NULL, 1, 1, 80);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (10, 'main', 'Toys', NULL, 40);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (10, 'main', 'scale', 'Using a vibrator together', NULL, NULL, 1, 1, 10),
  (10, 'main', 'scale', '$femalepartner using a vibrator during sex', NULL, NULL, 1, 1, 20),
  (10, 'main', 'scale', 'A cock ring for $malepartner', NULL, NULL, 1, 1, 30),
  (10, 'main', 'scale', 'A remote-control toy worn by $femalepartner when out together', NULL, NULL, 1, 1, 40),
  (10, 'main', 'scale', 'Toys for $malepartner (sleeve, prostate massager)', NULL, NULL, 1, 1, 50),
  (10, 'main', 'scale', 'Shopping for toys together', NULL, NULL, 1, 1, 60);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (11, 'main', 'Anal play', NULL, 50);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (11, 'main', 'scale', '$malepartner touching or licking $femalepartner''s bottom', NULL, NULL, 1, 1, 10),
  (11, 'main', 'scale', 'Anal sex ($malepartner with $femalepartner)', NULL, NULL, 1, 1, 20),
  (11, 'main', 'scale', 'A butt plug for $femalepartner', NULL, NULL, 1, 1, 30),
  (11, 'main', 'scale', '$femalepartner playing with $malepartner''s bottom (fingers or toy)', NULL, NULL, 1, 1, 40),
  (11, 'main', 'scale', 'Pegging ($femalepartner using a strap-on with $malepartner)', NULL, NULL, 1, 1, 50);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (12, 'main', 'Talk, photos and media', NULL, 60);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (12, 'main', 'scale', 'Dirty talk during sex', NULL, NULL, 1, 1, 10),
  (12, 'main', 'scale', 'Watching porn together', NULL, NULL, 1, 1, 20),
  (12, 'main', 'scale', 'Reading erotica together', NULL, NULL, 1, 1, 30),
  (12, 'main', 'scale', 'Taking sexy photos for each other', NULL, NULL, 1, 1, 40),
  (12, 'main', 'scale', 'Filming ourselves (kept private)', NULL, NULL, 1, 1, 50),
  (12, 'main', 'scale', 'Phone or video sex when apart', NULL, NULL, 1, 1, 60);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (13, 'main', 'Fantasy and roleplay', NULL, 70);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (13, 'main', 'scale', 'Sharing fantasies with each other', NULL, NULL, 1, 1, 10),
  (13, 'main', 'scale', 'Roleplaying strangers meeting in a bar', NULL, NULL, 1, 1, 20),
  (13, 'main', 'scale', 'Costumes or uniforms', NULL, NULL, 1, 1, 30),
  (13, 'main', 'scale', '$femalepartner wearing lingerie', NULL, NULL, 1, 1, 40),
  (13, 'main', 'scale', 'Teacher and student or boss and assistant roleplay', NULL, NULL, 1, 1, 50);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (14, 'main', 'Bondage and sensation', NULL, 80);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (14, 'main', 'scale', 'Blindfolds', NULL, NULL, 1, 1, 10),
  (14, 'main', 'scale', '$malepartner tying up $femalepartner', NULL, NULL, 1, 1, 20),
  (14, 'main', 'scale', '$femalepartner tying up $malepartner', NULL, NULL, 1, 1, 30),
  (14, 'main', 'scale', 'Ice, wax or feathers', NULL, NULL, 1, 1, 40),
  (14, 'main', 'scale', 'Handcuffs or restraints', NULL, NULL, 1, 1, 50);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (15, 'main', 'Power and control', NULL, 90);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (15, 'main', 'scale', '$malepartner taking charge in bed', NULL, NULL, 1, 1, 10),
  (15, 'main', 'scale', '$femalepartner taking charge in bed', NULL, NULL, 1, 1, 20),
  (15, 'main', 'scale', 'Hair pulling', NULL, NULL, 1, 1, 30),
  (15, 'main', 'scale', 'A hand on the throat (light pressure)', NULL, NULL, 1, 1, 40),
  (15, 'main', 'scale', '$malepartner controlling when $femalepartner is allowed to orgasm', NULL, NULL, 1, 1, 50),
  (15, 'main', 'scale', '$femalepartner controlling when $malepartner is allowed to orgasm', NULL, NULL, 1, 1, 60);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (16, 'main', 'Impact play', NULL, 100);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (16, 'main', 'scale', '$malepartner spanking $femalepartner', NULL, NULL, 1, 1, 10),
  (16, 'main', 'scale', '$femalepartner spanking $malepartner', NULL, NULL, 1, 1, 20),
  (16, 'main', 'scale', 'Paddles, floggers or crops', NULL, NULL, 1, 1, 30),
  (16, 'main', 'scale', 'Biting and scratching', NULL, NULL, 1, 1, 40);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (17, 'main', 'Adventure and others', NULL, 110);
INSERT INTO questions (category_id, section, qtype, text, help, options, required, active, sort_order) VALUES
  (17, 'main', 'scale', 'Sex where there is a small risk of being caught', NULL, NULL, 1, 1, 10),
  (17, 'main', 'scale', '$femalepartner dressing sexy in public for $malepartner', NULL, NULL, 1, 1, 20),
  (17, 'main', 'scale', 'Going to a strip club together', NULL, NULL, 1, 1, 30),
  (17, 'main', 'scale', 'Watching another couple (no touching)', NULL, NULL, 1, 1, 40),
  (17, 'main', 'scale', 'Being watched by others', NULL, NULL, 1, 1, 50),
  (17, 'main', 'scale', 'A threesome with another woman', NULL, NULL, 1, 1, 60),
  (17, 'main', 'scale', 'A threesome with another man', NULL, NULL, 1, 1, 70),
  (17, 'main', 'scale', 'Swapping partners with another couple', NULL, NULL, 1, 1, 80);
