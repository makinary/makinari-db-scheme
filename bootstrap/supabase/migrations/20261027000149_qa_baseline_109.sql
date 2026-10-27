SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: site_ownership site_ownership_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_ownership
    ADD CONSTRAINT site_ownership_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: site_retired_stripe_subscriptions site_retired_stripe_subscriptions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_retired_stripe_subscriptions
    ADD CONSTRAINT site_retired_stripe_subscriptions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: site_secrets site_secrets_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_secrets
    ADD CONSTRAINT site_secrets_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: site_secrets site_secrets_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_secrets
    ADD CONSTRAINT site_secrets_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: site_skills site_skills_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_skills
    ADD CONSTRAINT site_skills_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: site_subscription_checkout_leases site_subscription_checkout_leases_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_subscription_checkout_leases
    ADD CONSTRAINT site_subscription_checkout_leases_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: sites sites_archived_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_archived_by_fkey FOREIGN KEY (archived_by) REFERENCES auth.users(id);


--
-- Name: sites sites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: social_comment_sync_state social_comment_sync_state_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_comment_sync_state
    ADD CONSTRAINT social_comment_sync_state_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: states states_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- Name: stripe_subscription_invoice_settlements stripe_subscription_invoice_settlements_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stripe_subscription_invoice_settlements
    ADD CONSTRAINT stripe_subscription_invoice_settlements_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id);


--
-- Name: stripe_subscription_invoice_settlements stripe_subscription_invoice_settlements_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stripe_subscription_invoice_settlements
    ADD CONSTRAINT stripe_subscription_invoice_settlements_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: subscription_plan_items subscription_plan_items_digital_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_plan_items
    ADD CONSTRAINT subscription_plan_items_digital_fkey FOREIGN KEY (digital_catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: subscription_plan_items subscription_plan_items_plan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_plan_items
    ADD CONSTRAINT subscription_plan_items_plan_fkey FOREIGN KEY (plan_catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: subscription_plan_items subscription_plan_items_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_plan_items
    ADD CONSTRAINT subscription_plan_items_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_buyer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_buyer_user_id_fkey FOREIGN KEY (buyer_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: subscriptions subscriptions_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE RESTRICT;


--
-- Name: subscriptions subscriptions_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_owner_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_owner_site_id_fkey FOREIGN KEY (owner_site_id) REFERENCES public.sites(id) ON DELETE SET NULL;


--
-- Name: subscriptions subscriptions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: system_memories system_memories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_memories
    ADD CONSTRAINT system_memories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: system_status system_status_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_status
    ADD CONSTRAINT system_status_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.system_status_runs(id) ON DELETE CASCADE;


--
-- Name: task_categories task_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_categories
    ADD CONSTRAINT task_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: task_categories task_categories_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_categories
    ADD CONSTRAINT task_categories_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_comments task_comments_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;


--
-- Name: task_comments task_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_comments
    ADD CONSTRAINT task_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: tasks tasks_assignee_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_assignee_fkey FOREIGN KEY (assignee) REFERENCES auth.users(id);


--
-- Name: tasks tasks_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_conversation_id_fkey FOREIGN KEY (site_id, conversation_id) REFERENCES public.conversations(site_id, id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- Name: tasks tasks_deal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_deal_id_fkey FOREIGN KEY (site_id, deal_id) REFERENCES public.deals(site_id, id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- Name: tasks tasks_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_lead_id_fkey FOREIGN KEY (site_id, lead_id) REFERENCES public.leads(site_id, id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- Name: tasks tasks_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: taxes taxes_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxes
    ADD CONSTRAINT taxes_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: tenant_users tenant_users_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_users
    ADD CONSTRAINT tenant_users_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.apps_tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: transactions transactions_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_catalog_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_catalog_category_id_fkey FOREIGN KEY (catalog_category_id) REFERENCES public.catalog_categories(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_location_id_fkey FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE SET NULL (location_id) NOT VALID;


--
-- Name: transactions transactions_sale_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_sale_order_id_fkey FOREIGN KEY (site_id, sale_order_id) REFERENCES public.sale_orders(site_id, id) ON DELETE SET NULL (sale_order_id) NOT VALID;


--
-- Name: transactions transactions_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: transitions transitions_from_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_from_state_id_fkey FOREIGN KEY (from_state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: transitions transitions_to_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_to_state_id_fkey FOREIGN KEY (to_state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: user_shortcuts user_shortcuts_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_shortcuts
    ADD CONSTRAINT user_shortcuts_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: user_shortcuts user_shortcuts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_shortcuts
    ADD CONSTRAINT user_shortcuts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_site_notifications user_site_notifications_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_site_notifications
    ADD CONSTRAINT user_site_notifications_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: user_site_notifications user_site_notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_site_notifications
    ADD CONSTRAINT user_site_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: variants variants_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variants
    ADD CONSTRAINT variants_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: visitor_external_identities visitor_external_identities_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_external_identities
    ADD CONSTRAINT visitor_external_identities_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: visitor_external_identities visitor_external_identities_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_external_identities
    ADD CONSTRAINT visitor_external_identities_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_attributes visitor_identity_attributes_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_attributes
    ADD CONSTRAINT visitor_identity_attributes_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_challenges visitor_identity_challenges_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_challenges
    ADD CONSTRAINT visitor_identity_challenges_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_challenges visitor_identity_challenges_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_challenges
    ADD CONSTRAINT visitor_identity_challenges_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_challenges visitor_identity_challenges_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_challenges
    ADD CONSTRAINT visitor_identity_challenges_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_challenges visitor_identity_challenges_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_challenges
    ADD CONSTRAINT visitor_identity_challenges_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_session_state visitor_identity_session_state_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_session_state
    ADD CONSTRAINT visitor_identity_session_state_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_token_redemptions visitor_identity_token_redemptions_identity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_token_redemptions
    ADD CONSTRAINT visitor_identity_token_redemptions_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES public.visitor_external_identities(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_token_redemptions visitor_identity_token_redemptions_issuer_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_token_redemptions
    ADD CONSTRAINT visitor_identity_token_redemptions_issuer_key_id_fkey FOREIGN KEY (issuer_key_id) REFERENCES public.api_keys(id) ON DELETE SET NULL;
