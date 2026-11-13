# Couples Quiz

A private, self-hosted questionnaire for couples. Each partner answers on their own; the results page only shows the items you **both** rated 2 or higher. Plain PHP 8 + MySQL, no build step, no Composer. Made for cPanel shared hosting.

## Setup on cPanel

1. **Create a database.** cPanel > *MySQL Databases*: create a database and a user, and add the user to the database with *All privileges*.
2. **Import the tables and starter questions.** cPanel > *phpMyAdmin*, pick the new database, *Import*, choose `install.sql`. (Re-importing wipes all data.)
3. **Upload the files** to `public_html/` (or a subfolder such as `public_html/quiz/`). Make sure the hidden `.htaccess` files come along.
4. **Create `config.php`.** Copy `config.sample.php` to `config.php` and fill in the database name, user and password, and set `admin_password`.
   For a hashed password run `php -r "echo password_hash('your-password', PASSWORD_DEFAULT);"` and paste the `$2y$...` value.
5. **Subfolder install only:** in `.htaccess` change `RewriteBase /` to `RewriteBase /quiz/`.
6. Use HTTPS (cPanel > *SSL/TLS Status* > AutoSSL). The links are the only key to each person's answers.

Open `/admin` to log in.

**Already installed the first version?** Don't re-import `install.sql` (it wipes everything). Back up the database, then import `upgrade-workbook-questions.sql`. It adds the her-view wording column and replaces the main questions with the workbook set. This deletes existing main-quiz answers but keeps the intro questions and answers.

## Pages

| URL | What it does |
| --- | --- |
| `/` | Landing: start a new quiz or paste a link |
| `/start` | Person A picks man/woman, their name and what they call their partner |
| `/join/{token}` | Private intro questions (Person B starts here from the shared link; Person A continues here after `/start`) |
| `/share/{token}` | Person A gets the partner link and their own private link |
| `/quiz/{token}` | Main questionnaire, works out who is A or B from the token |
| `/results/{token}` | Matches only, once both have finished |
| `/admin` | Usage, all surveys with both people's answers and results, question editor, page settings |

Adding `/Dbg1357` to a `/join/{token}` or `/quiz/{token}` URL shows the page normally, with the partner's choices highlighted in yellow, their text answers shown left of each text box, and their notes shown as gray placeholder text in the note box. Turn it off with `debug_suffix_enabled => false` in `config.php`.

## How matching works

Main questions are scored 0 to 4:

* 0: I would lose respect for or leave my partner if this happened
* 1: Not interested
* 2: I would like to try it
* 3: I would like to do it occasionally
* 4: I want to do it regularly

An item appears in results only when both partners answered 2 or higher, labelled by the lower score: 2 = **Try**, 3 = **Occasionally**, 4 = **Regularly**. If both tapped ♥ it is highlighted. Notes from both partners on matched items are shown. Anything a partner scored 0 or 1 is never shown. Main questions of the "pick one / pick any" type show only the options both picked. Free-text main questions are never revealed. Intro answers are never shown to the partner (only in `/admin`).

## Questions

The main quiz ships with the 368 questions from the couples quiz workbook, in 13 categories, ordered by the workbook's ID numbers. Everything is editable in `/admin > Questions`: categories (intro or main), order, question text, her-view wording, type, options, required, and active/hidden.

Each question has a main wording (his view) and an optional **her-view wording**. The woman sees the her-view wording when one is set, so a single question can read "Receive a massage from $femalepartner" for him and "Give $malepartner a massage" for her. Both partners' answers are matched on the same question, and each person's results page uses their own wording. Placeholders in question text and options:

* `$malepartner` and `$femalepartner`: the names each person entered (from the reader's point of view, so each sees the names they typed)
* `$me` and `$partner`: the reader and their partner

Write main questions as activities (for example `$malepartner giving $femalepartner a massage`) so results read naturally ("Try: Jim giving Sue a massage").

## Pages and pagination

`/admin > Settings` sets the most questions per page (default 15) and the most categories per page (default 2). Questions stay grouped by category; a category bigger than one page is split across pages and marked "(continued)". The main quiz autosaves as people answer.

## Security notes

* Each person has their own 64-character token from `random_bytes(32)` (256 bits). No accounts, emails or passwords.
* Pages send `noindex` and `no-referrer` so links do not leak to search engines or other sites.
* All forms have CSRF protection; all queries use prepared statements.
* Admin login is rate limited (8 tries per 15 minutes per IP) and refuses to work until `admin_password` is changed from the sample value.
* The debug suffix lets anyone holding one partner's link see the other partner's answers. Switch it off once you are done testing.
