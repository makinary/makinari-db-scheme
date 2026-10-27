SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION activate_pending_site_memberships(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.activate_pending_site_memberships() FROM PUBLIC;
GRANT ALL ON FUNCTION public.activate_pending_site_memberships() TO authenticated;
GRANT ALL ON FUNCTION public.activate_pending_site_memberships() TO service_role;


--
-- Name: FUNCTION activate_requirement_cron_run(p_requirement_id uuid, p_run_id text, p_max_concurrent integer, p_ttl_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.activate_requirement_cron_run(p_requirement_id uuid, p_run_id text, p_max_concurrent integer, p_ttl_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.activate_requirement_cron_run(p_requirement_id uuid, p_run_id text, p_max_concurrent integer, p_ttl_seconds integer) TO service_role;


--
-- Name: FUNCTION activate_requirement_cron_run_before_assistant_handoff(p_requirement_id uuid, p_run_id text, p_max_concurrent integer, p_ttl_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.activate_requirement_cron_run_before_assistant_handoff(p_requirement_id uuid, p_run_id text, p_max_concurrent integer, p_ttl_seconds integer) FROM PUBLIC;


--
-- Name: FUNCTION add_balance(p_site_id uuid, p_amount numeric); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.add_balance(p_site_id uuid, p_amount numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_balance(p_site_id uuid, p_amount numeric) TO service_role;


--
-- Name: FUNCTION add_command_id_to_all_tables(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.add_command_id_to_all_tables() TO anon;
GRANT ALL ON FUNCTION public.add_command_id_to_all_tables() TO authenticated;
GRANT ALL ON FUNCTION public.add_command_id_to_all_tables() TO service_role;


--
-- Name: FUNCTION add_credits(p_site_id uuid, p_credits integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.add_credits(p_site_id uuid, p_credits integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_credits(p_site_id uuid, p_credits integer) TO service_role;


--
-- Name: FUNCTION add_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.add_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb) TO service_role;


--
-- Name: FUNCTION add_delete_protection_trigger(p_table_name text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.add_delete_protection_trigger(p_table_name text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_delete_protection_trigger(p_table_name text) TO authenticated;
GRANT ALL ON FUNCTION public.add_delete_protection_trigger(p_table_name text) TO service_role;


--
-- Name: FUNCTION add_to_waitlist(email_param text, name_param text, referral_code_param text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.add_to_waitlist(email_param text, name_param text, referral_code_param text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.add_to_waitlist(email_param text, name_param text, referral_code_param text) TO authenticated;
GRANT ALL ON FUNCTION public.add_to_waitlist(email_param text, name_param text, referral_code_param text) TO service_role;


--
-- Name: FUNCTION advance_credit_auto_top_up_settings_revision(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.advance_credit_auto_top_up_settings_revision() FROM PUBLIC;
GRANT ALL ON FUNCTION public.advance_credit_auto_top_up_settings_revision() TO service_role;


--
-- Name: FUNCTION agent_requirement_runner_allowed(p_requirement_id uuid, p_instance_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.agent_requirement_runner_allowed(p_requirement_id uuid, p_instance_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION append_instance_plan_repair_step_atomic(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.append_instance_plan_repair_step_atomic(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.append_instance_plan_repair_step_atomic(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.append_instance_plan_repair_step_atomic(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb) TO service_role;


--
-- Name: FUNCTION append_session_recording_chunk(p_event_id uuid, p_site_id text, p_visitor_id uuid, p_session_id uuid, p_url text, p_timestamp bigint, p_storage_path text, p_chunk_id uuid, p_content_hash text, p_start_timestamp bigint, p_end_timestamp bigint, p_event_count integer, p_metadata jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.append_session_recording_chunk(p_event_id uuid, p_site_id text, p_visitor_id uuid, p_session_id uuid, p_url text, p_timestamp bigint, p_storage_path text, p_chunk_id uuid, p_content_hash text, p_start_timestamp bigint, p_end_timestamp bigint, p_event_count integer, p_metadata jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.append_session_recording_chunk(p_event_id uuid, p_site_id text, p_visitor_id uuid, p_session_id uuid, p_url text, p_timestamp bigint, p_storage_path text, p_chunk_id uuid, p_content_hash text, p_start_timestamp bigint, p_end_timestamp bigint, p_event_count integer, p_metadata jsonb) TO service_role;


--
-- Name: FUNCTION append_session_recording_chunks(p_chunks jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.append_session_recording_chunks(p_chunks jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.append_session_recording_chunks(p_chunks jsonb) TO service_role;


--
-- Name: FUNCTION apply_marketplace_provisioning(p_integration_id uuid, p_status text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_marketplace_provisioning(p_integration_id uuid, p_status text) FROM PUBLIC;


--
-- Name: FUNCTION apply_paid_subscription_credit_coverage(p_invoice jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_paid_subscription_credit_coverage(p_invoice jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apply_paid_subscription_credit_coverage(p_invoice jsonb) TO service_role;


--
-- Name: FUNCTION apply_pending_requirement_commands(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_pending_requirement_commands() FROM PUBLIC;
GRANT ALL ON FUNCTION public.apply_pending_requirement_commands() TO service_role;


--
-- Name: FUNCTION apply_recovered_requirement_commands(p_id uuid, p_patch jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_recovered_requirement_commands(p_id uuid, p_patch jsonb) FROM PUBLIC;


--
-- Name: FUNCTION apply_self_service_line_inventory(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_self_service_line_inventory() FROM PUBLIC;
GRANT ALL ON FUNCTION public.apply_self_service_line_inventory() TO service_role;


--
-- Name: FUNCTION apply_site_partner_license(p_license_key uuid, p_site_id uuid, p_actor_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_site_partner_license(p_license_key uuid, p_site_id uuid, p_actor_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apply_site_partner_license(p_license_key uuid, p_site_id uuid, p_actor_id uuid) TO service_role;


--
-- Name: FUNCTION apply_stripe_sale_financial_effects(p_sale_id uuid, p_session_id text, p_settlement_amount numeric, p_settlement_currency text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_stripe_sale_financial_effects(p_sale_id uuid, p_session_id text, p_settlement_amount numeric, p_settlement_currency text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apply_stripe_sale_financial_effects(p_sale_id uuid, p_session_id text, p_settlement_amount numeric, p_settlement_currency text) TO service_role;


--
-- Name: FUNCTION apply_stripe_sale_inventory_effect(p_sale_id uuid, p_order_id uuid, p_session_id text, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apply_stripe_sale_inventory_effect(p_sale_id uuid, p_order_id uuid, p_session_id text, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apply_stripe_sale_inventory_effect(p_sale_id uuid, p_order_id uuid, p_session_id text, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION apps_apply_migration(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_migration_sql text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apps_apply_migration(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_migration_sql text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apps_apply_migration(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_migration_sql text) TO service_role;


--
-- Name: FUNCTION apps_ensure_tenant(p_requirement_id uuid, p_candidate_tenant_id uuid, p_user_id uuid, p_site_id uuid, p_auth_provider text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apps_ensure_tenant(p_requirement_id uuid, p_candidate_tenant_id uuid, p_user_id uuid, p_site_id uuid, p_auth_provider text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apps_ensure_tenant(p_requirement_id uuid, p_candidate_tenant_id uuid, p_user_id uuid, p_site_id uuid, p_auth_provider text) TO service_role;


--
-- Name: FUNCTION apps_exec_sql(sql text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apps_exec_sql(sql text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apps_exec_sql(sql text) TO service_role;


--
-- Name: FUNCTION apps_get_migration_receipt(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apps_get_migration_receipt(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apps_get_migration_receipt(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text) TO service_role;


--
-- Name: FUNCTION apps_get_migration_workspace(p_target_schema text, p_expected_tenant_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apps_get_migration_workspace(p_target_schema text, p_expected_tenant_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apps_get_migration_workspace(p_target_schema text, p_expected_tenant_id uuid) TO service_role;


--
-- Name: TABLE apps_migration_feedback; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.apps_migration_feedback TO service_role;


--
-- Name: FUNCTION apps_record_migration_feedback(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_context_key text, p_error jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apps_record_migration_feedback(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_context_key text, p_error jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apps_record_migration_feedback(p_target_schema text, p_expected_tenant_id uuid, p_migration_key text, p_migration_checksum text, p_context_key text, p_error jsonb) TO service_role;


--
-- Name: FUNCTION apps_reload_migration_schema(p_target_schema text, p_expected_tenant_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.apps_reload_migration_schema(p_target_schema text, p_expected_tenant_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.apps_reload_migration_schema(p_target_schema text, p_expected_tenant_id uuid) TO service_role;


--
-- Name: FUNCTION archive_catalog_category(p_site_id uuid, p_category_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.archive_catalog_category(p_site_id uuid, p_category_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.archive_catalog_category(p_site_id uuid, p_category_id uuid) TO authenticated;


--
-- Name: FUNCTION archive_site(p_site_id uuid, p_actor_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.archive_site(p_site_id uuid, p_actor_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.archive_site(p_site_id uuid, p_actor_id uuid) TO service_role;


--
-- Name: FUNCTION assert_agent_requirement_run(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_allow_terminal boolean, p_renew_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assert_agent_requirement_run(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_allow_terminal boolean, p_renew_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.assert_agent_requirement_run(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_allow_terminal boolean, p_renew_seconds integer) TO service_role;


--
-- Name: FUNCTION assert_credit_auto_top_up_service_role(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assert_credit_auto_top_up_service_role() FROM PUBLIC;
GRANT ALL ON FUNCTION public.assert_credit_auto_top_up_service_role() TO service_role;


--
-- Name: FUNCTION assert_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid, p_resource text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assert_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid, p_resource text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.assert_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid, p_resource text) TO service_role;


--
-- Name: FUNCTION assert_requirement_cron_execution_owner(p_requirement_id uuid, p_run_id text, p_expected_execution_generation integer, p_allow_inactive boolean, p_allow_terminal boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assert_requirement_cron_execution_owner(p_requirement_id uuid, p_run_id text, p_expected_execution_generation integer, p_allow_inactive boolean, p_allow_terminal boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.assert_requirement_cron_execution_owner(p_requirement_id uuid, p_run_id text, p_expected_execution_generation integer, p_allow_inactive boolean, p_allow_terminal boolean) TO service_role;


--
-- Name: FUNCTION assert_requirement_cron_execution_owner_before_assistant_handof(p_requirement_id uuid, p_run_id text, p_expected_execution_generation integer, p_allow_inactive boolean, p_allow_terminal boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assert_requirement_cron_execution_owner_before_assistant_handof(p_requirement_id uuid, p_run_id text, p_expected_execution_generation integer, p_allow_inactive boolean, p_allow_terminal boolean) FROM PUBLIC;


--
-- Name: FUNCTION assert_visitor_identity_service_role(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assert_visitor_identity_service_role() FROM PUBLIC;
GRANT ALL ON FUNCTION public.assert_visitor_identity_service_role() TO service_role;


--
-- Name: FUNCTION assign_location_scope(p_table text, p_id uuid, p_site_id uuid, p_location_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assign_location_scope(p_table text, p_id uuid, p_site_id uuid, p_location_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.assign_location_scope(p_table text, p_id uuid, p_site_id uuid, p_location_id uuid) TO authenticated;


--
-- Name: FUNCTION assign_migration_diagnostic_followup(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.assign_migration_diagnostic_followup(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.assign_migration_diagnostic_followup(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text) TO service_role;


--
-- Name: FUNCTION attach_credit_auto_top_up_payment_method_internal(p_site_id uuid, p_stripe_payment_method_id text, p_stripe_customer_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.attach_credit_auto_top_up_payment_method_internal(p_site_id uuid, p_stripe_payment_method_id text, p_stripe_customer_id text) FROM PUBLIC;


--
-- Name: FUNCTION auth_user_id(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.auth_user_id() FROM PUBLIC;
GRANT ALL ON FUNCTION public.auth_user_id() TO authenticated;
GRANT ALL ON FUNCTION public.auth_user_id() TO service_role;


--
-- Name: FUNCTION authorize_credit_auto_top_up_dispatch(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.authorize_credit_auto_top_up_dispatch(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.authorize_credit_auto_top_up_dispatch(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION authorize_order_item_unit_sync(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.authorize_order_item_unit_sync() FROM PUBLIC;
GRANT ALL ON FUNCTION public.authorize_order_item_unit_sync() TO service_role;


--
-- Name: FUNCTION backfill_catalog_search(p_after_id uuid, p_limit integer, p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.backfill_catalog_search(p_after_id uuid, p_limit integer, p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.backfill_catalog_search(p_after_id uuid, p_limit integer, p_site_id uuid) TO service_role;


--
-- Name: FUNCTION begin_credit_auto_top_up_attempt(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.begin_credit_auto_top_up_attempt(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.begin_credit_auto_top_up_attempt(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION begin_credit_auto_top_up_setup(p_site_id uuid, p_actor_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.begin_credit_auto_top_up_setup(p_site_id uuid, p_actor_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.begin_credit_auto_top_up_setup(p_site_id uuid, p_actor_id uuid) TO service_role;


--
-- Name: FUNCTION begin_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_owner text, p_resource text, p_token uuid, p_bootstrap boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.begin_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_owner text, p_resource text, p_token uuid, p_bootstrap boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.begin_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_owner text, p_resource text, p_token uuid, p_bootstrap boolean) TO service_role;


--
-- Name: FUNCTION begin_icp_dispatch(p_id uuid, p_run_id uuid, p_workflow_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.begin_icp_dispatch(p_id uuid, p_run_id uuid, p_workflow_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.begin_icp_dispatch(p_id uuid, p_run_id uuid, p_workflow_id text) TO service_role;


--
-- Name: FUNCTION begin_marketplace_oauth(p_context jsonb, p_state_hash text, p_encrypted_context text, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.begin_marketplace_oauth(p_context jsonb, p_state_hash text, p_encrypted_context text, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.begin_marketplace_oauth(p_context jsonb, p_state_hash text, p_encrypted_context text, p_actor_user_id uuid) TO service_role;


--
-- Name: FUNCTION begin_migration_diagnostic_review(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_value jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.begin_migration_diagnostic_review(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_value jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.begin_migration_diagnostic_review(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_value jsonb) TO service_role;


--
-- Name: FUNCTION bill_openrouter_generation(p_site_id uuid, p_event_id text, p_provider_cost numeric, p_metadata jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.bill_openrouter_generation(p_site_id uuid, p_event_id text, p_provider_cost numeric, p_metadata jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.bill_openrouter_generation(p_site_id uuid, p_event_id text, p_provider_cost numeric, p_metadata jsonb) TO service_role;


--
-- Name: FUNCTION bill_sandbox_sessions(p_sandbox_name text, p_sessions jsonb, p_observed_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.bill_sandbox_sessions(p_sandbox_name text, p_sessions jsonb, p_observed_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.bill_sandbox_sessions(p_sandbox_name text, p_sessions jsonb, p_observed_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION billing_license_changed(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.billing_license_changed() FROM PUBLIC;


--
-- Name: FUNCTION block_backlog_item_for_circuit_atomic(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_backlog_item_id text, p_expected_step_generation integer, p_expected_execution_generation integer, p_circuit_kind text, p_blocker_id text, p_category text, p_reason text, p_resolution_actor text, p_retry_after timestamp with time zone, p_provenance text, p_cycle_id text, p_minimum_failures integer, p_core_attempt_limit integer, p_ornamental_attempt_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.block_backlog_item_for_circuit_atomic(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_backlog_item_id text, p_expected_step_generation integer, p_expected_execution_generation integer, p_circuit_kind text, p_blocker_id text, p_category text, p_reason text, p_resolution_actor text, p_retry_after timestamp with time zone, p_provenance text, p_cycle_id text, p_minimum_failures integer, p_core_attempt_limit integer, p_ornamental_attempt_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_backlog_item_for_circuit_atomic(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_backlog_item_id text, p_expected_step_generation integer, p_expected_execution_generation integer, p_circuit_kind text, p_blocker_id text, p_category text, p_reason text, p_resolution_actor text, p_retry_after timestamp with time zone, p_provenance text, p_cycle_id text, p_minimum_failures integer, p_core_attempt_limit integer, p_ornamental_attempt_limit integer) TO service_role;


--
-- Name: FUNCTION block_requirement_for_cron_infrastructure_cycles(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.block_requirement_for_cron_infrastructure_cycles(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_requirement_for_cron_infrastructure_cycles(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer) TO service_role;


--
-- Name: FUNCTION block_requirement_for_infrastructure_circuit(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_expected_generation integer, p_provenance text, p_message text, p_event_id text, p_expected_execution_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.block_requirement_for_infrastructure_circuit(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_expected_generation integer, p_provenance text, p_message text, p_event_id text, p_expected_execution_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_requirement_for_infrastructure_circuit(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_expected_generation integer, p_provenance text, p_message text, p_event_id text, p_expected_execution_generation integer) TO service_role;


--
-- Name: FUNCTION block_requirement_for_product_attempt_budget(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_max_attempts integer, p_message text, p_expected_execution_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.block_requirement_for_product_attempt_budget(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_max_attempts integer, p_message text, p_expected_execution_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_requirement_for_product_attempt_budget(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_max_attempts integer, p_message text, p_expected_execution_generation integer) TO service_role;


--
-- Name: FUNCTION block_requirement_for_product_no_progress(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.block_requirement_for_product_no_progress(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_requirement_for_product_no_progress(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer) TO service_role;


--
-- Name: FUNCTION block_requirement_for_product_no_progress(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer, p_plan_id uuid, p_step_id text, p_expected_step_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.block_requirement_for_product_no_progress(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer, p_plan_id uuid, p_step_id text, p_expected_step_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_requirement_for_product_no_progress(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_cycle_id text, p_minimum_failures integer, p_message text, p_expected_execution_generation integer, p_plan_id uuid, p_step_id text, p_expected_step_generation integer) TO service_role;


--
-- Name: FUNCTION block_requirement_with_provenance(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_provenance text, p_message text, p_event_id text, p_expected_execution_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.block_requirement_with_provenance(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_provenance text, p_message text, p_event_id text, p_expected_execution_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.block_requirement_with_provenance(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_provenance text, p_message text, p_event_id text, p_expected_execution_generation integer) TO service_role;
