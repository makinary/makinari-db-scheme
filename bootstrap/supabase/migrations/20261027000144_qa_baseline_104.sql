SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: harness_host_state harness_host_state_session_id_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_host_state
    ADD CONSTRAINT harness_host_state_session_id_site_id_fkey FOREIGN KEY (session_id, site_id) REFERENCES public.harness_sessions(id, site_id) ON DELETE CASCADE;


--
-- Name: harness_model_credit_reservations harness_model_credit_reservations_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_model_credit_reservations
    ADD CONSTRAINT harness_model_credit_reservations_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id);


--
-- Name: harness_model_credit_reservations harness_model_credit_reservations_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_model_credit_reservations
    ADD CONSTRAINT harness_model_credit_reservations_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.harness_sessions(id);


--
-- Name: harness_model_credit_reservations harness_model_credit_reservations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_model_credit_reservations
    ADD CONSTRAINT harness_model_credit_reservations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: harness_requirement_credit_reservations harness_requirement_credit_reservations_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_requirement_credit_reservations
    ADD CONSTRAINT harness_requirement_credit_reservations_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: harness_requirement_runs harness_requirement_runs_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_requirement_runs
    ADD CONSTRAINT harness_requirement_runs_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: harness_requirement_runs harness_requirement_runs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_requirement_runs
    ADD CONSTRAINT harness_requirement_runs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: harness_sessions harness_sessions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_sessions
    ADD CONSTRAINT harness_sessions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: harness_sessions harness_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_sessions
    ADD CONSTRAINT harness_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: icp_dispatch_list_state icp_dispatch_list_state_icp_mining_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_list_state
    ADD CONSTRAINT icp_dispatch_list_state_icp_mining_id_fkey FOREIGN KEY (icp_mining_id) REFERENCES public.icp_mining(id);


--
-- Name: icp_dispatch_list_state icp_dispatch_list_state_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_list_state
    ADD CONSTRAINT icp_dispatch_list_state_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: icp_dispatch_runs icp_dispatch_runs_icp_mining_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_runs
    ADD CONSTRAINT icp_dispatch_runs_icp_mining_id_fkey FOREIGN KEY (icp_mining_id) REFERENCES public.icp_mining(id);


--
-- Name: icp_dispatch_runs icp_dispatch_runs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_runs
    ADD CONSTRAINT icp_dispatch_runs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: icp_dispatch_site_state icp_dispatch_site_state_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_dispatch_site_state
    ADD CONSTRAINT icp_dispatch_site_state_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: icp_mining icp_mining_role_query_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_mining
    ADD CONSTRAINT icp_mining_role_query_id_fkey FOREIGN KEY (role_query_id) REFERENCES public.role_queries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: icp_mining icp_mining_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icp_mining
    ADD CONSTRAINT icp_mining_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: icypeas_email_searches icypeas_email_searches_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.icypeas_email_searches
    ADD CONSTRAINT icypeas_email_searches_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE RESTRICT;


--
-- Name: image_generation_credit_reservations image_generation_credit_reservations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_generation_credit_reservations
    ADD CONSTRAINT image_generation_credit_reservations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: instance_artifacts instance_artifacts_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_artifacts
    ADD CONSTRAINT instance_artifacts_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: instance_context_memories instance_context_memories_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_context_memories
    ADD CONSTRAINT instance_context_memories_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: instance_context_memories instance_context_memories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_context_memories
    ADD CONSTRAINT instance_context_memories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_context_state instance_context_state_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_context_state
    ADD CONSTRAINT instance_context_state_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: instance_context_state instance_context_state_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_context_state
    ADD CONSTRAINT instance_context_state_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_logs instance_logs_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_logs
    ADD CONSTRAINT instance_logs_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE SET NULL;


--
-- Name: instance_logs instance_logs_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_logs
    ADD CONSTRAINT instance_logs_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: instance_logs instance_logs_parent_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_logs
    ADD CONSTRAINT instance_logs_parent_log_id_fkey FOREIGN KEY (parent_log_id) REFERENCES public.instance_logs(id) ON DELETE SET NULL;


--
-- Name: instance_logs instance_logs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_logs
    ADD CONSTRAINT instance_logs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_logs instance_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_logs
    ADD CONSTRAINT instance_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: instance_nodes instance_nodes_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_nodes
    ADD CONSTRAINT instance_nodes_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: instance_nodes instance_nodes_original_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_nodes
    ADD CONSTRAINT instance_nodes_original_node_id_fkey FOREIGN KEY (original_node_id) REFERENCES public.instance_nodes(id) ON DELETE SET NULL;


--
-- Name: instance_nodes instance_nodes_parent_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_nodes
    ADD CONSTRAINT instance_nodes_parent_log_id_fkey FOREIGN KEY (parent_instance_log_id) REFERENCES public.instance_logs(id) ON DELETE SET NULL;


--
-- Name: instance_nodes instance_nodes_parent_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_nodes
    ADD CONSTRAINT instance_nodes_parent_node_id_fkey FOREIGN KEY (parent_node_id) REFERENCES public.instance_nodes(id) ON DELETE SET NULL;


--
-- Name: instance_nodes instance_nodes_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_nodes
    ADD CONSTRAINT instance_nodes_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_nodes instance_nodes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_nodes
    ADD CONSTRAINT instance_nodes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: instance_pending_work instance_pending_work_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_pending_work
    ADD CONSTRAINT instance_pending_work_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: instance_pending_work instance_pending_work_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_pending_work
    ADD CONSTRAINT instance_pending_work_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_pending_work instance_pending_work_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_pending_work
    ADD CONSTRAINT instance_pending_work_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: instance_plan_step_infrastructure_events instance_plan_step_infrastructure_events_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plan_step_infrastructure_events
    ADD CONSTRAINT instance_plan_step_infrastructure_events_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.instance_plans(id) ON DELETE CASCADE;


--
-- Name: instance_plans instance_plans_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plans
    ADD CONSTRAINT instance_plans_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE SET NULL;


--
-- Name: instance_plans instance_plans_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plans
    ADD CONSTRAINT instance_plans_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: instance_plans instance_plans_parent_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plans
    ADD CONSTRAINT instance_plans_parent_plan_id_fkey FOREIGN KEY (parent_plan_id) REFERENCES public.instance_plans(id) ON DELETE CASCADE;


--
-- Name: instance_plans instance_plans_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plans
    ADD CONSTRAINT instance_plans_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_plans instance_plans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plans
    ADD CONSTRAINT instance_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: inventory_levels inventory_levels_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_levels
    ADD CONSTRAINT inventory_levels_catalog_item_id_fkey FOREIGN KEY (site_id, catalog_item_id) REFERENCES public.catalog_items(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: inventory_levels inventory_levels_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_levels
    ADD CONSTRAINT inventory_levels_location_id_fkey FOREIGN KEY (site_id, location_id) REFERENCES public.locations(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: inventory_levels inventory_levels_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_levels
    ADD CONSTRAINT inventory_levels_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: invoice_reminders invoice_reminders_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_reminders
    ADD CONSTRAINT invoice_reminders_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id);


--
-- Name: invoice_reminders invoice_reminders_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_reminders
    ADD CONSTRAINT invoice_reminders_sale_id_fkey FOREIGN KEY (site_id, sale_id) REFERENCES public.sales(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: invoice_reminders invoice_reminders_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_reminders
    ADD CONSTRAINT invoice_reminders_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: item_spec_categories item_spec_categories_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_spec_categories
    ADD CONSTRAINT item_spec_categories_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: item_specs item_specs_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_specs
    ADD CONSTRAINT item_specs_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.item_spec_categories(id) ON DELETE CASCADE;


--
-- Name: item_specs item_specs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_specs
    ADD CONSTRAINT item_specs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: journal_entries journal_entries_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT journal_entries_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: journal_lines journal_lines_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: journal_lines journal_lines_catalog_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_catalog_category_id_fkey FOREIGN KEY (catalog_category_id) REFERENCES public.catalog_categories(id) ON DELETE SET NULL;


--
-- Name: journal_lines journal_lines_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE SET NULL;


--
-- Name: journal_lines journal_lines_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: journal_lines journal_lines_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES public.journal_entries(id) ON DELETE CASCADE;


--
-- Name: journal_lines journal_lines_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: journal_lines journal_lines_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE SET NULL;


--
-- Name: journal_lines journal_lines_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_lines
    ADD CONSTRAINT journal_lines_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE SET NULL;
