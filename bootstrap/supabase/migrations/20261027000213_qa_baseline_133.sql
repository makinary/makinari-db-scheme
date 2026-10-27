SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION fail_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_error text, p_manual_review boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fail_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_error text, p_manual_review boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fail_stripe_sale_compensation(p_session_id text, p_claim_token uuid, p_error text, p_manual_review boolean) TO service_role;


--
-- Name: FUNCTION fail_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fail_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fail_stripe_sale_fulfillment(p_session_id text, p_claim_token uuid) TO service_role;


--
-- Name: FUNCTION fail_stripe_webhook_event(p_event_id text, p_claim_token uuid, p_error_message text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fail_stripe_webhook_event(p_event_id text, p_claim_token uuid, p_error_message text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fail_stripe_webhook_event(p_event_id text, p_claim_token uuid, p_error_message text) TO service_role;


--
-- Name: FUNCTION fence_retired_stripe_subscription_identity(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fence_retired_stripe_subscription_identity() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fence_retired_stripe_subscription_identity() TO service_role;


--
-- Name: FUNCTION fetch_sites_needing_billing_initialization(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fetch_sites_needing_billing_initialization() FROM PUBLIC;
GRANT ALL ON FUNCTION public.fetch_sites_needing_billing_initialization() TO service_role;


--
-- Name: FUNCTION fetch_social_posts_due_for_analytics(p_site_ids uuid[], p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.fetch_social_posts_due_for_analytics(p_site_ids uuid[], p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.fetch_social_posts_due_for_analytics(p_site_ids uuid[], p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.fetch_social_posts_due_for_analytics(p_site_ids uuid[], p_limit integer) TO service_role;


--
-- Name: FUNCTION finalize_requirement_execution_atomic(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_expected_execution_generation integer, p_event_id text, p_existing_status_id uuid, p_stage text, p_message text, p_repo_url text, p_preview_url text, p_source_code text, p_snapshot_id text, p_is_complete boolean, p_mark_on_review boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finalize_requirement_execution_atomic(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_expected_execution_generation integer, p_event_id text, p_existing_status_id uuid, p_stage text, p_message text, p_repo_url text, p_preview_url text, p_source_code text, p_snapshot_id text, p_is_complete boolean, p_mark_on_review boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finalize_requirement_execution_atomic(p_requirement_id uuid, p_site_id uuid, p_instance_id uuid, p_expected_execution_generation integer, p_event_id text, p_existing_status_id uuid, p_stage text, p_message text, p_repo_url text, p_preview_url text, p_source_code text, p_snapshot_id text, p_is_complete boolean, p_mark_on_review boolean) TO service_role;


--
-- Name: FUNCTION finalize_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid, p_state text, p_receipt jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finalize_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid, p_state text, p_receipt jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finalize_setup_email_delivery(p_operation_key text, p_site_id uuid, p_payload jsonb, p_claim_token uuid, p_state text, p_receipt jsonb) TO service_role;


--
-- Name: FUNCTION finish_agent_requirement_cycle(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_session_status text, p_reason text, p_summary text, p_repo_url text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_agent_requirement_cycle(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_session_status text, p_reason text, p_summary text, p_repo_url text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_agent_requirement_cycle(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_session_status text, p_reason text, p_summary text, p_repo_url text) TO service_role;


--
-- Name: FUNCTION finish_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_cost numeric, p_generation_id text, p_model text, p_cancel_reason text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_cost numeric, p_generation_id text, p_model text, p_cancel_reason text) FROM PUBLIC;


--
-- Name: FUNCTION finish_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_harness_sandbox_cleanup(p_id uuid, p_site_id uuid, p_token uuid) TO service_role;


--
-- Name: FUNCTION finish_icp_dispatch(p_id uuid, p_run_id uuid, p_errors jsonb, p_retry_after_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_icp_dispatch(p_id uuid, p_run_id uuid, p_errors jsonb, p_retry_after_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_icp_dispatch(p_id uuid, p_run_id uuid, p_errors jsonb, p_retry_after_seconds integer) TO service_role;


--
-- Name: FUNCTION finish_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_count integer, p_reason text, p_generation_id text, p_model text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_count integer, p_reason text, p_generation_id text, p_model text) FROM PUBLIC;


--
-- Name: FUNCTION finish_marketplace_action(p_action_id uuid, p_result text, p_metadata jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_marketplace_action(p_action_id uuid, p_result text, p_metadata jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_marketplace_action(p_action_id uuid, p_result text, p_metadata jsonb) TO service_role;


--
-- Name: FUNCTION finish_marketplace_provisioning(p_integration_id uuid, p_batch_id uuid, p_result text, p_actor_user_id uuid, p_provider_batch_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_marketplace_provisioning(p_integration_id uuid, p_batch_id uuid, p_result text, p_actor_user_id uuid, p_provider_batch_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_marketplace_provisioning(p_integration_id uuid, p_batch_id uuid, p_result text, p_actor_user_id uuid, p_provider_batch_id text) TO service_role;


--
-- Name: FUNCTION finish_marketplace_webhook_registration(p_claim_id uuid, p_result text, p_secret_ciphertext text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_marketplace_webhook_registration(p_claim_id uuid, p_result text, p_secret_ciphertext text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_marketplace_webhook_registration(p_claim_id uuid, p_result text, p_secret_ciphertext text) TO service_role;


--
-- Name: FUNCTION finish_marketplace_webhook_registration_app(p_claim_id uuid, p_result text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_marketplace_webhook_registration_app(p_claim_id uuid, p_result text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_marketplace_webhook_registration_app(p_claim_id uuid, p_result text) TO service_role;


--
-- Name: FUNCTION finish_provider_webhook_event(p_provider text, p_event_id text, p_claim_token uuid, p_status text, p_error_message text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_provider_webhook_event(p_provider text, p_event_id text, p_claim_token uuid, p_status text, p_error_message text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_provider_webhook_event(p_provider text, p_event_id text, p_claim_token uuid, p_status text, p_error_message text) TO service_role;


--
-- Name: FUNCTION finish_site_subscription_checkout(p_site_id uuid, p_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_site_subscription_checkout(p_site_id uuid, p_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_site_subscription_checkout(p_site_id uuid, p_token uuid) TO service_role;


--
-- Name: FUNCTION finish_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_status text, p_error_message text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.finish_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_status text, p_error_message text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.finish_workflow_run_execution(p_run_plan_id uuid, p_claim_token uuid, p_status text, p_error_message text) TO service_role;


--
-- Name: FUNCTION generate_task_serial_id(site_uuid uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.generate_task_serial_id(site_uuid uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.generate_task_serial_id(site_uuid uuid) TO authenticated;
GRANT ALL ON FUNCTION public.generate_task_serial_id(site_uuid uuid) TO service_role;


--
-- Name: FUNCTION get_auth_user_id(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_auth_user_id() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_auth_user_id() TO authenticated;
GRANT ALL ON FUNCTION public.get_auth_user_id() TO service_role;


--
-- Name: FUNCTION get_my_accessible_sites(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_my_accessible_sites() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_my_accessible_sites() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_accessible_sites() TO service_role;


--
-- Name: FUNCTION get_my_site_capabilities(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_my_site_capabilities(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_my_site_capabilities(p_site_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_my_site_capabilities(p_site_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_my_site_capabilities(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION get_my_site_members(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_my_site_members(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_my_site_members(p_site_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_my_site_members(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION get_performance_status(command_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_performance_status(command_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_performance_status(command_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_performance_status(command_id uuid) TO service_role;


--
-- Name: FUNCTION get_record_diagram_context(p_record_id uuid, p_node_limit integer, p_content_limit integer, p_edge_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_record_diagram_context(p_record_id uuid, p_node_limit integer, p_content_limit integer, p_edge_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_record_diagram_context(p_record_id uuid, p_node_limit integer, p_content_limit integer, p_edge_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_record_diagram_context(p_record_id uuid, p_node_limit integer, p_content_limit integer, p_edge_limit integer) TO service_role;


--
-- Name: FUNCTION get_record_diagram_neighborhood(p_node_ids uuid[], p_neighbor_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_record_diagram_neighborhood(p_node_ids uuid[], p_neighbor_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_record_diagram_neighborhood(p_node_ids uuid[], p_neighbor_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_record_diagram_neighborhood(p_node_ids uuid[], p_neighbor_limit integer) TO service_role;


--
-- Name: FUNCTION get_records_similarity_edges(p_site_id uuid, match_threshold double precision, match_per_record integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_records_similarity_edges(p_site_id uuid, match_threshold double precision, match_per_record integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_records_similarity_edges(p_site_id uuid, match_threshold double precision, match_per_record integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_records_similarity_edges(p_site_id uuid, match_threshold double precision, match_per_record integer) TO service_role;


--
-- Name: FUNCTION get_robot_instance_deletion_scope(p_instance_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_robot_instance_deletion_scope(p_instance_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_robot_instance_deletion_scope(p_instance_id uuid) TO authenticated;


--
-- Name: FUNCTION get_secure_token(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_secure_token(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_secure_token(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text) TO authenticated;
GRANT ALL ON FUNCTION public.get_secure_token(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text) TO service_role;


--
-- Name: FUNCTION get_site_licensed_resources(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_site_licensed_resources(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_site_licensed_resources(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION get_site_member_license(p_site_id uuid, p_member_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_site_member_license(p_site_id uuid, p_member_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_site_member_license(p_site_id uuid, p_member_id uuid) TO service_role;


--
-- Name: FUNCTION get_site_startup_trial(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_site_startup_trial(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_site_startup_trial(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION get_system_status_daily(p_since timestamp with time zone, p_until timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_system_status_daily(p_since timestamp with time zone, p_until timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_system_status_daily(p_since timestamp with time zone, p_until timestamp with time zone) TO service_role;


--
-- Name: FUNCTION get_system_status_observed_sla(p_since timestamp with time zone, p_until timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_system_status_observed_sla(p_since timestamp with time zone, p_until timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_system_status_observed_sla(p_since timestamp with time zone, p_until timestamp with time zone) TO service_role;


--
-- Name: FUNCTION get_system_status_sla(p_since timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_system_status_sla(p_since timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_system_status_sla(p_since timestamp with time zone) TO service_role;


--
-- Name: FUNCTION get_user_by_phone(phone_variants text[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_user_by_phone(phone_variants text[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_user_by_phone(phone_variants text[]) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_by_phone(phone_variants text[]) TO service_role;


--
-- Name: FUNCTION get_user_profile_complete(user_id_param uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.get_user_profile_complete(user_id_param uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_user_profile_complete(user_id_param uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_user_profile_complete(user_id_param uuid) TO service_role;


--
-- Name: FUNCTION grant_new_visitor_identity(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_lead_id uuid, p_normalized_email text, p_trusted_token_hash text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.grant_new_visitor_identity(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_lead_id uuid, p_normalized_email text, p_trusted_token_hash text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.grant_new_visitor_identity(p_site_id uuid, p_session_id uuid, p_visitor_id uuid, p_lead_id uuid, p_normalized_email text, p_trusted_token_hash text) TO service_role;


--
-- Name: FUNCTION grant_purchased_site_credits(p_site_id uuid, p_amount numeric, p_idempotency_key text, p_metadata jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.grant_purchased_site_credits(p_site_id uuid, p_amount numeric, p_idempotency_key text, p_metadata jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.grant_purchased_site_credits(p_site_id uuid, p_amount numeric, p_idempotency_key text, p_metadata jsonb) TO service_role;


--
-- Name: FUNCTION guard_allowed_domain_provenance(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_allowed_domain_provenance() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_allowed_domain_provenance() TO service_role;


--
-- Name: FUNCTION guard_archived_runner_reassignment_history(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_archived_runner_reassignment_history() FROM PUBLIC;


--
-- Name: FUNCTION guard_archived_site_domain(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_archived_site_domain() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_archived_site_domain() TO service_role;


--
-- Name: FUNCTION guard_billing_credit_buckets(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_billing_credit_buckets() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_billing_credit_buckets() TO service_role;


--
-- Name: FUNCTION guard_billing_paid_subscription_coverage(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.guard_billing_paid_subscription_coverage() TO anon;
GRANT ALL ON FUNCTION public.guard_billing_paid_subscription_coverage() TO authenticated;
GRANT ALL ON FUNCTION public.guard_billing_paid_subscription_coverage() TO service_role;


--
-- Name: FUNCTION guard_cancelled_instance_plan(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_cancelled_instance_plan() FROM PUBLIC;


--
-- Name: FUNCTION guard_catalog_archive_redeemable_link(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_catalog_archive_redeemable_link() FROM PUBLIC;


--
-- Name: FUNCTION guard_catalog_category_archive(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_catalog_category_archive() FROM PUBLIC;


--
-- Name: FUNCTION guard_catalog_import_category_name(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_catalog_import_category_name() FROM PUBLIC;


--
-- Name: FUNCTION guard_catalog_item_archive_membership(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_catalog_item_archive_membership() FROM PUBLIC;


--
-- Name: FUNCTION guard_credit_auto_top_up_card_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_credit_auto_top_up_card_binding() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_credit_auto_top_up_card_binding() TO service_role;


--
-- Name: FUNCTION guard_cron_outcome_instance_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_cron_outcome_instance_binding() FROM PUBLIC;


--
-- Name: FUNCTION guard_external_identity_grant(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_external_identity_grant() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_external_identity_grant() TO service_role;


--
-- Name: FUNCTION guard_harness_sandbox_cleanup(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_harness_sandbox_cleanup() FROM PUBLIC;
GRANT ALL ON FUNCTION public.guard_harness_sandbox_cleanup() TO service_role;


--
-- Name: FUNCTION guard_harness_session(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_harness_session() FROM PUBLIC;


--
-- Name: FUNCTION guard_icp_mining_execution_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.guard_icp_mining_execution_update() TO anon;
GRANT ALL ON FUNCTION public.guard_icp_mining_execution_update() TO authenticated;
GRANT ALL ON FUNCTION public.guard_icp_mining_execution_update() TO service_role;


--
-- Name: FUNCTION guard_icypeas_email_search(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_icypeas_email_search() FROM PUBLIC;


--
-- Name: FUNCTION guard_instance_log_requirement_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_instance_log_requirement_binding() FROM PUBLIC;


--
-- Name: FUNCTION guard_instance_plan_requirement_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_instance_plan_requirement_binding() FROM PUBLIC;


--
-- Name: FUNCTION guard_instance_requirement_metadata_binding(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.guard_instance_requirement_metadata_binding() FROM PUBLIC;
