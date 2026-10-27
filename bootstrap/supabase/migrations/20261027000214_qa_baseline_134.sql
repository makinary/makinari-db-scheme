SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION guard_marketplace_native_write(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_marketplace_native_write() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_marketplace_native_write() TO service_role;


--
-- Name: FUNCTION guard_member_license(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_member_license() FROM PUBLIC;


--
-- Name: FUNCTION guard_migration_execution_handoff(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_migration_execution_handoff() FROM PUBLIC;


--
-- Name: FUNCTION guard_pending_migration_reconciliation(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_pending_migration_reconciliation() FROM PUBLIC;


--
-- Name: FUNCTION guard_platform_key_requirement_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_platform_key_requirement_binding() FROM PUBLIC;


--
-- Name: FUNCTION guard_requirement_assistant_admission(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_requirement_assistant_admission() FROM PUBLIC;


--
-- Name: FUNCTION guard_requirement_deletion_authority(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_requirement_deletion_authority() FROM PUBLIC;


--
-- Name: FUNCTION guard_requirement_instance_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_requirement_instance_binding() FROM PUBLIC;


--
-- Name: FUNCTION guard_requirement_migration_status(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_requirement_migration_status() FROM PUBLIC;


--
-- Name: FUNCTION guard_requirement_owned_receipt_delete(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_requirement_owned_receipt_delete() FROM PUBLIC;


--
-- Name: FUNCTION guard_requirement_sandbox_cleanup(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_requirement_sandbox_cleanup() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_requirement_sandbox_cleanup() TO service_role;


--
-- Name: FUNCTION guard_requirement_status_instance_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_requirement_status_instance_binding() FROM PUBLIC;


--
-- Name: FUNCTION guard_robot_deletion_child_authority(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_robot_deletion_child_authority() FROM PUBLIC;


--
-- Name: FUNCTION guard_sandbox_cleanup_registration(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_sandbox_cleanup_registration() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_sandbox_cleanup_registration() TO service_role;


--
-- Name: FUNCTION guard_self_service_line(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_self_service_line() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_self_service_line() TO service_role;


--
-- Name: FUNCTION guard_self_service_order(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_self_service_order() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_self_service_order() TO service_role;


--
-- Name: FUNCTION guard_self_service_unit(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_self_service_unit() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_self_service_unit() TO service_role;


--
-- Name: FUNCTION guard_site_archive_state(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_site_archive_state() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_site_archive_state() TO service_role;


--
-- Name: FUNCTION guard_startup_trial_billing(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_startup_trial_billing() FROM PUBLIC;


--
-- Name: FUNCTION guard_visitor_identity_issuer_scope(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_visitor_identity_issuer_scope() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_visitor_identity_issuer_scope() TO service_role;


--
-- Name: FUNCTION handle_campaign_deletion(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_campaign_deletion() TO anon;
GRANT ALL ON FUNCTION public.handle_campaign_deletion() TO authenticated;
GRANT ALL ON FUNCTION public.handle_campaign_deletion() TO service_role;


--
-- Name: FUNCTION handle_campaign_deletion_orphans_only(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_campaign_deletion_orphans_only() TO anon;
GRANT ALL ON FUNCTION public.handle_campaign_deletion_orphans_only() TO authenticated;
GRANT ALL ON FUNCTION public.handle_campaign_deletion_orphans_only() TO service_role;


--
-- Name: FUNCTION handle_command_insert(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_command_insert() TO anon;
GRANT ALL ON FUNCTION public.handle_command_insert() TO authenticated;
GRANT ALL ON FUNCTION public.handle_command_insert() TO service_role;


--
-- Name: FUNCTION handle_command_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_command_update() TO anon;
GRANT ALL ON FUNCTION public.handle_command_update() TO authenticated;
GRANT ALL ON FUNCTION public.handle_command_update() TO service_role;


--
-- Name: FUNCTION handle_event_insert(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_event_insert() TO anon;
GRANT ALL ON FUNCTION public.handle_event_insert() TO authenticated;
GRANT ALL ON FUNCTION public.handle_event_insert() TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION handle_new_user_debug(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.handle_new_user_debug() FROM PUBLIC;
GRANT ALL ON FUNCTION public.handle_new_user_debug() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user_debug() TO service_role;


--
-- Name: FUNCTION handle_new_user_simple(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.handle_new_user_simple() FROM PUBLIC;
GRANT ALL ON FUNCTION public.handle_new_user_simple() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user_simple() TO service_role;


--
-- Name: FUNCTION handle_session_active_state(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_session_active_state() TO anon;
GRANT ALL ON FUNCTION public.handle_session_active_state() TO authenticated;
GRANT ALL ON FUNCTION public.handle_session_active_state() TO service_role;


--
-- Name: FUNCTION handle_session_events_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_session_events_updated_at() TO anon;
GRANT ALL ON FUNCTION public.handle_session_events_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.handle_session_events_updated_at() TO service_role;


--
-- Name: FUNCTION handle_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_updated_at() TO anon;
GRANT ALL ON FUNCTION public.handle_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.handle_updated_at() TO service_role;


--
-- Name: FUNCTION has_requirement_scope_authorization(p_requirement_id uuid, p_completed_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.has_requirement_scope_authorization(p_requirement_id uuid, p_completed_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.has_requirement_scope_authorization(p_requirement_id uuid, p_completed_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION hold_harness_model_credits(p_session_id uuid, p_site_id uuid, p_event_id uuid, p_amount numeric, p_requirement_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.hold_harness_model_credits(p_session_id uuid, p_site_id uuid, p_event_id uuid, p_amount numeric, p_requirement_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION hold_image_generation_credits(p_site_id uuid, p_operation_id text, p_request_hash text, p_token uuid, p_count integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.hold_image_generation_credits(p_site_id uuid, p_operation_id text, p_request_hash text, p_token uuid, p_count integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.hold_image_generation_credits(p_site_id uuid, p_operation_id text, p_request_hash text, p_token uuid, p_count integer) TO service_role;


--
-- Name: FUNCTION hold_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text, p_plan_id uuid, p_step_id text, p_reason text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.hold_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text, p_plan_id uuid, p_step_id text, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.hold_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text, p_plan_id uuid, p_step_id text, p_reason text) TO service_role;


--
-- Name: FUNCTION import_catalog_batch(p_site_id uuid, p_rows jsonb, p_mode text, p_request_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.import_catalog_batch(p_site_id uuid, p_rows jsonb, p_mode text, p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.import_catalog_batch(p_site_id uuid, p_rows jsonb, p_mode text, p_request_id uuid) TO authenticated;


--
-- Name: FUNCTION increment_agent_conversations(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.increment_agent_conversations() TO anon;
GRANT ALL ON FUNCTION public.increment_agent_conversations() TO authenticated;
GRANT ALL ON FUNCTION public.increment_agent_conversations() TO service_role;


--
-- Name: FUNCTION increment_referral_code_usage(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.increment_referral_code_usage() TO anon;
GRANT ALL ON FUNCTION public.increment_referral_code_usage() TO authenticated;
GRANT ALL ON FUNCTION public.increment_referral_code_usage() TO service_role;


--
-- Name: FUNCTION increment_requirement_metadata_counter(p_requirement_id uuid, p_key text, p_increment integer, p_initial_value integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.increment_requirement_metadata_counter(p_requirement_id uuid, p_key text, p_increment integer, p_initial_value integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.increment_requirement_metadata_counter(p_requirement_id uuid, p_key text, p_increment integer, p_initial_value integer) TO service_role;


--
-- Name: FUNCTION increment_system_memory_access(p_memory_id uuid, p_amount integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.increment_system_memory_access(p_memory_id uuid, p_amount integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.increment_system_memory_access(p_memory_id uuid, p_amount integer) TO service_role;


--
-- Name: FUNCTION increment_template_usage(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.increment_template_usage() FROM PUBLIC;
GRANT ALL ON FUNCTION public.increment_template_usage() TO authenticated;
GRANT ALL ON FUNCTION public.increment_template_usage() TO service_role;


--
-- Name: FUNCTION increment_template_usage(template_sid_param text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.increment_template_usage(template_sid_param text) TO anon;
GRANT ALL ON FUNCTION public.increment_template_usage(template_sid_param text) TO authenticated;
GRANT ALL ON FUNCTION public.increment_template_usage(template_sid_param text) TO service_role;


--
-- Name: FUNCTION increment_usage_count(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.increment_usage_count() TO anon;
GRANT ALL ON FUNCTION public.increment_usage_count() TO authenticated;
GRANT ALL ON FUNCTION public.increment_usage_count() TO service_role;


--
-- Name: FUNCTION increment_visitor_sessions(visitor_id uuid, last_seen_timestamp bigint); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.increment_visitor_sessions(visitor_id uuid, last_seen_timestamp bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.increment_visitor_sessions(visitor_id uuid, last_seen_timestamp bigint) TO authenticated;
GRANT ALL ON FUNCTION public.increment_visitor_sessions(visitor_id uuid, last_seen_timestamp bigint) TO service_role;


--
-- Name: FUNCTION ingest_marketplace_event(p_integration_id uuid, p_event_key text, p_order jsonb, p_event_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.ingest_marketplace_event(p_integration_id uuid, p_event_key text, p_order jsonb, p_event_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.ingest_marketplace_event(p_integration_id uuid, p_event_key text, p_order jsonb, p_event_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION initialize_site_billing(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.initialize_site_billing(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.initialize_site_billing(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION inspect_requirement_assistant_handoff(p_requirement_id uuid, p_instance_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.inspect_requirement_assistant_handoff(p_requirement_id uuid, p_instance_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.inspect_requirement_assistant_handoff(p_requirement_id uuid, p_instance_id uuid) TO service_role;


--
-- Name: FUNCTION inspect_requirement_commands(p_requirement_ids uuid[], p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.inspect_requirement_commands(p_requirement_ids uuid[], p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.inspect_requirement_commands(p_requirement_ids uuid[], p_site_id uuid) TO service_role;


--
-- Name: FUNCTION is_deal_owner(p_deal_id uuid, p_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.is_deal_owner(p_deal_id uuid, p_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.is_deal_owner(p_deal_id uuid, p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.is_deal_owner(p_deal_id uuid, p_user_id uuid) TO service_role;


--
-- Name: FUNCTION is_self_service_order_items(p_items jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.is_self_service_order_items(p_items jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.is_self_service_order_items(p_items jsonb) TO service_role;


--
-- Name: FUNCTION is_service_role(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.is_service_role() FROM PUBLIC;
GRANT ALL ON FUNCTION public.is_service_role() TO authenticated;
GRANT ALL ON FUNCTION public.is_service_role() TO service_role;


--
-- Name: FUNCTION is_superadmin(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.is_superadmin() FROM PUBLIC;
GRANT ALL ON FUNCTION public.is_superadmin() TO authenticated;
GRANT ALL ON FUNCTION public.is_superadmin() TO service_role;


--
-- Name: FUNCTION is_valid_task_type(task_type text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.is_valid_task_type(task_type text) TO anon;
GRANT ALL ON FUNCTION public.is_valid_task_type(task_type text) TO authenticated;
GRANT ALL ON FUNCTION public.is_valid_task_type(task_type text) TO service_role;


--
-- Name: FUNCTION issue_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_lead_id uuid, p_normalized_email text, p_masked_email text, p_otp_hash text, p_request_ip_hash text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.issue_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_lead_id uuid, p_normalized_email text, p_masked_email text, p_otp_hash text, p_request_ip_hash text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.issue_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_lead_id uuid, p_normalized_email text, p_masked_email text, p_otp_hash text, p_request_ip_hash text) TO service_role;


--
-- Name: FUNCTION lead_open_invoice_snapshot(p_site_id uuid, p_lead_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.lead_open_invoice_snapshot(p_site_id uuid, p_lead_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.lead_open_invoice_snapshot(p_site_id uuid, p_lead_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.lead_open_invoice_snapshot(p_site_id uuid, p_lead_id uuid) TO service_role;


--
-- Name: FUNCTION license_resource_identity(item jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.license_resource_identity(item jsonb) FROM PUBLIC;


--
-- Name: FUNCTION link_stripe_checkout_session(p_sale_id uuid, p_attempt bigint, p_session_id text, p_amount_minor bigint, p_currency text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.link_stripe_checkout_session(p_sale_id uuid, p_attempt bigint, p_session_id text, p_amount_minor bigint, p_currency text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.link_stripe_checkout_session(p_sale_id uuid, p_attempt bigint, p_session_id text, p_amount_minor bigint, p_currency text) TO service_role;


--
-- Name: FUNCTION list_credit_auto_top_up_candidates(p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.list_credit_auto_top_up_candidates(p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.list_credit_auto_top_up_candidates(p_limit integer) TO service_role;


--
-- Name: FUNCTION load_harness_host_state(p_id uuid, p_site_id uuid, p_owner text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.load_harness_host_state(p_id uuid, p_site_id uuid, p_owner text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.load_harness_host_state(p_id uuid, p_site_id uuid, p_owner text) TO service_role;


--
-- Name: TABLE instance_pending_work; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_pending_work TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_pending_work TO authenticated;
GRANT ALL ON TABLE public.instance_pending_work TO service_role;
