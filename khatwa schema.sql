-- ============================================================
-- KHATWA خطوة — Supabase Database Schema
-- انسخ هذا الكود كاملاً في Supabase SQL Editor وشغّله
-- ============================================================

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────────
-- 1. FORUM POSTS
-- ─────────────────────────────────────────────
create table if not exists posts (
  id          uuid default gen_random_uuid() primary key,
  cat         text not null default 'general',
  title       text not null,
  body        text not null,
  anon_idx    integer default 0,
  likes       integer default 0,
  views       integer default 0,
  pinned      boolean default false,
  created_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 2. POST LIKES (prevent double-like)
-- ─────────────────────────────────────────────
create table if not exists post_likes (
  post_id     uuid references posts(id) on delete cascade,
  user_token  text not null,
  primary key (post_id, user_token)
);

-- ─────────────────────────────────────────────
-- 3. FORUM COMMENTS
-- ─────────────────────────────────────────────
create table if not exists comments (
  id          uuid default gen_random_uuid() primary key,
  post_id     uuid references posts(id) on delete cascade,
  body        text not null,
  anon_idx    integer default 0,
  is_ai       boolean default false,
  created_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 4. SOBRIETY COUNTERS (anonymous users)
-- ─────────────────────────────────────────────
create table if not exists counters (
  id           uuid default gen_random_uuid() primary key,
  user_token   text unique not null,
  substance    text default 'alcohol',
  user_name    text default '',
  start_ts     bigint,
  daily_cost   numeric default 50,
  updated_at   timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 5. PLATFORM STATS (optional analytics)
-- ─────────────────────────────────────────────
create table if not exists platform_stats (
  id           serial primary key,
  event_type   text,  -- 'page_view', 'article_read', 'video_play'
  substance    text,
  stage        text,
  created_at   timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 6. RLS POLICIES (Row Level Security)
-- السماح للجميع بالقراءة والكتابة بشكل مجهول
-- ─────────────────────────────────────────────

-- Posts: anyone can read, anyone can insert
alter table posts enable row level security;
create policy "posts_read"   on posts for select using (true);
create policy "posts_insert" on posts for insert with check (true);
create policy "posts_update" on posts for update using (true);

-- Post likes
alter table post_likes enable row level security;
create policy "likes_read"   on post_likes for select using (true);
create policy "likes_insert" on post_likes for insert with check (true);
create policy "likes_delete" on post_likes for delete using (true);

-- Comments
alter table comments enable row level security;
create policy "comments_read"   on comments for select using (true);
create policy "comments_insert" on comments for insert with check (true);

-- Counters
alter table counters enable row level security;
create policy "counters_all" on counters for all using (true) with check (true);

-- Stats
alter table platform_stats enable row level security;
create policy "stats_insert" on platform_stats for insert with check (true);
create policy "stats_read"   on platform_stats for select using (true);

-- ─────────────────────────────────────────────
-- 7. SEED DATA — مشاركات أولية في المنتدى
-- ─────────────────────────────────────────────
insert into posts (cat, title, body, anon_idx, likes, views, pinned) values
(
  'success',
  '١٠٠ يوم بدون شبو — رسالة لمن يعاني',
  'قبل ١٠٠ يوم كنت أظن أنني لن أتمكن من الإقلاع أبداً. الشبو كان قد سيطر على كل جانب من حياتي. لكن مع دعم الأسرة والعلاج النفسي والتوكل على الله وصلت لهنا. أريد أن تعرفوا أن التعافي ممكن مهما كانت الظروف. كل يوم خطوة جديدة.',
  0, 47, 312, true
),
(
  'religious',
  'آيات وأحاديث تثبتني في رحلة التعافي',
  'أشاركم ما يثبتني يومياً. قوله تعالى: {أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ}. وحديث النبي ﷺ: "ما يصيب المسلم من نصب... إلا كفّر الله بها من خطاياه". هذه الكلمات تعطيني قوة لا تصدقونها.',
  4, 56, 289, false
),
(
  'general',
  'نصيحة واحدة غيّرت مسار تعافيي',
  'النصيحة التي غيّرت كل شيء بالنسبة لي: "اليوم الواحد فقط". لا تفكر في باقي حياتك. فقط اسأل نفسك: هل أستطيع الصمود اليوم؟ والجواب دائماً: نعم.',
  5, 39, 201, false
),
(
  'medical',
  'سؤال طبي: متى تنتهي أعراض انسحاب الترامادول؟',
  'مضى على إقلاعي أسبوع والألم العضلي لم يختفِ. هل هذا طبيعي؟ متى سأشعر بتحسن؟',
  2, 18, 145, false
),
(
  'psych',
  'كيف أتعامل مع عائلتي بعد التعافي؟',
  'تعافيت من إدمان الكحول منذ ٦ أشهر لكن عائلتي لا تزال تنظر إليّ بعين الشك. كيف أستعيد ثقتهم؟',
  3, 31, 178, false
);

-- Seed comments for first post
insert into comments (post_id, body, anon_idx, is_ai)
select id, 'مبروك عليك هذا الإنجاز العظيم. رسالتك أعطتني أملاً. أنا في اليوم الثاني عشر.', 1, false
from posts where pinned = true limit 1;

insert into comments (post_id, body, anon_idx, is_ai)
select id, '🌟 مبارك! ١٠٠ يوم إنجاز حقيقي. الدراسات تُثبت أن فرص الانتكاسة تنخفض بشكل كبير بعد ٩٠ يوم. استمر في بناء روتينك اليومي وشبكة دعمك. أنت على الطريق الصحيح.', 0, true
from posts where pinned = true limit 1;

-- ============================================================
-- ✅ انتهى! الآن اذهب لـ Settings > API وانسخ:
-- 1. Project URL
-- 2. anon public key
-- ============================================================
