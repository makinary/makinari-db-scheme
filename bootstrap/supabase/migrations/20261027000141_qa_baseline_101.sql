SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: visitor_sessions trigger_update_permission_visitor_sessions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_visitor_sessions BEFORE UPDATE ON public.visitor_sessions FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: visitors trigger_update_permission_visitors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_visitors BEFORE UPDATE ON public.visitors FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: sale_orders trigger_update_sale_orders_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_sale_orders_updated_at BEFORE UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.update_sale_orders_updated_at();


--
-- Name: synced_objects trigger_update_synced_objects_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_synced_objects_updated_at BEFORE UPDATE ON public.synced_objects FOR EACH ROW EXECUTE FUNCTION public.update_synced_objects_updated_at();


--
-- Name: whatsapp_templates trigger_update_whatsapp_templates_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_whatsapp_templates_updated_at BEFORE UPDATE ON public.whatsapp_templates FOR EACH ROW EXECUTE FUNCTION public.update_whatsapp_templates_updated_at();


--
-- Name: api_keys update_api_keys_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: automation_auth_sessions update_automation_auth_sessions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_automation_auth_sessions_updated_at BEFORE UPDATE ON public.automation_auth_sessions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: companies update_companies_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: content_performance update_content_performance_modtime; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_content_performance_modtime BEFORE UPDATE ON public.content_performance FOR EACH ROW EXECUTE FUNCTION public.update_content_performance_updated_at();


--
-- Name: instance_plans update_instance_plans_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_instance_plans_updated_at BEFORE UPDATE ON public.instance_plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: record_categories update_record_categories_modtime; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_record_categories_modtime BEFORE UPDATE ON public.record_categories FOR EACH ROW EXECUTE FUNCTION public.update_modified_column();


--
-- Name: records update_records_modtime; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_records_modtime BEFORE UPDATE ON public.records FOR EACH ROW EXECUTE FUNCTION public.update_modified_column();


--
-- Name: referral_codes update_referral_codes_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_referral_codes_updated_at BEFORE UPDATE ON public.referral_codes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: remote_instances update_remote_instances_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_remote_instances_updated_at BEFORE UPDATE ON public.remote_instances FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: remote_sessions update_remote_sessions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_remote_sessions_updated_at BEFORE UPDATE ON public.remote_sessions FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


--
-- Name: site_secrets update_site_secrets_updated_at_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_site_secrets_updated_at_trigger BEFORE UPDATE ON public.site_secrets FOR EACH ROW EXECUTE FUNCTION public.update_site_secrets_updated_at();


--
-- Name: waitlist update_waitlist_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_waitlist_updated_at BEFORE UPDATE ON public.waitlist FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: commands validate_performance_bitmask_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_performance_bitmask_trigger BEFORE INSERT OR UPDATE ON public.commands FOR EACH ROW EXECUTE FUNCTION public.validate_performance_bitmask();


--
-- Name: sale_orders validate_sale_order_attribution; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_sale_order_attribution BEFORE INSERT OR UPDATE OF seller_user_id, requested_by_lead_id ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.validate_sale_order_attribution();


--
-- Name: webhook_events webhook_events_updated_at_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER webhook_events_updated_at_trigger BEFORE UPDATE ON public.webhook_events FOR EACH ROW EXECUTE FUNCTION public.update_webhook_events_updated_at();


--
-- Name: billing zz_guard_billing_credit_buckets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zz_guard_billing_credit_buckets BEFORE INSERT OR UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.guard_billing_credit_buckets();


--
-- Name: billing zzz_guard_billing_paid_subscription_coverage; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zzz_guard_billing_paid_subscription_coverage BEFORE INSERT OR UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.guard_billing_paid_subscription_coverage();


--
-- Name: billing zzzz_guard_startup_trial_billing; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER zzzz_guard_startup_trial_billing BEFORE INSERT OR UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.guard_startup_trial_billing();


--
-- Name: accounting_accounts accounting_accounts_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_accounts
    ADD CONSTRAINT accounting_accounts_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: accounting_sale_refunds accounting_sale_refunds_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_sale_refunds
    ADD CONSTRAINT accounting_sale_refunds_sale_id_fkey FOREIGN KEY (site_id, sale_id) REFERENCES public.sales(site_id, id) ON DELETE RESTRICT NOT VALID;


--
-- Name: accounting_sale_refunds accounting_sale_refunds_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_sale_refunds
    ADD CONSTRAINT accounting_sale_refunds_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: activity activity_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: agent_assets agent_assets_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_assets
    ADD CONSTRAINT agent_assets_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;


--
-- Name: agent_assets agent_assets_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_assets
    ADD CONSTRAINT agent_assets_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- Name: agent_memories agent_memories_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memories
    ADD CONSTRAINT agent_memories_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: agents agents_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: agents agents_supervisor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_supervisor_fkey FOREIGN KEY (supervisor) REFERENCES public.agents(id);


--
-- Name: agents agents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: allowed_domains allowed_domains_requirement_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowed_domains
    ADD CONSTRAINT allowed_domains_requirement_site_fkey FOREIGN KEY (requirement_id, site_id) REFERENCES public.requirements(id, site_id) ON DELETE SET NULL (requirement_id);


--
-- Name: allowed_domains allowed_domains_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.allowed_domains
    ADD CONSTRAINT allowed_domains_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: analysis analysis_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis
    ADD CONSTRAINT analysis_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: analysis analysis_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis
    ADD CONSTRAINT analysis_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: appointments appointments_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: assets assets_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: assets assets_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: assets assets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: audience_leads audience_leads_audience_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audience_leads
    ADD CONSTRAINT audience_leads_audience_id_fkey FOREIGN KEY (audience_id) REFERENCES public.audiences(id) ON DELETE CASCADE;


--
-- Name: audience_leads audience_leads_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audience_leads
    ADD CONSTRAINT audience_leads_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: audiences audiences_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audiences
    ADD CONSTRAINT audiences_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE SET NULL;


--
-- Name: audiences audiences_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audiences
    ADD CONSTRAINT audiences_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: audiences audiences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audiences
    ADD CONSTRAINT audiences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: automation_auth_sessions automation_auth_sessions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automation_auth_sessions
    ADD CONSTRAINT automation_auth_sessions_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: automation_auth_sessions automation_auth_sessions_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automation_auth_sessions
    ADD CONSTRAINT automation_auth_sessions_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE SET NULL;


--
-- Name: automation_auth_sessions automation_auth_sessions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automation_auth_sessions
    ADD CONSTRAINT automation_auth_sessions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: automation_auth_sessions automation_auth_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.automation_auth_sessions
    ADD CONSTRAINT automation_auth_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: billing_credit_grant_keys billing_credit_grant_keys_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_credit_grant_keys
    ADD CONSTRAINT billing_credit_grant_keys_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: billing_credit_migration_audit billing_credit_migration_audit_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_credit_migration_audit
    ADD CONSTRAINT billing_credit_migration_audit_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: billing billing_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: calendar_blocks calendar_blocks_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_blocks
    ADD CONSTRAINT calendar_blocks_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: campaign_requirements campaign_requirements_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_requirements
    ADD CONSTRAINT campaign_requirements_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: campaign_requirements campaign_requirements_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_requirements
    ADD CONSTRAINT campaign_requirements_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: campaign_segments campaign_segments_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_segments
    ADD CONSTRAINT campaign_segments_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: campaign_segments campaign_segments_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_segments
    ADD CONSTRAINT campaign_segments_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE;


--
-- Name: campaign_subtasks campaign_subtasks_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_subtasks
    ADD CONSTRAINT campaign_subtasks_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: campaigns campaigns_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: campaigns campaigns_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: catalog_categories catalog_categories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_categories
    ADD CONSTRAINT catalog_categories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: catalog_embedding_jobs catalog_embedding_jobs_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_embedding_jobs
    ADD CONSTRAINT catalog_embedding_jobs_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_search_documents(catalog_item_id) ON DELETE CASCADE;


--
-- Name: catalog_embedding_jobs catalog_embedding_jobs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.catalog_embedding_jobs
    ADD CONSTRAINT catalog_embedding_jobs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;
