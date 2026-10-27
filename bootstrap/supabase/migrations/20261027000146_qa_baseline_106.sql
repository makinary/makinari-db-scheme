SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: pass_round_robin_state pass_round_robin_state_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pass_round_robin_state
    ADD CONSTRAINT pass_round_robin_state_site_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: payments payments_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: payout_requests payout_requests_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payout_requests
    ADD CONSTRAINT payout_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: payout_requests payout_requests_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payout_requests
    ADD CONSTRAINT payout_requests_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: payout_requests payout_requests_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payout_requests
    ADD CONSTRAINT payout_requests_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: persons persons_role_query_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_role_query_id_fkey FOREIGN KEY (role_query_id) REFERENCES public.role_queries(id) ON DELETE SET NULL;


--
-- Name: platform_user_roles platform_user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_user_roles
    ADD CONSTRAINT platform_user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: pos_checkout_attempts pos_checkout_attempts_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_checkout_attempts
    ADD CONSTRAINT pos_checkout_attempts_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: pos_client_mutations pos_client_mutations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_client_mutations
    ADD CONSTRAINT pos_client_mutations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: pos_register_movements pos_register_movements_session_id_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_movements
    ADD CONSTRAINT pos_register_movements_session_id_site_id_fkey FOREIGN KEY (session_id, site_id) REFERENCES public.pos_register_sessions(id, site_id);


--
-- Name: pos_register_receipts pos_register_receipts_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_receipts
    ADD CONSTRAINT pos_register_receipts_sale_id_fkey FOREIGN KEY (site_id, sale_id) REFERENCES public.sales(site_id, id) NOT VALID;


--
-- Name: pos_register_receipts pos_register_receipts_session_id_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_receipts
    ADD CONSTRAINT pos_register_receipts_session_id_site_id_fkey FOREIGN KEY (session_id, site_id) REFERENCES public.pos_register_sessions(id, site_id);


--
-- Name: pos_register_sessions pos_register_sessions_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_sessions
    ADD CONSTRAINT pos_register_sessions_location_id_fkey FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) NOT VALID;


--
-- Name: pos_register_sessions pos_register_sessions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_register_sessions
    ADD CONSTRAINT pos_register_sessions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: price_list_items price_list_items_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: price_list_items price_list_items_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id) ON DELETE CASCADE;


--
-- Name: price_list_items price_list_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_list_items
    ADD CONSTRAINT price_list_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: price_lists price_lists_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_lists
    ADD CONSTRAINT price_lists_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: promotion_catalog_categories promotion_catalog_categories_catalog_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_categories
    ADD CONSTRAINT promotion_catalog_categories_catalog_category_id_fkey FOREIGN KEY (catalog_category_id) REFERENCES public.catalog_categories(id) ON DELETE CASCADE;


--
-- Name: promotion_catalog_categories promotion_catalog_categories_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_categories
    ADD CONSTRAINT promotion_catalog_categories_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(id) ON DELETE CASCADE;


--
-- Name: promotion_catalog_categories promotion_catalog_categories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_categories
    ADD CONSTRAINT promotion_catalog_categories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: promotion_catalog_items promotion_catalog_items_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_items
    ADD CONSTRAINT promotion_catalog_items_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: promotion_catalog_items promotion_catalog_items_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_items
    ADD CONSTRAINT promotion_catalog_items_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(id) ON DELETE CASCADE;


--
-- Name: promotion_catalog_items promotion_catalog_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_catalog_items
    ADD CONSTRAINT promotion_catalog_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: promotion_required_categories promotion_required_categories_catalog_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_categories
    ADD CONSTRAINT promotion_required_categories_catalog_category_id_fkey FOREIGN KEY (catalog_category_id) REFERENCES public.catalog_categories(id) ON DELETE CASCADE;


--
-- Name: promotion_required_categories promotion_required_categories_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_categories
    ADD CONSTRAINT promotion_required_categories_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(id) ON DELETE CASCADE;


--
-- Name: promotion_required_categories promotion_required_categories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_categories
    ADD CONSTRAINT promotion_required_categories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: promotion_required_items promotion_required_items_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_items
    ADD CONSTRAINT promotion_required_items_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: promotion_required_items promotion_required_items_promotion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_items
    ADD CONSTRAINT promotion_required_items_promotion_id_fkey FOREIGN KEY (promotion_id) REFERENCES public.promotions(id) ON DELETE CASCADE;


--
-- Name: promotion_required_items promotion_required_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotion_required_items
    ADD CONSTRAINT promotion_required_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: promotions promotions_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: promotions promotions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: promotions promotions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: purchase_items purchase_items_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items
    ADD CONSTRAINT purchase_items_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE SET NULL;


--
-- Name: purchase_items purchase_items_purchase_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items
    ADD CONSTRAINT purchase_items_purchase_site_fkey FOREIGN KEY (purchase_id, site_id) REFERENCES public.purchases(id, site_id) ON DELETE CASCADE NOT VALID;


--
-- Name: purchase_items purchase_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_items
    ADD CONSTRAINT purchase_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: purchases purchases_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_location_id_fkey FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE SET NULL (location_id) NOT VALID;


--
-- Name: purchases purchases_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: purchases purchases_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: purchases purchases_vendor_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_vendor_company_id_fkey FOREIGN KEY (vendor_company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: quotation_items quotation_items_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotation_items
    ADD CONSTRAINT quotation_items_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE RESTRICT;


--
-- Name: quotation_items quotation_items_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotation_items
    ADD CONSTRAINT quotation_items_quotation_id_fkey FOREIGN KEY (quotation_id) REFERENCES public.quotations(id) ON DELETE CASCADE;


--
-- Name: quotations quotations_buyer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_buyer_user_id_fkey FOREIGN KEY (buyer_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: quotations quotations_checkout_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_checkout_order_id_fkey FOREIGN KEY (checkout_order_id) REFERENCES public.sale_orders(id) ON DELETE SET NULL NOT VALID;


--
-- Name: quotations quotations_checkout_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_checkout_sale_id_fkey FOREIGN KEY (checkout_sale_id) REFERENCES public.sales(id) ON DELETE SET NULL NOT VALID;


--
-- Name: quotations quotations_deal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_deal_id_fkey FOREIGN KEY (site_id, deal_id) REFERENCES public.deals(site_id, id) ON DELETE SET NULL (deal_id) NOT VALID;


--
-- Name: quotations quotations_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE RESTRICT;


--
-- Name: quotations quotations_price_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id) ON DELETE SET NULL;


--
-- Name: quotations quotations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotations
    ADD CONSTRAINT quotations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: record_categories record_categories_parent_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_categories
    ADD CONSTRAINT record_categories_parent_category_id_fkey FOREIGN KEY (parent_category_id) REFERENCES public.record_categories(id) ON DELETE SET NULL;


--
-- Name: record_categories record_categories_parent_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_categories
    ADD CONSTRAINT record_categories_parent_site_fkey FOREIGN KEY (parent_category_id, site_id) REFERENCES public.record_categories(id, site_id);


--
-- Name: record_categories record_categories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_categories
    ADD CONSTRAINT record_categories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: record_diagram_edges record_diagram_edges_record_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_edges
    ADD CONSTRAINT record_diagram_edges_record_site_fkey FOREIGN KEY (record_id, site_id) REFERENCES public.record_diagrams(record_id, site_id) ON DELETE CASCADE;


--
-- Name: record_diagram_edges record_diagram_edges_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_edges
    ADD CONSTRAINT record_diagram_edges_source_fkey FOREIGN KEY (record_id, source_node_id) REFERENCES public.record_diagram_nodes(record_id, id) ON DELETE CASCADE;


--
-- Name: record_diagram_edges record_diagram_edges_target_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_edges
    ADD CONSTRAINT record_diagram_edges_target_fkey FOREIGN KEY (record_id, target_node_id) REFERENCES public.record_diagram_nodes(record_id, id) ON DELETE CASCADE;


--
-- Name: record_diagram_nodes record_diagram_nodes_record_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagram_nodes
    ADD CONSTRAINT record_diagram_nodes_record_site_fkey FOREIGN KEY (record_id, site_id) REFERENCES public.record_diagrams(record_id, site_id) ON DELETE CASCADE;


--
-- Name: record_diagrams record_diagrams_record_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagrams
    ADD CONSTRAINT record_diagrams_record_id_fkey FOREIGN KEY (record_id) REFERENCES public.records(id) ON DELETE CASCADE;


--
-- Name: record_diagrams record_diagrams_record_site_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagrams
    ADD CONSTRAINT record_diagrams_record_site_parent_fkey FOREIGN KEY (record_id, site_id) REFERENCES public.records(id, site_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: record_diagrams record_diagrams_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_diagrams
    ADD CONSTRAINT record_diagrams_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: record_embedding_jobs record_embedding_jobs_record_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_embedding_jobs
    ADD CONSTRAINT record_embedding_jobs_record_id_fkey FOREIGN KEY (record_id) REFERENCES public.records(id) ON DELETE CASCADE;
