SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: outstand_initial_imports outstand_initial_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outstand_initial_imports
    ADD CONSTRAINT outstand_initial_imports_pkey PRIMARY KEY (account_id);


--
-- Name: partner_licenses partner_licenses_license_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_licenses
    ADD CONSTRAINT partner_licenses_license_key_key UNIQUE (license_key);


--
-- Name: partner_licenses partner_licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_licenses
    ADD CONSTRAINT partner_licenses_pkey PRIMARY KEY (id);


--
-- Name: pass_redeemable_items pass_redeemable_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_redeemable_items
    ADD CONSTRAINT pass_redeemable_items_pkey PRIMARY KEY (id);


--
-- Name: pass_redeemable_items pass_redeemable_items_unique_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_redeemable_items
    ADD CONSTRAINT pass_redeemable_items_unique_pair UNIQUE (pass_catalog_item_id, reservable_catalog_item_id);


--
-- Name: pass_round_robin_state pass_round_robin_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_round_robin_state
    ADD CONSTRAINT pass_round_robin_state_pkey PRIMARY KEY (pass_catalog_item_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: payout_requests payout_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payout_requests
    ADD CONSTRAINT payout_requests_pkey PRIMARY KEY (id);


--
-- Name: persons persons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_pkey PRIMARY KEY (id);


--
-- Name: platform_audit_log platform_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_audit_log
    ADD CONSTRAINT platform_audit_log_pkey PRIMARY KEY (id);


--
-- Name: platform_quotas platform_quotas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_quotas
    ADD CONSTRAINT platform_quotas_pkey PRIMARY KEY (id);


--
-- Name: platform_quotas platform_quotas_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_quotas
    ADD CONSTRAINT platform_quotas_unique UNIQUE (site_id, capability, period);


--
-- Name: platform_tracking_events platform_tracking_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_tracking_events
    ADD CONSTRAINT platform_tracking_events_pkey PRIMARY KEY (id);


--
-- Name: platform_user_roles platform_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_user_roles
    ADD CONSTRAINT platform_user_roles_pkey PRIMARY KEY (user_id);


--
-- Name: pos_checkout_attempts pos_checkout_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_checkout_attempts
    ADD CONSTRAINT pos_checkout_attempts_pkey PRIMARY KEY (site_id, client_mutation_id);


--
-- Name: pos_client_mutations pos_client_mutations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_client_mutations
    ADD CONSTRAINT pos_client_mutations_pkey PRIMARY KEY (id);


--
-- Name: pos_client_mutations pos_client_mutations_site_id_client_mutation_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_client_mutations
    ADD CONSTRAINT pos_client_mutations_site_id_client_mutation_id_key UNIQUE (site_id, client_mutation_id);


--
-- Name: pos_register_movements pos_register_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_movements
    ADD CONSTRAINT pos_register_movements_pkey PRIMARY KEY (id);


--
-- Name: pos_register_movements pos_register_movements_site_id_request_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_movements
    ADD CONSTRAINT pos_register_movements_site_id_request_id_key UNIQUE (site_id, request_id);


--
-- Name: pos_register_receipts pos_register_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_receipts
    ADD CONSTRAINT pos_register_receipts_pkey PRIMARY KEY (id);


--
-- Name: pos_register_sessions pos_register_sessions_id_site_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_sessions
    ADD CONSTRAINT pos_register_sessions_id_site_id_key UNIQUE (id, site_id);


--
-- Name: pos_register_sessions pos_register_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_sessions
    ADD CONSTRAINT pos_register_sessions_pkey PRIMARY KEY (id);


--
-- Name: price_list_items price_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_pkey PRIMARY KEY (id);


--
-- Name: price_lists price_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_lists
    ADD CONSTRAINT price_lists_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: promotion_catalog_categories promotion_catalog_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_categories
    ADD CONSTRAINT promotion_catalog_categories_pkey PRIMARY KEY (id);


--
-- Name: promotion_catalog_items promotion_catalog_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_items
    ADD CONSTRAINT promotion_catalog_items_pkey PRIMARY KEY (id);


--
-- Name: promotion_required_categories promotion_required_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_categories
    ADD CONSTRAINT promotion_required_categories_pkey PRIMARY KEY (id);


--
-- Name: promotion_required_categories promotion_required_categories_promotion_id_catalog_category_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_categories
    ADD CONSTRAINT promotion_required_categories_promotion_id_catalog_category_key UNIQUE (promotion_id, catalog_category_id);


--
-- Name: promotion_required_items promotion_required_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_items
    ADD CONSTRAINT promotion_required_items_pkey PRIMARY KEY (id);


--
-- Name: promotion_required_items promotion_required_items_promotion_id_catalog_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_items
    ADD CONSTRAINT promotion_required_items_promotion_id_catalog_item_id_key UNIQUE (promotion_id, catalog_item_id);


--
-- Name: promotions promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (id);


--
-- Name: purchase_items purchase_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items
    ADD CONSTRAINT purchase_items_pkey PRIMARY KEY (id);


--
-- Name: purchases purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_pkey PRIMARY KEY (id);


--
-- Name: quotation_items quotation_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotation_items
    ADD CONSTRAINT quotation_items_pkey PRIMARY KEY (id);


--
-- Name: quotations quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_pkey PRIMARY KEY (id);


--
-- Name: record_categories record_categories_id_site_uidx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_categories
    ADD CONSTRAINT record_categories_id_site_uidx UNIQUE (id, site_id);


--
-- Name: record_categories record_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_categories
    ADD CONSTRAINT record_categories_pkey PRIMARY KEY (id);


--
-- Name: record_diagram_edges record_diagram_edges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_edges
    ADD CONSTRAINT record_diagram_edges_pkey PRIMARY KEY (id);


--
-- Name: record_diagram_edges record_diagram_edges_unique_semantic_link; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_edges
    ADD CONSTRAINT record_diagram_edges_unique_semantic_link UNIQUE (record_id, source_node_id, target_node_id, relation_type);


--
-- Name: record_diagram_nodes record_diagram_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_nodes
    ADD CONSTRAINT record_diagram_nodes_pkey PRIMARY KEY (id);


--
-- Name: record_diagram_nodes record_diagram_nodes_record_id_id_uidx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_nodes
    ADD CONSTRAINT record_diagram_nodes_record_id_id_uidx UNIQUE (record_id, id);


--
-- Name: record_diagrams record_diagrams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagrams
    ADD CONSTRAINT record_diagrams_pkey PRIMARY KEY (record_id);


--
-- Name: record_diagrams record_diagrams_record_site_uidx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagrams
    ADD CONSTRAINT record_diagrams_record_site_uidx UNIQUE (record_id, site_id);


--
-- Name: record_embedding_jobs record_embedding_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_embedding_jobs
    ADD CONSTRAINT record_embedding_jobs_pkey PRIMARY KEY (id);


--
-- Name: record_embedding_jobs record_embedding_jobs_revision_uidx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_embedding_jobs
    ADD CONSTRAINT record_embedding_jobs_revision_uidx UNIQUE (record_id, diagram_revision, record_revision);


--
-- Name: records records_id_site_uidx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_id_site_uidx UNIQUE (id, site_id);


--
-- Name: records records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_pkey PRIMARY KEY (id);


--
-- Name: referral_code_uses referral_code_uses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_code_uses
    ADD CONSTRAINT referral_code_uses_pkey PRIMARY KEY (id);


--
-- Name: referral_code_uses referral_code_uses_referral_code_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_code_uses
    ADD CONSTRAINT referral_code_uses_referral_code_id_user_id_key UNIQUE (referral_code_id, user_id);


--
-- Name: referral_codes referral_codes_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_codes
    ADD CONSTRAINT referral_codes_code_key UNIQUE (code);


--
-- Name: referral_codes referral_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_codes
    ADD CONSTRAINT referral_codes_pkey PRIMARY KEY (id);


--
-- Name: remote_instances remote_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_instances
    ADD CONSTRAINT remote_instances_pkey PRIMARY KEY (id);


--
-- Name: remote_sessions remote_sessions_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_sessions
    ADD CONSTRAINT remote_sessions_phone_number_key UNIQUE (phone_number);


--
-- Name: remote_sessions remote_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_sessions
    ADD CONSTRAINT remote_sessions_pkey PRIMARY KEY (id);


--
-- Name: requirement_archived_runner_reassignments requirement_archived_runner_r_requirement_id_execution_gene_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_archived_runner_reassignments
    ADD CONSTRAINT requirement_archived_runner_r_requirement_id_execution_gene_key UNIQUE (requirement_id, execution_generation);


--
-- Name: requirement_archived_runner_reassignments requirement_archived_runner_reassignments_instance_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_archived_runner_reassignments
    ADD CONSTRAINT requirement_archived_runner_reassignments_instance_id_key UNIQUE (instance_id);


--
-- Name: requirement_archived_runner_reassignments requirement_archived_runner_reassignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_archived_runner_reassignments
    ADD CONSTRAINT requirement_archived_runner_reassignments_pkey PRIMARY KEY (requirement_id, run_id);


--
-- Name: requirement_commands requirement_commands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_commands
    ADD CONSTRAINT requirement_commands_pkey PRIMARY KEY (requirement_id, action_id);


--
-- Name: requirement_commands requirement_commands_requirement_id_revision_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_commands
    ADD CONSTRAINT requirement_commands_requirement_id_revision_key UNIQUE (requirement_id, revision);


--
-- Name: requirement_cron_cycle_outcomes requirement_cron_cycle_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_cron_cycle_outcomes
    ADD CONSTRAINT requirement_cron_cycle_outcomes_pkey PRIMARY KEY (requirement_id, cycle_id);
