SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: tasks location_acl_deal_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.tasks
    ADD CONSTRAINT location_acl_deal_id_requires_site CHECK (((deal_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: tasks location_acl_lead_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.tasks
    ADD CONSTRAINT location_acl_lead_id_requires_site CHECK (((lead_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: purchase_items location_acl_purchase_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.purchase_items
    ADD CONSTRAINT location_acl_purchase_id_requires_site CHECK (((purchase_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sale_orders location_acl_quotation_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sale_orders
    ADD CONSTRAINT location_acl_quotation_id_requires_site CHECK (((quotation_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sales location_acl_quotation_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sales
    ADD CONSTRAINT location_acl_quotation_id_requires_site CHECK (((quotation_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: accounting_sale_refunds location_acl_sale_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.accounting_sale_refunds
    ADD CONSTRAINT location_acl_sale_id_requires_site CHECK (((sale_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: invoice_reminders location_acl_sale_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.invoice_reminders
    ADD CONSTRAINT location_acl_sale_id_requires_site CHECK (((sale_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: pos_register_receipts location_acl_sale_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.pos_register_receipts
    ADD CONSTRAINT location_acl_sale_id_requires_site CHECK (((sale_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sale_orders location_acl_sale_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sale_orders
    ADD CONSTRAINT location_acl_sale_id_requires_site CHECK (((sale_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: shipments location_acl_sale_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.shipments
    ADD CONSTRAINT location_acl_sale_id_requires_site CHECK (((sale_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sale_order_items location_acl_sale_order_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sale_order_items
    ADD CONSTRAINT location_acl_sale_order_id_requires_site CHECK (((sale_order_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: shipments location_acl_sale_order_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.shipments
    ADD CONSTRAINT location_acl_sale_order_id_requires_site CHECK (((sale_order_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: transactions location_acl_sale_order_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.transactions
    ADD CONSTRAINT location_acl_sale_order_id_requires_site CHECK (((sale_order_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: reservations location_acl_sale_order_item_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.reservations
    ADD CONSTRAINT location_acl_sale_order_item_id_requires_site CHECK (((sale_order_item_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sale_order_item_units location_acl_sale_order_item_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sale_order_item_units
    ADD CONSTRAINT location_acl_sale_order_item_id_requires_site CHECK (((sale_order_item_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: conversations location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.conversations
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: deals location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.deals
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: inventory_levels location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.inventory_levels
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: pos_register_sessions location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.pos_register_sessions
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: purchases location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.purchases
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: quotations location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.quotations
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: records location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.records
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: reservations location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.reservations
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((operating_location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sale_orders location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sale_orders
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sales location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sales
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: shipments location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.shipments
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((origin_location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: subscriptions location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: tasks location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.tasks
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: transactions location_acl_scope_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.transactions
    ADD CONSTRAINT location_acl_scope_requires_site CHECK (((location_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: pos_register_movements location_acl_session_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.pos_register_movements
    ADD CONSTRAINT location_acl_session_id_requires_site CHECK (((session_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: pos_register_receipts location_acl_session_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.pos_register_receipts
    ADD CONSTRAINT location_acl_session_id_requires_site CHECK (((session_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sale_order_item_units location_acl_shipment_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sale_order_item_units
    ADD CONSTRAINT location_acl_shipment_id_requires_site CHECK (((shipment_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sale_order_items location_acl_shipment_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sale_order_items
    ADD CONSTRAINT location_acl_shipment_id_requires_site CHECK (((shipment_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: shipment_location_pings location_acl_shipment_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.shipment_location_pings
    ADD CONSTRAINT location_acl_shipment_id_requires_site CHECK (((shipment_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: sales location_acl_subscription_id_requires_site; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.sales
    ADD CONSTRAINT location_acl_subscription_id_requires_site CHECK (((subscription_id IS NULL) OR (site_id IS NOT NULL))) NOT VALID;


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: marketplace_actions marketplace_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_actions
    ADD CONSTRAINT marketplace_actions_pkey PRIMARY KEY (id);


--
-- Name: marketplace_events marketplace_events_integration_id_event_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_events
    ADD CONSTRAINT marketplace_events_integration_id_event_key_key UNIQUE (integration_id, event_key);


--
-- Name: marketplace_events marketplace_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_events
    ADD CONSTRAINT marketplace_events_pkey PRIMARY KEY (id);


--
-- Name: marketplace_integrations marketplace_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_pkey PRIMARY KEY (id);


--
-- Name: marketplace_integrations marketplace_integrations_provider_environment_external_stor_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_provider_environment_external_stor_key UNIQUE (provider, environment, external_store_id);


--
-- Name: marketplace_integrations marketplace_integrations_secret_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_secret_id_key UNIQUE (secret_id);


--
-- Name: marketplace_merchant_connections marketplace_merchant_connections_oauth_session_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_merchant_connections
    ADD CONSTRAINT marketplace_merchant_connections_oauth_session_id_key UNIQUE (oauth_session_id);


--
-- Name: marketplace_merchant_connections marketplace_merchant_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_merchant_connections
    ADD CONSTRAINT marketplace_merchant_connections_pkey PRIMARY KEY (id);


--
-- Name: marketplace_oauth_sessions marketplace_oauth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_oauth_sessions
    ADD CONSTRAINT marketplace_oauth_sessions_pkey PRIMARY KEY (id);


--
-- Name: marketplace_oauth_sessions marketplace_oauth_sessions_state_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_oauth_sessions
    ADD CONSTRAINT marketplace_oauth_sessions_state_hash_key UNIQUE (state_hash);


--
-- Name: marketplace_platform_apps marketplace_platform_apps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_platform_apps
    ADD CONSTRAINT marketplace_platform_apps_pkey PRIMARY KEY (id);


--
-- Name: marketplace_platform_apps marketplace_platform_apps_provider_environment_country_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_platform_apps
    ADD CONSTRAINT marketplace_platform_apps_provider_environment_country_key UNIQUE (provider, environment, country);


--
-- Name: marketplace_provider_webhook_keys marketplace_provider_webhook__app_client_id_hash_provider_e_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_provider_webhook_keys
    ADD CONSTRAINT marketplace_provider_webhook__app_client_id_hash_provider_e_key UNIQUE NULLS NOT DISTINCT (app_client_id_hash, provider, environment, country, integration_id, event);


--
-- Name: marketplace_provider_webhook_keys marketplace_provider_webhook_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_provider_webhook_keys
    ADD CONSTRAINT marketplace_provider_webhook_keys_pkey PRIMARY KEY (id);


--
-- Name: marketplace_rebind_permits marketplace_rebind_permits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_rebind_permits
    ADD CONSTRAINT marketplace_rebind_permits_pkey PRIMARY KEY (id);


--
-- Name: marketplace_webhook_registration_apps marketplace_webhook_registrat_app_client_id_hash_provider__key1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_webhook_registration_apps
    ADD CONSTRAINT marketplace_webhook_registrat_app_client_id_hash_provider__key1 UNIQUE NULLS NOT DISTINCT (app_client_id_hash, provider, environment, country);


--
-- Name: marketplace_webhook_registrations marketplace_webhook_registrat_app_client_id_hash_provider_e_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_webhook_registrations
    ADD CONSTRAINT marketplace_webhook_registrat_app_client_id_hash_provider_e_key UNIQUE NULLS NOT DISTINCT (app_client_id_hash, provider, environment, country, integration_id, event);


--
-- Name: marketplace_webhook_registration_apps marketplace_webhook_registration_apps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_webhook_registration_apps
    ADD CONSTRAINT marketplace_webhook_registration_apps_pkey PRIMARY KEY (claim_id);


--
-- Name: marketplace_webhook_registrations marketplace_webhook_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_webhook_registrations
    ADD CONSTRAINT marketplace_webhook_registrations_pkey PRIMARY KEY (claim_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: modifier_group_items modifier_group_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_group_items
    ADD CONSTRAINT modifier_group_items_pkey PRIMARY KEY (id);


--
-- Name: modifier_group_items modifier_group_items_unique_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_group_items
    ADD CONSTRAINT modifier_group_items_unique_pair UNIQUE (modifier_group_id, catalog_item_id);


--
-- Name: modifier_groups modifier_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_groups
    ADD CONSTRAINT modifier_groups_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: openrouter_generation_charges openrouter_generation_charges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.openrouter_generation_charges
    ADD CONSTRAINT openrouter_generation_charges_pkey PRIMARY KEY (event_id);
