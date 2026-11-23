-- Keep-alive: fungsi sangat ringan agar proyek Supabase paket gratis tidak di-pause
-- karena tidak ada aktivitas. Dipanggil harian oleh aplikasi (frontend) dan GitHub Actions.
-- Tidak membaca data toko; hanya mengembalikan waktu server.
-- Migrasi 2 mencabut execute dari anon untuk semua fungsi, jadi izin diberikan eksplisit di sini.
create or replace function public.ping() returns jsonb
language sql stable security invoker set search_path = public
as $$ select jsonb_build_object('ok', true, 'at', now()) $$;

revoke execute on function public.ping() from public;
grant execute on function public.ping() to anon, authenticated;
