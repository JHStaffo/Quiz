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
  qtype       ENUM('scale','single','multi','text','textarea','number') NOT NULL DEFAULT 'scale',
  text        VARCHAR(1000) NOT NULL,
  text_female VARCHAR(1000) NULL,
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

-- Intro (private) questions from the Private Info tab
INSERT INTO categories (id, section, name, description, sort_order) VALUES (1, 'intro', 'Currently we engage in', 'Activities you and $partner do now. Never shown to $partner.', 10);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (1, 'intro', 'multi', 'Which of these do you and $partner currently engage in?', NULL, 'Tick all that apply.', 'Oral
Vaginal
Anal
69
Threesomes
Group sex
Make porn for ourselves
Make porn for others
Swinging
Being watched / exhibitionism
Roleplay
Toys during sex
BDSM / light bondage
Pegging
Same-sex play (with others)
Cuckolding / hotwife style', 0, 1, 10);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (2, 'intro', 'With past partners, and I wish we did', 'Things you did with past partners that you and $partner don''t do now, but you wish you did. Never shown to $partner.', 20);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (2, 'intro', 'single', 'Oral', NULL, NULL, 'Yes
No
Maybe', 1, 1, 10),
  (2, 'intro', 'single', 'Vaginal', NULL, NULL, 'Yes
No
Maybe', 1, 1, 20),
  (2, 'intro', 'single', 'Anal', NULL, NULL, 'Yes
No
Maybe', 1, 1, 30),
  (2, 'intro', 'single', '69', NULL, NULL, 'Yes
No
Maybe', 1, 1, 40),
  (2, 'intro', 'single', 'Threesomes', NULL, NULL, 'Yes
No
Maybe', 1, 1, 50),
  (2, 'intro', 'single', 'Group sex', NULL, NULL, 'Yes
No
Maybe', 1, 1, 60),
  (2, 'intro', 'single', 'Make porn for ourselves', NULL, NULL, 'Yes
No
Maybe', 1, 1, 70),
  (2, 'intro', 'single', 'Make porn for others', NULL, NULL, 'Yes
No
Maybe', 1, 1, 80),
  (2, 'intro', 'single', 'Swinging', NULL, NULL, 'Yes
No
Maybe', 1, 1, 90),
  (2, 'intro', 'single', 'Being watched / exhibitionism', NULL, NULL, 'Yes
No
Maybe', 1, 1, 100),
  (2, 'intro', 'single', 'Roleplay', NULL, NULL, 'Yes
No
Maybe', 1, 1, 110),
  (2, 'intro', 'single', 'Toys during sex', NULL, NULL, 'Yes
No
Maybe', 1, 1, 120),
  (2, 'intro', 'single', 'BDSM / light bondage', NULL, NULL, 'Yes
No
Maybe', 1, 1, 130),
  (2, 'intro', 'single', 'Pegging', NULL, NULL, 'Yes
No
Maybe', 1, 1, 140),
  (2, 'intro', 'single', 'Same-sex play (with others)', NULL, NULL, 'Yes
No
Maybe', 1, 1, 150),
  (2, 'intro', 'single', 'Cuckolding / hotwife style', NULL, NULL, 'Yes
No
Maybe', 1, 1, 160);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (3, 'intro', 'In the past we have tried', 'Things you and $partner have tried together at some point. Never shown to $partner.', 30);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (3, 'intro', 'multi', 'Which of these have you and $partner tried at some point?', NULL, 'Tick all that apply.', 'Oral
Vaginal
Anal
69
Threesomes
Group sex
Make porn for ourselves
Make porn for others
Swinging
Being watched / exhibitionism
Roleplay
Toys during sex
BDSM / light bondage
Pegging
Same-sex play (with others)
Cuckolding / hotwife style', 0, 1, 10);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (4, 'intro', 'Individual history, permission and honesty', 'Private. $partner never sees these answers.', 40);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (4, 'intro', 'number', 'How many consensual male sexual partners have you had?', NULL, 'Lifetime count of male partners', NULL, 1, 1, 10),
  (4, 'intro', 'number', 'How many consensual female sexual partners have you had?', NULL, 'Lifetime count of female partners', NULL, 1, 1, 20),
  (4, 'intro', 'single', 'Have you had oral sex with past partners/hookups?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 30),
  (4, 'intro', 'single', 'Have you had vaginal sex with past partners/hookups?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 40),
  (4, 'intro', 'single', 'Have you done anal with past partners/hookups?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 50),
  (4, 'intro', 'single', 'Have you ever cheated (sexual contact) on a past partner?', NULL, 'Any past relationship', 'Yes
No
Prefer not to say', 1, 1, 60),
  (4, 'intro', 'single', 'Have you ever cheated (sexual contact) on your current partner?', NULL, 'With the person taking this quiz with you', 'Yes
No
Prefer not to say', 1, 1, 70),
  (4, 'intro', 'single', 'Has your current partner ever allowed you to have sex with someone else and you didn''t?', NULL, 'Permission was given but you chose not to', 'Yes
No
Prefer not to say', 1, 1, 80),
  (4, 'intro', 'single', 'Has your current partner ever allowed you to have sex with someone else and you did?', NULL, 'Permission was given and you acted on it', 'Yes
No
Prefer not to say', 1, 1, 90),
  (4, 'intro', 'single', 'Has your partner ever allowed you to have sex with someone else, you said you didn''t, but you actually did?', NULL, 'You lied about following through', 'Yes
No
Prefer not to say', 1, 1, 100),
  (4, 'intro', 'single', 'Has your current partner ever allowed you to receive oral from someone else and you didn''t?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 110),
  (4, 'intro', 'single', 'Has your current partner ever allowed you to receive oral from someone else and you did?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 120),
  (4, 'intro', 'single', 'Has your partner allowed you to do something sexual with others, you said no, but you did it anyway?', NULL, 'Any sexual contact beyond kissing', 'Yes
No
Prefer not to say', 1, 1, 130),
  (4, 'intro', 'single', 'Have you ever given your partner permission to have sex with someone else and they didn''t?', NULL, 'You offered, they declined', 'Yes
No
Prefer not to say', 1, 1, 140),
  (4, 'intro', 'single', 'Have you ever given your partner permission to have sex with someone else and they did?', NULL, 'You offered and they accepted', 'Yes
No
Prefer not to say', 1, 1, 150),
  (4, 'intro', 'single', 'Have you ever told your partner you were okay with them sleeping with someone else, but you weren''t actually okay with it?', NULL, 'You gave permission you didn''t fully mean', 'Yes
No
Prefer not to say', 1, 1, 160),
  (4, 'intro', 'single', 'Have you ever been offered permission by your partner to play with others but you were too nervous/scared to take it?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 170),
  (4, 'intro', 'single', 'Have you ever taken permission from your partner to play with others and then felt guilty afterward?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 180),
  (4, 'intro', 'single', 'Have you ever been in a situation where your partner said ''you can if you want'' regarding someone else, and you did?', NULL, 'Casual or non-explicit permission', 'Yes
No
Prefer not to say', 1, 1, 190),
  (4, 'intro', 'single', 'Have you ever been in a situation where your partner said ''you can if you want'' regarding someone else, and you didn''t?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 200),
  (4, 'intro', 'single', 'Have you ever lied to your current partner about sexual contact with someone else (even if it was ''allowed'')?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 210),
  (4, 'intro', 'single', 'Would you want your current partner to give you explicit permission to have sex with someone else?', NULL, 'Future desire', 'Yes
No
Maybe
Prefer not to say', 1, 1, 220),
  (4, 'intro', 'single', 'Would you be willing to give your current partner explicit permission to have sex with someone else?', NULL, 'Future willingness', 'Yes
No
Maybe
Prefer not to say', 1, 1, 230),
  (4, 'intro', 'single', 'Have you ever fantasized about your partner giving you permission to sleep with someone specific?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 240),
  (4, 'intro', 'single', 'Have you ever been jealous after giving your partner permission to play with someone else?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 250),
  (4, 'intro', 'single', 'Has your partner ever given you permission to do something sexual with others that you later regretted doing?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 260);

-- Main questionnaire (from the Quiz Questions tab)
INSERT INTO categories (id, section, name, description, sort_order) VALUES (7, 'main', 'Vanilla / Basics', NULL, 10);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (7, 'main', 'scale', 'Have longer, slower foreplay sessions with $femalepartner', 'Have longer, slower foreplay sessions with $malepartner', NULL, NULL, 1, 1, 1),
  (7, 'main', 'scale', 'Receive a full-body sensual massage from $femalepartner', 'Give $malepartner a full-body sensual massage', NULL, NULL, 1, 1, 2),
  (7, 'main', 'scale', 'Give $femalepartner a full-body sensual massage', 'Receive a full-body sensual massage from $malepartner', NULL, NULL, 1, 1, 3),
  (7, 'main', 'scale', 'Be completely undressed by $femalepartner', 'Completely undress $malepartner', NULL, NULL, 1, 1, 4),
  (7, 'main', 'scale', 'Completely undress $femalepartner', 'Be completely undressed by $malepartner', NULL, NULL, 1, 1, 5),
  (7, 'main', 'scale', 'Have sex in the missionary position with $femalepartner', 'Have sex in the missionary position with $malepartner', NULL, NULL, 1, 1, 6),
  (7, 'main', 'scale', 'Have $femalepartner on top during sex', 'Be on top during sex with $malepartner', NULL, NULL, 1, 1, 7),
  (7, 'main', 'scale', 'Be on top during sex with $femalepartner', 'Have $malepartner on top during sex', NULL, NULL, 1, 1, 8),
  (7, 'main', 'scale', 'Have sex in doggy style with $femalepartner', 'Have sex in doggy style with $malepartner', NULL, NULL, 1, 1, 9),
  (7, 'main', 'scale', 'Have sex in reverse cowgirl with $femalepartner', 'Have sex in reverse cowgirl with $malepartner', NULL, NULL, 1, 1, 10),
  (7, 'main', 'scale', 'Have sex with $femalepartner''s legs over your shoulders', 'Have sex with your legs over $malepartner''s shoulders', NULL, NULL, 1, 1, 11),
  (7, 'main', 'scale', 'Keep most of your clothes on while having sex with $femalepartner', 'Keep most of your clothes on while having sex with $malepartner', NULL, NULL, 1, 1, 12),
  (7, 'main', 'scale', 'Have phone or video sex with $femalepartner', 'Have phone or video sex with $malepartner', NULL, NULL, 1, 1, 13),
  (7, 'main', 'scale', 'Cuddle and make out for a long time before sex with $femalepartner', 'Cuddle and make out for a long time before sex with $malepartner', NULL, NULL, 1, 1, 14),
  (7, 'main', 'scale', 'Have $femalepartner go down on you slowly and teasingly', 'Go down on $malepartner slowly and teasingly', NULL, NULL, 1, 1, 15),
  (7, 'main', 'scale', 'Go down on $femalepartner slowly and teasingly', 'Have $malepartner go down on you slowly and teasingly', NULL, NULL, 1, 1, 16),
  (7, 'main', 'scale', 'Use lots of dirty talk during sex with $femalepartner', 'Use lots of dirty talk during sex with $malepartner', NULL, NULL, 1, 1, 17),
  (7, 'main', 'scale', 'Have $femalepartner whisper dirty things in your ear', 'Whisper dirty things in $malepartner''s ear', NULL, NULL, 1, 1, 18),
  (7, 'main', 'scale', 'Take sexy photos of $femalepartner', 'Have sexy photos taken of you by $malepartner', NULL, NULL, 1, 1, 19),
  (7, 'main', 'scale', 'Have sexy photos taken of you by $femalepartner', 'Take sexy photos of $malepartner', NULL, NULL, 1, 1, 20),
  (7, 'main', 'scale', 'Have sex in the shower or bath with $femalepartner', 'Have sex in the shower or bath with $malepartner', NULL, NULL, 1, 1, 21),
  (7, 'main', 'scale', 'Have morning sex with $femalepartner', 'Have morning sex with $malepartner', NULL, NULL, 1, 1, 22),
  (7, 'main', 'scale', 'Have quickie sex with $femalepartner', 'Have quickie sex with $malepartner', NULL, NULL, 1, 1, 23),
  (7, 'main', 'scale', 'Edge each other for a long time before finishing with $femalepartner', 'Edge each other for a long time before finishing with $malepartner', NULL, NULL, 1, 1, 24),
  (7, 'main', 'scale', 'Have $femalepartner finish inside you', 'Finish inside $malepartner', NULL, NULL, 1, 1, 25),
  (7, 'main', 'scale', 'Finish inside $femalepartner', 'Have $malepartner finish inside you', NULL, NULL, 1, 1, 26),
  (7, 'main', 'scale', 'Have $femalepartner finish on your body', 'Finish on $malepartner''s body', NULL, NULL, 1, 1, 27),
  (7, 'main', 'scale', 'Finish on $femalepartner''s body', 'Have $malepartner finish on your body', NULL, NULL, 1, 1, 28),
  (7, 'main', 'scale', 'Have sex while $femalepartner is still wearing underwear', 'Have sex while still wearing underwear with $malepartner', NULL, NULL, 1, 1, 29),
  (7, 'main', 'scale', 'Have sex on the couch or living room floor with $femalepartner', 'Have sex on the couch or living room floor with $malepartner', NULL, NULL, 1, 1, 30),
  (7, 'main', 'scale', 'Have $femalepartner use their hands only to get you off', 'Use your hands only to get $malepartner off', NULL, NULL, 1, 1, 31),
  (7, 'main', 'scale', 'Use your hands only to get $femalepartner off', 'Have $malepartner use their hands only to get you off', NULL, NULL, 1, 1, 32),
  (7, 'main', 'scale', 'Have simultaneous orgasms with $femalepartner', 'Have simultaneous orgasms with $malepartner', NULL, NULL, 1, 1, 33),
  (7, 'main', 'scale', 'Have $femalepartner ride you slowly', 'Ride $malepartner slowly', NULL, NULL, 1, 1, 34),
  (7, 'main', 'scale', 'Ride $femalepartner slowly', 'Have $malepartner ride you slowly', NULL, NULL, 1, 1, 35),
  (7, 'main', 'scale', 'Have sex with the lights on with $femalepartner', 'Have sex with the lights on with $malepartner', NULL, NULL, 1, 1, 36),
  (7, 'main', 'scale', 'Have sex with the lights off with $femalepartner', 'Have sex with the lights off with $malepartner', NULL, NULL, 1, 1, 37),
  (7, 'main', 'scale', 'Have $femalepartner hold you down gently during sex', 'Hold $malepartner down gently during sex', NULL, NULL, 1, 1, 38),
  (7, 'main', 'scale', 'Hold $femalepartner down gently during sex', 'Have $malepartner hold you down gently during sex', NULL, NULL, 1, 1, 39),
  (7, 'main', 'scale', 'Have a long session of mutual masturbation with $femalepartner', 'Have a long session of mutual masturbation with $malepartner', NULL, NULL, 1, 1, 40),
  (7, 'main', 'scale', 'Have $femalepartner watch you masturbate', 'Watch $malepartner masturbate', NULL, NULL, 1, 1, 41),
  (7, 'main', 'scale', 'Watch $femalepartner masturbate', 'Have $malepartner watch you masturbate', NULL, NULL, 1, 1, 42),
  (7, 'main', 'scale', 'Have sex in multiple positions in one session with $femalepartner', 'Have sex in multiple positions in one session with $malepartner', NULL, NULL, 1, 1, 43),
  (7, 'main', 'scale', 'Have $femalepartner give you a handjob while you kiss', 'Give $malepartner a handjob while you kiss', NULL, NULL, 1, 1, 44),
  (7, 'main', 'scale', 'Give $femalepartner a handjob while you kiss', 'Have $malepartner give you a handjob while you kiss', NULL, NULL, 1, 1, 45);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (8, 'main', 'Oral', NULL, 20);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (8, 'main', 'scale', 'Have $femalepartner perform oral sex on you', 'Perform oral sex on $malepartner', NULL, NULL, 1, 1, 46),
  (8, 'main', 'scale', 'Perform oral sex on $femalepartner', 'Have $malepartner perform oral sex on you', NULL, NULL, 1, 1, 47),
  (8, 'main', 'scale', 'Have $femalepartner deepthroat you', 'Deepthroat $malepartner', NULL, NULL, 1, 1, 48),
  (8, 'main', 'scale', 'Deepthroat $femalepartner', 'Have $malepartner deepthroat you', NULL, NULL, 1, 1, 49),
  (8, 'main', 'scale', 'Have $femalepartner give you a slow, teasing blowjob', 'Give $malepartner a slow, teasing blowjob', NULL, NULL, 1, 1, 50),
  (8, 'main', 'scale', 'Give $femalepartner a slow, teasing cunnilingus', 'Have $malepartner give you a slow, teasing cunnilingus', NULL, NULL, 1, 1, 51),
  (8, 'main', 'scale', 'Have $femalepartner finish in your mouth', 'Finish in $malepartner''s mouth', NULL, NULL, 1, 1, 52),
  (8, 'main', 'scale', 'Finish in $femalepartner''s mouth', 'Have $malepartner finish in your mouth', NULL, NULL, 1, 1, 53),
  (8, 'main', 'scale', 'Have $femalepartner swallow', 'Swallow $malepartner''s finish', NULL, NULL, 1, 1, 54),
  (8, 'main', 'scale', 'Swallow $femalepartner''s finish', 'Have $malepartner swallow', NULL, NULL, 1, 1, 55),
  (8, 'main', 'scale', 'Have $femalepartner perform oral on you while you''re standing', 'Perform oral on $malepartner while they are standing', NULL, NULL, 1, 1, 56),
  (8, 'main', 'scale', 'Perform oral on $femalepartner while they are standing', 'Have $malepartner perform oral on you while you''re standing', NULL, NULL, 1, 1, 57),
  (8, 'main', 'scale', 'Have 69 with $femalepartner', 'Have 69 with $malepartner', NULL, NULL, 1, 1, 58),
  (8, 'main', 'scale', 'Have $femalepartner edge you with their mouth', 'Edge $malepartner with your mouth', NULL, NULL, 1, 1, 59),
  (8, 'main', 'scale', 'Edge $femalepartner with your mouth', 'Have $malepartner edge you with their mouth', NULL, NULL, 1, 1, 60),
  (8, 'main', 'scale', 'Have $femalepartner lick you all over before oral', 'Lick $malepartner all over before oral', NULL, NULL, 1, 1, 61),
  (8, 'main', 'scale', 'Lick $femalepartner all over before oral', 'Have $malepartner lick you all over before oral', NULL, NULL, 1, 1, 62),
  (8, 'main', 'scale', 'Have $femalepartner use their tongue only for a long time', 'Use your tongue only for a long time on $malepartner', NULL, NULL, 1, 1, 63),
  (8, 'main', 'scale', 'Use your tongue only for a long time on $femalepartner', 'Have $malepartner use their tongue only for a long time', NULL, NULL, 1, 1, 64),
  (8, 'main', 'scale', 'Have $femalepartner give you oral while you watch porn together', 'Give $malepartner oral while watching porn together', NULL, NULL, 1, 1, 65),
  (8, 'main', 'scale', 'Give $femalepartner oral while watching porn together', 'Have $malepartner give you oral while you watch porn together', NULL, NULL, 1, 1, 66),
  (8, 'main', 'scale', 'Have $femalepartner perform oral under the covers', 'Perform oral on $malepartner under the covers', NULL, NULL, 1, 1, 67),
  (8, 'main', 'scale', 'Perform oral on $femalepartner under the covers', 'Have $malepartner perform oral on you under the covers', NULL, NULL, 1, 1, 68),
  (8, 'main', 'scale', 'Have $femalepartner keep going after you finish', 'Keep going after $malepartner finishes', NULL, NULL, 1, 1, 69),
  (8, 'main', 'scale', 'Keep going after $femalepartner finishes', 'Have $malepartner keep going after you finish', NULL, NULL, 1, 1, 70),
  (8, 'main', 'scale', 'Have $femalepartner give you oral while tied up', 'Give $malepartner oral while they are tied up', NULL, NULL, 1, 1, 71),
  (8, 'main', 'scale', 'Give $femalepartner oral while they are tied up', 'Have $malepartner give you oral while tied up', NULL, NULL, 1, 1, 72),
  (8, 'main', 'scale', 'Have $femalepartner spit on you during oral', 'Spit on $malepartner during oral', NULL, NULL, 1, 1, 73),
  (8, 'main', 'scale', 'Spit on $femalepartner during oral', 'Have $malepartner spit on you during oral', NULL, NULL, 1, 1, 74),
  (8, 'main', 'scale', 'Have $femalepartner use ice or cold sensations during oral', 'Use ice or cold sensations during oral on $malepartner', NULL, NULL, 1, 1, 75),
  (8, 'main', 'scale', 'Use ice or cold sensations during oral on $femalepartner', 'Have $malepartner use ice or cold sensations during oral', NULL, NULL, 1, 1, 76),
  (8, 'main', 'scale', 'Have $femalepartner perform oral while you''re blindfolded', 'Perform oral on $malepartner while they are blindfolded', NULL, NULL, 1, 1, 77),
  (8, 'main', 'scale', 'Perform oral on $femalepartner while they are blindfolded', 'Have $malepartner perform oral on you while you''re blindfolded', NULL, NULL, 1, 1, 78),
  (8, 'main', 'scale', 'Have $femalepartner give you a facial after oral', 'Give $malepartner a facial after oral', NULL, NULL, 1, 1, 79),
  (8, 'main', 'scale', 'Give $femalepartner a facial after oral', 'Have $malepartner give you a facial after oral', NULL, NULL, 1, 1, 80);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (9, 'main', 'Toys', NULL, 30);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (9, 'main', 'scale', 'Have $femalepartner use a vibrator on you', 'Use a vibrator on $malepartner', NULL, NULL, 1, 1, 81),
  (9, 'main', 'scale', 'Use a vibrator on $femalepartner', 'Have $malepartner use a vibrator on you', NULL, NULL, 1, 1, 82),
  (9, 'main', 'scale', 'Have $femalepartner use a dildo on you', 'Use a dildo on $malepartner', NULL, NULL, 1, 1, 83),
  (9, 'main', 'scale', 'Use a dildo on $femalepartner', 'Have $malepartner use a dildo on you', NULL, NULL, 1, 1, 84),
  (9, 'main', 'scale', 'Have $femalepartner watch you use toys', 'Watch $malepartner use toys', NULL, NULL, 1, 1, 85),
  (9, 'main', 'scale', 'Watch $femalepartner use toys', 'Have $malepartner watch you use toys', NULL, NULL, 1, 1, 86),
  (9, 'main', 'scale', 'Have $femalepartner use a wand massager on you', 'Use a wand massager on $malepartner', NULL, NULL, 1, 1, 87),
  (9, 'main', 'scale', 'Use a wand massager on $femalepartner', 'Have $malepartner use a wand massager on you', NULL, NULL, 1, 1, 88),
  (9, 'main', 'scale', 'Have $femalepartner use nipple clamps on you', 'Use nipple clamps on $malepartner', NULL, NULL, 1, 1, 89),
  (9, 'main', 'scale', 'Use nipple clamps on $femalepartner', 'Have $malepartner use nipple clamps on you', NULL, NULL, 1, 1, 90),
  (9, 'main', 'scale', 'Have $femalepartner use a butt plug on you during sex', 'Use a butt plug on $malepartner during sex', NULL, NULL, 1, 1, 91),
  (9, 'main', 'scale', 'Use a butt plug on $femalepartner during sex', 'Have $malepartner use a butt plug on you during sex', NULL, NULL, 1, 1, 92),
  (9, 'main', 'scale', 'Have $femalepartner use a cock ring during sex', 'Have $malepartner use a cock ring during sex', NULL, NULL, 1, 1, 93),
  (9, 'main', 'scale', 'Use a cock ring during sex with $femalepartner', 'Use a cock ring during sex with $malepartner', NULL, NULL, 1, 1, 94),
  (9, 'main', 'scale', 'Have $femalepartner use a remote-controlled toy on you in public', 'Use a remote-controlled toy on $malepartner in public', NULL, NULL, 1, 1, 95),
  (9, 'main', 'scale', 'Use a remote-controlled toy on $femalepartner in public', 'Have $malepartner use a remote-controlled toy on you in public', NULL, NULL, 1, 1, 96),
  (9, 'main', 'scale', 'Have $femalepartner use a strap-on on you', 'Use a strap-on on $malepartner', NULL, NULL, 1, 1, 97),
  (9, 'main', 'scale', 'Use a strap-on on $femalepartner', 'Have $malepartner use a strap-on on you', NULL, NULL, 1, 1, 98),
  (9, 'main', 'scale', 'Have $femalepartner use sex furniture with you', 'Use sex furniture with $malepartner', NULL, NULL, 1, 1, 99),
  (9, 'main', 'scale', 'Use sex furniture with $femalepartner', 'Have $malepartner use sex furniture with you', NULL, NULL, 1, 1, 100),
  (9, 'main', 'scale', 'Have $femalepartner use a clitoral suction toy on you', 'Use a clitoral suction toy on $malepartner', NULL, NULL, 1, 1, 101),
  (9, 'main', 'scale', 'Use a clitoral suction toy on $femalepartner', 'Have $malepartner use a clitoral suction toy on you', NULL, NULL, 1, 1, 102),
  (9, 'main', 'scale', 'Have $femalepartner use a prostate massager on you', 'Use a prostate massager on $malepartner', NULL, NULL, 1, 1, 103),
  (9, 'main', 'scale', 'Use a prostate massager on $femalepartner', 'Have $malepartner use a prostate massager on you', NULL, NULL, 1, 1, 104),
  (9, 'main', 'scale', 'Have $femalepartner use a fleshlight or stroker on you', 'Use a fleshlight or stroker on $malepartner', NULL, NULL, 1, 1, 105),
  (9, 'main', 'scale', 'Use a fleshlight or stroker on $femalepartner', 'Have $malepartner use a fleshlight or stroker on you', NULL, NULL, 1, 1, 106),
  (9, 'main', 'scale', 'Have $femalepartner control a toy while you wear it', 'Control a toy that $malepartner is wearing', NULL, NULL, 1, 1, 107),
  (9, 'main', 'scale', 'Control a toy that $femalepartner is wearing', 'Have $malepartner control a toy while you wear it', NULL, NULL, 1, 1, 108),
  (9, 'main', 'scale', 'Have $femalepartner use a spreader bar on you', 'Use a spreader bar on $malepartner', NULL, NULL, 1, 1, 109),
  (9, 'main', 'scale', 'Use a spreader bar on $femalepartner', 'Have $malepartner use a spreader bar on you', NULL, NULL, 1, 1, 110),
  (9, 'main', 'scale', 'Have $femalepartner finger you anally', 'Finger $malepartner anally', NULL, NULL, 1, 1, 111),
  (9, 'main', 'scale', 'Finger $femalepartner anally', 'Have $malepartner finger you anally', NULL, NULL, 1, 1, 112),
  (9, 'main', 'scale', 'Have $femalepartner insert a small anal toy into you', 'Insert a small anal toy into $malepartner', NULL, NULL, 1, 1, 113),
  (9, 'main', 'scale', 'Insert a small anal toy into $femalepartner', 'Have $malepartner insert a small anal toy into you', NULL, NULL, 1, 1, 114),
  (9, 'main', 'scale', 'Have $femalepartner insert a larger anal toy into you', 'Insert a larger anal toy into $malepartner', NULL, NULL, 1, 1, 115),
  (9, 'main', 'scale', 'Have $femalepartner use a vibrating prostate toy on you', 'Use a vibrating prostate toy on $malepartner', NULL, NULL, 1, 1, 116),
  (9, 'main', 'scale', 'Have $femalepartner peg you with a small strap-on', 'Peg $malepartner with a small strap-on', NULL, NULL, 1, 1, 117),
  (9, 'main', 'scale', 'Have $femalepartner peg you with a larger strap-on', 'Peg $malepartner with a larger strap-on', NULL, NULL, 1, 1, 118);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (10, 'main', 'BDSM / Power Play', NULL, 40);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (10, 'main', 'scale', 'Have $femalepartner blindfold you', 'Blindfold $malepartner', NULL, NULL, 1, 1, 119),
  (10, 'main', 'scale', 'Blindfold $femalepartner', 'Have $malepartner blindfold you', NULL, NULL, 1, 1, 120),
  (10, 'main', 'scale', 'Have $femalepartner tie you up', 'Tie $malepartner up', NULL, NULL, 1, 1, 121),
  (10, 'main', 'scale', 'Tie $femalepartner up', 'Have $malepartner tie you up', NULL, NULL, 1, 1, 122),
  (10, 'main', 'scale', 'Have $femalepartner spank you with their hand', 'Spank $malepartner with your hand', NULL, NULL, 1, 1, 123),
  (10, 'main', 'scale', 'Spank $femalepartner with your hand', 'Have $malepartner spank you with their hand', NULL, NULL, 1, 1, 124),
  (10, 'main', 'scale', 'Have $femalepartner spank you with a toy or paddle', 'Spank $malepartner with a toy or paddle', NULL, NULL, 1, 1, 125),
  (10, 'main', 'scale', 'Spank $femalepartner with a toy or paddle', 'Have $malepartner spank you with a toy or paddle', NULL, NULL, 1, 1, 126),
  (10, 'main', 'scale', 'Have $femalepartner lightly choke you', 'Lightly choke $malepartner', NULL, NULL, 1, 1, 127),
  (10, 'main', 'scale', 'Lightly choke $femalepartner', 'Have $malepartner lightly choke you', NULL, NULL, 1, 1, 128),
  (10, 'main', 'scale', 'Have $femalepartner pull your hair during sex', 'Pull $malepartner''s hair during sex', NULL, NULL, 1, 1, 129),
  (10, 'main', 'scale', 'Pull $femalepartner''s hair during sex', 'Have $malepartner pull your hair during sex', NULL, NULL, 1, 1, 130),
  (10, 'main', 'scale', 'Have $femalepartner hold your wrists down', 'Hold $malepartner''s wrists down', NULL, NULL, 1, 1, 131),
  (10, 'main', 'scale', 'Hold $femalepartner''s wrists down', 'Have $malepartner hold your wrists down', NULL, NULL, 1, 1, 132),
  (10, 'main', 'scale', 'Have $femalepartner be dominant with you', 'Be dominant with $malepartner', NULL, NULL, 1, 1, 133),
  (10, 'main', 'scale', 'Be dominant with $femalepartner', 'Have $malepartner be dominant with you', NULL, NULL, 1, 1, 134),
  (10, 'main', 'scale', 'Have $femalepartner be submissive with you', 'Be submissive with $malepartner', NULL, NULL, 1, 1, 135),
  (10, 'main', 'scale', 'Be submissive with $femalepartner', 'Have $malepartner be submissive with you', NULL, NULL, 1, 1, 136),
  (10, 'main', 'scale', 'Have $femalepartner call you degrading names', 'Call $malepartner degrading names', NULL, NULL, 1, 1, 137),
  (10, 'main', 'scale', 'Call $femalepartner degrading names', 'Have $malepartner call you degrading names', NULL, NULL, 1, 1, 138),
  (10, 'main', 'scale', 'Have $femalepartner edge and deny you orgasms', 'Edge and deny $malepartner orgasms', NULL, NULL, 1, 1, 139),
  (10, 'main', 'scale', 'Edge and deny $femalepartner orgasms', 'Have $malepartner edge and deny you orgasms', NULL, NULL, 1, 1, 140),
  (10, 'main', 'scale', 'Have $femalepartner use a collar on you', 'Use a collar on $malepartner', NULL, NULL, 1, 1, 141),
  (10, 'main', 'scale', 'Use a collar on $femalepartner', 'Have $malepartner use a collar on you', NULL, NULL, 1, 1, 142),
  (10, 'main', 'scale', 'Have $femalepartner use a gag on you', 'Use a gag on $malepartner', NULL, NULL, 1, 1, 143),
  (10, 'main', 'scale', 'Use a gag on $femalepartner', 'Have $malepartner use a gag on you', NULL, NULL, 1, 1, 144),
  (10, 'main', 'scale', 'Have $femalepartner use rope bondage on you', 'Use rope bondage on $malepartner', NULL, NULL, 1, 1, 145),
  (10, 'main', 'scale', 'Use rope bondage on $femalepartner', 'Have $malepartner use rope bondage on you', NULL, NULL, 1, 1, 146),
  (10, 'main', 'scale', 'Have $femalepartner bite you', 'Bite $malepartner', NULL, NULL, 1, 1, 147),
  (10, 'main', 'scale', 'Bite $femalepartner', 'Have $malepartner bite you', NULL, NULL, 1, 1, 148),
  (10, 'main', 'scale', 'Have $femalepartner use wax play on you', 'Use wax play on $malepartner', NULL, NULL, 1, 1, 149),
  (10, 'main', 'scale', 'Use wax play on $femalepartner', 'Have $malepartner use wax play on you', NULL, NULL, 1, 1, 150),
  (10, 'main', 'scale', 'Have $femalepartner force you to orgasm multiple times', 'Force $malepartner to orgasm multiple times', NULL, NULL, 1, 1, 151),
  (10, 'main', 'scale', 'Force $femalepartner to orgasm multiple times', 'Have $malepartner force you to orgasm multiple times', NULL, NULL, 1, 1, 152),
  (10, 'main', 'scale', 'Have $femalepartner act as your pet', 'Act as $malepartner''s pet', NULL, NULL, 1, 1, 153),
  (10, 'main', 'scale', 'Act as $femalepartner''s pet', 'Have $malepartner act as your pet', NULL, NULL, 1, 1, 154),
  (10, 'main', 'scale', 'Have $femalepartner wear a butt plug all day for you', 'Wear a butt plug all day for $malepartner', NULL, NULL, 1, 1, 155),
  (10, 'main', 'scale', 'Wear a butt plug all day for $femalepartner', 'Have $malepartner wear a butt plug all day for you', NULL, NULL, 1, 1, 156),
  (10, 'main', 'scale', 'Have $femalepartner use impact play on you', 'Use impact play on $malepartner', NULL, NULL, 1, 1, 157),
  (10, 'main', 'scale', 'Use impact play on $femalepartner', 'Have $malepartner use impact play on you', NULL, NULL, 1, 1, 158);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (11, 'main', 'Anal', NULL, 50);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (11, 'main', 'scale', 'Have $femalepartner play with your ass (no penetration)', 'Play with $malepartner''s ass (no penetration)', NULL, NULL, 1, 1, 159),
  (11, 'main', 'scale', 'Play with $femalepartner''s ass (no penetration)', 'Have $malepartner play with your ass (no penetration)', NULL, NULL, 1, 1, 160),
  (11, 'main', 'scale', 'Have $femalepartner finger you anally', 'Finger $malepartner anally', NULL, NULL, 1, 1, 161),
  (11, 'main', 'scale', 'Finger $femalepartner anally', 'Have $malepartner finger you anally', NULL, NULL, 1, 1, 162),
  (11, 'main', 'scale', 'Have $femalepartner perform anal sex on you', 'Perform anal sex on $malepartner', NULL, NULL, 1, 1, 163),
  (11, 'main', 'scale', 'Perform anal sex on $femalepartner', 'Have $malepartner perform anal sex on you', NULL, NULL, 1, 1, 164),
  (11, 'main', 'scale', 'Have $femalepartner rim you', 'Rim $malepartner', NULL, NULL, 1, 1, 165),
  (11, 'main', 'scale', 'Rim $femalepartner', 'Have $malepartner rim you', NULL, NULL, 1, 1, 166),
  (11, 'main', 'scale', 'Have $femalepartner use a plug on you', 'Use a plug on $malepartner', NULL, NULL, 1, 1, 167),
  (11, 'main', 'scale', 'Use a plug on $femalepartner', 'Have $malepartner use a plug on you', NULL, NULL, 1, 1, 168),
  (11, 'main', 'scale', 'Have $femalepartner finish in your ass', 'Finish in $malepartner''s ass', NULL, NULL, 1, 1, 169),
  (11, 'main', 'scale', 'Finish in $femalepartner''s ass', 'Have $malepartner finish in your ass', NULL, NULL, 1, 1, 170),
  (11, 'main', 'scale', 'Have $femalepartner peg you with a strap-on', 'Peg $malepartner with a strap-on', NULL, NULL, 1, 1, 171),
  (11, 'main', 'scale', 'Peg $femalepartner with a strap-on', 'Have $malepartner peg you with a strap-on', NULL, NULL, 1, 1, 172),
  (11, 'main', 'scale', 'Have double penetration with $femalepartner (toy + real)', 'Have double penetration with $malepartner (toy + real)', NULL, NULL, 1, 1, 173),
  (11, 'main', 'scale', 'Have $femalepartner use a prostate toy on you', 'Use a prostate toy on $malepartner', NULL, NULL, 1, 1, 174),
  (11, 'main', 'scale', 'Use a prostate toy on $femalepartner', 'Have $malepartner use a prostate toy on you', NULL, NULL, 1, 1, 175),
  (11, 'main', 'scale', 'Have $femalepartner give you an enema before anal', 'Give $malepartner an enema before anal', NULL, NULL, 1, 1, 176),
  (11, 'main', 'scale', 'Give $femalepartner an enema before anal', 'Have $malepartner give you an enema before anal', NULL, NULL, 1, 1, 177),
  (11, 'main', 'scale', 'Have $femalepartner spit or lube your ass', 'Spit or lube $malepartner''s ass', NULL, NULL, 1, 1, 178),
  (11, 'main', 'scale', 'Spit or lube $femalepartner''s ass', 'Have $malepartner spit or lube your ass', NULL, NULL, 1, 1, 179),
  (11, 'main', 'scale', 'Have $femalepartner go slowly and gently for anal', 'Go slowly and gently for anal with $malepartner', NULL, NULL, 1, 1, 180),
  (11, 'main', 'scale', 'Go slowly and gently for anal with $femalepartner', 'Have $malepartner go slowly and gently for anal', NULL, NULL, 1, 1, 181),
  (11, 'main', 'scale', 'Have $femalepartner talk dirty about anal', 'Talk dirty about anal with $malepartner', NULL, NULL, 1, 1, 182),
  (11, 'main', 'scale', 'Talk dirty about anal with $femalepartner', 'Have $malepartner talk dirty about anal', NULL, NULL, 1, 1, 183);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (12, 'main', 'Public / Exhibitionism', NULL, 60);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (12, 'main', 'scale', 'Have $femalepartner fondle you in public', 'Fondle $malepartner in public', NULL, NULL, 1, 1, 184),
  (12, 'main', 'scale', 'Fondle $femalepartner in public', 'Have $malepartner fondle you in public', NULL, NULL, 1, 1, 185),
  (12, 'main', 'scale', 'Have sex in a car with $femalepartner', 'Have sex in a car with $malepartner', NULL, NULL, 1, 1, 186),
  (12, 'main', 'scale', 'Have sex outdoors with $femalepartner', 'Have sex outdoors with $malepartner', NULL, NULL, 1, 1, 187),
  (12, 'main', 'scale', 'Have sex in a place where you might get caught with $femalepartner', 'Have sex in a place where you might get caught with $malepartner', NULL, NULL, 1, 1, 188),
  (12, 'main', 'scale', 'Have sex in front of a window with $femalepartner', 'Have sex in front of a window with $malepartner', NULL, NULL, 1, 1, 189),
  (12, 'main', 'scale', 'Have sex at work or in an office with $femalepartner', 'Have sex at work or in an office with $malepartner', NULL, NULL, 1, 1, 190),
  (12, 'main', 'scale', 'Have sex on a beach with $femalepartner', 'Have sex on a beach with $malepartner', NULL, NULL, 1, 1, 191),
  (12, 'main', 'scale', 'Have sex on a hotel balcony with $femalepartner', 'Have sex on a hotel balcony with $malepartner', NULL, NULL, 1, 1, 192),
  (12, 'main', 'scale', 'Have $femalepartner give you oral in a semi-public place', 'Give $malepartner oral in a semi-public place', NULL, NULL, 1, 1, 193),
  (12, 'main', 'scale', 'Give $femalepartner oral in a semi-public place', 'Have $malepartner give you oral in a semi-public place', NULL, NULL, 1, 1, 194),
  (12, 'main', 'scale', 'Have $femalepartner flash you in public', 'Flash $malepartner in public', NULL, NULL, 1, 1, 195),
  (12, 'main', 'scale', 'Flash $femalepartner in public', 'Have $malepartner flash you in public', NULL, NULL, 1, 1, 196),
  (12, 'main', 'scale', 'Have $femalepartner control a remote toy on you in public', 'Control a remote toy on $malepartner in public', NULL, NULL, 1, 1, 197),
  (12, 'main', 'scale', 'Control a remote toy on $femalepartner in public', 'Have $malepartner control a remote toy on you in public', NULL, NULL, 1, 1, 198),
  (12, 'main', 'scale', 'Have sex in a changing room with $femalepartner', 'Have sex in a changing room with $malepartner', NULL, NULL, 1, 1, 199),
  (12, 'main', 'scale', 'Have sex in a park or woods with $femalepartner', 'Have sex in a park or woods with $malepartner', NULL, NULL, 1, 1, 200),
  (12, 'main', 'scale', 'Have $femalepartner take photos of you in public (sexy)', 'Take photos of $malepartner in public (sexy)', NULL, NULL, 1, 1, 201),
  (12, 'main', 'scale', 'Take photos of $femalepartner in public (sexy)', 'Have $malepartner take photos of you in public (sexy)', NULL, NULL, 1, 1, 202),
  (12, 'main', 'scale', 'Have sex while others might hear you with $femalepartner', 'Have sex while others might hear you with $malepartner', NULL, NULL, 1, 1, 203);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (13, 'main', 'Roleplay', NULL, 70);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (13, 'main', 'scale', 'Roleplay a boss/employee scenario with $femalepartner', 'Roleplay a boss/employee scenario with $malepartner', NULL, NULL, 1, 1, 204),
  (13, 'main', 'scale', 'Roleplay a teacher/student scenario with $femalepartner', 'Roleplay a teacher/student scenario with $malepartner', NULL, NULL, 1, 1, 205),
  (13, 'main', 'scale', 'Roleplay a doctor/patient scenario with $femalepartner', 'Roleplay a doctor/patient scenario with $malepartner', NULL, NULL, 1, 1, 206),
  (13, 'main', 'scale', 'Roleplay strangers meeting in a bar with $femalepartner', 'Roleplay strangers meeting in a bar with $malepartner', NULL, NULL, 1, 1, 207),
  (13, 'main', 'scale', 'Roleplay a cop and criminal with $femalepartner', 'Roleplay a cop and criminal with $malepartner', NULL, NULL, 1, 1, 208),
  (13, 'main', 'scale', 'Roleplay a maid/servant with $femalepartner', 'Roleplay a maid/servant with $malepartner', NULL, NULL, 1, 1, 209),
  (13, 'main', 'scale', 'Roleplay a dominant/submissive scene with $femalepartner', 'Roleplay a dominant/submissive scene with $malepartner', NULL, NULL, 1, 1, 210),
  (13, 'main', 'scale', 'Roleplay a massage therapist and client with $femalepartner', 'Roleplay a massage therapist and client with $malepartner', NULL, NULL, 1, 1, 211),
  (13, 'main', 'scale', 'Roleplay a forbidden affair with $femalepartner', 'Roleplay a forbidden affair with $malepartner', NULL, NULL, 1, 1, 212),
  (13, 'main', 'scale', 'Roleplay a celebrity and fan with $femalepartner', 'Roleplay a celebrity and fan with $malepartner', NULL, NULL, 1, 1, 213),
  (13, 'main', 'scale', 'Roleplay a kidnap/rescue scenario with $femalepartner', 'Roleplay a kidnap/rescue scenario with $malepartner', NULL, NULL, 1, 1, 214),
  (13, 'main', 'scale', 'Roleplay a fantasy character with $femalepartner', 'Roleplay a fantasy character with $malepartner', NULL, NULL, 1, 1, 215),
  (13, 'main', 'scale', 'Roleplay a stripper and customer with $femalepartner', 'Roleplay a stripper and customer with $malepartner', NULL, NULL, 1, 1, 216),
  (13, 'main', 'scale', 'Roleplay a personal trainer and client with $femalepartner', 'Roleplay a personal trainer and client with $malepartner', NULL, NULL, 1, 1, 217),
  (13, 'main', 'scale', 'Roleplay a spy or secret agent with $femalepartner', 'Roleplay a spy or secret agent with $malepartner', NULL, NULL, 1, 1, 218),
  (13, 'main', 'scale', 'Roleplay a royal and servant with $femalepartner', 'Roleplay a royal and servant with $malepartner', NULL, NULL, 1, 1, 219),
  (13, 'main', 'scale', 'Roleplay a delivery person and homeowner with $femalepartner', 'Roleplay a delivery person and homeowner with $malepartner', NULL, NULL, 1, 1, 220),
  (13, 'main', 'scale', 'Roleplay a photographer and model with $femalepartner', 'Roleplay a photographer and model with $malepartner', NULL, NULL, 1, 1, 221),
  (13, 'main', 'scale', 'Roleplay a nurse and patient with $femalepartner', 'Roleplay a nurse and patient with $malepartner', NULL, NULL, 1, 1, 222),
  (13, 'main', 'scale', 'Roleplay a hotel guest and staff with $femalepartner', 'Roleplay a hotel guest and staff with $malepartner', NULL, NULL, 1, 1, 223),
  (13, 'main', 'scale', 'Roleplay a fantasy where $femalepartner is in charge', 'Roleplay a fantasy where you are in charge with $malepartner', NULL, NULL, 1, 1, 224),
  (13, 'main', 'scale', 'Roleplay a fantasy where you are in charge with $femalepartner', 'Roleplay a fantasy where $malepartner is in charge', NULL, NULL, 1, 1, 225),
  (13, 'main', 'scale', 'Roleplay a scene with costumes and props with $femalepartner', 'Roleplay a scene with costumes and props with $malepartner', NULL, NULL, 1, 1, 226),
  (13, 'main', 'scale', 'Roleplay a first-time encounter with $femalepartner', 'Roleplay a first-time encounter with $malepartner', NULL, NULL, 1, 1, 227),
  (13, 'main', 'scale', 'Roleplay a power imbalance scenario with $femalepartner', 'Roleplay a power imbalance scenario with $malepartner', NULL, NULL, 1, 1, 228);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (14, 'main', 'Solo Play', NULL, 80);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (14, 'main', 'scale', 'Have $femalepartner watch you masturbate', 'Watch $malepartner masturbate', NULL, NULL, 1, 1, 229),
  (14, 'main', 'scale', 'Watch $femalepartner masturbate', 'Have $malepartner watch you masturbate', NULL, NULL, 1, 1, 230),
  (14, 'main', 'scale', 'Have $femalepartner give you instructions while you masturbate', 'Give $malepartner instructions while they masturbate', NULL, NULL, 1, 1, 231),
  (14, 'main', 'scale', 'Give $femalepartner instructions while they masturbate', 'Have $malepartner give you instructions while you masturbate', NULL, NULL, 1, 1, 232),
  (14, 'main', 'scale', 'Have $femalepartner film you while you masturbate', 'Film $malepartner while they masturbate', NULL, NULL, 1, 1, 233),
  (14, 'main', 'scale', 'Film $femalepartner while they masturbate', 'Have $malepartner film you while you masturbate', NULL, NULL, 1, 1, 234),
  (14, 'main', 'scale', 'Have $femalepartner use toys on themselves while you watch', 'Use toys on yourself while $malepartner watches', NULL, NULL, 1, 1, 235),
  (14, 'main', 'scale', 'Use toys on yourself while $femalepartner watches', 'Have $malepartner use toys on themselves while you watch', NULL, NULL, 1, 1, 236),
  (14, 'main', 'scale', 'Have $femalepartner edge themselves for you', 'Edge yourself for $malepartner', NULL, NULL, 1, 1, 237),
  (14, 'main', 'scale', 'Edge yourself for $femalepartner', 'Have $malepartner edge themselves for you', NULL, NULL, 1, 1, 238),
  (14, 'main', 'scale', 'Have $femalepartner send you videos of them masturbating', 'Send $malepartner videos of you masturbating', NULL, NULL, 1, 1, 239),
  (14, 'main', 'scale', 'Send $femalepartner videos of you masturbating', 'Have $malepartner send you videos of them masturbating', NULL, NULL, 1, 1, 240),
  (14, 'main', 'scale', 'Have $femalepartner masturbate next to you while you sleep', 'Masturbate next to $malepartner while they sleep', NULL, NULL, 1, 1, 241),
  (14, 'main', 'scale', 'Masturbate next to $femalepartner while they sleep', 'Have $malepartner masturbate next to you while you sleep', NULL, NULL, 1, 1, 242),
  (14, 'main', 'scale', 'Have $femalepartner use a toy on you while you masturbate', 'Use a toy on $malepartner while they masturbate', NULL, NULL, 1, 1, 243),
  (14, 'main', 'scale', 'Use a toy on $femalepartner while they masturbate', 'Have $malepartner use a toy on you while you masturbate', NULL, NULL, 1, 1, 244),
  (14, 'main', 'scale', 'Have $femalepartner dirty talk while you masturbate alone', 'Dirty talk while $malepartner masturbates alone', NULL, NULL, 1, 1, 245),
  (14, 'main', 'scale', 'Dirty talk while $femalepartner masturbates alone', 'Have $malepartner dirty talk while you masturbate alone', NULL, NULL, 1, 1, 246),
  (14, 'main', 'scale', 'Have $femalepartner control your orgasm while you solo play', 'Control $malepartner''s orgasm while they solo play', NULL, NULL, 1, 1, 247),
  (14, 'main', 'scale', 'Control $femalepartner''s orgasm while they solo play', 'Have $malepartner control your orgasm while you solo play', NULL, NULL, 1, 1, 248);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (15, 'main', 'Group Play / Orgy', NULL, 90);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (15, 'main', 'scale', 'Have a threesome with $femalepartner and another person', 'Have a threesome with $malepartner and another person', NULL, NULL, 1, 1, 249),
  (15, 'main', 'scale', 'Have a threesome where $femalepartner is the focus', 'Have a threesome where you are the focus with $malepartner', NULL, NULL, 1, 1, 250),
  (15, 'main', 'scale', 'Have a threesome where you are the focus with $femalepartner', 'Have a threesome where $malepartner is the focus', NULL, NULL, 1, 1, 251),
  (15, 'main', 'scale', 'Have group sex with $femalepartner and multiple others', 'Have group sex with $malepartner and multiple others', NULL, NULL, 1, 1, 252),
  (15, 'main', 'scale', 'Have $femalepartner watch you with someone else', 'Watch $malepartner with someone else', NULL, NULL, 1, 1, 253),
  (15, 'main', 'scale', 'Watch $femalepartner with someone else', 'Have $malepartner watch you with someone else', NULL, NULL, 1, 1, 254),
  (15, 'main', 'scale', 'Have $femalepartner join you with another couple', 'Join $malepartner with another couple', NULL, NULL, 1, 1, 255),
  (15, 'main', 'scale', 'Join $femalepartner with another couple', 'Have $malepartner join you with another couple', NULL, NULL, 1, 1, 256),
  (15, 'main', 'scale', 'Have a same-sex threesome with $femalepartner', 'Have a same-sex threesome with $malepartner', NULL, NULL, 1, 1, 257),
  (15, 'main', 'scale', 'Have an opposite-sex threesome with $femalepartner', 'Have an opposite-sex threesome with $malepartner', NULL, NULL, 1, 1, 258),
  (15, 'main', 'scale', 'Have $femalepartner be the only one touching others', 'Be the only one touching others with $malepartner', NULL, NULL, 1, 1, 259),
  (15, 'main', 'scale', 'Be the only one touching others with $femalepartner', 'Have $malepartner be the only one touching others', NULL, NULL, 1, 1, 260),
  (15, 'main', 'scale', 'Have soft play (no penetration) in a group with $femalepartner', 'Have soft play in a group with $malepartner', NULL, NULL, 1, 1, 261),
  (15, 'main', 'scale', 'Have full swap in a group with $femalepartner', 'Have full swap in a group with $malepartner', NULL, NULL, 1, 1, 262),
  (15, 'main', 'scale', 'Have $femalepartner take the lead in a group scene', 'Take the lead in a group scene with $malepartner', NULL, NULL, 1, 1, 263),
  (15, 'main', 'scale', 'Take the lead in a group scene with $femalepartner', 'Have $malepartner take the lead in a group scene', NULL, NULL, 1, 1, 264),
  (15, 'main', 'scale', 'Have a foursome with $femalepartner', 'Have a foursome with $malepartner', NULL, NULL, 1, 1, 265),
  (15, 'main', 'scale', 'Have $femalepartner perform oral on others while you watch', 'Perform oral on others while $malepartner watches', NULL, NULL, 1, 1, 266),
  (15, 'main', 'scale', 'Perform oral on others while $femalepartner watches', 'Have $malepartner perform oral on others while you watch', NULL, NULL, 1, 1, 267),
  (15, 'main', 'scale', 'Have $femalepartner be double-penetrated in a group', 'Be double-penetrated in a group with $malepartner', NULL, NULL, 1, 1, 268),
  (15, 'main', 'scale', 'Be double-penetrated in a group with $femalepartner', 'Have $malepartner be double-penetrated in a group', NULL, NULL, 1, 1, 269),
  (15, 'main', 'scale', 'Have a gangbang scenario with $femalepartner', 'Have a gangbang scenario with $malepartner', NULL, NULL, 1, 1, 270),
  (15, 'main', 'scale', 'Have $femalepartner be the center of attention in a group', 'Be the center of attention in a group with $malepartner', NULL, NULL, 1, 1, 271),
  (15, 'main', 'scale', 'Be the center of attention in a group with $femalepartner', 'Have $malepartner be the center of attention in a group', NULL, NULL, 1, 1, 272),
  (15, 'main', 'scale', 'Have $femalepartner set rules for a group play session', 'Set rules for a group play session with $malepartner', NULL, NULL, 1, 1, 273),
  (15, 'main', 'scale', 'Participate in an orgy with $femalepartner', 'Participate in an orgy with $malepartner', NULL, NULL, 1, 1, 274),
  (15, 'main', 'scale', 'Have $femalepartner watch you in an orgy', 'Watch $malepartner in an orgy', NULL, NULL, 1, 1, 275),
  (15, 'main', 'scale', 'Watch $femalepartner in an orgy', 'Have $malepartner watch you in an orgy', NULL, NULL, 1, 1, 276),
  (15, 'main', 'scale', 'Have $femalepartner be used by multiple people in an orgy', 'Be used by multiple people in an orgy with $malepartner', NULL, NULL, 1, 1, 277),
  (15, 'main', 'scale', 'Be used by multiple people in an orgy with $femalepartner', 'Have $malepartner be used by multiple people in an orgy', NULL, NULL, 1, 1, 278);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (16, 'main', 'Swinging', NULL, 100);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (16, 'main', 'scale', 'Swap partners with another couple with $femalepartner', 'Swap partners with another couple with $malepartner', NULL, NULL, 1, 1, 279),
  (16, 'main', 'scale', 'Have $femalepartner play with others while you watch', 'Play with others while $malepartner watches', NULL, NULL, 1, 1, 280),
  (16, 'main', 'scale', 'Play with others while $femalepartner watches', 'Have $malepartner play with others while you watch', NULL, NULL, 1, 1, 281),
  (16, 'main', 'scale', 'Have soft swap (no penetration) with another couple with $femalepartner', 'Have soft swap with another couple with $malepartner', NULL, NULL, 1, 1, 282),
  (16, 'main', 'scale', 'Have full swap with another couple with $femalepartner', 'Have full swap with another couple with $malepartner', NULL, NULL, 1, 1, 283),
  (16, 'main', 'scale', 'Have $femalepartner choose the other couple', 'Choose the other couple with $malepartner', NULL, NULL, 1, 1, 284),
  (16, 'main', 'scale', 'Choose the other couple with $femalepartner', 'Have $malepartner choose the other couple', NULL, NULL, 1, 1, 285),
  (16, 'main', 'scale', 'Have $femalepartner be the one who initiates with others', 'Be the one who initiates with others with $malepartner', NULL, NULL, 1, 1, 286),
  (16, 'main', 'scale', 'Be the one who initiates with others with $femalepartner', 'Have $malepartner be the one who initiates with others', NULL, NULL, 1, 1, 287),
  (16, 'main', 'scale', 'Have a same-room swap with $femalepartner', 'Have a same-room swap with $malepartner', NULL, NULL, 1, 1, 288),
  (16, 'main', 'scale', 'Have a separate-room swap with $femalepartner', 'Have a separate-room swap with $malepartner', NULL, NULL, 1, 1, 289),
  (16, 'main', 'scale', 'Have $femalepartner only do oral with others', 'Only do oral with others with $malepartner', NULL, NULL, 1, 1, 290),
  (16, 'main', 'scale', 'Only do oral with others with $femalepartner', 'Have $malepartner only do oral with others', NULL, NULL, 1, 1, 291),
  (16, 'main', 'scale', 'Have $femalepartner go home with another couple', 'Go home with another couple with $malepartner', NULL, NULL, 1, 1, 292),
  (16, 'main', 'scale', 'Go home with another couple with $femalepartner', 'Have $malepartner go home with another couple', NULL, NULL, 1, 1, 293),
  (16, 'main', 'scale', 'Have $femalepartner set boundaries for swinging', 'Set boundaries for swinging with $malepartner', NULL, NULL, 1, 1, 294),
  (16, 'main', 'scale', 'Set boundaries for swinging with $femalepartner', 'Have $malepartner set boundaries for swinging', NULL, NULL, 1, 1, 295),
  (16, 'main', 'scale', 'Have $femalepartner be more active in the lifestyle', 'Be more active in the lifestyle with $malepartner', NULL, NULL, 1, 1, 296),
  (16, 'main', 'scale', 'Be more active in the lifestyle with $femalepartner', 'Have $malepartner be more active in the lifestyle', NULL, NULL, 1, 1, 297),
  (16, 'main', 'scale', 'Have a unicorn (single person) join you and $femalepartner', 'Have a unicorn join you and $malepartner', NULL, NULL, 1, 1, 298);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (17, 'main', 'Bisexual / Same-sex Acts', NULL, 110);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (17, 'main', 'scale', 'Have $femalepartner watch you get a handjob from another man', 'Watch $malepartner get a handjob from another man', NULL, NULL, 1, 1, 299),
  (17, 'main', 'scale', 'Watch $femalepartner get a handjob from another man', 'Have $malepartner watch you get a handjob from another man', NULL, NULL, 1, 1, 300),
  (17, 'main', 'scale', 'Have $femalepartner watch you fluff another man', 'Watch $malepartner fluff another man', NULL, NULL, 1, 1, 301),
  (17, 'main', 'scale', 'Watch $femalepartner fluff another man', 'Have $malepartner watch you fluff another man', NULL, NULL, 1, 1, 302),
  (17, 'main', 'scale', 'Have $femalepartner watch you suck another man', 'Watch $malepartner suck another man', NULL, NULL, 1, 1, 303),
  (17, 'main', 'scale', 'Watch $femalepartner suck another man', 'Have $malepartner watch you suck another man', NULL, NULL, 1, 1, 304),
  (17, 'main', 'scale', 'Have $femalepartner watch you deepthroat another man', 'Watch $malepartner deepthroat another man', NULL, NULL, 1, 1, 305),
  (17, 'main', 'scale', 'Have $femalepartner watch you swallow another man''s load', 'Watch $malepartner swallow another man''s load', NULL, NULL, 1, 1, 306),
  (17, 'main', 'scale', 'Have $femalepartner eat you out after another man ejaculates in you', 'Eat $malepartner out after another man ejaculates in you', NULL, NULL, 1, 1, 307),
  (17, 'main', 'scale', 'Eat $femalepartner out after another man ejaculates in you', 'Have $malepartner eat you out after another man ejaculates in you', NULL, NULL, 1, 1, 308),
  (17, 'main', 'scale', 'Have $femalepartner watch you take anal from another man', 'Watch $malepartner take anal from another man', NULL, NULL, 1, 1, 309),
  (17, 'main', 'scale', 'Watch $femalepartner take anal from another man', 'Have $malepartner watch you take anal from another man', NULL, NULL, 1, 1, 310),
  (17, 'main', 'scale', 'Have $femalepartner watch you get pegged by another man with a strap-on', 'Watch $malepartner get pegged by another man with a strap-on', NULL, NULL, 1, 1, 311),
  (17, 'main', 'scale', 'Have $femalepartner suck and swallow another man while you watch', 'Suck and swallow another man while $malepartner watches', NULL, NULL, 1, 1, 312),
  (17, 'main', 'scale', 'Suck and swallow another man while $femalepartner watches', 'Have $malepartner suck and swallow another man while you watch', NULL, NULL, 1, 1, 313),
  (17, 'main', 'scale', 'Have $femalepartner give you a facial from another man''s load', 'Give $malepartner a facial from another man''s load', NULL, NULL, 1, 1, 314),
  (17, 'main', 'scale', 'Have $femalepartner rim you after another man has been in you', 'Rim $malepartner after another man has been in you', NULL, NULL, 1, 1, 315),
  (17, 'main', 'scale', 'Have $femalepartner finger you while another man fucks you', 'Finger $malepartner while another man fucks you', NULL, NULL, 1, 1, 316),
  (17, 'main', 'scale', 'Have $femalepartner hold you while another man fucks you', 'Hold $malepartner while another man fucks you', NULL, NULL, 1, 1, 317),
  (17, 'main', 'scale', 'Have $femalepartner dirty talk while another man uses you', 'Dirty talk while another man uses $malepartner', NULL, NULL, 1, 1, 318),
  (17, 'main', 'scale', 'Have $femalepartner film you with another man', 'Film $malepartner with another man', NULL, NULL, 1, 1, 319),
  (17, 'main', 'scale', 'Film $femalepartner with another man', 'Have $malepartner film you with another man', NULL, NULL, 1, 1, 320),
  (17, 'main', 'scale', 'Have $femalepartner watch you go down on another woman', 'Watch $malepartner go down on another woman', NULL, NULL, 1, 1, 321),
  (17, 'main', 'scale', 'Watch $femalepartner go down on another woman', 'Have $malepartner watch you go down on another woman', NULL, NULL, 1, 1, 322),
  (17, 'main', 'scale', 'Have $femalepartner go down on another woman while you watch', 'Go down on another woman while $malepartner watches', NULL, NULL, 1, 1, 323),
  (17, 'main', 'scale', 'Go down on another woman while $femalepartner watches', 'Have $malepartner go down on another woman while you watch', NULL, NULL, 1, 1, 324),
  (17, 'main', 'scale', 'Have $femalepartner scissor or tribbing with another woman', 'Scissor or tribbing with another woman with $malepartner', NULL, NULL, 1, 1, 325),
  (17, 'main', 'scale', 'Have $femalepartner use a strap-on on another woman', 'Use a strap-on on another woman with $malepartner', NULL, NULL, 1, 1, 326),
  (17, 'main', 'scale', 'Have $femalepartner be eaten out by another woman', 'Be eaten out by another woman with $malepartner', NULL, NULL, 1, 1, 327),
  (17, 'main', 'scale', 'Have $femalepartner finish on another woman''s face', 'Finish on another woman''s face with $malepartner', NULL, NULL, 1, 1, 328);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (18, 'main', 'Cuckolding / Hotwife / Hothusband', NULL, 120);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (18, 'main', 'scale', 'Have $femalepartner watch you with another man (cuck)', 'Watch $malepartner with another man (cuck)', NULL, NULL, 1, 1, 329),
  (18, 'main', 'scale', 'Watch $femalepartner with another man (hotwife)', 'Have $malepartner watch you with another man (hotwife)', NULL, NULL, 1, 1, 330),
  (18, 'main', 'scale', 'Have $femalepartner clean you up after another man finishes in you', 'Clean $malepartner up after another man finishes in you', NULL, NULL, 1, 1, 331),
  (18, 'main', 'scale', 'Clean $femalepartner up after another man finishes in you', 'Have $malepartner clean you up after another man finishes in you', NULL, NULL, 1, 1, 332),
  (18, 'main', 'scale', 'Have $femalepartner lock you in chastity while she plays with others', 'Lock $malepartner in chastity while you play with others', NULL, NULL, 1, 1, 333),
  (18, 'main', 'scale', 'Lock $femalepartner in chastity while he plays with others', 'Have $malepartner lock you in chastity while you play with others', NULL, NULL, 1, 1, 334),
  (18, 'main', 'scale', 'Have $femalepartner tell you about her encounters in detail', 'Tell $malepartner about your encounters in detail', NULL, NULL, 1, 1, 335),
  (18, 'main', 'scale', 'Tell $femalepartner about your encounters in detail', 'Have $malepartner tell you about his encounters in detail', NULL, NULL, 1, 1, 336),
  (18, 'main', 'scale', 'Have $femalepartner make you watch while she is with another man', 'Make $malepartner watch while you are with another man', NULL, NULL, 1, 1, 337),
  (18, 'main', 'scale', 'Make $femalepartner watch while he is with another man', 'Have $malepartner make you watch while he is with another man', NULL, NULL, 1, 1, 338),
  (18, 'main', 'scale', 'Have $femalepartner reclaim you after another man has finished', 'Reclaim $malepartner after another man has finished', NULL, NULL, 1, 1, 339),
  (18, 'main', 'scale', 'Reclaim $femalepartner after another man has finished', 'Have $malepartner reclaim you after another man has finished', NULL, NULL, 1, 1, 340),
  (18, 'main', 'scale', 'Have $femalepartner compare you to other men while she is with them', 'Compare $malepartner to other men while you are with them', NULL, NULL, 1, 1, 341),
  (18, 'main', 'scale', 'Compare $femalepartner to other women while he is with them', 'Have $malepartner compare you to other women while he is with them', NULL, NULL, 1, 1, 342),
  (18, 'main', 'scale', 'Have $femalepartner be a hotwife and come home to you', 'Be a hotwife and come home to $malepartner', NULL, NULL, 1, 1, 343),
  (18, 'main', 'scale', 'Be a hotwife and come home to $femalepartner', 'Have $malepartner be a hothusband and come home to you', NULL, NULL, 1, 1, 344),
  (18, 'main', 'scale', 'Have $femalepartner be a hothusband and come home to you', 'Be a hothusband and come home to $malepartner', NULL, NULL, 1, 1, 345),
  (18, 'main', 'scale', 'Have $femalepartner wear a cum-soaked item home for you', 'Wear a cum-soaked item home for $malepartner', NULL, NULL, 1, 1, 346),
  (18, 'main', 'scale', 'Wear a cum-soaked item home for $femalepartner', 'Have $malepartner wear a cum-soaked item home for you', NULL, NULL, 1, 1, 347),
  (18, 'main', 'scale', 'Have $femalepartner record herself with others for you', 'Record yourself with others for $malepartner', NULL, NULL, 1, 1, 348),
  (18, 'main', 'scale', 'Record yourself with others for $femalepartner', 'Have $malepartner record himself with others for you', NULL, NULL, 1, 1, 349),
  (18, 'main', 'scale', 'Have $femalepartner set rules for your cuckolding', 'Set rules for $malepartner''s cuckolding', NULL, NULL, 1, 1, 350),
  (18, 'main', 'scale', 'Set rules for $femalepartner''s hotwife play', 'Have $malepartner set rules for your hotwife play', NULL, NULL, 1, 1, 351),
  (18, 'main', 'scale', 'Have $femalepartner humiliate you about being a cuck', 'Humiliate $malepartner about being a cuck', NULL, NULL, 1, 1, 352),
  (18, 'main', 'scale', 'Humiliate $femalepartner about being a hotwife', 'Have $malepartner humiliate you about being a hotwife', NULL, NULL, 1, 1, 353);
INSERT INTO categories (id, section, name, description, sort_order) VALUES (19, 'main', 'Extreme / Fetishes', NULL, 130);
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (19, 'main', 'scale', 'Have $femalepartner do watersports with you', 'Do watersports with $malepartner', NULL, NULL, 1, 1, 354),
  (19, 'main', 'scale', 'Do watersports with $femalepartner', 'Have $malepartner do watersports with you', NULL, NULL, 1, 1, 355),
  (19, 'main', 'scale', 'Have $femalepartner engage in mild pain play with you', 'Engage in mild pain play with $malepartner', NULL, NULL, 1, 1, 356),
  (19, 'main', 'scale', 'Engage in mild pain play with $femalepartner', 'Have $malepartner engage in mild pain play with you', NULL, NULL, 1, 1, 357),
  (19, 'main', 'scale', 'Have $femalepartner do breath play with you', 'Do breath play with $malepartner', NULL, NULL, 1, 1, 358),
  (19, 'main', 'scale', 'Do breath play with $femalepartner', 'Have $malepartner do breath play with you', NULL, NULL, 1, 1, 359),
  (19, 'main', 'scale', 'Have $femalepartner do foot worship with you', 'Do foot worship with $malepartner', NULL, NULL, 1, 1, 360),
  (19, 'main', 'scale', 'Do foot worship with $femalepartner', 'Have $malepartner do foot worship with you', NULL, NULL, 1, 1, 361),
  (19, 'main', 'scale', 'Have $femalepartner do lactation play with you', 'Do lactation play with $malepartner', NULL, NULL, 1, 1, 362),
  (19, 'main', 'scale', 'Do lactation play with $femalepartner', 'Have $malepartner do lactation play with you', NULL, NULL, 1, 1, 363),
  (19, 'main', 'scale', 'Have $femalepartner do age play with you', 'Do age play with $malepartner', NULL, NULL, 1, 1, 364),
  (19, 'main', 'scale', 'Do age play with $femalepartner', 'Have $malepartner do age play with you', NULL, NULL, 1, 1, 365),
  (19, 'main', 'scale', 'Have $femalepartner do medical play with you', 'Do medical play with $malepartner', NULL, NULL, 1, 1, 366),
  (19, 'main', 'scale', 'Do medical play with $femalepartner', 'Have $malepartner do medical play with you', NULL, NULL, 1, 1, 367),
  (19, 'main', 'scale', 'Have $femalepartner do animal roleplay with you', 'Do animal roleplay with $malepartner', NULL, NULL, 1, 1, 368);
