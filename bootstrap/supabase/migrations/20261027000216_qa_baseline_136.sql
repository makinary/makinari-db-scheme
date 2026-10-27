SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION pos_register_capture_sale_payments(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_capture_sale_payments() FROM PUBLIC;


--
-- Name: FUNCTION pos_register_close(p_session_id uuid, p_counted_amount numeric, p_notes text, p_request_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_close(p_session_id uuid, p_counted_amount numeric, p_notes text, p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pos_register_close(p_session_id uuid, p_counted_amount numeric, p_notes text, p_request_id uuid) TO authenticated;


--
-- Name: FUNCTION pos_register_immutable_ledger(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_immutable_ledger() FROM PUBLIC;


--
-- Name: FUNCTION pos_register_move(p_session_id uuid, p_kind text, p_amount numeric, p_reason text, p_request_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_move(p_session_id uuid, p_kind text, p_amount numeric, p_reason text, p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pos_register_move(p_session_id uuid, p_kind text, p_amount numeric, p_reason text, p_request_id uuid) TO authenticated;


--
-- Name: FUNCTION pos_register_open(p_site_id uuid, p_location_id uuid, p_currency text, p_opening_amount numeric, p_request_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_open(p_site_id uuid, p_location_id uuid, p_currency text, p_opening_amount numeric, p_request_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pos_register_open(p_site_id uuid, p_location_id uuid, p_currency text, p_opening_amount numeric, p_request_id uuid) TO authenticated;


--
-- Name: FUNCTION pos_register_preserve_session(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_preserve_session() FROM PUBLIC;


--
-- Name: FUNCTION pos_register_summary(p_session_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_summary(p_session_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pos_register_summary(p_session_id uuid) TO authenticated;


--
-- Name: FUNCTION prepare_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_intent jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.prepare_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_intent jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.prepare_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_intent jsonb) TO service_role;


--
-- Name: FUNCTION preserve_marketplace_secret_identity(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.preserve_marketplace_secret_identity() FROM PUBLIC;
GRANT ALL ON FUNCTION public.preserve_marketplace_secret_identity() TO service_role;


--
-- Name: FUNCTION preserve_sale_order_creator(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.preserve_sale_order_creator() TO anon;
GRANT ALL ON FUNCTION public.preserve_sale_order_creator() TO authenticated;
GRANT ALL ON FUNCTION public.preserve_sale_order_creator() TO service_role;


--
-- Name: FUNCTION prevent_cancelled_order_reopen(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.prevent_cancelled_order_reopen() FROM PUBLIC;
GRANT ALL ON FUNCTION public.prevent_cancelled_order_reopen() TO service_role;


--
-- Name: FUNCTION prevent_last_admin_deletion(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.prevent_last_admin_deletion() TO anon;
GRANT ALL ON FUNCTION public.prevent_last_admin_deletion() TO authenticated;
GRANT ALL ON FUNCTION public.prevent_last_admin_deletion() TO service_role;


--
-- Name: FUNCTION prevent_last_admin_role_change(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.prevent_last_admin_role_change() TO anon;
GRANT ALL ON FUNCTION public.prevent_last_admin_role_change() TO authenticated;
GRANT ALL ON FUNCTION public.prevent_last_admin_role_change() TO service_role;


--
-- Name: FUNCTION preview_catalog_import_categories(p_site_id uuid, p_names jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.preview_catalog_import_categories(p_site_id uuid, p_names jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.preview_catalog_import_categories(p_site_id uuid, p_names jsonb) TO authenticated;


--
-- Name: FUNCTION process_referral_code_use(p_referral_code_id uuid, p_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.process_referral_code_use(p_referral_code_id uuid, p_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.process_referral_code_use(p_referral_code_id uuid, p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.process_referral_code_use(p_referral_code_id uuid, p_user_id uuid) TO service_role;


--
-- Name: FUNCTION protect_member_license(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.protect_member_license() FROM PUBLIC;


--
-- Name: FUNCTION protect_settings_license(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.protect_settings_license() FROM PUBLIC;


--
-- Name: FUNCTION publish_requirement_migration_hold(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.publish_requirement_migration_hold() FROM PUBLIC;


--
-- Name: FUNCTION put_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_artifact_id text, p_text text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.put_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_artifact_id text, p_text text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.put_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_artifact_id text, p_text text) TO service_role;


--
-- Name: FUNCTION queue_record_embedding_on_record_change(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.queue_record_embedding_on_record_change() FROM PUBLIC;
GRANT ALL ON FUNCTION public.queue_record_embedding_on_record_change() TO service_role;


--
-- Name: FUNCTION read_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_artifact_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.read_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_artifact_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.read_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_artifact_id text) TO service_role;


--
-- Name: FUNCTION read_site_location_restrictions(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.read_site_location_restrictions(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.read_site_location_restrictions(p_site_id uuid) TO authenticated;


--
-- Name: FUNCTION rebind_marketplace_merchant_connection(p_integration_id uuid, p_connection_id uuid, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.rebind_marketplace_merchant_connection(p_integration_id uuid, p_connection_id uuid, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.rebind_marketplace_merchant_connection(p_integration_id uuid, p_connection_id uuid, p_actor_user_id uuid) TO service_role;


--
-- Name: FUNCTION recheck_requirement_economic_pauses(p_excluded_ids uuid[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.recheck_requirement_economic_pauses(p_excluded_ids uuid[]) FROM PUBLIC;


--
-- Name: FUNCTION reconcile_instance_plan_status_atomic(p_plan_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reconcile_instance_plan_status_atomic(p_plan_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reconcile_instance_plan_status_atomic(p_plan_id uuid) TO service_role;


--
-- Name: FUNCTION reconcile_marketplace_provider_status(p_integration_id uuid, p_status text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reconcile_marketplace_provider_status(p_integration_id uuid, p_status text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reconcile_marketplace_provider_status(p_integration_id uuid, p_status text) TO service_role;


--
-- Name: FUNCTION reconcile_marketplace_provisioning(p_integration_id uuid, p_provider_batch_id text, p_status text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reconcile_marketplace_provisioning(p_integration_id uuid, p_provider_batch_id text, p_status text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reconcile_marketplace_provisioning(p_integration_id uuid, p_provider_batch_id text, p_status text) TO service_role;


--
-- Name: FUNCTION reconcile_marketplace_provisioning_status(p_integration_id uuid, p_actor_user_id uuid, p_status text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reconcile_marketplace_provisioning_status(p_integration_id uuid, p_actor_user_id uuid, p_status text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reconcile_marketplace_provisioning_status(p_integration_id uuid, p_actor_user_id uuid, p_status text) TO service_role;


--
-- Name: FUNCTION reconcile_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_expected_updated_at timestamp with time zone, p_expected_backlog_revision bigint, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reconcile_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_expected_updated_at timestamp with time zone, p_expected_backlog_revision bigint, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reconcile_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_expected_updated_at timestamp with time zone, p_expected_backlog_revision bigint, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb) TO service_role;


--
-- Name: FUNCTION reconcile_site_member_license(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reconcile_site_member_license(p_site_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION record_channel_health_event(p_site_id uuid, p_channel text, p_direction text, p_source_id uuid, p_outcome text, p_error_class text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_channel_health_event(p_site_id uuid, p_channel text, p_direction text, p_source_id uuid, p_outcome text, p_error_class text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_channel_health_event(p_site_id uuid, p_channel text, p_direction text, p_source_id uuid, p_outcome text, p_error_class text) TO service_role;


--
-- Name: FUNCTION record_credit_auto_top_up_consent(p_site_id uuid, p_actor_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_credit_auto_top_up_consent(p_site_id uuid, p_actor_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_credit_auto_top_up_consent(p_site_id uuid, p_actor_id uuid) TO service_role;


--
-- Name: FUNCTION record_credit_auto_top_up_intent(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_credit_auto_top_up_intent(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_credit_auto_top_up_intent(p_site_id uuid, p_attempt_id uuid, p_claim_token uuid, p_stripe_payment_intent_id text) TO service_role;


--
-- Name: FUNCTION record_harness_diagnostic_decision(p_site_id uuid, p_requirement_id uuid, p_instance_id uuid, p_expected_backlog_revision bigint, p_expected_updated_at timestamp with time zone, p_request_id uuid, p_decision text, p_item_id text, p_reason text, p_payload jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_harness_diagnostic_decision(p_site_id uuid, p_requirement_id uuid, p_instance_id uuid, p_expected_backlog_revision bigint, p_expected_updated_at timestamp with time zone, p_request_id uuid, p_decision text, p_item_id text, p_reason text, p_payload jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_harness_diagnostic_decision(p_site_id uuid, p_requirement_id uuid, p_instance_id uuid, p_expected_backlog_revision bigint, p_expected_updated_at timestamp with time zone, p_request_id uuid, p_decision text, p_item_id text, p_reason text, p_payload jsonb) TO service_role;


--
-- Name: FUNCTION record_instance_context_breakdown(p_instance_id uuid, p_site_id uuid, p_model text, p_used_tokens integer, p_source text, p_measured_at timestamp with time zone, p_breakdown jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_instance_context_breakdown(p_instance_id uuid, p_site_id uuid, p_model text, p_used_tokens integer, p_source text, p_measured_at timestamp with time zone, p_breakdown jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_instance_context_breakdown(p_instance_id uuid, p_site_id uuid, p_model text, p_used_tokens integer, p_source text, p_measured_at timestamp with time zone, p_breakdown jsonb) TO service_role;


--
-- Name: FUNCTION record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_available_tokens integer, p_source text, p_measured_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_available_tokens integer, p_source text, p_measured_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_available_tokens integer, p_source text, p_measured_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_output_tokens integer, p_available_tokens integer, p_source text, p_measured_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_output_tokens integer, p_available_tokens integer, p_source text, p_measured_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_output_tokens integer, p_available_tokens integer, p_source text, p_measured_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_output_tokens integer, p_available_tokens integer, p_reserved_output_tokens integer, p_source text, p_measured_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_output_tokens integer, p_available_tokens integer, p_reserved_output_tokens integer, p_source text, p_measured_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_instance_context_usage(p_instance_id uuid, p_site_id uuid, p_model text, p_provider text, p_used_tokens integer, p_output_tokens integer, p_available_tokens integer, p_reserved_output_tokens integer, p_source text, p_measured_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION record_instance_plan_step_infrastructure_failure(p_plan_id uuid, p_step_id text, p_event_id text, p_error_message text, p_wait jsonb, p_max_retries integer, p_expected_generation integer, p_allow_retryable_failed boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_instance_plan_step_infrastructure_failure(p_plan_id uuid, p_step_id text, p_event_id text, p_error_message text, p_wait jsonb, p_max_retries integer, p_expected_generation integer, p_allow_retryable_failed boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_instance_plan_step_infrastructure_failure(p_plan_id uuid, p_step_id text, p_event_id text, p_error_message text, p_wait jsonb, p_max_retries integer, p_expected_generation integer, p_allow_retryable_failed boolean) TO service_role;


--
-- Name: FUNCTION record_lead_invoice_payment(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_lead_invoice_payment(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_lead_invoice_payment(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.record_lead_invoice_payment(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text) TO service_role;


--
-- Name: FUNCTION record_outstand_initial_import(p_site_id uuid, p_account_id text, p_status text, p_job_id text, p_imported integer, p_failed integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_outstand_initial_import(p_site_id uuid, p_account_id text, p_status text, p_job_id text, p_imported integer, p_failed integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_outstand_initial_import(p_site_id uuid, p_account_id text, p_status text, p_job_id text, p_imported integer, p_failed integer) TO authenticated;
GRANT ALL ON FUNCTION public.record_outstand_initial_import(p_site_id uuid, p_account_id text, p_status text, p_job_id text, p_imported integer, p_failed integer) TO service_role;


--
-- Name: FUNCTION record_payment(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying, p_payment_method character varying, p_details jsonb, p_credits integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_payment(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying, p_payment_method character varying, p_details jsonb, p_credits integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_payment(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying, p_payment_method character varying, p_details jsonb, p_credits integer) TO authenticated;
GRANT ALL ON FUNCTION public.record_payment(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying, p_payment_method character varying, p_details jsonb, p_credits integer) TO service_role;


--
-- Name: FUNCTION record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid) TO service_role;


--
-- Name: FUNCTION record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid, p_plan_id uuid, p_step_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid, p_plan_id uuid, p_step_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_requirement_cron_cycle_outcome(p_requirement_id uuid, p_cycle_id text, p_cycle_started_at timestamp with time zone, p_outcome text, p_expected_execution_generation integer, p_runner_instance_id uuid, p_plan_id uuid, p_step_id text) TO service_role;


--
-- Name: FUNCTION record_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_result jsonb, p_baseline jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.record_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_result jsonb, p_baseline jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.record_requirement_source_checkpoint(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_owner text, p_result jsonb, p_baseline jsonb) TO service_role;


--
-- Name: FUNCTION recover_ready_deployment_infrastructure(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_branch text, p_commit_sha text, p_deployment_id text, p_preview_url text, p_recovery_id text, p_allow_legacy boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.recover_ready_deployment_infrastructure(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_branch text, p_commit_sha text, p_deployment_id text, p_preview_url text, p_recovery_id text, p_allow_legacy boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.recover_ready_deployment_infrastructure(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_branch text, p_commit_sha text, p_deployment_id text, p_preview_url text, p_recovery_id text, p_allow_legacy boolean) TO service_role;


--
-- Name: FUNCTION refresh_catalog_search_document(p_item_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.refresh_catalog_search_document(p_item_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION refresh_conversation_message_summary(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.refresh_conversation_message_summary() FROM PUBLIC;
GRANT ALL ON FUNCTION public.refresh_conversation_message_summary() TO authenticated;
GRANT ALL ON FUNCTION public.refresh_conversation_message_summary() TO service_role;


--
-- Name: FUNCTION register_referral_code_use(code_param text, user_id_param uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.register_referral_code_use(code_param text, user_id_param uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.register_referral_code_use(code_param text, user_id_param uuid) TO authenticated;
GRANT ALL ON FUNCTION public.register_referral_code_use(code_param text, user_id_param uuid) TO service_role;


--
-- Name: FUNCTION register_sandbox_billing(p_sandbox_name text, p_owner_kind text, p_owner_id uuid, p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.register_sandbox_billing(p_sandbox_name text, p_owner_kind text, p_owner_id uuid, p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.register_sandbox_billing(p_sandbox_name text, p_owner_kind text, p_owner_id uuid, p_site_id uuid) TO service_role;


--
-- Name: FUNCTION reject_migration_execution_handoff_mutation(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reject_migration_execution_handoff_mutation() FROM PUBLIC;


--
-- Name: FUNCTION reject_migration_reconciliation_mutation(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reject_migration_reconciliation_mutation() FROM PUBLIC;


--
-- Name: FUNCTION reject_migration_retirement_mutation(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reject_migration_retirement_mutation() FROM PUBLIC;


--
-- Name: FUNCTION release_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.release_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.release_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text) TO service_role;


--
-- Name: FUNCTION release_harness_session(p_id uuid, p_site_id uuid, p_owner text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.release_harness_session(p_id uuid, p_site_id uuid, p_owner text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.release_harness_session(p_id uuid, p_site_id uuid, p_owner text) TO service_role;


--
-- Name: FUNCTION release_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_reason text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.release_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.release_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION release_quotation_checkout_claim(p_quotation_id uuid, p_claim_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.release_quotation_checkout_claim(p_quotation_id uuid, p_claim_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.release_quotation_checkout_claim(p_quotation_id uuid, p_claim_id uuid) TO service_role;


--
-- Name: FUNCTION release_self_service_order(p_site_id uuid, p_order_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.release_self_service_order(p_site_id uuid, p_order_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.release_self_service_order(p_site_id uuid, p_order_id uuid) TO service_role;


--
-- Name: FUNCTION remove_all_delete_protection_triggers(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.remove_all_delete_protection_triggers() FROM PUBLIC;
GRANT ALL ON FUNCTION public.remove_all_delete_protection_triggers() TO authenticated;
GRANT ALL ON FUNCTION public.remove_all_delete_protection_triggers() TO service_role;


--
-- Name: FUNCTION remove_delete_protection_trigger(p_table_name text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.remove_delete_protection_trigger(p_table_name text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.remove_delete_protection_trigger(p_table_name text) TO authenticated;
GRANT ALL ON FUNCTION public.remove_delete_protection_trigger(p_table_name text) TO service_role;


--
-- Name: FUNCTION renew_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.renew_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.renew_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer) TO service_role;
