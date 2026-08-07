-- ═══════════════════════════════════════════════════════════
--  CUTZ — Datenbankschema (Supabase / PostgreSQL)
--
--  Wird in Phase 2 gebraucht. Für Phase 1 läuft die App mit
--  Testdaten aus CUTZ/Core/Data/MockData.swift.
--
--  Anwenden: Supabase Dashboard → SQL Editor → einfügen → Run
--  Danach seed.sql daneben ausführen, dann sind die 5 Testshops drin.
--
--  ── Eine Regel, die man nicht sieht, aber teuer bezahlt ───
--
--  Wo hier feste Textwerte stehen ('haircut', 'skinFade', …),
--  müssen sie ZEICHENGENAU den `rawValue`s der Swift-Enums
--  entsprechen. Swift benennt Fälle in camelCase, SQL benennt
--  Spalten üblicherweise in snake_case — die Versuchung, hier
--  'skin_fade' zu schreiben, ist groß.
--
--  Tut man das, schlägt kein Constraint an und keine Abfrage
--  scheitert. Stattdessen wirft `JSONDecoder` beim Laden einen
--  Fehler, und in der App bleibt die Liste einfach leer.
-- ═══════════════════════════════════════════════════════════

-- ─── Shops ────────────────────────────────────────────────
create table if not exists public.barbershops (
    id            uuid primary key default gen_random_uuid(),
    name          text        not null,
    description   text        not null default '',
    street        text        not null,
    postal_code   text        not null,
    city          text        not null,
    latitude      double precision not null,
    longitude     double precision not null,
    phone         text,
    image_url     text,
    -- Beispielarbeiten des Ladens. Noch leer; echte Fotos kommen mit
    -- Supabase Storage (Phase 5). Bis dahin zeichnet die App einen
    -- Farbverlauf als Platzhalter.
    portfolio_image_urls text[] not null default '{}',
    price_level   int         not null default 2 check (price_level between 1 and 3),
    created_at    timestamptz not null default now()
);

-- Beschleunigt "Shops in meiner Nähe". Für den Anfang reicht ein
-- einfacher Index auf die Koordinaten; wenn die Datenmenge wächst,
-- steigen wir auf die PostGIS-Erweiterung um.
create index if not exists barbershops_location_idx
    on public.barbershops (latitude, longitude);


-- ─── Mitarbeiter ──────────────────────────────────────────
--
-- Warum eigene Tabelle und nicht nur ein Name am Shop?
--
-- Weil man sich beim Friseur nicht den Laden aussucht, sondern die
-- Person. Wer einmal einen guten Fade bei Samir hatte, will wieder zu
-- Samir. Der Buchungsablauf in der App baut darauf auf: Schritt 2 ist
-- "Wer soll dich schneiden?".
create table if not exists public.employees (
    id           uuid primary key default gen_random_uuid(),
    shop_id      uuid not null references public.barbershops(id) on delete cascade,
    name         text not null,

    -- Bewertung des einzelnen Barbers.
    --
    -- Anders als beim Shop wird sie NICHT aus `reviews` gerechnet,
    -- sondern hier abgelegt. Grund: In der App kann man bisher nur
    -- einen Laden bewerten, keine Person — `Review` hat gar kein Feld
    -- dafür. Sobald es das gibt (Phase 3), kann man diese beiden
    -- Spalten durch eine View ersetzen, so wie beim Shop.
    rating       double precision not null default 0 check (rating between 0 and 5),
    review_count int              not null default 0 check (review_count >= 0),

    -- Worauf diese Person spezialisiert ist. `<@` heißt "ist enthalten
    -- in" — die Bedingung erlaubt also nur bekannte Kategorien.
    specialties  text[] not null default '{}'
                 check (specialties <@ array['haircut', 'skinFade', 'hairAndBeard', 'beard']),

    image_url            text,
    portfolio_image_urls text[] not null default '{}',

    created_at   timestamptz not null default now()
);

create index if not exists employees_shop_idx on public.employees (shop_id);


-- ─── Leistungen ───────────────────────────────────────────
create table if not exists public.services (
    id               uuid primary key default gen_random_uuid(),
    shop_id          uuid not null references public.barbershops(id) on delete cascade,
    name             text not null,
    duration_minutes int  not null check (duration_minutes > 0),
    -- Preis in Cent, damit beim Rechnen nichts durch Kommazahlen verrutscht.
    price_cents      int  not null check (price_cents >= 0),

    -- Die Art der Leistung. Danach filtert die App unter "Entdecken",
    -- und danach richten sich die Spezialgebiete der Mitarbeiter.
    --
    -- Der Name der Leistung reicht dafür nicht: "Skin Fade",
    -- "Buzz Cut" und "Classic Cut" heißen in jedem Laden anders,
    -- meinen aber vergleichbare Dinge.
    category         text not null default 'haircut'
                     check (category in ('haircut', 'skinFade', 'hairAndBeard', 'beard'))
);

create index if not exists services_shop_idx on public.services (shop_id);


-- ─── Öffnungszeiten ───────────────────────────────────────
create table if not exists public.opening_hours (
    id                uuid primary key default gen_random_uuid(),
    shop_id           uuid not null references public.barbershops(id) on delete cascade,
    -- Apples Zählung: 1 = Sonntag … 7 = Samstag.
    -- Bewusst identisch zur App, damit nirgends umgerechnet werden muss.
    weekday           int  not null check (weekday between 1 and 7),
    opens_at_minute   int  not null check (opens_at_minute  between 0 and 1440),
    closes_at_minute  int  not null check (closes_at_minute between 0 and 1440),

    check (closes_at_minute > opens_at_minute),
    -- Pro Shop und Wochentag nur ein Eintrag.
    unique (shop_id, weekday)
);


-- ─── Profile (ergänzt Supabase Auth) ──────────────────────
-- auth.users verwaltet Supabase selbst und wir dürfen es nicht ändern.
-- Zusatzangaben kommen deshalb in eine eigene Tabelle.
create table if not exists public.profiles (
    id           uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    avatar_url   text,
    created_at   timestamptz not null default now()
);


-- ─── Bewertungen ──────────────────────────────────────────
create table if not exists public.reviews (
    id         uuid primary key default gen_random_uuid(),
    shop_id    uuid not null references public.barbershops(id) on delete cascade,

    -- Der angezeigte Name. Steht hier und wird NICHT aus `profiles`
    -- geholt, weil `Review` in der App genau dieses Feld hat und weil
    -- eine Bewertung ihren Namen behalten soll, auch wenn das Konto
    -- später gelöscht wird.
    author_name text not null,

    -- Wer die Bewertung geschrieben hat — falls es jemand mit Konto war.
    --
    -- Bewusst NULL erlaubt: Ein Verzeichnis startet nicht mit einer
    -- leeren Bewertungsseite. Die ersten Bewertungen sind übernommene
    -- (und die Testdaten in seed.sql gehören auch zu niemandem).
    -- Stünde hier `not null`, ließe sich keine einzige davon einspielen.
    user_id    uuid references auth.users(id) on delete set null,

    rating     int  not null check (rating between 1 and 5),
    comment    text not null default '',
    created_at timestamptz not null default now(),

    -- Jeder angemeldete Nutzer darf jeden Shop nur einmal bewerten.
    --
    -- Für übernommene Bewertungen greift die Regel nicht: In SQL gilt
    -- NULL nie als gleich zu NULL, mehrere davon sind also erlaubt.
    -- Genau das wollen wir hier.
    unique (shop_id, user_id)
);

create index if not exists reviews_shop_idx on public.reviews (shop_id);


-- ─── Buchungen ────────────────────────────────────────────
create table if not exists public.bookings (
    id          uuid primary key default gen_random_uuid(),
    shop_id     uuid not null references public.barbershops(id) on delete cascade,
    service_id  uuid not null references public.services(id)    on delete restrict,
    user_id     uuid not null references auth.users(id)         on delete cascade,

    -- Bei wem der Termin ist. NULL heißt "egal welcher Barber" — das
    -- ist im Buchungsablauf eine ausdrückliche Wahl und der schnellste
    -- Weg zu einem Termin.
    employee_id uuid references public.employees(id) on delete set null,

    starts_at   timestamptz not null,
    ends_at     timestamptz not null,
    status      text not null default 'confirmed'
                check (status in ('confirmed', 'cancelled', 'completed')),
    created_at  timestamptz not null default now(),

    check (ends_at > starts_at)
);

create index if not exists bookings_shop_time_idx on public.bookings (shop_id, starts_at);
create index if not exists bookings_user_idx      on public.bookings (user_id);

-- ─── Schutz gegen Doppelbuchungen ─────────────────────────
--
-- Das ist die wichtigste Regel der ganzen Datenbank.
--
-- Ohne sie könnten zwei Leute exakt gleichzeitig denselben Termin
-- buchen: Beide Apps fragen "ist 14:00 frei?", beide bekommen "ja",
-- beide speichern. Eine Prüfung in der App kann das prinzipiell nicht
-- verhindern — nur die Datenbank kann das zuverlässig.
--
-- `tstzrange` ist ein Zeitraum, `&&` heißt "überschneidet sich".
-- Die Bedingung: Für denselben Shop darf es keine zwei aktiven
-- Buchungen mit überlappenden Zeiträumen geben.
--
-- ── Achtung: Ein Shop gilt hier als EIN Stuhl ─────────────
--
-- Die Regel sperrt pro Shop, nicht pro Mitarbeiter. Ein Laden mit
-- fünf Barbern kann damit auch nur einen Termin um 14:00 annehmen.
--
-- Das ist kein Versehen, sondern deckt sich mit der App: Der
-- `MockBarbershopRepository` filtert belegte Zeiten ebenfalls nur über
-- `shopID` und ignoriert den Mitarbeiter dabei. Datenbank und App
-- sagen also dasselbe — nur beide dasselbe Falsche.
--
-- Bevor echte Läden damit arbeiten, muss das an BEIDEN Stellen
-- zusammen geändert werden. Hier wäre es wenig Arbeit:
--
--     shop_id with =,     →    employee_id with =,
--
-- Der Haken ist die andere Hälfte. Buchungen ohne Mitarbeiter ("egal
-- welcher Barber") haben employee_id = NULL, und NULL überschneidet
-- sich in SQL mit nichts — zwei solche Buchungen um 14:00 blieben
-- unbemerkt. Sauber wird das erst, wenn beim Buchen immer ein
-- konkreter Barber zugewiesen wird, auch wenn der Kunde keinen
-- ausgesucht hat. Genau dann muss auch der `SlotCalculator` wissen,
-- wie viele Stühle ein Laden hat.
create extension if not exists btree_gist;

alter table public.bookings
    drop constraint if exists bookings_no_overlap;

alter table public.bookings
    add constraint bookings_no_overlap
    exclude using gist (
        shop_id with =,
        tstzrange(starts_at, ends_at) with &&
    )
    where (status = 'confirmed');


-- ─── View: Shops inklusive Durchschnittsbewertung ─────────
--
-- Damit die App nicht für jeden Shop alle Bewertungen laden muss,
-- rechnet die Datenbank den Durchschnitt aus.
create or replace view public.barbershops_with_rating as
select
    b.*,
    coalesce(round(avg(r.rating)::numeric, 2), 0)::float8 as average_rating,
    count(r.id)::int                                      as review_count
from public.barbershops b
left join public.reviews r on r.shop_id = b.id
group by b.id;


-- ═══════════════════════════════════════════════════════════
--  Row Level Security (RLS)
--
--  Supabase-Apps sprechen direkt mit der Datenbank — der
--  Anon-Key steckt in der App und ist für jeden auslesbar.
--  RLS ist deshalb NICHT optional: Ohne diese Regeln könnte
--  jeder alle Buchungen lesen und fremde Bewertungen löschen.
-- ═══════════════════════════════════════════════════════════

alter table public.barbershops   enable row level security;
alter table public.employees     enable row level security;
alter table public.services      enable row level security;
alter table public.opening_hours enable row level security;
alter table public.reviews       enable row level security;
alter table public.bookings      enable row level security;
alter table public.profiles      enable row level security;

-- Shops, Mitarbeiter, Leistungen und Öffnungszeiten darf jeder LESEN
-- (auch ohne Login — die Karte soll ohne Anmeldung funktionieren).
-- Schreiben kann sie vorerst nur, wer direkten Datenbankzugang hat.
drop policy if exists "Shops öffentlich lesbar" on public.barbershops;
create policy "Shops öffentlich lesbar"
    on public.barbershops for select using (true);

drop policy if exists "Mitarbeiter öffentlich lesbar" on public.employees;
create policy "Mitarbeiter öffentlich lesbar"
    on public.employees for select using (true);

drop policy if exists "Leistungen öffentlich lesbar" on public.services;
create policy "Leistungen öffentlich lesbar"
    on public.services for select using (true);

drop policy if exists "Öffnungszeiten öffentlich lesbar" on public.opening_hours;
create policy "Öffnungszeiten öffentlich lesbar"
    on public.opening_hours for select using (true);

-- Bewertungen: jeder darf lesen, aber nur eingeloggte Nutzer
-- schreiben — und nur ihre eigenen ändern oder löschen.
drop policy if exists "Bewertungen öffentlich lesbar" on public.reviews;
create policy "Bewertungen öffentlich lesbar"
    on public.reviews for select using (true);

drop policy if exists "Eigene Bewertung anlegen" on public.reviews;
create policy "Eigene Bewertung anlegen"
    on public.reviews for insert with check (auth.uid() = user_id);

drop policy if exists "Eigene Bewertung ändern" on public.reviews;
create policy "Eigene Bewertung ändern"
    on public.reviews for update using (auth.uid() = user_id);

drop policy if exists "Eigene Bewertung löschen" on public.reviews;
create policy "Eigene Bewertung löschen"
    on public.reviews for delete using (auth.uid() = user_id);

-- Buchungen sind privat: Man sieht ausschließlich die eigenen.
drop policy if exists "Eigene Buchungen lesen" on public.bookings;
create policy "Eigene Buchungen lesen"
    on public.bookings for select using (auth.uid() = user_id);

drop policy if exists "Eigene Buchung anlegen" on public.bookings;
create policy "Eigene Buchung anlegen"
    on public.bookings for insert with check (auth.uid() = user_id);

drop policy if exists "Eigene Buchung stornieren" on public.bookings;
create policy "Eigene Buchung stornieren"
    on public.bookings for update using (auth.uid() = user_id);

-- Profile: jeder sieht Anzeigenamen (für Bewertungen),
-- ändern darf jeder nur sein eigenes.
drop policy if exists "Profile öffentlich lesbar" on public.profiles;
create policy "Profile öffentlich lesbar"
    on public.profiles for select using (true);

drop policy if exists "Eigenes Profil ändern" on public.profiles;
create policy "Eigenes Profil ändern"
    on public.profiles for update using (auth.uid() = id);

drop policy if exists "Eigenes Profil anlegen" on public.profiles;
create policy "Eigenes Profil anlegen"
    on public.profiles for insert with check (auth.uid() = id);
