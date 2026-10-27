SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: assets location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.assets AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: audience_leads location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.audience_leads AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: audiences location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.audiences AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: automation_auth_sessions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.automation_auth_sessions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: billing location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.billing AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: billing_credit_grant_keys location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.billing_credit_grant_keys AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: billing_credit_migration_audit location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.billing_credit_migration_audit AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: calendar_blocks location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.calendar_blocks AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: campaign_requirements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.campaign_requirements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: campaign_segments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.campaign_segments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: campaign_subtasks location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.campaign_subtasks AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: campaigns location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.campaigns AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_embedding_jobs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_embedding_jobs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_import_batches location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_import_batches AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_item_modifier_groups location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_item_modifier_groups AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_item_requirements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_item_requirements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_item_specs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_item_specs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_item_taxes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_item_taxes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_search_documents location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_search_documents AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_search_refresh_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_search_refresh_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_search_revision_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_search_revision_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: catalog_search_revisions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.catalog_search_revisions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: categories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.categories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: channel_health location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.channel_health AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: channel_health_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.channel_health_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: commands location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.commands AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: companies location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.companies AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: content location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.content AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: content_assets location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.content_assets AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: content_performance location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.content_performance AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: conversations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.conversations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: copywriting location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.copywriting AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: credit_auto_top_up_attempts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.credit_auto_top_up_attempts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: credit_auto_top_up_card_setups location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.credit_auto_top_up_card_setups AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: credit_auto_top_up_consent_log location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.credit_auto_top_up_consent_log AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: credit_auto_top_up_settings location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.credit_auto_top_up_settings AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: credit_transactions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.credit_transactions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: cron_status location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.cron_status AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: customizations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.customizations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: deal_leads location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.deal_leads AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: deal_owners location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.deal_owners AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: deals location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.deals AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: debug_logs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.debug_logs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: deployment_recovery_scan_leases location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.deployment_recovery_scan_leases AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: editor location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.editor AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: elements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.elements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: entitlements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.entitlements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: experiment_segments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.experiment_segments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: experiments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.experiments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: external_resources location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.external_resources AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: harness_artifact_reservations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.harness_artifact_reservations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: harness_artifacts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.harness_artifacts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: harness_host_state location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.harness_host_state AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: harness_model_credit_reservations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.harness_model_credit_reservations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: harness_requirement_credit_reservations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.harness_requirement_credit_reservations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: harness_requirement_runs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.harness_requirement_runs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: harness_sessions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.harness_sessions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: icp_dispatch_config location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.icp_dispatch_config AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: icp_dispatch_list_state location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.icp_dispatch_list_state AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: icp_dispatch_runs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.icp_dispatch_runs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: icp_dispatch_site_state location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.icp_dispatch_site_state AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: icp_mining location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.icp_mining AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: icypeas_email_searches location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.icypeas_email_searches AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_artifacts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_artifacts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_context_memories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_context_memories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_context_state location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_context_state AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_logs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_logs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_node_contexts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_node_contexts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_nodes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_nodes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: instance_pending_work location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.instance_pending_work AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);
