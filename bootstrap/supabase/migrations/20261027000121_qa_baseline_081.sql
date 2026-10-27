SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: apps_migration_feedback apps_migration_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apps_migration_feedback
    ADD CONSTRAINT apps_migration_feedback_pkey PRIMARY KEY (target_schema, migration_key);


--
-- Name: apps_tenants apps_tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apps_tenants
    ADD CONSTRAINT apps_tenants_pkey PRIMARY KEY (tenant_id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: audience_leads audience_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audience_leads
    ADD CONSTRAINT audience_leads_pkey PRIMARY KEY (id);


--
-- Name: audiences audiences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audiences
    ADD CONSTRAINT audiences_pkey PRIMARY KEY (id);


--
-- Name: automation_auth_sessions automation_auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automation_auth_sessions
    ADD CONSTRAINT automation_auth_sessions_pkey PRIMARY KEY (id);


--
-- Name: automation_auth_sessions automation_auth_sessions_site_domain_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automation_auth_sessions
    ADD CONSTRAINT automation_auth_sessions_site_domain_name_unique UNIQUE (site_id, domain, name);


--
-- Name: billing_credit_grant_keys billing_credit_grant_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_credit_grant_keys
    ADD CONSTRAINT billing_credit_grant_keys_pkey PRIMARY KEY (idempotency_key);


--
-- Name: billing_credit_migration_audit billing_credit_migration_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_credit_migration_audit
    ADD CONSTRAINT billing_credit_migration_audit_pkey PRIMARY KEY (site_id);


--
-- Name: billing billing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_pkey PRIMARY KEY (id);


--
-- Name: calendar_blocks calendar_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_blocks
    ADD CONSTRAINT calendar_blocks_pkey PRIMARY KEY (id);


--
-- Name: campaign_requirements campaign_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_requirements
    ADD CONSTRAINT campaign_requirements_pkey PRIMARY KEY (campaign_id, requirement_id);


--
-- Name: campaign_segments campaign_segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_segments
    ADD CONSTRAINT campaign_segments_pkey PRIMARY KEY (campaign_id, segment_id);


--
-- Name: campaign_subtasks campaign_subtasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_subtasks
    ADD CONSTRAINT campaign_subtasks_pkey PRIMARY KEY (id);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: catalog_categories catalog_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_categories
    ADD CONSTRAINT catalog_categories_pkey PRIMARY KEY (id);


--
-- Name: catalog_embedding_jobs catalog_embedding_jobs_catalog_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_embedding_jobs
    ADD CONSTRAINT catalog_embedding_jobs_catalog_item_id_key UNIQUE (catalog_item_id);


--
-- Name: catalog_embedding_jobs catalog_embedding_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_embedding_jobs
    ADD CONSTRAINT catalog_embedding_jobs_pkey PRIMARY KEY (id);


--
-- Name: catalog_import_batches catalog_import_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_import_batches
    ADD CONSTRAINT catalog_import_batches_pkey PRIMARY KEY (site_id, request_id);


--
-- Name: catalog_item_modifier_groups catalog_item_modifier_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_modifier_groups
    ADD CONSTRAINT catalog_item_modifier_groups_pkey PRIMARY KEY (id);


--
-- Name: catalog_item_modifier_groups catalog_item_modifier_groups_unique_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_modifier_groups
    ADD CONSTRAINT catalog_item_modifier_groups_unique_pair UNIQUE (catalog_item_id, modifier_group_id);


--
-- Name: catalog_item_requirements catalog_item_requirements_catalog_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_catalog_item_id_key UNIQUE (catalog_item_id);


--
-- Name: catalog_item_requirements catalog_item_requirements_instance_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_instance_id_key UNIQUE (instance_id);


--
-- Name: catalog_item_requirements catalog_item_requirements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_pkey PRIMARY KEY (id);


--
-- Name: catalog_item_requirements catalog_item_requirements_requirement_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_requirement_id_key UNIQUE (requirement_id);


--
-- Name: catalog_item_specs catalog_item_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_specs
    ADD CONSTRAINT catalog_item_specs_pkey PRIMARY KEY (catalog_item_id, item_spec_id);


--
-- Name: catalog_item_taxes catalog_item_taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_taxes
    ADD CONSTRAINT catalog_item_taxes_pkey PRIMARY KEY (id);


--
-- Name: catalog_item_taxes catalog_item_taxes_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_taxes
    ADD CONSTRAINT catalog_item_taxes_unique UNIQUE (catalog_item_id, tax_id);


--
-- Name: catalog_items catalog_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_items
    ADD CONSTRAINT catalog_items_pkey PRIMARY KEY (id);


--
-- Name: catalog_search_documents catalog_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_search_documents
    ADD CONSTRAINT catalog_search_documents_pkey PRIMARY KEY (catalog_item_id);


--
-- Name: catalog_search_refresh_events catalog_search_refresh_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_search_refresh_events
    ADD CONSTRAINT catalog_search_refresh_events_pkey PRIMARY KEY (id);


--
-- Name: catalog_search_revision_events catalog_search_revision_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_search_revision_events
    ADD CONSTRAINT catalog_search_revision_events_pkey PRIMARY KEY (id);


--
-- Name: catalog_search_revisions catalog_search_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_search_revisions
    ADD CONSTRAINT catalog_search_revisions_pkey PRIMARY KEY (scope);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: channel_health_events channel_health_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_health_events
    ADD CONSTRAINT channel_health_events_pkey PRIMARY KEY (id);


--
-- Name: channel_health_events channel_health_events_source_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_health_events
    ADD CONSTRAINT channel_health_events_source_unique UNIQUE (site_id, channel, direction, source_id);


--
-- Name: channel_health channel_health_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_health
    ADD CONSTRAINT channel_health_pkey PRIMARY KEY (site_id, channel, direction);


--
-- Name: commands commands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: content_assets content_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_assets
    ADD CONSTRAINT content_assets_pkey PRIMARY KEY (content_id, asset_id);


--
-- Name: content_performance content_performance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_performance
    ADD CONSTRAINT content_performance_pkey PRIMARY KEY (id);


--
-- Name: content_performance content_performance_site_id_outstand_post_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_performance
    ADD CONSTRAINT content_performance_site_id_outstand_post_id_key UNIQUE (site_id, outstand_post_id);


--
-- Name: content content_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: copywriting copywriting_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.copywriting
    ADD CONSTRAINT copywriting_pkey PRIMARY KEY (id);


--
-- Name: copywriting copywriting_site_user_title_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.copywriting
    ADD CONSTRAINT copywriting_site_user_title_unique UNIQUE (site_id, user_id, title);


--
-- Name: credit_auto_top_up_attempts credit_auto_top_up_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_attempts
    ADD CONSTRAINT credit_auto_top_up_attempts_pkey PRIMARY KEY (id);


--
-- Name: credit_auto_top_up_attempts credit_auto_top_up_attempts_stripe_payment_intent_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_attempts
    ADD CONSTRAINT credit_auto_top_up_attempts_stripe_payment_intent_id_key UNIQUE (stripe_payment_intent_id);


--
-- Name: credit_auto_top_up_card_setups credit_auto_top_up_card_setups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_card_setups
    ADD CONSTRAINT credit_auto_top_up_card_setups_pkey PRIMARY KEY (site_id);


--
-- Name: credit_auto_top_up_card_setups credit_auto_top_up_card_setups_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_card_setups
    ADD CONSTRAINT credit_auto_top_up_card_setups_token_key UNIQUE (token);


--
-- Name: credit_auto_top_up_consent_log credit_auto_top_up_consent_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_consent_log
    ADD CONSTRAINT credit_auto_top_up_consent_log_pkey PRIMARY KEY (id);


--
-- Name: credit_auto_top_up_settings credit_auto_top_up_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_settings
    ADD CONSTRAINT credit_auto_top_up_settings_pkey PRIMARY KEY (site_id);


--
-- Name: credit_transactions credit_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_transactions
    ADD CONSTRAINT credit_transactions_pkey PRIMARY KEY (id);


--
-- Name: cron_status cron_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cron_status
    ADD CONSTRAINT cron_status_pkey PRIMARY KEY (id);


--
-- Name: customizations customizations_element_id_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customizations
    ADD CONSTRAINT customizations_element_id_key_key UNIQUE (element_id, key);


--
-- Name: customizations customizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customizations
    ADD CONSTRAINT customizations_pkey PRIMARY KEY (id);


--
-- Name: deal_leads deal_leads_deal_id_lead_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_leads
    ADD CONSTRAINT deal_leads_deal_id_lead_id_key UNIQUE (deal_id, lead_id);


--
-- Name: deal_leads deal_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_leads
    ADD CONSTRAINT deal_leads_pkey PRIMARY KEY (id);


--
-- Name: deal_owners deal_owners_deal_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_owners
    ADD CONSTRAINT deal_owners_deal_id_user_id_key UNIQUE (deal_id, user_id);


--
-- Name: deal_owners deal_owners_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_owners
    ADD CONSTRAINT deal_owners_pkey PRIMARY KEY (id);


--
-- Name: deals deals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_pkey PRIMARY KEY (id);
