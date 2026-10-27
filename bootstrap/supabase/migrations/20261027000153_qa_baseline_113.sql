SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: catalog_item_taxes catalog_item_taxes_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_item_taxes_unified ON public.catalog_item_taxes USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = catalog_item_taxes.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: catalog_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_items ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_items catalog_items_marketplace_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_items_marketplace_read ON public.catalog_items FOR SELECT USING (((is_marketplace_listed = true) AND (status = 'active'::text)));


--
-- Name: catalog_items catalog_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_items_unified ON public.catalog_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = catalog_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: catalog_search_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_search_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_search_refresh_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_search_refresh_events ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_search_revision_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_search_revision_events ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_search_revisions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.catalog_search_revisions ENABLE ROW LEVEL SECURITY;

--
-- Name: catalog_search_revisions catalog_search_revisions_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY catalog_search_revisions_service_read ON public.catalog_search_revisions FOR SELECT TO service_role USING (true);


--
-- Name: categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

--
-- Name: categories categories_for_owned_sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categories_for_owned_sites ON public.categories USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = categories.site_id) AND (s.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = categories.site_id) AND (s.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: channel_health; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.channel_health ENABLE ROW LEVEL SECURITY;

--
-- Name: channel_health_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.channel_health_events ENABLE ROW LEVEL SECURITY;

--
-- Name: commands; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.commands ENABLE ROW LEVEL SECURITY;

--
-- Name: commands commands_site_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY commands_site_access_policy ON public.commands TO authenticated USING (((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = commands.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))))) OR (user_id = ( SELECT auth.uid() AS uid)))) WITH CHECK (((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = commands.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))))) OR (user_id = ( SELECT auth.uid() AS uid))));


--
-- Name: companies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

--
-- Name: content; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;

--
-- Name: content_assets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.content_assets ENABLE ROW LEVEL SECURITY;

--
-- Name: content_assets content_assets_unified_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY content_assets_unified_policy ON public.content_assets TO authenticated USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM (public.content c
     JOIN public.sites s ON ((s.id = c.site_id)))
  WHERE ((c.id = content_assets.content_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))))))) WITH CHECK (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM (public.content c
     JOIN public.sites s ON ((s.id = c.site_id)))
  WHERE ((c.id = content_assets.content_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))))))));


--
-- Name: content_performance; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.content_performance ENABLE ROW LEVEL SECURITY;

--
-- Name: content content_unified_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY content_unified_access_policy ON public.content USING (((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = content.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (content.user_id = auth.uid()) OR (content.author_id = auth.uid()))))))))) OR (user_id = auth.uid()) OR (author_id = auth.uid())));


--
-- Name: conversations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

--
-- Name: conversations conversations_unified_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY conversations_unified_access_policy ON public.conversations USING (((auth.uid() IS NULL) OR ((auth.uid() IS NOT NULL) AND ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = conversations.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (conversations.user_id = auth.uid()) OR (conversations.agent_id = auth.uid()) OR (conversations.delegate_id = auth.uid()) OR (EXISTS ( SELECT 1
                   FROM public.leads l
                  WHERE ((l.id = conversations.lead_id) AND ((l.user_id = auth.uid()) OR (l.assignee_id = auth.uid()))))))))))))) OR (user_id = auth.uid()) OR (visitor_id = auth.uid())))));


--
-- Name: copywriting; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.copywriting ENABLE ROW LEVEL SECURITY;

--
-- Name: copywriting copywriting_site_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY copywriting_site_access_policy ON public.copywriting TO authenticated USING ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))) WITH CHECK ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))));


--
-- Name: credit_auto_top_up_attempts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.credit_auto_top_up_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: credit_auto_top_up_card_setups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.credit_auto_top_up_card_setups ENABLE ROW LEVEL SECURITY;

--
-- Name: credit_auto_top_up_consent_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.credit_auto_top_up_consent_log ENABLE ROW LEVEL SECURITY;

--
-- Name: credit_auto_top_up_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.credit_auto_top_up_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: credit_transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: cron_status; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cron_status ENABLE ROW LEVEL SECURITY;

--
-- Name: customizations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.customizations ENABLE ROW LEVEL SECURITY;

--
-- Name: customizations customizations_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customizations_delete_owner_admin ON public.customizations FOR DELETE USING (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: customizations customizations_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customizations_insert_owner_admin ON public.customizations FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: customizations customizations_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customizations_select_owner_admin ON public.customizations FOR SELECT USING (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: customizations customizations_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customizations_update_owner_admin ON public.customizations FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: deal_leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deal_leads ENABLE ROW LEVEL SECURITY;

--
-- Name: deal_leads deal_leads_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY deal_leads_unified ON public.deal_leads USING ((EXISTS ( SELECT 1
   FROM public.deals d
  WHERE ((d.id = deal_leads.deal_id) AND ((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
           FROM public.sites s
          WHERE ((s.id = d.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
                   FROM public.site_members sm
                  WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))))));


--
-- Name: deal_owners; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deal_owners ENABLE ROW LEVEL SECURITY;

--
-- Name: deal_owners deal_owners_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY deal_owners_unified ON public.deal_owners USING ((EXISTS ( SELECT 1
   FROM public.deals d
  WHERE ((d.id = deal_owners.deal_id) AND ((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
           FROM public.sites s
          WHERE ((s.id = d.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
                   FROM public.site_members sm
                  WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))))));


--
-- Name: deals; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;

--
-- Name: deals deals_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY deals_unified ON public.deals USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = deals.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (deals.user_id = auth.uid()) OR public.is_deal_owner(deals.id, auth.uid())))))))))));


--
-- Name: debug_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.debug_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: debug_logs debug_logs_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY debug_logs_optimized_policy ON public.debug_logs FOR SELECT USING (((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = debug_logs.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));


--
-- Name: deployment_recovery_scan_leases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deployment_recovery_scan_leases ENABLE ROW LEVEL SECURITY;

--
-- Name: deployment_recovery_scan_leases deployment_recovery_scan_leases_service_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY deployment_recovery_scan_leases_service_role ON public.deployment_recovery_scan_leases TO service_role USING (true) WITH CHECK (true);


--
-- Name: editor; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.editor ENABLE ROW LEVEL SECURITY;

--
-- Name: editor editor_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY editor_delete_owner_admin ON public.editor FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: editor editor_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY editor_insert_owner_admin ON public.editor FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: editor editor_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY editor_select_owner_admin ON public.editor FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: editor editor_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY editor_update_owner_admin ON public.editor FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: elements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.elements ENABLE ROW LEVEL SECURITY;
