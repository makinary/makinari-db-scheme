SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: stripe_sale_checkout_effects stripe_sale_checkout_effects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stripe_sale_checkout_effects
    ADD CONSTRAINT stripe_sale_checkout_effects_pkey PRIMARY KEY (stripe_session_id);


--
-- Name: stripe_subscription_invoice_settlements stripe_subscription_invoice_settlements_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stripe_subscription_invoice_settlements
    ADD CONSTRAINT stripe_subscription_invoice_settlements_payment_id_key UNIQUE (payment_id);


--
-- Name: stripe_subscription_invoice_settlements stripe_subscription_invoice_settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stripe_subscription_invoice_settlements
    ADD CONSTRAINT stripe_subscription_invoice_settlements_pkey PRIMARY KEY (invoice_id);


--
-- Name: subscription_plan_items subscription_plan_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_plan_items
    ADD CONSTRAINT subscription_plan_items_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: synced_objects synced_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.synced_objects
    ADD CONSTRAINT synced_objects_pkey PRIMARY KEY (id);


--
-- Name: system_memories system_memories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_memories
    ADD CONSTRAINT system_memories_pkey PRIMARY KEY (id);


--
-- Name: system_memories system_memories_site_id_system_type_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_memories
    ADD CONSTRAINT system_memories_site_id_system_type_key_key UNIQUE (site_id, system_type, key);


--
-- Name: system_status system_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_status
    ADD CONSTRAINT system_status_pkey PRIMARY KEY (id);


--
-- Name: system_status_runs system_status_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_status_runs
    ADD CONSTRAINT system_status_runs_pkey PRIMARY KEY (id);


--
-- Name: system_telemetry system_telemetry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_telemetry
    ADD CONSTRAINT system_telemetry_pkey PRIMARY KEY (id);


--
-- Name: task_categories task_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_categories
    ADD CONSTRAINT task_categories_pkey PRIMARY KEY (task_id, category_id);


--
-- Name: task_comments task_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: taxes taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: taxes taxes_site_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT taxes_site_name_unique UNIQUE (site_id, name);


--
-- Name: tenant_users tenant_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_users
    ADD CONSTRAINT tenant_users_pkey PRIMARY KEY (tenant_id, user_id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: transitions transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_pkey PRIMARY KEY (id);


--
-- Name: persons uniq_persons_ext; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT uniq_persons_ext UNIQUE (external_person_id, external_role_id);


--
-- Name: audience_leads unique_audience_lead; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audience_leads
    ADD CONSTRAINT unique_audience_lead UNIQUE (audience_id, lead_id);


--
-- Name: allowed_domains unique_domain_per_site; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowed_domains
    ADD CONSTRAINT unique_domain_per_site UNIQUE (site_id, domain);


--
-- Name: instance_node_contexts unique_node_context; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_node_contexts
    ADD CONSTRAINT unique_node_context UNIQUE (target_node_id, context_node_id);


--
-- Name: inventory_levels uq_inventory_levels_catalog_location; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_levels
    ADD CONSTRAINT uq_inventory_levels_catalog_location UNIQUE (catalog_item_id, location_id);


--
-- Name: price_list_items uq_price_list_items_list_catalog; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT uq_price_list_items_list_catalog UNIQUE (price_list_id, catalog_item_id);


--
-- Name: promotion_catalog_categories uq_promotion_catalog_categories; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_categories
    ADD CONSTRAINT uq_promotion_catalog_categories UNIQUE (promotion_id, catalog_category_id);


--
-- Name: promotion_catalog_items uq_promotion_catalog_items; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_items
    ADD CONSTRAINT uq_promotion_catalog_items UNIQUE (promotion_id, catalog_item_id);


--
-- Name: user_shortcuts user_shortcuts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_shortcuts
    ADD CONSTRAINT user_shortcuts_pkey PRIMARY KEY (user_id, site_id);


--
-- Name: user_site_notifications user_site_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_site_notifications
    ADD CONSTRAINT user_site_notifications_pkey PRIMARY KEY (user_id, site_id);


--
-- Name: variants variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variants
    ADD CONSTRAINT variants_pkey PRIMARY KEY (id);


--
-- Name: variants variants_state_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variants
    ADD CONSTRAINT variants_state_id_name_key UNIQUE (state_id, name);


--
-- Name: visitor_external_identities visitor_external_identities_lead_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_external_identities
    ADD CONSTRAINT visitor_external_identities_lead_id_key UNIQUE (lead_id);


--
-- Name: visitor_external_identities visitor_external_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_external_identities
    ADD CONSTRAINT visitor_external_identities_pkey PRIMARY KEY (id);


--
-- Name: visitor_external_identities visitor_external_identities_site_id_issuer_external_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_external_identities
    ADD CONSTRAINT visitor_external_identities_site_id_issuer_external_user_id_key UNIQUE (site_id, issuer, external_user_id);


--
-- Name: visitor_identity_attributes visitor_identity_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_attributes
    ADD CONSTRAINT visitor_identity_attributes_pkey PRIMARY KEY (session_id);


--
-- Name: visitor_identity_challenges visitor_identity_challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_challenges
    ADD CONSTRAINT visitor_identity_challenges_pkey PRIMARY KEY (id);


--
-- Name: visitor_identity_session_state visitor_identity_session_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_session_state
    ADD CONSTRAINT visitor_identity_session_state_pkey PRIMARY KEY (session_id);


--
-- Name: visitor_identity_token_redemptions visitor_identity_token_redemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_token_redemptions
    ADD CONSTRAINT visitor_identity_token_redemptions_pkey PRIMARY KEY (jti);


--
-- Name: visitor_session_identity_grants visitor_session_identity_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_session_identity_grants
    ADD CONSTRAINT visitor_session_identity_grants_pkey PRIMARY KEY (id);


--
-- Name: visitor_session_identity_grants visitor_session_identity_grants_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_session_identity_grants
    ADD CONSTRAINT visitor_session_identity_grants_session_id_key UNIQUE (session_id);


--
-- Name: visitor_sessions visitor_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_sessions
    ADD CONSTRAINT visitor_sessions_pkey PRIMARY KEY (id);


--
-- Name: visitors visitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitors
    ADD CONSTRAINT visitors_pkey PRIMARY KEY (id);


--
-- Name: voice_call_deliveries voice_call_deliveries_message_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_call_deliveries
    ADD CONSTRAINT voice_call_deliveries_message_unique UNIQUE (message_id);


--
-- Name: voice_call_deliveries voice_call_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_call_deliveries
    ADD CONSTRAINT voice_call_deliveries_pkey PRIMARY KEY (id);


--
-- Name: waitlist waitlist_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_email_key UNIQUE (email);


--
-- Name: waitlist waitlist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_pkey PRIMARY KEY (id);


--
-- Name: webhook_events webhook_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_events
    ADD CONSTRAINT webhook_events_pkey PRIMARY KEY (id);


--
-- Name: webhook_events webhook_events_stripe_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_events
    ADD CONSTRAINT webhook_events_stripe_event_id_key UNIQUE (stripe_event_id);


--
-- Name: webhooks_deliveries webhooks_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_deliveries
    ADD CONSTRAINT webhooks_deliveries_pkey PRIMARY KEY (id);


--
-- Name: webhooks_endpoints webhooks_endpoints_name_per_site_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_endpoints
    ADD CONSTRAINT webhooks_endpoints_name_per_site_unique UNIQUE (site_id, name);


--
-- Name: webhooks_endpoints webhooks_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_endpoints
    ADD CONSTRAINT webhooks_endpoints_pkey PRIMARY KEY (id);


--
-- Name: webhooks_subscriptions webhooks_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_subscriptions
    ADD CONSTRAINT webhooks_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: webhooks_subscriptions webhooks_subscriptions_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_subscriptions
    ADD CONSTRAINT webhooks_subscriptions_unique UNIQUE (endpoint_id, event_type);


--
-- Name: whatsapp_templates whatsapp_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whatsapp_templates
    ADD CONSTRAINT whatsapp_templates_pkey PRIMARY KEY (id);


--
-- Name: whatsapp_templates whatsapp_templates_unique_name_site; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whatsapp_templates
    ADD CONSTRAINT whatsapp_templates_unique_name_site UNIQUE (template_name, site_id);


--
-- Name: whatsapp_templates whatsapp_templates_unique_sid; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whatsapp_templates
    ADD CONSTRAINT whatsapp_templates_unique_sid UNIQUE (template_sid);


--
-- Name: workflow_runs workflow_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_pkey PRIMARY KEY (id);


--
-- Name: workflow_triggers workflow_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_triggers
    ADD CONSTRAINT workflow_triggers_pkey PRIMARY KEY (id);


--
-- Name: provider_webhook_events_stale_claim_idx; Type: INDEX; Schema: private; Owner: -
--

CREATE INDEX provider_webhook_events_stale_claim_idx ON private.provider_webhook_events USING btree (claim_expires_at) WHERE (status = 'processing'::text);


--
-- Name: accounting_accounts_site_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting_accounts_site_key_idx ON public.accounting_accounts USING btree (site_id, key) WHERE (key IS NOT NULL);
