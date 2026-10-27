SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;


--
-- Name: insufficient_credit_email_site_gates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.insufficient_credit_email_site_gates ENABLE ROW LEVEL SECURITY;

--
-- Name: inventory_levels; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inventory_levels ENABLE ROW LEVEL SECURITY;

--
-- Name: inventory_levels inventory_levels_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY inventory_levels_unified ON public.inventory_levels USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = inventory_levels.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: invoice_reminders; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invoice_reminders ENABLE ROW LEVEL SECURITY;

--
-- Name: item_spec_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.item_spec_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: item_spec_categories item_spec_categories_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY item_spec_categories_unified ON public.item_spec_categories USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = item_spec_categories.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: item_specs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.item_specs ENABLE ROW LEVEL SECURITY;

--
-- Name: item_specs item_specs_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY item_specs_unified ON public.item_specs USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = item_specs.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: journal_entries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: journal_entries journal_entries_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_entries_select ON public.journal_entries FOR SELECT TO authenticated USING (public.user_can(site_id, 'select'::text));


--
-- Name: journal_lines; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journal_lines ENABLE ROW LEVEL SECURITY;

--
-- Name: journal_lines journal_lines_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_lines_select ON public.journal_lines FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journal_entries e
  WHERE ((e.id = journal_lines.entry_id) AND public.user_can(e.site_id, 'select'::text)))));


--
-- Name: kpis; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.kpis ENABLE ROW LEVEL SECURITY;

--
-- Name: kpis kpis_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY kpis_optimized_policy ON public.kpis USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = kpis.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: layers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.layers ENABLE ROW LEVEL SECURITY;

--
-- Name: layers layers_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY layers_delete_owner_admin ON public.layers FOR DELETE USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: layers layers_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY layers_insert_owner_admin ON public.layers FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: layers layers_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY layers_select_owner_admin ON public.layers FOR SELECT USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: layers layers_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY layers_update_owner_admin ON public.layers FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: lead_analysis; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lead_analysis ENABLE ROW LEVEL SECURITY;

--
-- Name: lead_analysis lead_analysis_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lead_analysis_insert ON public.lead_analysis FOR INSERT WITH CHECK (true);


--
-- Name: lead_analysis lead_analysis_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lead_analysis_select ON public.lead_analysis FOR SELECT USING (true);


--
-- Name: lead_analysis lead_analysis_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lead_analysis_update ON public.lead_analysis FOR UPDATE USING (true);


--
-- Name: lead_invoice_payment_requests lead_invoice_payment_actor_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY lead_invoice_payment_actor_read ON public.lead_invoice_payment_requests FOR SELECT TO authenticated USING (((actor_id = auth.uid()) AND public.user_can(site_id, 'update'::text)));


--
-- Name: lead_invoice_payment_requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lead_invoice_payment_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

--
-- Name: leads leads_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY leads_unified ON public.leads USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = leads.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (leads.user_id = auth.uid()) OR (leads.assignee_id = auth.uid())))))))))));


--
-- Name: site_members license_members_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY license_members_access ON public.site_members AS RESTRICTIVE TO authenticated USING ((public.current_user_site_role(site_id) IS NOT NULL)) WITH CHECK ((public.current_user_site_role(site_id) IS NOT NULL));


--
-- Name: settings license_settings_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY license_settings_access ON public.settings AS RESTRICTIVE TO authenticated USING ((public.current_user_site_role(site_id) IS NOT NULL)) WITH CHECK ((public.current_user_site_role(site_id) IS NOT NULL));


--
-- Name: sites license_sites_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY license_sites_access ON public.sites AS RESTRICTIVE TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) OR (public.current_user_site_role(id) IS NOT NULL))) WITH CHECK (((user_id = auth.uid()) OR (public.current_user_site_role(id) IS NOT NULL)));


--
-- Name: location_access_rollout; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.location_access_rollout ENABLE ROW LEVEL SECURITY;

--
-- Name: accounting_sale_refunds location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.accounting_sale_refunds AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: conversations location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.conversations AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: deal_owners location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.deal_owners AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.deals acl_action_parent
  WHERE ((acl_action_parent.id = deal_owners.deal_id) AND public.user_can(acl_action_parent.site_id, 'delete'::text))))));


--
-- Name: deals location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.deals AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: inventory_levels location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.inventory_levels AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: invoice_reminders location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.invoice_reminders AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: locations location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.locations AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: messages location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.messages AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.conversations acl_action_parent
  WHERE ((acl_action_parent.id = messages.conversation_id) AND public.user_can(acl_action_parent.site_id, 'delete'::text))))));


--
-- Name: pos_register_movements location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.pos_register_movements AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: pos_register_receipts location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.pos_register_receipts AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: pos_register_sessions location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.pos_register_sessions AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: purchase_items location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.purchase_items AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: purchases location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.purchases AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: quotation_items location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.quotation_items AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.quotations acl_action_parent
  WHERE ((acl_action_parent.id = quotation_items.quotation_id) AND public.user_can(acl_action_parent.site_id, 'delete'::text))))));


--
-- Name: quotations location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.quotations AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: records location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.records AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: reservations location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.reservations AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: sale_order_item_units location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.sale_order_item_units AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: sale_order_items location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.sale_order_items AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: sale_orders location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.sale_orders AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: sales location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.sales AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: shipment_location_pings location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.shipment_location_pings AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: shipments location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.shipments AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: subscriptions location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.subscriptions AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: task_categories location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.task_categories AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_categories.task_id) AND public.user_can(acl_action_parent.site_id, 'delete'::text))))));


--
-- Name: task_comments location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.task_comments AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_comments.task_id) AND public.user_can(acl_action_parent.site_id, 'delete'::text))))));


--
-- Name: tasks location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.tasks AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: transactions location_acl_action_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_delete ON public.transactions AS RESTRICTIVE FOR DELETE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'delete'::text)));


--
-- Name: accounting_sale_refunds location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.accounting_sale_refunds AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: conversations location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.conversations AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: deal_owners location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.deal_owners AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.deals acl_action_parent
  WHERE ((acl_action_parent.id = deal_owners.deal_id) AND public.user_can(acl_action_parent.site_id, 'insert'::text))))));
