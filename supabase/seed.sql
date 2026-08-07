-- ═══════════════════════════════════════════════════════════
--  CUTZ — Testdaten
--
--  Die fünf Kasseler Shops aus CUTZ/Core/Data/MockData.swift,
--  einmal als echte Datensätze. Damit kann man Phase 2 gegen
--  eine gefüllte Datenbank entwickeln, statt erst von Hand
--  Shops anzulegen.
--
--  Anwenden: erst schema.sql, dann diese Datei.
--  Supabase Dashboard → SQL Editor → einfügen → Run
--
--  Die Daten sind erfunden. Adressen und Koordinaten in Kassel
--  sind echt gewählt, die Betriebe und Namen aber ausgedacht.
--
--  ── Zweimal ausführen ist erlaubt ─────────────────────────
--
--  Jede Anweisung endet auf `on conflict … do nothing`. Wer die
--  Datei versehentlich ein zweites Mal laufen lässt, bekommt
--  keine Fehlermeldung und keine doppelten Shops.
--
--  Möglich ist das nur, weil die IDs hier fest eingetragen sind
--  und nicht von der Datenbank vergeben werden — dieselben IDs
--  wie in MockData.swift. Praktischer Nebeneffekt: Favoriten,
--  die man in Phase 1 gesetzt hat, zeigen nach dem Umstieg noch
--  auf dieselben Shops.
--
--  ── Was NACH dem Umstieg anders aussieht ──────────────────
--
--  In MockData steht bei Shop 1 "4,7 ★ · 184 Bewertungen". Diese
--  Zahlen sind dort von Hand gesetzt; hier gibt es nur die vier
--  Bewertungen, zu denen auch ein Text existiert.
--
--  Die Datenbank rechnet den Durchschnitt selbst aus (View
--  `barbershops_with_rating`). Nach dem Umstieg steht bei Shop 1
--  also 4,25 ★ aus 4 Bewertungen. Das ist kein Fehler, sondern
--  der ehrliche Wert — die 184 waren erfunden.
-- ═══════════════════════════════════════════════════════════

-- ── Shops ──
insert into public.barbershops (id, name, description, street, postal_code, city, latitude, longitude, phone, price_level) values
    ('11111111-1111-1111-1111-111111111111', 'Königs Barbershop', 'Klassischer Herrenschnitt mit heißem Handtuch und Nassrasur. Mitten auf der Königsstraße.', 'Königsstraße 42', '34117', 'Kassel', 51.3155, 9.4930, '+49 561 1234567', 2),
    ('22222222-2222-2222-2222-222222222222', 'Fade Lounge Nord', 'Spezialisiert auf Fades, Skin Fades und moderne Styles. Junges Team, laute Musik.', 'Holländische Straße 74', '34127', 'Kassel', 51.3262, 9.4878, '+49 561 2345678', 3),
    ('33333333-3333-3333-3333-333333333333', 'Westend Cuts', 'Familienbetrieb in dritter Generation. Auch Kinderhaarschnitte, oft auch ohne Termin.', 'Friedrich-Ebert-Straße 88', '34119', 'Kassel', 51.3106, 9.4788, '+49 561 3456789', 1),
    ('44444444-4444-4444-4444-444444444444', 'Wilhelmshöhe Grooming', 'Gehobenes Ambiente nahe dem Bergpark, Espresso inklusive. Termin empfohlen.', 'Wilhelmshöher Allee 259', '34131', 'Kassel', 51.3124, 9.4571, '+49 561 4567890', 3),
    ('55555555-5555-5555-5555-555555555555', 'Südstadt Razor', 'Walk-ins willkommen. Barbier-Handwerk ohne Schnickschnack, seit 2011.', 'Frankfurter Straße 55', '34121', 'Kassel', 51.3052, 9.4906, '+49 561 5678901', 2)
on conflict (id) do nothing;

-- ── Mitarbeiter ──
insert into public.employees (id, shop_id, name, rating, review_count, specialties) values
    ('b1000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Samir', 4.9, 96, array['skinFade', 'beard']::text[]),
    ('b1000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Erol', 4.7, 61, array['haircut', 'hairAndBeard']::text[]),
    ('b1000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Tobias', 4.5, 27, array['haircut']::text[]),
    ('b2000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Deniz', 5.0, 142, array['skinFade', 'haircut']::text[]),
    ('b2000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Luis', 4.8, 74, array['skinFade', 'beard']::text[]),
    ('b3000000-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'Michael', 4.3, 38, array['haircut']::text[]),
    ('b3000000-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 'Andreas', 4.1, 19, array['haircut', 'beard']::text[]),
    ('b4000000-0000-0000-0000-000000000001', '44444444-4444-4444-4444-444444444444', 'Julian', 4.8, 64, array['haircut', 'hairAndBeard']::text[]),
    ('b4000000-0000-0000-0000-000000000002', '44444444-4444-4444-4444-444444444444', 'Marco', 4.4, 29, array['beard']::text[]),
    ('b5000000-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555555', 'Kai', 4.2, 33, array['haircut', 'skinFade']::text[])
on conflict (id) do nothing;

-- ── Leistungen ──
insert into public.services (id, shop_id, name, duration_minutes, price_cents, category) values
    ('a1000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Herrenhaarschnitt', 30, 2600, 'haircut'),
    ('a1000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Bart trimmen', 20, 1600, 'beard'),
    ('a1000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Schnitt & Bart', 60, 3900, 'hairAndBeard'),
    ('a2000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Skin Fade', 45, 3300, 'skinFade'),
    ('a2000000-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Buzz Cut', 15, 1400, 'haircut'),
    ('a2000000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'Komplettpaket', 75, 5500, 'hairAndBeard'),
    ('a2000000-0000-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222', 'Beard Shape', 20, 1800, 'beard'),
    ('a3000000-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'Herrenhaarschnitt', 30, 1800, 'haircut'),
    ('a3000000-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 'Kinderhaarschnitt', 20, 1200, 'haircut'),
    ('a3000000-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 'Bart trimmen', 15, 1000, 'beard'),
    ('a4000000-0000-0000-0000-000000000001', '44444444-4444-4444-4444-444444444444', 'Signature Cut', 60, 5900, 'haircut'),
    ('a4000000-0000-0000-0000-000000000002', '44444444-4444-4444-4444-444444444444', 'Nassrasur', 45, 4200, 'beard'),
    ('a4000000-0000-0000-0000-000000000003', '44444444-4444-4444-4444-444444444444', 'Cut & Beard Deluxe', 90, 8900, 'hairAndBeard'),
    ('a5000000-0000-0000-0000-000000000001', '55555555-5555-5555-5555-555555555555', 'Classic Cut', 30, 2300, 'haircut'),
    ('a5000000-0000-0000-0000-000000000002', '55555555-5555-5555-5555-555555555555', 'Bart-Styling', 30, 2000, 'beard'),
    ('a5000000-0000-0000-0000-000000000003', '55555555-5555-5555-5555-555555555555', 'Fade', 40, 2800, 'skinFade')
on conflict (id) do nothing;

-- ── Öffnungszeiten ──
insert into public.opening_hours (shop_id, weekday, opens_at_minute, closes_at_minute) values
    ('11111111-1111-1111-1111-111111111111', 2, 540, 1140),
    ('11111111-1111-1111-1111-111111111111', 3, 540, 1140),
    ('11111111-1111-1111-1111-111111111111', 4, 540, 1140),
    ('11111111-1111-1111-1111-111111111111', 5, 540, 1140),
    ('11111111-1111-1111-1111-111111111111', 6, 540, 1140),
    ('11111111-1111-1111-1111-111111111111', 7, 600, 960),
    ('22222222-2222-2222-2222-222222222222', 3, 660, 1260),
    ('22222222-2222-2222-2222-222222222222', 4, 660, 1260),
    ('22222222-2222-2222-2222-222222222222', 5, 660, 1260),
    ('22222222-2222-2222-2222-222222222222', 6, 660, 1320),
    ('22222222-2222-2222-2222-222222222222', 7, 600, 1200),
    ('33333333-3333-3333-3333-333333333333', 2, 540, 1140),
    ('33333333-3333-3333-3333-333333333333', 3, 540, 1140),
    ('33333333-3333-3333-3333-333333333333', 4, 540, 1140),
    ('33333333-3333-3333-3333-333333333333', 5, 540, 1140),
    ('33333333-3333-3333-3333-333333333333', 6, 540, 1140),
    ('33333333-3333-3333-3333-333333333333', 7, 600, 960),
    ('44444444-4444-4444-4444-444444444444', 2, 540, 1140),
    ('44444444-4444-4444-4444-444444444444', 3, 540, 1140),
    ('44444444-4444-4444-4444-444444444444', 4, 540, 1140),
    ('44444444-4444-4444-4444-444444444444', 5, 540, 1140),
    ('44444444-4444-4444-4444-444444444444', 6, 540, 1140),
    ('44444444-4444-4444-4444-444444444444', 7, 600, 960),
    ('55555555-5555-5555-5555-555555555555', 2, 540, 1140),
    ('55555555-5555-5555-5555-555555555555', 3, 540, 1140),
    ('55555555-5555-5555-5555-555555555555', 4, 540, 1140),
    ('55555555-5555-5555-5555-555555555555', 5, 540, 1140),
    ('55555555-5555-5555-5555-555555555555', 6, 540, 1140),
    ('55555555-5555-5555-5555-555555555555', 7, 600, 960)
on conflict (shop_id, weekday) do nothing;

-- ── Bewertungen ──
insert into public.reviews (id, shop_id, author_name, rating, comment, created_at) values
    ('c0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Jonas M.', 5, 'Bester Schnitt seit Jahren. Sehr entspannte Atmosphäre, wird nichts überstürzt.', now() - interval '3 days'),
    ('c0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Ali K.', 5, 'Nassrasur war top. Komme definitiv wieder.', now() - interval '12 days'),
    ('c0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Tim R.', 4, 'Guter Schnitt, aber trotz Termin 15 Minuten Wartezeit.', now() - interval '25 days'),
    ('c0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'Bene', 3, 'Handwerklich in Ordnung, mir persönlich zu hektisch.', now() - interval '40 days'),
    ('c0000000-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'Deniz Y.', 5, 'Die besten Fades in Kassel, kein Vergleich.', now() - interval '2 days'),
    ('c0000000-0000-0000-0000-000000000006', '22222222-2222-2222-2222-222222222222', 'Marc B.', 5, 'Preis ist gehoben, aber das Ergebnis stimmt jedes Mal.', now() - interval '9 days'),
    ('c0000000-0000-0000-0000-000000000007', '22222222-2222-2222-2222-222222222222', 'Nico', 5, 'Deniz weiß genau, was er tut. Termin online in 30 Sekunden gebucht.', now() - interval '15 days'),
    ('c0000000-0000-0000-0000-000000000008', '33333333-3333-3333-3333-333333333333', 'Familie Schulz', 4, 'Sehr geduldig mit unserem Sohn. Faire Preise.', now() - interval '5 days'),
    ('c0000000-0000-0000-0000-000000000009', '33333333-3333-3333-3333-333333333333', 'Nina P.', 4, 'Unkompliziert und schnell, auch spontan.', now() - interval '18 days'),
    ('c0000000-0000-0000-0000-00000000000a', '33333333-3333-3333-3333-333333333333', 'Hendrik', 3, 'Solide fürs Geld, optisch etwas altmodisch.', now() - interval '30 days'),
    ('c0000000-0000-0000-0000-00000000000b', '44444444-4444-4444-4444-444444444444', 'Sebastian L.', 5, 'Fühlt sich eher nach Spa an als nach Friseur. Top.', now() - interval '7 days'),
    ('c0000000-0000-0000-0000-00000000000c', '44444444-4444-4444-4444-444444444444', 'Philipp', 4, 'Sehr gute Arbeit, aber der Preis muss einem das wert sein.', now() - interval '21 days'),
    ('c0000000-0000-0000-0000-00000000000d', '55555555-5555-5555-5555-555555555555', 'Kevin H.', 4, 'Ordentlicher Schnitt, sehr sympathisches Team.', now() - interval '4 days'),
    ('c0000000-0000-0000-0000-00000000000e', '55555555-5555-5555-5555-555555555555', 'Sven', 4, 'Ohne Termin reingegangen, nach 10 Minuten dran gewesen.', now() - interval '11 days')
on conflict (id) do nothing;

