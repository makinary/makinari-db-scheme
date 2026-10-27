SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: entitlements entitlements_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT entitlements_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE RESTRICT;


--
-- Name: entitlements entitlements_owner_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT entitlements_owner_site_id_fkey FOREIGN KEY (owner_site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: entitlements entitlements_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.entitlements
    ADD CONSTRAINT entitlements_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: experiment_segments experiment_segments_experiment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_segments
    ADD CONSTRAINT experiment_segments_experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES public.experiments(id) ON DELETE CASCADE;


--
-- Name: experiment_segments experiment_segments_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_segments
    ADD CONSTRAINT experiment_segments_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE;


--
-- Name: experiments experiments_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: experiments experiments_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: experiments experiments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: external_resources external_resources_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_resources
    ADD CONSTRAINT external_resources_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: external_resources external_resources_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_resources
    ADD CONSTRAINT external_resources_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: agent_assets fk_command_agent_assets; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_assets
    ADD CONSTRAINT fk_command_agent_assets FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: agent_memories fk_command_agent_memories; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memories
    ADD CONSTRAINT fk_command_agent_memories FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: agents fk_command_agents; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT fk_command_agents FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: analysis fk_command_analysis; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis
    ADD CONSTRAINT fk_command_analysis FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: assets fk_command_assets; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_command_assets FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: billing fk_command_billing; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT fk_command_billing FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: campaign_requirements fk_command_campaign_requirements; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_requirements
    ADD CONSTRAINT fk_command_campaign_requirements FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: campaign_segments fk_command_campaign_segments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_segments
    ADD CONSTRAINT fk_command_campaign_segments FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: campaign_subtasks fk_command_campaign_subtasks; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_subtasks
    ADD CONSTRAINT fk_command_campaign_subtasks FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: campaigns fk_command_campaigns; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT fk_command_campaigns FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: conversations fk_command_conversations; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_command_conversations FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: debug_logs fk_command_debug_logs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debug_logs
    ADD CONSTRAINT fk_command_debug_logs FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: experiment_segments fk_command_experiment_segments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiment_segments
    ADD CONSTRAINT fk_command_experiment_segments FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: experiments fk_command_experiments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT fk_command_experiments FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: external_resources fk_command_external_resources; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_resources
    ADD CONSTRAINT fk_command_external_resources FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: instance_logs fk_command_instance_logs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_logs
    ADD CONSTRAINT fk_command_instance_logs FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE SET NULL;


--
-- Name: instance_plans fk_command_instance_plans; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_plans
    ADD CONSTRAINT fk_command_instance_plans FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE SET NULL;


--
-- Name: kpis fk_command_kpis; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kpis
    ADD CONSTRAINT fk_command_kpis FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: leads fk_command_leads; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT fk_command_leads FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: messages fk_command_messages; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_command_messages FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: notifications fk_command_notifications; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_command_notifications FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: payments fk_command_payments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_command_payments FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: profiles fk_command_profiles; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT fk_command_profiles FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: remote_instances fk_command_remote_instances; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_instances
    ADD CONSTRAINT fk_command_remote_instances FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE SET NULL;


--
-- Name: requirement_segments fk_command_requirement_segments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_segments
    ADD CONSTRAINT fk_command_requirement_segments FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: requirements fk_command_requirements; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirements
    ADD CONSTRAINT fk_command_requirements FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: sales fk_command_sales; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT fk_command_sales FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: segments fk_command_segments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.segments
    ADD CONSTRAINT fk_command_segments FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: session_events fk_command_session_events; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_events
    ADD CONSTRAINT fk_command_session_events FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: settings fk_command_settings; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT fk_command_settings FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: sites fk_command_sites; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT fk_command_sites FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: system_memories fk_command_system_memories; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_memories
    ADD CONSTRAINT fk_command_system_memories FOREIGN KEY (command_id) REFERENCES public.commands(id);


--
-- Name: tasks fk_command_tasks; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT fk_command_tasks FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: transactions fk_command_transactions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_command_transactions FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: visitor_sessions fk_command_visitor_sessions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_sessions
    ADD CONSTRAINT fk_command_visitor_sessions FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: visitors fk_command_visitors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitors
    ADD CONSTRAINT fk_command_visitors FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE;


--
-- Name: instance_node_contexts fk_context_node; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_node_contexts
    ADD CONSTRAINT fk_context_node FOREIGN KEY (context_node_id) REFERENCES public.instance_nodes(id) ON DELETE CASCADE;


--
-- Name: messages fk_conversation; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_conversation FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: messages fk_lead; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_lead FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: requirement_status fk_requirement_status_requirement; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_status
    ADD CONSTRAINT fk_requirement_status_requirement FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_status fk_requirement_status_site; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_status
    ADD CONSTRAINT fk_requirement_status_site FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: api_keys fk_site; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT fk_site FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_node_contexts fk_site; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_node_contexts
    ADD CONSTRAINT fk_site FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: instance_node_contexts fk_target_node; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_node_contexts
    ADD CONSTRAINT fk_target_node FOREIGN KEY (target_node_id) REFERENCES public.instance_nodes(id) ON DELETE CASCADE;


--
-- Name: api_keys fk_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: instance_node_contexts fk_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_node_contexts
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: conversations fk_visitor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_visitor FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE SET NULL;


--
-- Name: messages fk_visitor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_visitor FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE SET NULL;


--
-- Name: session_events fk_visitor_session; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_events
    ADD CONSTRAINT fk_visitor_session FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE;


--
-- Name: harness_artifact_reservations harness_artifact_reservations_session_id_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_artifact_reservations
    ADD CONSTRAINT harness_artifact_reservations_session_id_site_id_fkey FOREIGN KEY (session_id, site_id) REFERENCES public.harness_sessions(id, site_id) ON DELETE CASCADE;


--
-- Name: harness_artifacts harness_artifacts_session_id_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harness_artifacts
    ADD CONSTRAINT harness_artifacts_session_id_site_id_fkey FOREIGN KEY (session_id, site_id) REFERENCES public.harness_sessions(id, site_id) ON DELETE CASCADE;
