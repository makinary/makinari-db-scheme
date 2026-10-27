SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: instance_plan_step_infrastructure_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_plan_step_infrastructure_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_plans location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_plans AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: inventory_levels location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.inventory_levels AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: invoice_reminders location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.invoice_reminders AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: item_spec_categories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.item_spec_categories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: item_specs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.item_specs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: journal_entries location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.journal_entries AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: journal_lines location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.journal_lines AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: kpis location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.kpis AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: layers location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.layers AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: lead_analysis location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.lead_analysis AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: lead_invoice_payment_requests location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.lead_invoice_payment_requests AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: leads location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.leads AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: location_access_rollout location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.location_access_rollout AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: locations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.locations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_actions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_actions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_integrations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_integrations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_merchant_connections location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_merchant_connections AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_oauth_sessions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_oauth_sessions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_platform_apps location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_platform_apps AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_provider_webhook_keys location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_provider_webhook_keys AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_rebind_permits location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_rebind_permits AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_webhook_registration_apps location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_webhook_registration_apps AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: marketplace_webhook_registrations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.marketplace_webhook_registrations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: messages location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.messages AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: modifier_group_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.modifier_group_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: modifier_groups location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.modifier_groups AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: notifications location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.notifications AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: openrouter_generation_charges location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.openrouter_generation_charges AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: outstand_initial_imports location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.outstand_initial_imports AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: partner_licenses location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.partner_licenses AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: pass_redeemable_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.pass_redeemable_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: pass_round_robin_state location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.pass_round_robin_state AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: payments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.payments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: payout_requests location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.payout_requests AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: persons location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.persons AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: platform_audit_log location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.platform_audit_log AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: platform_quotas location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.platform_quotas AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: platform_tracking_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.platform_tracking_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: platform_user_roles location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.platform_user_roles AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: pos_client_mutations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.pos_client_mutations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: pos_register_movements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.pos_register_movements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: pos_register_receipts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.pos_register_receipts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: pos_register_sessions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.pos_register_sessions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: profiles location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.profiles AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: promotion_catalog_categories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.promotion_catalog_categories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: promotion_catalog_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.promotion_catalog_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: promotion_required_categories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.promotion_required_categories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: promotion_required_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.promotion_required_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: purchase_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.purchase_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: purchases location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.purchases AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: quotation_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.quotation_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: quotations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.quotations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: record_categories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.record_categories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: record_diagram_edges location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.record_diagram_edges AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: record_diagram_nodes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.record_diagram_nodes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: record_diagrams location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.record_diagrams AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: record_embedding_jobs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.record_embedding_jobs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: records location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.records AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: referral_code_uses location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.referral_code_uses AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: referral_codes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.referral_codes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: remote_instances location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.remote_instances AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: remote_sessions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.remote_sessions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_archived_runner_reassignments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_archived_runner_reassignments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_commands location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_commands AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_cron_cycle_outcomes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_cron_cycle_outcomes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_harness_decisions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_harness_decisions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_migration_diagnostics location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_migration_diagnostics AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_migration_execution_handoffs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_migration_execution_handoffs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);
