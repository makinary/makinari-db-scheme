SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: sale_order_items sale_order_items_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE SET NULL;


--
-- Name: sale_order_items sale_order_items_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE SET NULL;


--
-- Name: sale_order_items sale_order_items_parent_sale_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_parent_sale_order_item_id_fkey FOREIGN KEY (parent_sale_order_item_id) REFERENCES public.sale_order_items(id) ON DELETE CASCADE;


--
-- Name: sale_order_items sale_order_items_sale_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_sale_order_id_fkey FOREIGN KEY (site_id, sale_order_id) REFERENCES public.sale_orders(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: sale_order_items sale_order_items_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_shipment_id_fkey FOREIGN KEY (site_id, shipment_id) REFERENCES public.shipments(site_id, id) ON DELETE SET NULL (shipment_id) NOT VALID;


--
-- Name: sale_order_items sale_order_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: sale_orders sale_orders_buyer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_buyer_user_id_fkey FOREIGN KEY (buyer_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_marketplace_integration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_marketplace_integration_id_fkey FOREIGN KEY (marketplace_integration_id) REFERENCES public.marketplace_integrations(id);


--
-- Name: sale_orders sale_orders_origin_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_origin_location_id_fkey FOREIGN KEY (origin_location_id) REFERENCES public.locations(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_owner_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_owner_site_id_fkey FOREIGN KEY (owner_site_id) REFERENCES public.sites(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_quotation_id_fkey FOREIGN KEY (site_id, quotation_id) REFERENCES public.quotations(site_id, id) ON DELETE SET NULL (quotation_id) NOT VALID;


--
-- Name: sale_orders sale_orders_requested_by_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_requested_by_lead_id_fkey FOREIGN KEY (requested_by_lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_sale_id_fkey FOREIGN KEY (site_id, sale_id) REFERENCES public.sales(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: sale_orders sale_orders_seller_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_seller_user_id_fkey FOREIGN KEY (seller_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: sale_orders sale_orders_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_orders
    ADD CONSTRAINT sale_orders_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: sales sales_buyer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_buyer_user_id_fkey FOREIGN KEY (buyer_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: sales sales_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: sales sales_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: sales sales_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: sales sales_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_location_id_fkey FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE SET NULL (location_id) NOT VALID;


--
-- Name: sales sales_owner_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_owner_site_id_fkey FOREIGN KEY (owner_site_id) REFERENCES public.sites(id) ON DELETE SET NULL;


--
-- Name: sales sales_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_quotation_id_fkey FOREIGN KEY (site_id, quotation_id) REFERENCES public.quotations(site_id, id) ON DELETE SET NULL (quotation_id) NOT VALID;


--
-- Name: sales sales_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE SET NULL;


--
-- Name: sales sales_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: sales sales_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_subscription_id_fkey FOREIGN KEY (site_id, subscription_id) REFERENCES public.subscriptions(site_id, id) ON DELETE SET NULL (subscription_id) NOT VALID;


--
-- Name: sales sales_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sandbox_billing_resources sandbox_billing_resources_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sandbox_billing_resources
    ADD CONSTRAINT sandbox_billing_resources_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: sandbox_billing_sessions sandbox_billing_sessions_sandbox_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sandbox_billing_sessions
    ADD CONSTRAINT sandbox_billing_sessions_sandbox_name_fkey FOREIGN KEY (sandbox_name) REFERENCES public.sandbox_billing_resources(sandbox_name);


--
-- Name: sections sections_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: secure_tokens secure_tokens_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secure_tokens
    ADD CONSTRAINT secure_tokens_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: segments segments_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.segments
    ADD CONSTRAINT segments_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: segments segments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.segments
    ADD CONSTRAINT segments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: self_service_inventory_releases self_service_inventory_releases_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_service_inventory_releases
    ADD CONSTRAINT self_service_inventory_releases_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id);


--
-- Name: self_service_inventory_releases self_service_inventory_releases_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_service_inventory_releases
    ADD CONSTRAINT self_service_inventory_releases_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id);


--
-- Name: self_service_inventory_releases self_service_inventory_releases_sale_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_service_inventory_releases
    ADD CONSTRAINT self_service_inventory_releases_sale_order_id_fkey FOREIGN KEY (sale_order_id) REFERENCES public.sale_orders(id);


--
-- Name: self_service_inventory_releases self_service_inventory_releases_sale_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_service_inventory_releases
    ADD CONSTRAINT self_service_inventory_releases_sale_order_item_id_fkey FOREIGN KEY (sale_order_item_id) REFERENCES public.sale_order_items(id);


--
-- Name: self_service_inventory_releases self_service_inventory_releases_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_service_inventory_releases
    ADD CONSTRAINT self_service_inventory_releases_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: session_events session_events_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_events
    ADD CONSTRAINT session_events_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE;


--
-- Name: session_events session_events_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_events
    ADD CONSTRAINT session_events_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE CASCADE;


--
-- Name: session_recording_chunks session_recording_chunks_recording_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_recording_chunks
    ADD CONSTRAINT session_recording_chunks_recording_event_id_fkey FOREIGN KEY (recording_event_id) REFERENCES public.session_events(id) ON DELETE CASCADE;


--
-- Name: session_recording_chunks session_recording_chunks_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_recording_chunks
    ADD CONSTRAINT session_recording_chunks_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE;


--
-- Name: settings settings_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: setup_email_delivery_receipts setup_email_delivery_receipts_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setup_email_delivery_receipts
    ADD CONSTRAINT setup_email_delivery_receipts_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: shipment_location_pings shipment_location_pings_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_location_pings
    ADD CONSTRAINT shipment_location_pings_shipment_id_fkey FOREIGN KEY (site_id, shipment_id) REFERENCES public.shipments(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: shipment_location_pings shipment_location_pings_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_location_pings
    ADD CONSTRAINT shipment_location_pings_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: shipment_location_pings shipment_location_pings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_location_pings
    ADD CONSTRAINT shipment_location_pings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);


--
-- Name: shipments shipments_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: shipments shipments_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: shipments shipments_marketplace_integration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_marketplace_integration_id_fkey FOREIGN KEY (marketplace_integration_id) REFERENCES public.marketplace_integrations(id);


--
-- Name: shipments shipments_origin_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_origin_location_id_fkey FOREIGN KEY (site_id, origin_location_id) REFERENCES public.locations(site_id, id) NOT VALID;


--
-- Name: shipments shipments_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_sale_id_fkey FOREIGN KEY (site_id, sale_id) REFERENCES public.sales(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: shipments shipments_sale_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_sale_order_id_fkey FOREIGN KEY (site_id, sale_order_id) REFERENCES public.sale_orders(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: shipments shipments_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: shipments shipments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipments
    ADD CONSTRAINT shipments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: site_members site_members_added_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_members
    ADD CONSTRAINT site_members_added_by_fkey FOREIGN KEY (added_by) REFERENCES auth.users(id);


--
-- Name: site_members site_members_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_members
    ADD CONSTRAINT site_members_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: site_members site_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_members
    ADD CONSTRAINT site_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: site_ownership site_ownership_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_ownership
    ADD CONSTRAINT site_ownership_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;
