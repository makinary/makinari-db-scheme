-- Captured customizations on Supabase-owned objects. No platform tables or data copied.
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
CREATE POLICY "Anyone can read avatars" ON storage."objects" AS PERMISSIVE FOR SELECT TO "public" USING ((bucket_id = 'avatars'::text));
CREATE POLICY "Authenticated users can upload avatars" ON storage."objects" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((bucket_id = 'avatars'::text));
CREATE POLICY "Permitir a todos descargar archivos" ON storage."objects" AS PERMISSIVE FOR SELECT TO "anon", "authenticated" USING ((bucket_id = 'assets'::text));
CREATE POLICY "Permitir a usuarios autenticados actualizar sus archivos" ON storage."objects" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (((bucket_id = 'assets'::text) AND (owner = auth.uid())));
CREATE POLICY "Permitir a usuarios autenticados eliminar sus archivos" ON storage."objects" AS PERMISSIVE FOR DELETE TO "authenticated" USING (((bucket_id = 'assets'::text) AND (owner = auth.uid())));
CREATE POLICY "Permitir a usuarios autenticados subir archivos" ON storage."objects" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((bucket_id = 'assets'::text));
CREATE POLICY "Users can delete their own avatars" ON storage."objects" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((bucket_id = 'avatars'::text));
CREATE POLICY "Users can update their own avatars" ON storage."objects" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((bucket_id = 'avatars'::text)) WITH CHECK ((bucket_id = 'avatars'::text));
CREATE POLICY "Usuarios pueden acceder a archivos de sus tareas" ON storage."objects" AS PERMISSIVE FOR ALL TO "public" USING (((bucket_id = 'task_files'::text) AND (EXISTS ( SELECT 1
   FROM tasks t
  WHERE ((t.id = ((regexp_match(objects.name, '^([^/]+)/'::text))[1])::uuid) AND ((t.user_id = auth.uid()) OR (t.assignee = auth.uid())))))));
CREATE POLICY "buyers_read_own_visit_attestations" ON storage."objects" AS PERMISSIVE FOR SELECT TO "public" USING (((bucket_id = 'visit-attestations'::text) AND (EXISTS ( SELECT 1
   FROM reservations r
  WHERE ((r.buyer_user_id = auth.uid()) AND (objects.name ~~ ((((r.site_id)::text || '/'::text) || (r.id)::text) || '/%'::text)))))));
CREATE POLICY "location_acl_private_storage" ON storage."objects" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((NOT ( SELECT current_user_has_location_restrictions() AS current_user_has_location_restrictions))) WITH CHECK ((NOT ( SELECT current_user_has_location_restrictions() AS current_user_has_location_restrictions)));
CREATE POLICY "site_members_manage_visit_attestations" ON storage."objects" AS PERMISSIVE FOR ALL TO "public" USING (((bucket_id = 'visit-attestations'::text) AND (EXISTS ( SELECT 1
   FROM site_members sm
  WHERE (((sm.site_id)::text = (string_to_array(objects.name, '/'::text))[1]) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text))))));
CREATE POLICY "workspaces service only" ON storage."objects" AS PERMISSIVE FOR ALL TO "public" USING (((bucket_id = 'workspaces'::text) AND (auth.role() = 'service_role'::text))) WITH CHECK (((bucket_id = 'workspaces'::text) AND (auth.role() = 'service_role'::text)));
