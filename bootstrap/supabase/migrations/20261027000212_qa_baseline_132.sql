SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION claim_requirement_cron_candidates(p_max_concurrent integer, p_ttl_seconds integer, p_excluded_ids uuid[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_requirement_cron_candidates(p_max_concurrent integer, p_ttl_seconds integer, p_excluded_ids uuid[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_requirement_cron_candidates(p_max_concurrent integer, p_ttl_seconds integer, p_excluded_ids uuid[]) TO service_role;


--
-- Name: FUNCTION claim_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION claim_site_subscription_checkout(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_site_subscription_checkout(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_site_subscription_checkout(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION claim_stripe_sale_compensation(p_session_id text, p_sale_reference text, p_order_id uuid, p_payment_intent_id text, p_amount_minor bigint, p_currency text, p_reason text, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_stripe_sale_compensation(p_session_id text, p_sale_reference text, p_order_id uuid, p_payment_intent_id text, p_amount_minor bigint, p_currency text, p_reason text, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_stripe_sale_compensation(p_session_id text, p_sale_reference text, p_order_id uuid, p_payment_intent_id text, p_amount_minor bigint, p_currency text, p_reason text, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION claim_stripe_sale_fulfillment(p_sale_id uuid, p_session_id text, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_stripe_sale_fulfillment(p_sale_id uuid, p_session_id text, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_stripe_sale_fulfillment(p_sale_id uuid, p_session_id text, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION claim_stripe_webhook_event(p_event_id text, p_event_type text, p_event_data jsonb, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_stripe_webhook_event(p_event_id text, p_event_type text, p_event_data jsonb, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_stripe_webhook_event(p_event_id text, p_event_type text, p_event_data jsonb, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION claim_synced_objects_batch(p_site_id uuid, p_object_type text, p_objects jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_synced_objects_batch(p_site_id uuid, p_object_type text, p_objects jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_synced_objects_batch(p_site_id uuid, p_object_type text, p_objects jsonb) TO service_role;


--
-- Name: FUNCTION claim_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_lease_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_lease_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_lease_seconds integer) TO service_role;


--
-- Name: FUNCTION cleanup_old_webhook_events(days_old integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.cleanup_old_webhook_events(days_old integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cleanup_old_webhook_events(days_old integer) TO service_role;


--
-- Name: FUNCTION clear_instance_plan_step_infrastructure_state(p_plan_id uuid, p_step_id text, p_event_id text, p_expected_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.clear_instance_plan_step_infrastructure_state(p_plan_id uuid, p_step_id text, p_event_id text, p_expected_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.clear_instance_plan_step_infrastructure_state(p_plan_id uuid, p_step_id text, p_event_id text, p_expected_generation integer) TO service_role;


--
-- Name: FUNCTION commit_instance_context_memory(p_instance_id uuid, p_site_id uuid, p_expected_cursor timestamp with time zone, p_expected_log_id uuid, p_start_at timestamp with time zone, p_end_at timestamp with time zone, p_end_log_id uuid, p_log_ids uuid[], p_summary text, p_embedding public.vector); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.commit_instance_context_memory(p_instance_id uuid, p_site_id uuid, p_expected_cursor timestamp with time zone, p_expected_log_id uuid, p_start_at timestamp with time zone, p_end_at timestamp with time zone, p_end_log_id uuid, p_log_ids uuid[], p_summary text, p_embedding public.vector) FROM PUBLIC;
GRANT ALL ON FUNCTION public.commit_instance_context_memory(p_instance_id uuid, p_site_id uuid, p_expected_cursor timestamp with time zone, p_expected_log_id uuid, p_start_at timestamp with time zone, p_end_at timestamp with time zone, p_end_log_id uuid, p_log_ids uuid[], p_summary text, p_embedding public.vector) TO service_role;


--
-- Name: FUNCTION complete_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_source_hash text, p_source_revision bigint, p_embedding public.vector, p_model text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_source_hash text, p_source_revision bigint, p_embedding public.vector, p_model text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_source_hash text, p_source_revision bigint, p_embedding public.vector, p_model text) TO service_role;


--
-- Name: FUNCTION complete_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_customer_id text, p_amount_cents integer, p_currency text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_customer_id text, p_amount_cents integer, p_currency text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_customer_id text, p_amount_cents integer, p_currency text) TO service_role;


--
-- Name: FUNCTION complete_credit_auto_top_up_setup(p_site_id uuid, p_token uuid, p_stripe_customer_id text, p_stripe_payment_method_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_credit_auto_top_up_setup(p_site_id uuid, p_token uuid, p_stripe_customer_id text, p_stripe_payment_method_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_credit_auto_top_up_setup(p_site_id uuid, p_token uuid, p_stripe_customer_id text, p_stripe_payment_method_id text) TO service_role;


--
-- Name: FUNCTION complete_instance_plan_step_after_gate(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_final_gate_approved boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_instance_plan_step_after_gate(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_final_gate_approved boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_instance_plan_step_after_gate(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_final_gate_approved boolean) TO service_role;


--
-- Name: FUNCTION complete_marketplace_oauth(p_session_id uuid, p_encrypted_authorization text, p_expires_at timestamp with time zone, p_app_client_id_hash text, p_actor_user_id uuid, p_authorized_stores jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_marketplace_oauth(p_session_id uuid, p_encrypted_authorization text, p_expires_at timestamp with time zone, p_app_client_id_hash text, p_actor_user_id uuid, p_authorized_stores jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_marketplace_oauth(p_session_id uuid, p_encrypted_authorization text, p_expires_at timestamp with time zone, p_app_client_id_hash text, p_actor_user_id uuid, p_authorized_stores jsonb) TO service_role;


--
-- Name: FUNCTION complete_migration_diagnostic(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text, p_result jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_migration_diagnostic(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text, p_result jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_migration_diagnostic(p_requirement_id uuid, p_file text, p_token uuid, p_execution_generation integer, p_run_id text, p_result jsonb) TO service_role;


--
-- Name: FUNCTION complete_quotation_checkout(p_quotation_id uuid, p_claim_id uuid, p_sale_id uuid, p_order_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_quotation_checkout(p_quotation_id uuid, p_claim_id uuid, p_sale_id uuid, p_order_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_quotation_checkout(p_quotation_id uuid, p_claim_id uuid, p_sale_id uuid, p_order_id uuid) TO service_role;


--
-- Name: FUNCTION complete_sandbox_billing_observation(p_sandbox_name text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_sandbox_billing_observation(p_sandbox_name text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_sandbox_billing_observation(p_sandbox_name text) TO service_role;


--
-- Name: FUNCTION complete_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_refund_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_refund_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_refund_id text) TO service_role;


--
-- Name: FUNCTION complete_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION complete_stripe_webhook_event(p_event_id text, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.complete_stripe_webhook_event(p_event_id text, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.complete_stripe_webhook_event(p_event_id text, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION configure_credit_auto_top_up_settings_internal(p_site_id uuid, p_enabled boolean, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer, p_stripe_payment_method_id text, p_state text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.configure_credit_auto_top_up_settings_internal(p_site_id uuid, p_enabled boolean, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer, p_stripe_payment_method_id text, p_state text) FROM PUBLIC;


--
-- Name: FUNCTION consolidate_session_recording_duplicates(p_row_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.consolidate_session_recording_duplicates(p_row_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.consolidate_session_recording_duplicates(p_row_limit integer) TO service_role;


--
-- Name: FUNCTION control_harness_session(p_id uuid, p_site_id uuid, p_action text, p_message text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.control_harness_session(p_id uuid, p_site_id uuid, p_action text, p_message text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.control_harness_session(p_id uuid, p_site_id uuid, p_action text, p_message text) TO service_role;


--
-- Name: FUNCTION create_payout_request(p_site_id uuid, p_requested_credits numeric, p_bank_details jsonb, p_requested_by uuid, p_idempotency_key text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.create_payout_request(p_site_id uuid, p_requested_credits numeric, p_bank_details jsonb, p_requested_by uuid, p_idempotency_key text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.create_payout_request(p_site_id uuid, p_requested_credits numeric, p_bank_details jsonb, p_requested_by uuid, p_idempotency_key text) TO service_role;


--
-- Name: FUNCTION current_user_has_location_restrictions(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.current_user_has_location_restrictions() FROM PUBLIC;
GRANT ALL ON FUNCTION public.current_user_has_location_restrictions() TO authenticated;
GRANT ALL ON FUNCTION public.current_user_has_location_restrictions() TO anon;
GRANT ALL ON FUNCTION public.current_user_has_location_restrictions() TO service_role;


--
-- Name: FUNCTION current_user_has_site_location_restrictions(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.current_user_has_site_location_restrictions(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.current_user_has_site_location_restrictions(p_site_id uuid) TO authenticated;


--
-- Name: FUNCTION current_user_location_access(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.current_user_location_access(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.current_user_location_access(p_site_id uuid) TO authenticated;


--
-- Name: FUNCTION current_user_platform_role(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.current_user_platform_role() FROM PUBLIC;
GRANT ALL ON FUNCTION public.current_user_platform_role() TO authenticated;
GRANT ALL ON FUNCTION public.current_user_platform_role() TO service_role;


--
-- Name: FUNCTION current_user_site_role(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.current_user_site_role(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.current_user_site_role(p_site_id uuid) TO anon;
GRANT ALL ON FUNCTION public.current_user_site_role(p_site_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.current_user_site_role(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION debug_increment_visitor_sessions(p_visitor_id uuid, p_last_seen_timestamp bigint); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.debug_increment_visitor_sessions(p_visitor_id uuid, p_last_seen_timestamp bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.debug_increment_visitor_sessions(p_visitor_id uuid, p_last_seen_timestamp bigint) TO authenticated;
GRANT ALL ON FUNCTION public.debug_increment_visitor_sessions(p_visitor_id uuid, p_last_seen_timestamp bigint) TO service_role;


--
-- Name: FUNCTION decrypt_token(encrypted_value text, encryption_key text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.decrypt_token(encrypted_value text, encryption_key text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.decrypt_token(encrypted_value text, encryption_key text) TO authenticated;
GRANT ALL ON FUNCTION public.decrypt_token(encrypted_value text, encryption_key text) TO service_role;


--
-- Name: FUNCTION deduct_balance(p_site_id uuid, p_amount numeric); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.deduct_balance(p_site_id uuid, p_amount numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.deduct_balance(p_site_id uuid, p_amount numeric) TO service_role;


--
-- Name: FUNCTION deduct_credits(p_site_id uuid, p_credits numeric); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.deduct_credits(p_site_id uuid, p_credits numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.deduct_credits(p_site_id uuid, p_credits numeric) TO service_role;


--
-- Name: FUNCTION deduct_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.deduct_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.deduct_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb) TO service_role;


--
-- Name: FUNCTION delete_command_cascade(command_uuid uuid); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.delete_command_cascade(command_uuid uuid) TO anon;
GRANT ALL ON FUNCTION public.delete_command_cascade(command_uuid uuid) TO authenticated;
GRANT ALL ON FUNCTION public.delete_command_cascade(command_uuid uuid) TO service_role;


--
-- Name: FUNCTION delete_command_simple(command_uuid uuid); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.delete_command_simple(command_uuid uuid) TO anon;
GRANT ALL ON FUNCTION public.delete_command_simple(command_uuid uuid) TO authenticated;
GRANT ALL ON FUNCTION public.delete_command_simple(command_uuid uuid) TO service_role;


--
-- Name: FUNCTION delete_instance_logs_batch(p_instance_id uuid, p_limit integer); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.delete_instance_logs_batch(p_instance_id uuid, p_limit integer) TO anon;
GRANT ALL ON FUNCTION public.delete_instance_logs_batch(p_instance_id uuid, p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.delete_instance_logs_batch(p_instance_id uuid, p_limit integer) TO service_role;


--
-- Name: FUNCTION delete_robot_instance_with_requirements(p_instance_id uuid, p_expected_requirement_ids uuid[], p_expected_provider text, p_expected_provider_instance_id text, p_expected_status text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.delete_robot_instance_with_requirements(p_instance_id uuid, p_expected_requirement_ids uuid[], p_expected_provider text, p_expected_provider_instance_id text, p_expected_status text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_robot_instance_with_requirements(p_instance_id uuid, p_expected_requirement_ids uuid[], p_expected_provider text, p_expected_provider_instance_id text, p_expected_status text) TO authenticated;


--
-- Name: FUNCTION delete_secure_token(p_site_id uuid, p_token_type text, p_identifier text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.delete_secure_token(p_site_id uuid, p_token_type text, p_identifier text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.delete_secure_token(p_site_id uuid, p_token_type text, p_identifier text) TO authenticated;
GRANT ALL ON FUNCTION public.delete_secure_token(p_site_id uuid, p_token_type text, p_identifier text) TO service_role;


--
-- Name: FUNCTION delete_site_safely(site_id_param uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.delete_site_safely(site_id_param uuid) FROM PUBLIC;


--
-- Name: FUNCTION dispatch_harness_model_reservation(p_session_id uuid, p_event_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.dispatch_harness_model_reservation(p_session_id uuid, p_event_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.dispatch_harness_model_reservation(p_session_id uuid, p_event_id uuid) TO service_role;


--
-- Name: FUNCTION dispatch_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.dispatch_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.dispatch_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid) TO service_role;


--
-- Name: FUNCTION dispatch_workflow_database_webhook(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.dispatch_workflow_database_webhook() FROM PUBLIC;
GRANT ALL ON FUNCTION public.dispatch_workflow_database_webhook() TO service_role;


--
-- Name: FUNCTION effective_site_plan(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.effective_site_plan(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.effective_site_plan(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION encrypt_token(token_value text, encryption_key text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.encrypt_token(token_value text, encryption_key text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.encrypt_token(token_value text, encryption_key text) TO authenticated;
GRANT ALL ON FUNCTION public.encrypt_token(token_value text, encryption_key text) TO service_role;


--
-- Name: FUNCTION enforce_requirement_review_quarantine(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.enforce_requirement_review_quarantine() FROM PUBLIC;


--
-- Name: FUNCTION enforce_settings_license(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.enforce_settings_license() FROM PUBLIC;


--
-- Name: FUNCTION enforce_voice_call_concurrency(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.enforce_voice_call_concurrency() TO anon;
GRANT ALL ON FUNCTION public.enforce_voice_call_concurrency() TO authenticated;
GRANT ALL ON FUNCTION public.enforce_voice_call_concurrency() TO service_role;


--
-- Name: FUNCTION enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[]) TO service_role;


--
-- Name: FUNCTION enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[], p_replace boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[], p_replace boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.enqueue_record_embedding_job(p_record_id uuid, p_node_ids uuid[], p_replace boolean) TO service_role;


--
-- Name: FUNCTION ensure_api_key_not_expired(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.ensure_api_key_not_expired() TO anon;
GRANT ALL ON FUNCTION public.ensure_api_key_not_expired() TO authenticated;
GRANT ALL ON FUNCTION public.ensure_api_key_not_expired() TO service_role;


--
-- Name: FUNCTION evaluate_requirement_cycle_budget(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.evaluate_requirement_cycle_budget(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.evaluate_requirement_cycle_budget(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid) TO service_role;


--
-- Name: FUNCTION exchange_visitor_identity_token(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_issuer text, p_subject text, p_epoch bigint, p_jti uuid, p_issued_at bigint, p_expires_at bigint, p_token_hash text, p_name text, p_email text, p_key_id uuid, p_key_fingerprint text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.exchange_visitor_identity_token(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_issuer text, p_subject text, p_epoch bigint, p_jti uuid, p_issued_at bigint, p_expires_at bigint, p_token_hash text, p_name text, p_email text, p_key_id uuid, p_key_fingerprint text) FROM PUBLIC;


--
-- Name: FUNCTION exchange_visitor_identity_token_v2(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_issuer text, p_subject text, p_epoch bigint, p_jti uuid, p_issued_at bigint, p_expires_at bigint, p_token_hash text, p_name text, p_email text, p_key_id uuid, p_key_fingerprint text, p_key_version uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.exchange_visitor_identity_token_v2(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_issuer text, p_subject text, p_epoch bigint, p_jti uuid, p_issued_at bigint, p_expires_at bigint, p_token_hash text, p_name text, p_email text, p_key_id uuid, p_key_fingerprint text, p_key_version uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.exchange_visitor_identity_token_v2(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_issuer text, p_subject text, p_epoch bigint, p_jti uuid, p_issued_at bigint, p_expires_at bigint, p_token_hash text, p_name text, p_email text, p_key_id uuid, p_key_fingerprint text, p_key_version uuid) TO service_role;


--
-- Name: FUNCTION expire_old_api_keys(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.expire_old_api_keys() TO anon;
GRANT ALL ON FUNCTION public.expire_old_api_keys() TO authenticated;
GRANT ALL ON FUNCTION public.expire_old_api_keys() TO service_role;


--
-- Name: FUNCTION fail_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_error text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fail_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_error text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fail_catalog_embedding_job(p_job_id uuid, p_claim_token uuid, p_error text) TO service_role;


--
-- Name: FUNCTION fail_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_status text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fail_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_status text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fail_credit_auto_top_up_attempt(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text, p_stripe_status text) TO service_role;


--
-- Name: FUNCTION fail_marketplace_oauth(p_session_id uuid, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fail_marketplace_oauth(p_session_id uuid, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fail_marketplace_oauth(p_session_id uuid, p_actor_user_id uuid) TO service_role;
