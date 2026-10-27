SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: debug_logs debug_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debug_logs
    ADD CONSTRAINT debug_logs_pkey PRIMARY KEY (id);


--
-- Name: deployment_recovery_scan_leases deployment_recovery_scan_leases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_recovery_scan_leases
    ADD CONSTRAINT deployment_recovery_scan_leases_pkey PRIMARY KEY (lease_key);


--
-- Name: editor editor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editor
    ADD CONSTRAINT editor_pkey PRIMARY KEY (id);


--
-- Name: editor editor_site_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editor
    ADD CONSTRAINT editor_site_id_key UNIQUE (site_id);


--
-- Name: elements elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elements
    ADD CONSTRAINT elements_pkey PRIMARY KEY (id);


--
-- Name: entitlements entitlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT entitlements_pkey PRIMARY KEY (id);


--
-- Name: experiment_segments experiment_segments_experiment_id_segment_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_segments
    ADD CONSTRAINT experiment_segments_experiment_id_segment_id_key UNIQUE (experiment_id, segment_id);


--
-- Name: experiment_segments experiment_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_segments
    ADD CONSTRAINT experiment_segments_pkey PRIMARY KEY (id);


--
-- Name: experiments experiments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_pkey PRIMARY KEY (id);


--
-- Name: external_resources external_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_resources
    ADD CONSTRAINT external_resources_pkey PRIMARY KEY (id);


--
-- Name: harness_artifact_reservations harness_artifact_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_artifact_reservations
    ADD CONSTRAINT harness_artifact_reservations_pkey PRIMARY KEY (session_id, operation_id);


--
-- Name: harness_artifacts harness_artifacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_artifacts
    ADD CONSTRAINT harness_artifacts_pkey PRIMARY KEY (session_id, id);


--
-- Name: harness_host_state harness_host_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_host_state
    ADD CONSTRAINT harness_host_state_pkey PRIMARY KEY (session_id);


--
-- Name: harness_model_credit_reservations harness_model_credit_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_model_credit_reservations
    ADD CONSTRAINT harness_model_credit_reservations_pkey PRIMARY KEY (session_id, event_id);


--
-- Name: harness_requirement_credit_reservations harness_requirement_credit_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_requirement_credit_reservations
    ADD CONSTRAINT harness_requirement_credit_reservations_pkey PRIMARY KEY (session_id, event_id);


--
-- Name: harness_requirement_runs harness_requirement_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_requirement_runs
    ADD CONSTRAINT harness_requirement_runs_pkey PRIMARY KEY (requirement_id);


--
-- Name: harness_requirement_runs harness_requirement_runs_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_requirement_runs
    ADD CONSTRAINT harness_requirement_runs_session_id_key UNIQUE (session_id);


--
-- Name: harness_sessions harness_sessions_id_site_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_sessions
    ADD CONSTRAINT harness_sessions_id_site_key UNIQUE (id, site_id);


--
-- Name: harness_sessions harness_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_sessions
    ADD CONSTRAINT harness_sessions_pkey PRIMARY KEY (id);


--
-- Name: icp_dispatch_config icp_dispatch_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_config
    ADD CONSTRAINT icp_dispatch_config_pkey PRIMARY KEY (id);


--
-- Name: icp_dispatch_list_state icp_dispatch_list_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_list_state
    ADD CONSTRAINT icp_dispatch_list_state_pkey PRIMARY KEY (icp_mining_id);


--
-- Name: icp_dispatch_runs icp_dispatch_runs_dispatch_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_runs
    ADD CONSTRAINT icp_dispatch_runs_dispatch_key_key UNIQUE (dispatch_key);


--
-- Name: icp_dispatch_runs icp_dispatch_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_runs
    ADD CONSTRAINT icp_dispatch_runs_pkey PRIMARY KEY (id);


--
-- Name: icp_dispatch_runs icp_dispatch_runs_workflow_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_runs
    ADD CONSTRAINT icp_dispatch_runs_workflow_id_key UNIQUE (workflow_id);


--
-- Name: icp_dispatch_site_state icp_dispatch_site_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_site_state
    ADD CONSTRAINT icp_dispatch_site_state_pkey PRIMARY KEY (site_id);


--
-- Name: icp_mining icp_mining_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_mining
    ADD CONSTRAINT icp_mining_pkey PRIMARY KEY (id);


--
-- Name: icypeas_email_searches icypeas_email_searches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icypeas_email_searches
    ADD CONSTRAINT icypeas_email_searches_pkey PRIMARY KEY (id);


--
-- Name: icypeas_email_searches icypeas_email_searches_search_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icypeas_email_searches
    ADD CONSTRAINT icypeas_email_searches_search_id_key UNIQUE (search_id);


--
-- Name: icypeas_email_searches icypeas_email_searches_site_id_input_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icypeas_email_searches
    ADD CONSTRAINT icypeas_email_searches_site_id_input_hash_key UNIQUE (site_id, input_hash);


--
-- Name: image_generation_credit_reservations image_generation_credit_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_generation_credit_reservations
    ADD CONSTRAINT image_generation_credit_reservations_pkey PRIMARY KEY (site_id, operation_id);


--
-- Name: instance_artifacts instance_artifacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_artifacts
    ADD CONSTRAINT instance_artifacts_pkey PRIMARY KEY (id);


--
-- Name: instance_context_memories instance_context_memories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_context_memories
    ADD CONSTRAINT instance_context_memories_pkey PRIMARY KEY (id);


--
-- Name: instance_context_memories instance_context_memories_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_context_memories
    ADD CONSTRAINT instance_context_memories_unique UNIQUE (instance_id, start_at, end_at, end_log_id);


--
-- Name: instance_context_state instance_context_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_context_state
    ADD CONSTRAINT instance_context_state_pkey PRIMARY KEY (instance_id);


--
-- Name: instance_logs instance_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_logs
    ADD CONSTRAINT instance_logs_pkey PRIMARY KEY (id);


--
-- Name: instance_node_contexts instance_node_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_node_contexts
    ADD CONSTRAINT instance_node_contexts_pkey PRIMARY KEY (id);


--
-- Name: instance_nodes instance_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_nodes
    ADD CONSTRAINT instance_nodes_pkey PRIMARY KEY (id);


--
-- Name: instance_pending_work instance_pending_work_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_pending_work
    ADD CONSTRAINT instance_pending_work_pkey PRIMARY KEY (id);


--
-- Name: instance_plan_step_infrastructure_events instance_plan_step_infrastructure_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plan_step_infrastructure_events
    ADD CONSTRAINT instance_plan_step_infrastructure_events_pkey PRIMARY KEY (plan_id, step_id, event_id);


--
-- Name: instance_plans instance_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plans
    ADD CONSTRAINT instance_plans_pkey PRIMARY KEY (id);


--
-- Name: insufficient_credit_email_recipient_gates insufficient_credit_email_recipient_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insufficient_credit_email_recipient_gates
    ADD CONSTRAINT insufficient_credit_email_recipient_gates_pkey PRIMARY KEY (recipient_hash);


--
-- Name: insufficient_credit_email_site_gates insufficient_credit_email_site_gates_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insufficient_credit_email_site_gates
    ADD CONSTRAINT insufficient_credit_email_site_gates_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: insufficient_credit_email_site_gates insufficient_credit_email_site_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insufficient_credit_email_site_gates
    ADD CONSTRAINT insufficient_credit_email_site_gates_pkey PRIMARY KEY (site_id);


--
-- Name: inventory_levels inventory_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_levels
    ADD CONSTRAINT inventory_levels_pkey PRIMARY KEY (id);


--
-- Name: invoice_reminders invoice_reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_reminders
    ADD CONSTRAINT invoice_reminders_pkey PRIMARY KEY (id);


--
-- Name: invoice_reminders invoice_reminders_site_id_sale_id_reminder_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_reminders
    ADD CONSTRAINT invoice_reminders_site_id_sale_id_reminder_key_key UNIQUE (site_id, sale_id, reminder_key);


--
-- Name: item_spec_categories item_spec_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_spec_categories
    ADD CONSTRAINT item_spec_categories_pkey PRIMARY KEY (id);


--
-- Name: item_spec_categories item_spec_categories_site_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_spec_categories
    ADD CONSTRAINT item_spec_categories_site_slug_unique UNIQUE (site_id, slug);


--
-- Name: item_specs item_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_specs
    ADD CONSTRAINT item_specs_pkey PRIMARY KEY (id);


--
-- Name: journal_entries journal_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT journal_entries_pkey PRIMARY KEY (id);


--
-- Name: journal_entries journal_entries_site_id_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT journal_entries_site_id_idempotency_key_key UNIQUE (site_id, idempotency_key);


--
-- Name: journal_lines journal_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_pkey PRIMARY KEY (id);


--
-- Name: kpis kpis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpis
    ADD CONSTRAINT kpis_pkey PRIMARY KEY (id);


--
-- Name: layers layers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layers
    ADD CONSTRAINT layers_pkey PRIMARY KEY (id);


--
-- Name: lead_analysis lead_analysis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_analysis
    ADD CONSTRAINT lead_analysis_pkey PRIMARY KEY (id);


--
-- Name: lead_invoice_payment_requests lead_invoice_payment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_invoice_payment_requests
    ADD CONSTRAINT lead_invoice_payment_requests_pkey PRIMARY KEY (request_id);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: leads leads_site_name_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_site_name_email_unique UNIQUE (site_id, name, email);


--
-- Name: location_access_rollout location_access_rollout_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_access_rollout
    ADD CONSTRAINT location_access_rollout_pkey PRIMARY KEY (singleton);


--
-- Name: tasks location_acl_conversation_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.tasks
    ADD CONSTRAINT location_acl_conversation_id_requires_site CHECK (((conversation_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: quotations location_acl_deal_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.quotations
    ADD CONSTRAINT location_acl_deal_id_requires_site CHECK (((deal_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;
