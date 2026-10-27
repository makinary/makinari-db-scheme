SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;


--
-- Name: agents agents_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY agents_optimized_policy ON public.agents USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = agents.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: site_members allow_service_role_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete ON public.site_members FOR DELETE TO service_role USING (true);


--
-- Name: api_keys allow_service_role_delete_api_keys; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_api_keys ON public.api_keys FOR DELETE TO service_role USING (true);


--
-- Name: billing allow_service_role_delete_billing; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_billing ON public.billing FOR DELETE TO service_role USING (true);


--
-- Name: notifications allow_service_role_delete_notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_notifications ON public.notifications FOR DELETE TO service_role USING (true);


--
-- Name: payments allow_service_role_delete_payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_payments ON public.payments FOR DELETE TO service_role USING (true);


--
-- Name: profiles allow_service_role_delete_profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_profiles ON public.profiles FOR DELETE TO service_role USING (true);


--
-- Name: settings allow_service_role_delete_settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_settings ON public.settings FOR DELETE TO service_role USING (true);


--
-- Name: site_ownership allow_service_role_delete_site_ownership; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_site_ownership ON public.site_ownership FOR DELETE TO service_role USING (true);


--
-- Name: tasks allow_service_role_delete_tasks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_service_role_delete_tasks ON public.tasks FOR DELETE TO service_role USING (true);


--
-- Name: allowed_domains; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.allowed_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: allowed_domains allowed_domains_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allowed_domains_access_policy ON public.allowed_domains TO authenticated USING ((site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))) WITH CHECK ((site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))));


--
-- Name: analysis; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.analysis ENABLE ROW LEVEL SECURITY;

--
-- Name: analysis analysis_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY analysis_optimized_policy ON public.analysis USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: api_keys; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

--
-- Name: appointments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

--
-- Name: appointments appointments_site_members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY appointments_site_members ON public.appointments TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.sites site
  WHERE ((site.id = appointments.site_id) AND ((site.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members member
          WHERE ((member.site_id = site.id) AND (member.user_id = ( SELECT auth.uid() AS uid)) AND (member.status = 'active'::text) AND (member.restrict_to_assigned_only = false))))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.sites site
  WHERE ((site.id = appointments.site_id) AND ((site.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members member
          WHERE ((member.site_id = site.id) AND (member.user_id = ( SELECT auth.uid() AS uid)) AND (member.status = 'active'::text) AND (member.restrict_to_assigned_only = false)))))))));


--
-- Name: apps_migration_feedback; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.apps_migration_feedback ENABLE ROW LEVEL SECURITY;

--
-- Name: apps_migration_feedback apps_migration_feedback_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY apps_migration_feedback_service_read ON public.apps_migration_feedback FOR SELECT TO service_role USING (true);


--
-- Name: apps_tenants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.apps_tenants ENABLE ROW LEVEL SECURITY;

--
-- Name: apps_tenants apps_tenants_service_only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY apps_tenants_service_only ON public.apps_tenants USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: requirement_archived_runner_reassignments archived_runner_receipts_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY archived_runner_receipts_service_read ON public.requirement_archived_runner_reassignments FOR SELECT TO service_role USING (true);


--
-- Name: assets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

--
-- Name: assets assets_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY assets_optimized_policy ON public.assets USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = assets.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: audience_leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audience_leads ENABLE ROW LEVEL SECURITY;

--
-- Name: audience_leads audience_leads_site_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audience_leads_site_access ON public.audience_leads TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.audiences a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = audience_leads.audience_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.audiences a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = audience_leads.audience_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))));


--
-- Name: audiences; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audiences ENABLE ROW LEVEL SECURITY;

--
-- Name: audiences audiences_site_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audiences_site_access ON public.audiences USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = audiences.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (audiences.user_id = auth.uid()))))))))));


--
-- Name: activity authenticated_read_activity; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY authenticated_read_activity ON public.activity FOR SELECT TO authenticated USING ((((( SELECT auth.jwt() AS jwt) ->> 'role'::text) <> 'service_role'::text) AND ((( SELECT auth.jwt() AS jwt) ->> 'role'::text) = 'authenticated'::text) AND ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid)))) OR (site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: automation_auth_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.automation_auth_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: automation_auth_sessions automation_auth_sessions_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY automation_auth_sessions_access_policy ON public.automation_auth_sessions USING (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = automation_auth_sessions.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = automation_auth_sessions.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = automation_auth_sessions.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: billing; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.billing ENABLE ROW LEVEL SECURITY;

--
-- Name: billing_credit_grant_keys; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.billing_credit_grant_keys ENABLE ROW LEVEL SECURITY;

--
-- Name: billing_credit_migration_audit; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.billing_credit_migration_audit ENABLE ROW LEVEL SECURITY;

--
-- Name: billing billing_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY billing_optimized_policy ON public.billing USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = billing.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: synced_objects bypass_synced_objects; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bypass_synced_objects ON public.synced_objects USING (true);


--
-- Name: system_memories bypass_system_memories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bypass_system_memories ON public.system_memories USING (true);


--
-- Name: whatsapp_templates bypass_whatsapp_templates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bypass_whatsapp_templates ON public.whatsapp_templates USING (true);


--
-- Name: calendar_blocks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.calendar_blocks ENABLE ROW LEVEL SECURITY;

--
-- Name: campaign_requirements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.campaign_requirements ENABLE ROW LEVEL SECURITY;

--
-- Name: campaign_requirements campaign_requirements_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY campaign_requirements_optimized_policy ON public.campaign_requirements USING ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.sites s ON ((s.id = c.site_id)))
  WHERE ((c.id = campaign_requirements.campaign_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: campaign_segments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.campaign_segments ENABLE ROW LEVEL SECURITY;

--
-- Name: campaign_subtasks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.campaign_subtasks ENABLE ROW LEVEL SECURITY;

--
-- Name: campaigns; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

--
-- Name: campaigns campaigns_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY campaigns_unified ON public.campaigns USING (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = campaigns.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (campaigns.user_id = auth.uid())))))))))));


--
-- Name: catalog_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_categories catalog_categories_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_categories_unified ON public.catalog_categories USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = catalog_categories.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: catalog_embedding_jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_embedding_jobs ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_embedding_jobs catalog_embedding_jobs_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_embedding_jobs_service_read ON public.catalog_embedding_jobs FOR SELECT TO service_role USING (true);


--
-- Name: catalog_import_batches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_import_batches ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_import_batches catalog_import_batches_actor_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_import_batches_actor_read ON public.catalog_import_batches FOR SELECT TO authenticated USING (((actor_id = auth.uid()) AND public.user_can(site_id, 'select'::text)));


--
-- Name: catalog_item_modifier_groups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_item_modifier_groups ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_item_modifier_groups catalog_item_modifier_groups_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_item_modifier_groups_unified ON public.catalog_item_modifier_groups USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = catalog_item_modifier_groups.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: catalog_item_requirements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_item_requirements ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_item_requirements catalog_item_requirements_select_listed; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_item_requirements_select_listed ON public.catalog_item_requirements FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.catalog_items ci
  WHERE ((ci.id = catalog_item_requirements.catalog_item_id) AND (ci.is_dynamic_price = true) AND (ci.status = 'active'::text)))));


--
-- Name: catalog_item_requirements catalog_item_requirements_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_item_requirements_unified ON public.catalog_item_requirements USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = catalog_item_requirements.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: catalog_item_specs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_item_specs ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_item_specs catalog_item_specs_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_item_specs_unified ON public.catalog_item_specs USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM (public.catalog_items ci
     JOIN public.sites s ON ((s.id = ci.site_id)))
  WHERE ((ci.id = catalog_item_specs.catalog_item_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: catalog_item_taxes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_item_taxes ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_item_taxes catalog_item_taxes_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_item_taxes_read ON public.catalog_item_taxes FOR SELECT USING (true);
