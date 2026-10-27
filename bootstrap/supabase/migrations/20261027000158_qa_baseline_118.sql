SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: channel_health location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.channel_health AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: channel_health_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.channel_health_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: commands location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.commands AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: companies location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.companies AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: content location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.content AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: content_assets location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.content_assets AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: content_performance location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.content_performance AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: conversations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.conversations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id)))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id))));


--
-- Name: copywriting location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.copywriting AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: credit_auto_top_up_attempts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.credit_auto_top_up_attempts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: credit_auto_top_up_card_setups location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.credit_auto_top_up_card_setups AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: credit_auto_top_up_consent_log location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.credit_auto_top_up_consent_log AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: credit_auto_top_up_settings location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.credit_auto_top_up_settings AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: credit_transactions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.credit_transactions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: cron_status location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.cron_status AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: customizations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.customizations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: deal_leads location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.deal_leads AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: deal_owners location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.deal_owners AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.deals acl_parent
  WHERE (acl_parent.id = deal_owners.deal_id)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.deals acl_parent
  WHERE (acl_parent.id = deal_owners.deal_id))))));


--
-- Name: deals location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.deals AS RESTRICTIVE TO authenticated USING (commerce_rls_private.deals_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, location_id)) WITH CHECK (commerce_rls_private.deals_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, location_id));


--
-- Name: debug_logs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.debug_logs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: deployment_recovery_scan_leases location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.deployment_recovery_scan_leases AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: editor location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.editor AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: elements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.elements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: entitlements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.entitlements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: experiment_segments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.experiment_segments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: experiments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.experiments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: external_resources location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.external_resources AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: harness_artifact_reservations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.harness_artifact_reservations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: harness_artifacts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.harness_artifacts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: harness_host_state location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.harness_host_state AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: harness_model_credit_reservations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.harness_model_credit_reservations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: harness_requirement_credit_reservations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.harness_requirement_credit_reservations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: harness_requirement_runs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.harness_requirement_runs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: harness_sessions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.harness_sessions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: icp_dispatch_config location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.icp_dispatch_config AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: icp_dispatch_list_state location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.icp_dispatch_list_state AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: icp_dispatch_runs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.icp_dispatch_runs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: icp_dispatch_site_state location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.icp_dispatch_site_state AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: icp_mining location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.icp_mining AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: icypeas_email_searches location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.icypeas_email_searches AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_artifacts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_artifacts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_context_memories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_context_memories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_context_state location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_context_state AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_logs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_logs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_node_contexts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_node_contexts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_nodes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_nodes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_pending_work location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_pending_work AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_plan_step_infrastructure_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_plan_step_infrastructure_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: instance_plans location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.instance_plans AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: inventory_levels location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.inventory_levels AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND (EXISTS ( SELECT 1
   FROM public.catalog_items acl_item
  WHERE ((acl_item.id = inventory_levels.catalog_item_id) AND (acl_item.site_id = inventory_levels.site_id)))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND (EXISTS ( SELECT 1
   FROM public.catalog_items acl_item
  WHERE ((acl_item.id = inventory_levels.catalog_item_id) AND (acl_item.site_id = inventory_levels.site_id))))))));


--
-- Name: invoice_reminders location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.invoice_reminders AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = invoice_reminders.sale_id) AND (acl_parent.site_id = invoice_reminders.site_id)))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = invoice_reminders.sale_id) AND (acl_parent.site_id = invoice_reminders.site_id))))))));


--
-- Name: item_spec_categories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.item_spec_categories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: item_specs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.item_specs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: journal_entries location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.journal_entries AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: journal_lines location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.journal_lines AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: kpis location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.kpis AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: layers location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.layers AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: lead_analysis location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.lead_analysis AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: lead_invoice_payment_requests location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.lead_invoice_payment_requests AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: leads location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.leads AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: locations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.locations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, id)))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, id))));


--
-- Name: marketplace_actions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_actions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_integrations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_integrations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_merchant_connections location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_merchant_connections AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_oauth_sessions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_oauth_sessions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_platform_apps location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_platform_apps AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_provider_webhook_keys location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_provider_webhook_keys AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));
