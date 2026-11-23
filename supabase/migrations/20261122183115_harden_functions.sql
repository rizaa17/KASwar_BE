-- Pengerasan dari saran pemeriksa keamanan Supabase:
-- 1) audit_protect: tetapkan search_path agar tidak bisa dibelokkan.
-- 2) Fungsi pemicu internal tidak perlu dapat dipanggil lewat API (/rest/v1/rpc). Pemicu tetap berjalan: hak EXECUTE hanya diperiksa saat CREATE TRIGGER.
alter function public.audit_protect() set search_path = '';
revoke execute on function public.audit_chain_insert() from authenticated;
revoke execute on function public.audit_protect() from authenticated;
