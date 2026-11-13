-- Upgrade for an existing install: switch the intro questions to the Private Info tab.
-- Run upgrade-workbook-questions.sql first if you have not already.
-- 1. Adds the Number answer type.
-- 2. DELETES all existing INTRO categories and questions, and every answer to them.
--    Main questions and their answers are kept. Back up first (phpMyAdmin > Export).
-- New installs do not need this: install.sql already includes it.

SET NAMES utf8mb4;

ALTER TABLE questions MODIFY qtype ENUM('scale','single','multi','text','textarea','number') NOT NULL DEFAULT 'scale';

DELETE FROM categories WHERE section = 'intro';

-- Intro (private) questions from the Private Info tab
INSERT INTO categories (section, name, description, sort_order) VALUES ('intro', 'Currently we engage in', 'Activities you and $partner do now. Never shown to $partner.', 10);
SET @c = LAST_INSERT_ID();
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (@c, 'intro', 'multi', 'Which of these do you and $partner currently engage in?', NULL, 'Tick all that apply.', 'Oral
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
INSERT INTO categories (section, name, description, sort_order) VALUES ('intro', 'With past partners, and I wish we did', 'Things you did with past partners that you and $partner don''t do now, but you wish you did. Never shown to $partner.', 20);
SET @c = LAST_INSERT_ID();
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (@c, 'intro', 'single', 'Oral', NULL, NULL, 'Yes
No
Maybe', 1, 1, 10),
  (@c, 'intro', 'single', 'Vaginal', NULL, NULL, 'Yes
No
Maybe', 1, 1, 20),
  (@c, 'intro', 'single', 'Anal', NULL, NULL, 'Yes
No
Maybe', 1, 1, 30),
  (@c, 'intro', 'single', '69', NULL, NULL, 'Yes
No
Maybe', 1, 1, 40),
  (@c, 'intro', 'single', 'Threesomes', NULL, NULL, 'Yes
No
Maybe', 1, 1, 50),
  (@c, 'intro', 'single', 'Group sex', NULL, NULL, 'Yes
No
Maybe', 1, 1, 60),
  (@c, 'intro', 'single', 'Make porn for ourselves', NULL, NULL, 'Yes
No
Maybe', 1, 1, 70),
  (@c, 'intro', 'single', 'Make porn for others', NULL, NULL, 'Yes
No
Maybe', 1, 1, 80),
  (@c, 'intro', 'single', 'Swinging', NULL, NULL, 'Yes
No
Maybe', 1, 1, 90),
  (@c, 'intro', 'single', 'Being watched / exhibitionism', NULL, NULL, 'Yes
No
Maybe', 1, 1, 100),
  (@c, 'intro', 'single', 'Roleplay', NULL, NULL, 'Yes
No
Maybe', 1, 1, 110),
  (@c, 'intro', 'single', 'Toys during sex', NULL, NULL, 'Yes
No
Maybe', 1, 1, 120),
  (@c, 'intro', 'single', 'BDSM / light bondage', NULL, NULL, 'Yes
No
Maybe', 1, 1, 130),
  (@c, 'intro', 'single', 'Pegging', NULL, NULL, 'Yes
No
Maybe', 1, 1, 140),
  (@c, 'intro', 'single', 'Same-sex play (with others)', NULL, NULL, 'Yes
No
Maybe', 1, 1, 150),
  (@c, 'intro', 'single', 'Cuckolding / hotwife style', NULL, NULL, 'Yes
No
Maybe', 1, 1, 160);
INSERT INTO categories (section, name, description, sort_order) VALUES ('intro', 'In the past we have tried', 'Things you and $partner have tried together at some point. Never shown to $partner.', 30);
SET @c = LAST_INSERT_ID();
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (@c, 'intro', 'multi', 'Which of these have you and $partner tried at some point?', NULL, 'Tick all that apply.', 'Oral
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
INSERT INTO categories (section, name, description, sort_order) VALUES ('intro', 'Individual history, permission and honesty', 'Private. $partner never sees these answers.', 40);
SET @c = LAST_INSERT_ID();
INSERT INTO questions (category_id, section, qtype, text, text_female, help, options, required, active, sort_order) VALUES
  (@c, 'intro', 'number', 'How many consensual male sexual partners have you had?', NULL, 'Lifetime count of male partners', NULL, 1, 1, 10),
  (@c, 'intro', 'number', 'How many consensual female sexual partners have you had?', NULL, 'Lifetime count of female partners', NULL, 1, 1, 20),
  (@c, 'intro', 'single', 'Have you had oral sex with past partners/hookups?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 30),
  (@c, 'intro', 'single', 'Have you had vaginal sex with past partners/hookups?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 40),
  (@c, 'intro', 'single', 'Have you done anal with past partners/hookups?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 50),
  (@c, 'intro', 'single', 'Have you ever cheated (sexual contact) on a past partner?', NULL, 'Any past relationship', 'Yes
No
Prefer not to say', 1, 1, 60),
  (@c, 'intro', 'single', 'Have you ever cheated (sexual contact) on your current partner?', NULL, 'With the person taking this quiz with you', 'Yes
No
Prefer not to say', 1, 1, 70),
  (@c, 'intro', 'single', 'Has your current partner ever allowed you to have sex with someone else and you didn''t?', NULL, 'Permission was given but you chose not to', 'Yes
No
Prefer not to say', 1, 1, 80),
  (@c, 'intro', 'single', 'Has your current partner ever allowed you to have sex with someone else and you did?', NULL, 'Permission was given and you acted on it', 'Yes
No
Prefer not to say', 1, 1, 90),
  (@c, 'intro', 'single', 'Has your partner ever allowed you to have sex with someone else, you said you didn''t, but you actually did?', NULL, 'You lied about following through', 'Yes
No
Prefer not to say', 1, 1, 100),
  (@c, 'intro', 'single', 'Has your current partner ever allowed you to receive oral from someone else and you didn''t?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 110),
  (@c, 'intro', 'single', 'Has your current partner ever allowed you to receive oral from someone else and you did?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 120),
  (@c, 'intro', 'single', 'Has your partner allowed you to do something sexual with others, you said no, but you did it anyway?', NULL, 'Any sexual contact beyond kissing', 'Yes
No
Prefer not to say', 1, 1, 130),
  (@c, 'intro', 'single', 'Have you ever given your partner permission to have sex with someone else and they didn''t?', NULL, 'You offered, they declined', 'Yes
No
Prefer not to say', 1, 1, 140),
  (@c, 'intro', 'single', 'Have you ever given your partner permission to have sex with someone else and they did?', NULL, 'You offered and they accepted', 'Yes
No
Prefer not to say', 1, 1, 150),
  (@c, 'intro', 'single', 'Have you ever told your partner you were okay with them sleeping with someone else, but you weren''t actually okay with it?', NULL, 'You gave permission you didn''t fully mean', 'Yes
No
Prefer not to say', 1, 1, 160),
  (@c, 'intro', 'single', 'Have you ever been offered permission by your partner to play with others but you were too nervous/scared to take it?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 170),
  (@c, 'intro', 'single', 'Have you ever taken permission from your partner to play with others and then felt guilty afterward?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 180),
  (@c, 'intro', 'single', 'Have you ever been in a situation where your partner said ''you can if you want'' regarding someone else, and you did?', NULL, 'Casual or non-explicit permission', 'Yes
No
Prefer not to say', 1, 1, 190),
  (@c, 'intro', 'single', 'Have you ever been in a situation where your partner said ''you can if you want'' regarding someone else, and you didn''t?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 200),
  (@c, 'intro', 'single', 'Have you ever lied to your current partner about sexual contact with someone else (even if it was ''allowed'')?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 210),
  (@c, 'intro', 'single', 'Would you want your current partner to give you explicit permission to have sex with someone else?', NULL, 'Future desire', 'Yes
No
Maybe
Prefer not to say', 1, 1, 220),
  (@c, 'intro', 'single', 'Would you be willing to give your current partner explicit permission to have sex with someone else?', NULL, 'Future willingness', 'Yes
No
Maybe
Prefer not to say', 1, 1, 230),
  (@c, 'intro', 'single', 'Have you ever fantasized about your partner giving you permission to sleep with someone specific?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 240),
  (@c, 'intro', 'single', 'Have you ever been jealous after giving your partner permission to play with someone else?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 250),
  (@c, 'intro', 'single', 'Has your partner ever given you permission to do something sexual with others that you later regretted doing?', NULL, NULL, 'Yes
No
Prefer not to say', 1, 1, 260);
