SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: record_embedding_jobs record_embedding_jobs_record_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_embedding_jobs
    ADD CONSTRAINT record_embedding_jobs_record_site_fkey FOREIGN KEY (record_id, site_id) REFERENCES public.records(id, site_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: record_embedding_jobs record_embedding_jobs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.record_embedding_jobs
    ADD CONSTRAINT record_embedding_jobs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: records records_category_site_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_category_site_fkey FOREIGN KEY (category_id, site_id) REFERENCES public.record_categories(id, site_id) ON DELETE CASCADE;


--
-- Name: records records_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: referral_code_uses referral_code_uses_referral_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_code_uses
    ADD CONSTRAINT referral_code_uses_referral_code_id_fkey FOREIGN KEY (referral_code_id) REFERENCES public.referral_codes(id) ON DELETE CASCADE;


--
-- Name: referral_code_uses referral_code_uses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_code_uses
    ADD CONSTRAINT referral_code_uses_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: referral_codes referral_codes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referral_codes
    ADD CONSTRAINT referral_codes_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: remote_instances remote_instances_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_instances
    ADD CONSTRAINT remote_instances_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE SET NULL;


--
-- Name: remote_instances remote_instances_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_instances
    ADD CONSTRAINT remote_instances_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: remote_instances remote_instances_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_instances
    ADD CONSTRAINT remote_instances_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: remote_instances remote_instances_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_instances
    ADD CONSTRAINT remote_instances_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: remote_sessions remote_sessions_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_sessions
    ADD CONSTRAINT remote_sessions_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE SET NULL;


--
-- Name: remote_sessions remote_sessions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_sessions
    ADD CONSTRAINT remote_sessions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE SET NULL;


--
-- Name: remote_sessions remote_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remote_sessions
    ADD CONSTRAINT remote_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: requirement_archived_runner_reassignments requirement_archived_runner_reassignments_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_archived_runner_reassignments
    ADD CONSTRAINT requirement_archived_runner_reassignments_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_commands requirement_commands_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_commands
    ADD CONSTRAINT requirement_commands_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.instance_logs(id) ON DELETE CASCADE;


--
-- Name: requirement_commands requirement_commands_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_commands
    ADD CONSTRAINT requirement_commands_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_cron_cycle_outcomes requirement_cron_cycle_outcomes_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_cron_cycle_outcomes
    ADD CONSTRAINT requirement_cron_cycle_outcomes_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_economic_pauses requirement_economic_pauses_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_economic_pauses
    ADD CONSTRAINT requirement_economic_pauses_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_economic_pauses requirement_economic_pauses_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_economic_pauses
    ADD CONSTRAINT requirement_economic_pauses_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.requirement_status(id) ON DELETE CASCADE;


--
-- Name: requirement_harness_decisions requirement_harness_decisions_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_harness_decisions
    ADD CONSTRAINT requirement_harness_decisions_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id);


--
-- Name: requirement_harness_decisions requirement_harness_decisions_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_harness_decisions
    ADD CONSTRAINT requirement_harness_decisions_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_migration_diagnostics requirement_migration_diagnostics_requirement_id_file_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_diagnostics
    ADD CONSTRAINT requirement_migration_diagnostics_requirement_id_file_fkey FOREIGN KEY (requirement_id, file) REFERENCES public.requirement_migration_lifecycle(requirement_id, file) ON DELETE CASCADE;


--
-- Name: requirement_migration_execution_handoffs requirement_migration_execution_handof_requirement_id_file_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_execution_handoffs
    ADD CONSTRAINT requirement_migration_execution_handof_requirement_id_file_fkey FOREIGN KEY (requirement_id, file) REFERENCES public.requirement_migration_lifecycle(requirement_id, file) ON DELETE CASCADE;


--
-- Name: requirement_migration_execution_handoffs requirement_migration_execution_handoffs_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_execution_handoffs
    ADD CONSTRAINT requirement_migration_execution_handoffs_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id);


--
-- Name: requirement_migration_execution_handoffs requirement_migration_execution_handoffs_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_execution_handoffs
    ADD CONSTRAINT requirement_migration_execution_handoffs_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_migration_lifecycle requirement_migration_lifecycle_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_lifecycle
    ADD CONSTRAINT requirement_migration_lifecycle_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_migration_reconciliation_resumes requirement_migration_reconciliation_resume_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliation_resumes
    ADD CONSTRAINT requirement_migration_reconciliation_resume_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_migration_reconciliation_resumes requirement_migration_reconciliation_resumes_receipt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliation_resumes
    ADD CONSTRAINT requirement_migration_reconciliation_resumes_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES public.requirement_migration_reconciliations(id) ON DELETE CASCADE;


--
-- Name: requirement_migration_reconciliations requirement_migration_reconciliations_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliations
    ADD CONSTRAINT requirement_migration_reconciliations_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id);


--
-- Name: requirement_migration_reconciliations requirement_migration_reconciliations_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliations
    ADD CONSTRAINT requirement_migration_reconciliations_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.instance_plans(id);


--
-- Name: requirement_migration_reconciliations requirement_migration_reconciliations_requirement_id_file_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_reconciliations
    ADD CONSTRAINT requirement_migration_reconciliations_requirement_id_file_fkey FOREIGN KEY (requirement_id, file) REFERENCES public.requirement_migration_lifecycle(requirement_id, file) ON DELETE CASCADE;


--
-- Name: requirement_migration_retirements requirement_migration_retirements_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_migration_retirements
    ADD CONSTRAINT requirement_migration_retirements_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id);


--
-- Name: requirement_segments requirement_segments_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_segments
    ADD CONSTRAINT requirement_segments_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_segments requirement_segments_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_segments
    ADD CONSTRAINT requirement_segments_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE;


--
-- Name: requirement_source_checkpoints requirement_source_checkpoints_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_source_checkpoints
    ADD CONSTRAINT requirement_source_checkpoints_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirement_source_checkpoints requirement_source_checkpoints_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_source_checkpoints
    ADD CONSTRAINT requirement_source_checkpoints_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id);


--
-- Name: requirement_status requirement_status_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_status
    ADD CONSTRAINT requirement_status_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: requirement_status requirement_status_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_status
    ADD CONSTRAINT requirement_status_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: requirement_user_action_receipts requirement_user_action_receipts_action_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_user_action_receipts
    ADD CONSTRAINT requirement_user_action_receipts_action_id_fkey FOREIGN KEY (action_id) REFERENCES public.instance_logs(id) ON DELETE CASCADE;


--
-- Name: requirement_user_action_receipts requirement_user_action_receipts_requirement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirement_user_action_receipts
    ADD CONSTRAINT requirement_user_action_receipts_requirement_id_fkey FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE;


--
-- Name: requirements requirements_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirements
    ADD CONSTRAINT requirements_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: requirements requirements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requirements
    ADD CONSTRAINT requirements_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: reservation_schedules reservation_schedules_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_schedules
    ADD CONSTRAINT reservation_schedules_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE CASCADE;


--
-- Name: reservation_schedules reservation_schedules_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation_schedules
    ADD CONSTRAINT reservation_schedules_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: reservations reservations_assignee_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_assignee_user_id_fkey FOREIGN KEY (assignee_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_buyer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_buyer_user_id_fkey FOREIGN KEY (buyer_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_catalog_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_catalog_item_id_fkey FOREIGN KEY (catalog_item_id) REFERENCES public.catalog_items(id) ON DELETE RESTRICT;


--
-- Name: reservations reservations_entitlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_entitlement_id_fkey FOREIGN KEY (entitlement_id) REFERENCES public.entitlements(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: reservations reservations_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_owner_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_owner_site_id_fkey FOREIGN KEY (owner_site_id) REFERENCES public.sites(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_sale_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_sale_order_item_id_fkey FOREIGN KEY (site_id, sale_order_item_id) REFERENCES public.sale_order_items(site_id, id) ON DELETE SET NULL (sale_order_item_id) NOT VALID;


--
-- Name: reservations reservations_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: role_query_segments role_query_segments_role_query_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_query_segments
    ADD CONSTRAINT role_query_segments_role_query_id_fkey FOREIGN KEY (role_query_id) REFERENCES public.role_queries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_query_segments role_query_segments_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_query_segments
    ADD CONSTRAINT role_query_segments_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE;


--
-- Name: sale_order_item_units sale_order_item_units_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item_units
    ADD CONSTRAINT sale_order_item_units_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: sale_order_item_units sale_order_item_units_sale_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item_units
    ADD CONSTRAINT sale_order_item_units_sale_order_item_id_fkey FOREIGN KEY (site_id, sale_order_item_id) REFERENCES public.sale_order_items(site_id, id) ON DELETE CASCADE NOT VALID;


--
-- Name: sale_order_item_units sale_order_item_units_shipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item_units
    ADD CONSTRAINT sale_order_item_units_shipment_id_fkey FOREIGN KEY (site_id, shipment_id) REFERENCES public.shipments(site_id, id) ON DELETE SET NULL (shipment_id) NOT VALID;


--
-- Name: sale_order_item_units sale_order_item_units_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item_units
    ADD CONSTRAINT sale_order_item_units_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: sale_order_items sale_order_items_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_items
    ADD CONSTRAINT sale_order_items_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id) ON DELETE SET NULL;
