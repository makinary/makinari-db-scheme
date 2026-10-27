SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: catalog_import_batches catalog_import_batches_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_import_batches
    ADD CONSTRAINT catalog_import_batches_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: catalog_item_modifier_groups catalog_item_modifier_groups_catalog_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_modifier_groups
    ADD CONSTRAINT catalog_item_modifier_groups_catalog_item_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: catalog_item_modifier_groups catalog_item_modifier_groups_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_modifier_groups
    ADD CONSTRAINT catalog_item_modifier_groups_group_fkey FOREIGN KEY (modifier_group_id) REFERENCES public.modifier_groups(id) ON DELETE CASCADE;


--
-- Name: catalog_item_modifier_groups catalog_item_modifier_groups_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_modifier_groups
    ADD CONSTRAINT catalog_item_modifier_groups_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: catalog_item_requirements catalog_item_requirements_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: catalog_item_requirements catalog_item_requirements_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE RESTRICT;


--
-- Name: catalog_item_requirements catalog_item_requirements_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: catalog_item_requirements catalog_item_requirements_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_requirements
    ADD CONSTRAINT catalog_item_requirements_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: catalog_item_specs catalog_item_specs_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_specs
    ADD CONSTRAINT catalog_item_specs_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: catalog_item_specs catalog_item_specs_spec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_specs
    ADD CONSTRAINT catalog_item_specs_spec_id_fkey FOREIGN KEY (item_spec_id) REFERENCES public.item_specs(id) ON DELETE CASCADE;


--
-- Name: catalog_item_taxes catalog_item_taxes_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_taxes
    ADD CONSTRAINT catalog_item_taxes_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: catalog_item_taxes catalog_item_taxes_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_taxes
    ADD CONSTRAINT catalog_item_taxes_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: catalog_item_taxes catalog_item_taxes_tax_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_item_taxes
    ADD CONSTRAINT catalog_item_taxes_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.taxes(id) ON DELETE CASCADE;


--
-- Name: catalog_items catalog_items_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_items
    ADD CONSTRAINT catalog_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.catalog_categories(id);


--
-- Name: catalog_items catalog_items_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_items
    ADD CONSTRAINT catalog_items_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: catalog_items catalog_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_items
    ADD CONSTRAINT catalog_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: catalog_search_documents catalog_search_documents_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_search_documents
    ADD CONSTRAINT catalog_search_documents_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: catalog_search_documents catalog_search_documents_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_search_documents
    ADD CONSTRAINT catalog_search_documents_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: categories categories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: categories categories_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: channel_health_events channel_health_events_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_health_events
    ADD CONSTRAINT channel_health_events_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: channel_health channel_health_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_health
    ADD CONSTRAINT channel_health_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: commands commands_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: commands commands_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commands
    ADD CONSTRAINT commands_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: companies companies_acquired_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_acquired_by_id_fkey FOREIGN KEY (acquired_by_id) REFERENCES public.companies(id);


--
-- Name: companies companies_parent_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_parent_company_id_fkey FOREIGN KEY (parent_company_id) REFERENCES public.companies(id);


--
-- Name: content_assets content_assets_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_assets
    ADD CONSTRAINT content_assets_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- Name: content_assets content_assets_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_assets
    ADD CONSTRAINT content_assets_content_id_fkey FOREIGN KEY (content_id) REFERENCES public.content(id) ON DELETE CASCADE;


--
-- Name: content content_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_author_id_fkey FOREIGN KEY (author_id) REFERENCES auth.users(id);


--
-- Name: content content_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: content content_command_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_command_id_fkey FOREIGN KEY (command_id) REFERENCES public.commands(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: content_performance content_performance_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_performance
    ADD CONSTRAINT content_performance_content_id_fkey FOREIGN KEY (content_id) REFERENCES public.content(id) ON DELETE SET NULL;


--
-- Name: content_performance content_performance_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_performance
    ADD CONSTRAINT content_performance_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: content content_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id);


--
-- Name: content content_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: content content_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content
    ADD CONSTRAINT content_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: conversations conversations_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id);


--
-- Name: conversations conversations_delegate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_delegate_id_fkey FOREIGN KEY (delegate_id) REFERENCES public.agents(id);


--
-- Name: conversations conversations_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: conversations conversations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: copywriting copywriting_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.copywriting
    ADD CONSTRAINT copywriting_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: copywriting copywriting_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.copywriting
    ADD CONSTRAINT copywriting_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: credit_auto_top_up_attempts credit_auto_top_up_attempts_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_attempts
    ADD CONSTRAINT credit_auto_top_up_attempts_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: credit_auto_top_up_card_setups credit_auto_top_up_card_setups_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_card_setups
    ADD CONSTRAINT credit_auto_top_up_card_setups_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: credit_auto_top_up_consent_log credit_auto_top_up_consent_log_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_consent_log
    ADD CONSTRAINT credit_auto_top_up_consent_log_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: credit_auto_top_up_settings credit_auto_top_up_settings_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_auto_top_up_settings
    ADD CONSTRAINT credit_auto_top_up_settings_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: credit_transactions credit_transactions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credit_transactions
    ADD CONSTRAINT credit_transactions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: cron_status cron_status_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cron_status
    ADD CONSTRAINT cron_status_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: customizations customizations_element_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customizations
    ADD CONSTRAINT customizations_element_id_fkey FOREIGN KEY (element_id) REFERENCES public.elements(id) ON DELETE CASCADE;


--
-- Name: deal_leads deal_leads_deal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_leads
    ADD CONSTRAINT deal_leads_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON DELETE CASCADE;


--
-- Name: deal_leads deal_leads_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_leads
    ADD CONSTRAINT deal_leads_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: deal_owners deal_owners_deal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_owners
    ADD CONSTRAINT deal_owners_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON DELETE CASCADE;


--
-- Name: deal_owners deal_owners_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deal_owners
    ADD CONSTRAINT deal_owners_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: deals deals_accepted_quotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_accepted_quotation_id_fkey FOREIGN KEY (accepted_quotation_id) REFERENCES public.quotations(id) ON DELETE SET NULL;


--
-- Name: deals deals_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: deals deals_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales(id) ON DELETE SET NULL;


--
-- Name: deals deals_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: deals deals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deals
    ADD CONSTRAINT deals_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: editor editor_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.editor
    ADD CONSTRAINT editor_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: elements elements_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elements
    ADD CONSTRAINT elements_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES public.layers(id) ON DELETE CASCADE;


--
-- Name: entitlements entitlements_buyer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT entitlements_buyer_user_id_fkey FOREIGN KEY (buyer_user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
