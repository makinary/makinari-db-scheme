SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: marketplace_rebind_permits location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_rebind_permits AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_webhook_registration_apps location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_webhook_registration_apps AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: marketplace_webhook_registrations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.marketplace_webhook_registrations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: messages location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.messages AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.conversations acl_parent
  WHERE (acl_parent.id = messages.conversation_id)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.conversations acl_parent
  WHERE (acl_parent.id = messages.conversation_id))))));


--
-- Name: modifier_group_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.modifier_group_items AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: modifier_groups location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.modifier_groups AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: notifications location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.notifications AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: openrouter_generation_charges location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.openrouter_generation_charges AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: outstand_initial_imports location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.outstand_initial_imports AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: partner_licenses location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.partner_licenses AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: pass_redeemable_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.pass_redeemable_items AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: pass_round_robin_state location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.pass_round_robin_state AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: payments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.payments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: payout_requests location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.payout_requests AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: persons location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.persons AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: platform_audit_log location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.platform_audit_log AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: platform_quotas location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.platform_quotas AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: platform_tracking_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.platform_tracking_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: platform_user_roles location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.platform_user_roles AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: pos_client_mutations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.pos_client_mutations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: pos_register_movements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.pos_register_movements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.pos_register_sessions acl_parent
  WHERE ((acl_parent.id = pos_register_movements.session_id) AND (acl_parent.site_id = pos_register_movements.site_id)))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.pos_register_sessions acl_parent
  WHERE ((acl_parent.id = pos_register_movements.session_id) AND (acl_parent.site_id = pos_register_movements.site_id))))))));


--
-- Name: pos_register_receipts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.pos_register_receipts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = pos_register_receipts.sale_id) AND (acl_parent.site_id = pos_register_receipts.site_id)))) AND (EXISTS ( SELECT 1
   FROM public.pos_register_sessions acl_parent
  WHERE ((acl_parent.id = pos_register_receipts.session_id) AND (acl_parent.site_id = pos_register_receipts.site_id)))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = pos_register_receipts.sale_id) AND (acl_parent.site_id = pos_register_receipts.site_id)))) AND (EXISTS ( SELECT 1
   FROM public.pos_register_sessions acl_parent
  WHERE ((acl_parent.id = pos_register_receipts.session_id) AND (acl_parent.site_id = pos_register_receipts.site_id))))))));


--
-- Name: pos_register_sessions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.pos_register_sessions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id)))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id))));


--
-- Name: promotion_catalog_categories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.promotion_catalog_categories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: promotion_catalog_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.promotion_catalog_items AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: promotion_required_categories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.promotion_required_categories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: promotion_required_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.promotion_required_items AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: purchase_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.purchase_items AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.purchases acl_parent
  WHERE ((acl_parent.id = purchase_items.purchase_id) AND (acl_parent.site_id = purchase_items.site_id)))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.purchases acl_parent
  WHERE ((acl_parent.id = purchase_items.purchase_id) AND (acl_parent.site_id = purchase_items.site_id))))))));


--
-- Name: purchases location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.purchases AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id)))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id))));


--
-- Name: quotation_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.quotation_items AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.quotations acl_parent
  WHERE (acl_parent.id = quotation_items.quotation_id)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.quotations acl_parent
  WHERE (acl_parent.id = quotation_items.quotation_id))))));


--
-- Name: quotations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.quotations AS RESTRICTIVE TO authenticated USING (commerce_rls_private.quotations_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, deal_id, location_id)) WITH CHECK (commerce_rls_private.quotations_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, deal_id, location_id));


--
-- Name: record_categories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.record_categories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: record_diagram_edges location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.record_diagram_edges AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: record_diagram_nodes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.record_diagram_nodes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: record_diagrams location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.record_diagrams AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: record_embedding_jobs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.record_embedding_jobs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: records location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.records AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((relations IS NULL) OR (relations = ANY (ARRAY['[]'::jsonb, '{}'::jsonb]))) AND (source_id IS NULL))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((relations IS NULL) OR (relations = ANY (ARRAY['[]'::jsonb, '{}'::jsonb]))) AND (source_id IS NULL)))));


--
-- Name: referral_code_uses location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.referral_code_uses AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: referral_codes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.referral_codes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: remote_instances location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.remote_instances AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: remote_sessions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.remote_sessions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_archived_runner_reassignments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_archived_runner_reassignments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_commands location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_commands AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_cron_cycle_outcomes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_cron_cycle_outcomes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_harness_decisions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_harness_decisions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_migration_diagnostics location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_migration_diagnostics AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_migration_execution_handoffs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_migration_execution_handoffs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_migration_lifecycle location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_migration_lifecycle AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_migration_reconciliation_resumes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_migration_reconciliation_resumes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_migration_reconciliations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_migration_reconciliations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_migration_retirements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_migration_retirements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_segments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_segments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_status location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_status AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirement_user_action_receipts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirement_user_action_receipts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: requirements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.requirements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: reservation_schedules location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.reservation_schedules AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: reservations location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.reservations AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, operating_location_id) AND ((sale_order_item_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.sale_order_items acl_parent
  WHERE ((acl_parent.id = reservations.sale_order_item_id) AND (acl_parent.site_id = reservations.site_id))))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, operating_location_id) AND ((sale_order_item_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.sale_order_items acl_parent
  WHERE ((acl_parent.id = reservations.sale_order_item_id) AND (acl_parent.site_id = reservations.site_id)))))))));


--
-- Name: role_queries location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.role_queries AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: role_query_segments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.role_query_segments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: sale_order_item_units location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.sale_order_item_units AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sale_order_items acl_parent
  WHERE ((acl_parent.id = sale_order_item_units.sale_order_item_id) AND (acl_parent.site_id = sale_order_item_units.site_id)))) AND ((shipment_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.shipments acl_parent
  WHERE ((acl_parent.id = sale_order_item_units.shipment_id) AND (acl_parent.site_id = sale_order_item_units.site_id))))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sale_order_items acl_parent
  WHERE ((acl_parent.id = sale_order_item_units.sale_order_item_id) AND (acl_parent.site_id = sale_order_item_units.site_id)))) AND ((shipment_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.shipments acl_parent
  WHERE ((acl_parent.id = sale_order_item_units.shipment_id) AND (acl_parent.site_id = sale_order_item_units.site_id)))))))));


--
-- Name: sale_order_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.sale_order_items AS RESTRICTIVE TO authenticated USING (commerce_rls_private.sale_order_items_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), sale_order_id, site_id, location_id, shipment_id, parent_sale_order_item_id)) WITH CHECK (commerce_rls_private.sale_order_items_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), sale_order_id, site_id, location_id, shipment_id, parent_sale_order_item_id));


--
-- Name: sale_orders location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.sale_orders AS RESTRICTIVE TO authenticated USING (commerce_rls_private.sale_orders_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), sale_id, site_id, quotation_id, location_id)) WITH CHECK (commerce_rls_private.sale_orders_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), sale_id, site_id, quotation_id, location_id));


--
-- Name: sales location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.sales AS RESTRICTIVE TO authenticated USING (commerce_rls_private.sales_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, location_id, subscription_id, quotation_id)) WITH CHECK (commerce_rls_private.sales_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, location_id, subscription_id, quotation_id));


--
-- Name: sandbox_billing_resources location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.sandbox_billing_resources AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));
