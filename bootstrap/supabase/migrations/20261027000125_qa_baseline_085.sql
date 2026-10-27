SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: requirement_economic_pauses requirement_economic_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_economic_pauses
    ADD CONSTRAINT requirement_economic_pauses_pkey PRIMARY KEY (requirement_id);


--
-- Name: requirement_harness_decisions requirement_harness_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_harness_decisions
    ADD CONSTRAINT requirement_harness_decisions_pkey PRIMARY KEY (id);


--
-- Name: requirement_harness_decisions requirement_harness_decisions_requirement_id_request_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_harness_decisions
    ADD CONSTRAINT requirement_harness_decisions_requirement_id_request_id_key UNIQUE (requirement_id, request_id);


--
-- Name: requirement_migration_diagnostics requirement_migration_diagnostics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_diagnostics
    ADD CONSTRAINT requirement_migration_diagnostics_pkey PRIMARY KEY (requirement_id, file);


--
-- Name: requirement_migration_execution_handoffs requirement_migration_execution_handoff_requirement_id_file_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_execution_handoffs
    ADD CONSTRAINT requirement_migration_execution_handoff_requirement_id_file_key UNIQUE (requirement_id, file);


--
-- Name: requirement_migration_execution_handoffs requirement_migration_execution_handoffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_execution_handoffs
    ADD CONSTRAINT requirement_migration_execution_handoffs_pkey PRIMARY KEY (id);


--
-- Name: requirement_migration_lifecycle requirement_migration_lifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_lifecycle
    ADD CONSTRAINT requirement_migration_lifecycle_pkey PRIMARY KEY (requirement_id, file);


--
-- Name: requirement_migration_reconciliation_resumes requirement_migration_reconciliation_resumes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliation_resumes
    ADD CONSTRAINT requirement_migration_reconciliation_resumes_pkey PRIMARY KEY (receipt_id);


--
-- Name: requirement_migration_reconciliations requirement_migration_reconciliations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliations
    ADD CONSTRAINT requirement_migration_reconciliations_pkey PRIMARY KEY (id);


--
-- Name: requirement_migration_reconciliations requirement_migration_reconciliations_requirement_id_file_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliations
    ADD CONSTRAINT requirement_migration_reconciliations_requirement_id_file_key UNIQUE (requirement_id, file);


--
-- Name: requirement_migration_retirements requirement_migration_retirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_retirements
    ADD CONSTRAINT requirement_migration_retirements_pkey PRIMARY KEY (id);


--
-- Name: requirement_migration_retirements requirement_migration_retirements_requirement_id_file_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_retirements
    ADD CONSTRAINT requirement_migration_retirements_requirement_id_file_key UNIQUE (requirement_id, file);


--
-- Name: requirement_segments requirement_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_segments
    ADD CONSTRAINT requirement_segments_pkey PRIMARY KEY (requirement_id, segment_id);


--
-- Name: requirement_source_checkpoints requirement_source_checkpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_source_checkpoints
    ADD CONSTRAINT requirement_source_checkpoints_pkey PRIMARY KEY (requirement_id);


--
-- Name: requirement_status requirement_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_status
    ADD CONSTRAINT requirement_status_pkey PRIMARY KEY (id);


--
-- Name: requirement_user_action_receipts requirement_user_action_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_user_action_receipts
    ADD CONSTRAINT requirement_user_action_receipts_pkey PRIMARY KEY (requirement_id, action_id);


--
-- Name: requirement_user_action_receipts requirement_user_action_receipts_requirement_id_revision_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_user_action_receipts
    ADD CONSTRAINT requirement_user_action_receipts_requirement_id_revision_key UNIQUE (requirement_id, revision);


--
-- Name: requirements requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirements
    ADD CONSTRAINT requirements_pkey PRIMARY KEY (id);


--
-- Name: reservation_schedules reservation_schedules_catalog_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_schedules
    ADD CONSTRAINT reservation_schedules_catalog_item_id_key UNIQUE (catalog_item_id);


--
-- Name: reservation_schedules reservation_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_schedules
    ADD CONSTRAINT reservation_schedules_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: role_queries role_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_queries
    ADD CONSTRAINT role_queries_pkey PRIMARY KEY (id);


--
-- Name: role_queries role_queries_query_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_queries
    ADD CONSTRAINT role_queries_query_hash_key UNIQUE (query_hash);


--
-- Name: role_query_segments role_query_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_query_segments
    ADD CONSTRAINT role_query_segments_pkey PRIMARY KEY (id);


--
-- Name: role_query_segments role_query_segments_role_query_id_segment_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_query_segments
    ADD CONSTRAINT role_query_segments_role_query_id_segment_id_key UNIQUE (role_query_id, segment_id);


--
-- Name: sale_order_item_units sale_order_item_units_item_index_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item_units
    ADD CONSTRAINT sale_order_item_units_item_index_key UNIQUE (sale_order_item_id, unit_index);


--
-- Name: sale_order_item_units sale_order_item_units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item_units
    ADD CONSTRAINT sale_order_item_units_pkey PRIMARY KEY (id);


--
-- Name: sale_order_items sale_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_pkey PRIMARY KEY (id);


--
-- Name: sale_orders sale_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_pkey PRIMARY KEY (id);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: sandbox_billing_resources sandbox_billing_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sandbox_billing_resources
    ADD CONSTRAINT sandbox_billing_resources_pkey PRIMARY KEY (sandbox_name);


--
-- Name: sandbox_billing_sessions sandbox_billing_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sandbox_billing_sessions
    ADD CONSTRAINT sandbox_billing_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: secure_tokens secure_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secure_tokens
    ADD CONSTRAINT secure_tokens_pkey PRIMARY KEY (id);


--
-- Name: secure_tokens secure_tokens_site_id_token_type_identifier_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secure_tokens
    ADD CONSTRAINT secure_tokens_site_id_token_type_identifier_key UNIQUE (site_id, token_type, identifier);


--
-- Name: segments segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.segments
    ADD CONSTRAINT segments_pkey PRIMARY KEY (id);


--
-- Name: self_service_inventory_releases self_service_inventory_releases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_service_inventory_releases
    ADD CONSTRAINT self_service_inventory_releases_pkey PRIMARY KEY (sale_order_item_id);


--
-- Name: session_events session_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_events
    ADD CONSTRAINT session_events_pkey PRIMARY KEY (id);


--
-- Name: session_recording_chunks session_recording_chunks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_recording_chunks
    ADD CONSTRAINT session_recording_chunks_pkey PRIMARY KEY (chunk_id);


--
-- Name: session_recording_chunks session_recording_chunks_storage_path_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_recording_chunks
    ADD CONSTRAINT session_recording_chunks_storage_path_key UNIQUE (storage_path);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: settings settings_site_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_site_id_key UNIQUE (site_id);


--
-- Name: setup_email_delivery_receipts setup_email_delivery_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_email_delivery_receipts
    ADD CONSTRAINT setup_email_delivery_receipts_pkey PRIMARY KEY (operation_key);


--
-- Name: shipment_location_pings shipment_location_pings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_location_pings
    ADD CONSTRAINT shipment_location_pings_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_pkey PRIMARY KEY (id);


--
-- Name: site_member_location_restriction_audit site_member_location_restrict_site_id_site_member_id_revisi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_member_location_restriction_audit
    ADD CONSTRAINT site_member_location_restrict_site_id_site_member_id_revisi_key UNIQUE (site_id, site_member_id, revision);


--
-- Name: site_member_location_restriction_audit site_member_location_restriction_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_member_location_restriction_audit
    ADD CONSTRAINT site_member_location_restriction_audit_pkey PRIMARY KEY (id);


--
-- Name: site_member_location_restrictions site_member_location_restrictions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_member_location_restrictions
    ADD CONSTRAINT site_member_location_restrictions_pkey PRIMARY KEY (site_id, site_member_id, location_id);


--
-- Name: site_members site_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_members
    ADD CONSTRAINT site_members_pkey PRIMARY KEY (id);


--
-- Name: site_members site_members_site_id_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_members
    ADD CONSTRAINT site_members_site_id_email_key UNIQUE (site_id, email);


--
-- Name: site_members site_members_site_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_members
    ADD CONSTRAINT site_members_site_id_user_id_key UNIQUE (site_id, user_id);


--
-- Name: site_ownership site_ownership_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_ownership
    ADD CONSTRAINT site_ownership_pkey PRIMARY KEY (site_id);


--
-- Name: site_retired_stripe_subscriptions site_retired_stripe_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_retired_stripe_subscriptions
    ADD CONSTRAINT site_retired_stripe_subscriptions_pkey PRIMARY KEY (site_id, subscription_id);


--
-- Name: site_secrets site_secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_secrets
    ADD CONSTRAINT site_secrets_pkey PRIMARY KEY (id);


--
-- Name: site_skills site_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_skills
    ADD CONSTRAINT site_skills_pkey PRIMARY KEY (id);


--
-- Name: site_skills site_skills_site_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_skills
    ADD CONSTRAINT site_skills_site_id_slug_key UNIQUE (site_id, slug);


--
-- Name: site_startup_trials site_startup_trials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_startup_trials
    ADD CONSTRAINT site_startup_trials_pkey PRIMARY KEY (primary_owner_id);


--
-- Name: site_startup_trials site_startup_trials_site_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_startup_trials
    ADD CONSTRAINT site_startup_trials_site_id_key UNIQUE (site_id);


--
-- Name: site_subscription_checkout_leases site_subscription_checkout_leases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_subscription_checkout_leases
    ADD CONSTRAINT site_subscription_checkout_leases_pkey PRIMARY KEY (site_id);


--
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: social_comment_sync_state social_comment_sync_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_comment_sync_state
    ADD CONSTRAINT social_comment_sync_state_pkey PRIMARY KEY (site_id, outstand_post_id, network);
