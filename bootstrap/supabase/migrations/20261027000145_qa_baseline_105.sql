SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: kpis kpis_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpis
    ADD CONSTRAINT kpis_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE SET NULL;


--
-- Name: kpis kpis_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpis
    ADD CONSTRAINT kpis_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: kpis kpis_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpis
    ADD CONSTRAINT kpis_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: layers layers_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.layers
    ADD CONSTRAINT layers_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: lead_analysis lead_analysis_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_analysis
    ADD CONSTRAINT lead_analysis_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE SET NULL;


--
-- Name: lead_analysis lead_analysis_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_analysis
    ADD CONSTRAINT lead_analysis_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: lead_invoice_payment_requests lead_invoice_payment_requests_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_invoice_payment_requests
    ADD CONSTRAINT lead_invoice_payment_requests_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id);


--
-- Name: lead_invoice_payment_requests lead_invoice_payment_requests_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lead_invoice_payment_requests
    ADD CONSTRAINT lead_invoice_payment_requests_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: leads leads_assignee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_assignee_id_fkey FOREIGN KEY (assignee_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: leads leads_buyer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_buyer_user_id_fkey FOREIGN KEY (buyer_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: leads leads_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id);


--
-- Name: leads leads_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: leads leads_default_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_default_price_list_id_fkey FOREIGN KEY (default_price_list_id) REFERENCES public.price_lists(id) ON DELETE SET NULL;


--
-- Name: leads leads_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leads leads_referral_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_referral_lead_id_fkey FOREIGN KEY (referral_lead_id) REFERENCES public.leads(id);


--
-- Name: leads leads_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id);


--
-- Name: leads leads_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: leads leads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: conversations location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: deals location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: quotations location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: records location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: reservations location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, operating_location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: sale_orders location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: subscriptions location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: tasks location_acl_location_site_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT location_acl_location_site_fk FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: site_member_location_restrictions location_restrictions_location_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_member_location_restrictions
    ADD CONSTRAINT location_restrictions_location_site_fkey FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE RESTRICT;


--
-- Name: site_member_location_restrictions location_restrictions_member_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_member_location_restrictions
    ADD CONSTRAINT location_restrictions_member_site_fkey FOREIGN KEY (site_id, site_member_id) REFERENCES public.site_members(site_id, id) ON DELETE CASCADE;


--
-- Name: locations locations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: marketplace_actions marketplace_actions_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_actions
    ADD CONSTRAINT marketplace_actions_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES auth.users(id);


--
-- Name: marketplace_actions marketplace_actions_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_actions
    ADD CONSTRAINT marketplace_actions_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.sale_orders(id);


--
-- Name: marketplace_events marketplace_events_integration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_events
    ADD CONSTRAINT marketplace_events_integration_id_fkey FOREIGN KEY (integration_id) REFERENCES public.marketplace_integrations(id);


--
-- Name: marketplace_events marketplace_events_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_events
    ADD CONSTRAINT marketplace_events_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.sale_orders(id);


--
-- Name: marketplace_events marketplace_events_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_events
    ADD CONSTRAINT marketplace_events_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES public.shipments(id);


--
-- Name: marketplace_integrations marketplace_integrations_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES auth.users(id);


--
-- Name: marketplace_integrations marketplace_integrations_merchant_connection_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_merchant_connection_id_fkey FOREIGN KEY (merchant_connection_id) REFERENCES public.marketplace_merchant_connections(id);


--
-- Name: marketplace_integrations marketplace_integrations_origin_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_origin_location_id_fkey FOREIGN KEY (origin_location_id) REFERENCES public.locations(id);


--
-- Name: marketplace_integrations marketplace_integrations_secret_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_secret_id_fkey FOREIGN KEY (secret_id) REFERENCES public.site_secrets(id);


--
-- Name: marketplace_integrations marketplace_integrations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_integrations
    ADD CONSTRAINT marketplace_integrations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: marketplace_merchant_connections marketplace_merchant_connections_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_merchant_connections
    ADD CONSTRAINT marketplace_merchant_connections_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES auth.users(id);


--
-- Name: marketplace_merchant_connections marketplace_merchant_connections_oauth_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_merchant_connections
    ADD CONSTRAINT marketplace_merchant_connections_oauth_session_id_fkey FOREIGN KEY (oauth_session_id) REFERENCES public.marketplace_oauth_sessions(id);


--
-- Name: marketplace_merchant_connections marketplace_merchant_connections_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_merchant_connections
    ADD CONSTRAINT marketplace_merchant_connections_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: marketplace_oauth_sessions marketplace_oauth_sessions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_oauth_sessions
    ADD CONSTRAINT marketplace_oauth_sessions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: marketplace_oauth_sessions marketplace_oauth_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_oauth_sessions
    ADD CONSTRAINT marketplace_oauth_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: marketplace_provider_webhook_keys marketplace_provider_webhook_keys_integration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_provider_webhook_keys
    ADD CONSTRAINT marketplace_provider_webhook_keys_integration_id_fkey FOREIGN KEY (integration_id) REFERENCES public.marketplace_integrations(id);


--
-- Name: marketplace_webhook_registrations marketplace_webhook_registrations_integration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_webhook_registrations
    ADD CONSTRAINT marketplace_webhook_registrations_integration_id_fkey FOREIGN KEY (integration_id) REFERENCES public.marketplace_integrations(id);


--
-- Name: messages messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: modifier_group_items modifier_group_items_catalog_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_group_items
    ADD CONSTRAINT modifier_group_items_catalog_item_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: modifier_group_items modifier_group_items_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_group_items
    ADD CONSTRAINT modifier_group_items_group_fkey FOREIGN KEY (modifier_group_id) REFERENCES public.modifier_groups(id) ON DELETE CASCADE;


--
-- Name: modifier_group_items modifier_group_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_group_items
    ADD CONSTRAINT modifier_group_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: modifier_groups modifier_groups_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_groups
    ADD CONSTRAINT modifier_groups_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: openrouter_generation_charges openrouter_generation_charges_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.openrouter_generation_charges
    ADD CONSTRAINT openrouter_generation_charges_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: partner_licenses partner_licenses_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_licenses
    ADD CONSTRAINT partner_licenses_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: partner_licenses partner_licenses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_licenses
    ADD CONSTRAINT partner_licenses_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: pass_redeemable_items pass_redeemable_items_pass_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_redeemable_items
    ADD CONSTRAINT pass_redeemable_items_pass_catalog_item_id_fkey FOREIGN KEY (pass_catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: pass_redeemable_items pass_redeemable_items_reservable_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_redeemable_items
    ADD CONSTRAINT pass_redeemable_items_reservable_catalog_item_id_fkey FOREIGN KEY (reservable_catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: pass_redeemable_items pass_redeemable_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_redeemable_items
    ADD CONSTRAINT pass_redeemable_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: pass_round_robin_state pass_round_robin_state_last_member_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_round_robin_state
    ADD CONSTRAINT pass_round_robin_state_last_member_fkey FOREIGN KEY (last_member_id) REFERENCES public.catalog_items(id) ON DELETE SET NULL;


--
-- Name: pass_round_robin_state pass_round_robin_state_pass_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_round_robin_state
    ADD CONSTRAINT pass_round_robin_state_pass_fkey FOREIGN KEY (pass_catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;
