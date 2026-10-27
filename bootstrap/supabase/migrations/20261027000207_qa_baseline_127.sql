SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: site_member_location_restriction_audit; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_member_location_restriction_audit ENABLE ROW LEVEL SECURITY;

--
-- Name: site_member_location_restrictions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_member_location_restrictions ENABLE ROW LEVEL SECURITY;

--
-- Name: site_members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_members ENABLE ROW LEVEL SECURITY;

--
-- Name: site_members site_members_final_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY site_members_final_policy ON public.site_members TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) OR (site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid)))));


--
-- Name: promotion_catalog_categories site_members_promotion_catalog_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY site_members_promotion_catalog_categories ON public.promotion_catalog_categories USING ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())))) WITH CHECK ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid()))));


--
-- Name: activity site_owners_delete_activity; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY site_owners_delete_activity ON public.activity FOR DELETE TO authenticated USING ((((( SELECT auth.jwt() AS jwt) ->> 'role'::text) <> 'service_role'::text) AND ((( SELECT auth.jwt() AS jwt) ->> 'role'::text) = 'authenticated'::text) AND (site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: activity site_owners_update_activity; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY site_owners_update_activity ON public.activity FOR UPDATE TO authenticated USING ((((( SELECT auth.jwt() AS jwt) ->> 'role'::text) <> 'service_role'::text) AND ((( SELECT auth.jwt() AS jwt) ->> 'role'::text) = 'authenticated'::text) AND (site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: site_ownership; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_ownership ENABLE ROW LEVEL SECURITY;

--
-- Name: site_retired_stripe_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_retired_stripe_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: site_secrets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_secrets ENABLE ROW LEVEL SECURITY;

--
-- Name: site_skills; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_skills ENABLE ROW LEVEL SECURITY;

--
-- Name: site_startup_trials; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_startup_trials ENABLE ROW LEVEL SECURITY;

--
-- Name: site_subscription_checkout_leases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_subscription_checkout_leases ENABLE ROW LEVEL SECURITY;

--
-- Name: sites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;

--
-- Name: sites sites_active_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sites_active_only ON public.sites AS RESTRICTIVE TO anon, authenticated USING ((archived_at IS NULL)) WITH CHECK ((archived_at IS NULL));


--
-- Name: sites sites_delete_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sites_delete_policy ON public.sites FOR DELETE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: sites sites_insert_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sites_insert_policy ON public.sites FOR INSERT TO authenticated WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: sites sites_select_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sites_select_policy ON public.sites FOR SELECT TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sites.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));


--
-- Name: sites sites_update_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sites_update_policy ON public.sites FOR UPDATE USING (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sites.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))) WITH CHECK (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sites.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])))))));


--
-- Name: social_comment_sync_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.social_comment_sync_state ENABLE ROW LEVEL SECURITY;

--
-- Name: states; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;

--
-- Name: states states_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY states_delete_owner_admin ON public.states FOR DELETE USING (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: states states_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY states_insert_owner_admin ON public.states FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: states states_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY states_select_owner_admin ON public.states FOR SELECT USING (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: states states_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY states_update_owner_admin ON public.states FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: stripe_sale_checkout_effects; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stripe_sale_checkout_effects ENABLE ROW LEVEL SECURITY;

--
-- Name: stripe_subscription_invoice_settlements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stripe_subscription_invoice_settlements ENABLE ROW LEVEL SECURITY;

--
-- Name: subscription_plan_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subscription_plan_items ENABLE ROW LEVEL SECURITY;

--
-- Name: subscription_plan_items subscription_plan_items_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscription_plan_items_read ON public.subscription_plan_items FOR SELECT USING (true);


--
-- Name: subscription_plan_items subscription_plan_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscription_plan_items_unified ON public.subscription_plan_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = subscription_plan_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: subscriptions subscriptions_buyer_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscriptions_buyer_read ON public.subscriptions FOR SELECT USING (((buyer_user_id = auth.uid()) OR ((owner_site_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = subscriptions.owner_site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))));


--
-- Name: subscriptions subscriptions_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY subscriptions_unified ON public.subscriptions USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = subscriptions.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: settings supabase_auth_admin_full_access_settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supabase_auth_admin_full_access_settings ON public.settings TO supabase_auth_admin USING (true) WITH CHECK (true);


--
-- Name: site_members supabase_auth_admin_full_access_site_members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supabase_auth_admin_full_access_site_members ON public.site_members TO supabase_auth_admin USING (true) WITH CHECK (true);


--
-- Name: site_ownership supabase_auth_admin_full_access_site_ownership; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supabase_auth_admin_full_access_site_ownership ON public.site_ownership TO supabase_auth_admin USING (true) WITH CHECK (true);


--
-- Name: sites supabase_auth_admin_full_access_sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supabase_auth_admin_full_access_sites ON public.sites TO supabase_auth_admin USING (true) WITH CHECK (true);


--
-- Name: synced_objects; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.synced_objects ENABLE ROW LEVEL SECURITY;

--
-- Name: system_memories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.system_memories ENABLE ROW LEVEL SECURITY;

--
-- Name: system_status; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.system_status ENABLE ROW LEVEL SECURITY;

--
-- Name: system_status system_status service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "system_status service only" ON public.system_status USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: system_status_runs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.system_status_runs ENABLE ROW LEVEL SECURITY;

--
-- Name: system_status_runs system_status_runs service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "system_status_runs service only" ON public.system_status_runs USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: system_telemetry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.system_telemetry ENABLE ROW LEVEL SECURITY;

--
-- Name: system_telemetry system_telemetry service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "system_telemetry service only" ON public.system_telemetry USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: task_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: task_comments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

--
-- Name: task_comments task_comments_final_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY task_comments_final_policy ON public.task_comments USING (((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_comments.task_id) AND ((t.user_id = ( SELECT auth.uid() AS uid)) OR (t.assignee = ( SELECT auth.uid() AS uid))))))));


--
-- Name: tasks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

--
-- Name: tasks tasks_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tasks_unified ON public.tasks USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = tasks.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (tasks.user_id = auth.uid()) OR (tasks.assignee = auth.uid()))))))))));


--
-- Name: taxes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.taxes ENABLE ROW LEVEL SECURITY;

--
-- Name: taxes taxes_active_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY taxes_active_read ON public.taxes FOR SELECT USING ((is_active = true));


--
-- Name: taxes taxes_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY taxes_unified ON public.taxes USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = taxes.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: tenant_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenant_users ENABLE ROW LEVEL SECURITY;

--
-- Name: tenant_users tenant_users_self_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_users_self_read ON public.tenant_users FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: tenant_users tenant_users_service_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tenant_users_service_only ON public.tenant_users USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: transitions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transitions ENABLE ROW LEVEL SECURITY;

--
-- Name: transitions transitions_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY transitions_delete_owner_admin ON public.transitions FOR DELETE USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: transitions transitions_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY transitions_insert_owner_admin ON public.transitions FOR INSERT WITH CHECK ((((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = transitions.from_state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = transitions.from_state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))) AND ((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = transitions.to_state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = transitions.to_state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text)))))));
