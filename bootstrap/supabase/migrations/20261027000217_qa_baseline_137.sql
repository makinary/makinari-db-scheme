SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION renew_site_plan_credits(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.renew_site_plan_credits(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.renew_site_plan_credits(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION renew_workflow_run_execution_claim(p_run_plan_id uuid, p_claim_token uuid, p_lease_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.renew_workflow_run_execution_claim(p_run_plan_id uuid, p_claim_token uuid, p_lease_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.renew_workflow_run_execution_claim(p_run_plan_id uuid, p_claim_token uuid, p_lease_seconds integer) TO service_role;


--
-- Name: FUNCTION reorder_task_priorities(p_task_id uuid, p_new_position integer, p_status text, p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reorder_task_priorities(p_task_id uuid, p_new_position integer, p_status text, p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reorder_task_priorities(p_task_id uuid, p_new_position integer, p_status text, p_site_id uuid) TO authenticated;


--
-- Name: FUNCTION repair_stripe_sale_wallet_currency(p_site_id uuid, p_session_id text, p_expected_gross numeric, p_expected_commission numeric, p_expected_currency text, p_usd_amount_minor bigint, p_evidence jsonb, p_apply boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.repair_stripe_sale_wallet_currency(p_site_id uuid, p_session_id text, p_expected_gross numeric, p_expected_commission numeric, p_expected_currency text, p_usd_amount_minor bigint, p_evidence jsonb, p_apply boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.repair_stripe_sale_wallet_currency(p_site_id uuid, p_session_id text, p_expected_gross numeric, p_expected_commission numeric, p_expected_currency text, p_usd_amount_minor bigint, p_evidence jsonb, p_apply boolean) TO service_role;


--
-- Name: FUNCTION replace_archived_requirement_runner(p_requirement_id uuid, p_run_id text, p_expected_instance_id uuid, p_expected_execution_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.replace_archived_requirement_runner(p_requirement_id uuid, p_run_id text, p_expected_instance_id uuid, p_expected_execution_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.replace_archived_requirement_runner(p_requirement_id uuid, p_run_id text, p_expected_instance_id uuid, p_expected_execution_generation integer) TO service_role;


--
-- Name: FUNCTION replace_site_member_location_restrictions(p_site_id uuid, p_member_id uuid, p_location_ids uuid[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.replace_site_member_location_restrictions(p_site_id uuid, p_member_id uuid, p_location_ids uuid[]) FROM PUBLIC;


--
-- Name: FUNCTION replace_site_member_location_restrictions_checked(p_site_id uuid, p_member_id uuid, p_location_ids uuid[], p_expected_location_ids uuid[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.replace_site_member_location_restrictions_checked(p_site_id uuid, p_member_id uuid, p_location_ids uuid[], p_expected_location_ids uuid[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.replace_site_member_location_restrictions_checked(p_site_id uuid, p_member_id uuid, p_location_ids uuid[], p_expected_location_ids uuid[]) TO authenticated;


--
-- Name: FUNCTION requirement_budget_observation(p_requirement_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.requirement_budget_observation(p_requirement_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION requirement_pause_command_guard(p_id uuid, p_guard jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.requirement_pause_command_guard(p_id uuid, p_guard jsonb) FROM PUBLIC;


--
-- Name: FUNCTION requirement_quarantine_timestamp(p_item jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.requirement_quarantine_timestamp(p_item jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.requirement_quarantine_timestamp(p_item jsonb) TO service_role;


--
-- Name: FUNCTION resend_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_otp_hash text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.resend_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_otp_hash text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.resend_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_otp_hash text) TO service_role;


--
-- Name: FUNCTION reserve_agent_requirement_credits(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_event_id uuid, p_amount numeric); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reserve_agent_requirement_credits(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_event_id uuid, p_amount numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reserve_agent_requirement_credits(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_event_id uuid, p_amount numeric) TO service_role;


--
-- Name: FUNCTION reserve_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_bytes integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reserve_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_bytes integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reserve_harness_artifact(p_id uuid, p_site_id uuid, p_owner text, p_operation_id text, p_bytes integer) TO service_role;


--
-- Name: FUNCTION reserve_harness_model_credits(p_session_id uuid, p_site_id uuid, p_owner text, p_event_id uuid, p_amount numeric); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reserve_harness_model_credits(p_session_id uuid, p_site_id uuid, p_owner text, p_event_id uuid, p_amount numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reserve_harness_model_credits(p_session_id uuid, p_site_id uuid, p_owner text, p_event_id uuid, p_amount numeric) TO service_role;


--
-- Name: FUNCTION reserve_icp_dispatch(p_site_id uuid, p_icp_id uuid, p_dispatch_key text, p_workflow_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reserve_icp_dispatch(p_site_id uuid, p_icp_id uuid, p_dispatch_key text, p_workflow_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reserve_icp_dispatch(p_site_id uuid, p_icp_id uuid, p_dispatch_key text, p_workflow_id text) TO service_role;


--
-- Name: FUNCTION reserve_platform_quota(p_site_id uuid, p_capability text, p_period text, p_cost integer, p_default_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reserve_platform_quota(p_site_id uuid, p_capability text, p_period text, p_cost integer, p_default_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reserve_platform_quota(p_site_id uuid, p_capability text, p_period text, p_cost integer, p_default_limit integer) TO service_role;


--
-- Name: FUNCTION reserve_stripe_checkout_attempt(p_sale_id uuid, p_amount_minor bigint, p_currency text, p_expected_session_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reserve_stripe_checkout_attempt(p_sale_id uuid, p_amount_minor bigint, p_currency text, p_expected_session_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reserve_stripe_checkout_attempt(p_sale_id uuid, p_amount_minor bigint, p_currency text, p_expected_session_id text) TO service_role;


--
-- Name: FUNCTION reset_channel_health_on_reconfiguration(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reset_channel_health_on_reconfiguration() FROM PUBLIC;
GRANT ALL ON FUNCTION public.reset_channel_health_on_reconfiguration() TO service_role;


--
-- Name: FUNCTION reset_credit_auto_top_up_card_source(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reset_credit_auto_top_up_card_source() FROM PUBLIC;
GRANT ALL ON FUNCTION public.reset_credit_auto_top_up_card_source() TO service_role;


--
-- Name: FUNCTION reset_site_plan_credit_period(p_site_id uuid, p_period_start timestamp with time zone, p_period_end timestamp with time zone, p_allowance numeric, p_source text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reset_site_plan_credit_period(p_site_id uuid, p_period_start timestamp with time zone, p_period_end timestamp with time zone, p_allowance numeric, p_source text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reset_site_plan_credit_period(p_site_id uuid, p_period_start timestamp with time zone, p_period_end timestamp with time zone, p_allowance numeric, p_source text) TO service_role;


--
-- Name: FUNCTION reset_stuck_sending_messages(p_cutoff timestamp with time zone, p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.reset_stuck_sending_messages(p_cutoff timestamp with time zone, p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.reset_stuck_sending_messages(p_cutoff timestamp with time zone, p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.reset_stuck_sending_messages(p_cutoff timestamp with time zone, p_limit integer) TO service_role;


--
-- Name: FUNCTION resolve_payout_request(p_payout_id uuid, p_status text, p_resolved_by uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.resolve_payout_request(p_payout_id uuid, p_status text, p_resolved_by uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.resolve_payout_request(p_payout_id uuid, p_status text, p_resolved_by uuid) TO service_role;


--
-- Name: FUNCTION resume_instance_execution_on_user_action(p_requirement_id uuid, p_instance_id uuid, p_reopen_paused_plans boolean, p_action_id text, p_allow_terminal_reopen boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.resume_instance_execution_on_user_action(p_requirement_id uuid, p_instance_id uuid, p_reopen_paused_plans boolean, p_action_id text, p_allow_terminal_reopen boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.resume_instance_execution_on_user_action(p_requirement_id uuid, p_instance_id uuid, p_reopen_paused_plans boolean, p_action_id text, p_allow_terminal_reopen boolean) TO service_role;


--
-- Name: FUNCTION resume_reconciled_requirement_migration(p_requirement_id uuid, p_receipt_id uuid, p_evidence jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.resume_reconciled_requirement_migration(p_requirement_id uuid, p_receipt_id uuid, p_evidence jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.resume_reconciled_requirement_migration(p_requirement_id uuid, p_receipt_id uuid, p_evidence jsonb) TO service_role;


--
-- Name: FUNCTION retire_requirement_migration_hold(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.retire_requirement_migration_hold(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.retire_requirement_migration_hold(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text) TO service_role;


--
-- Name: FUNCTION retire_sandbox_billing(p_sandbox_name text, p_phase text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.retire_sandbox_billing(p_sandbox_name text, p_phase text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.retire_sandbox_billing(p_sandbox_name text, p_phase text) TO service_role;


--
-- Name: FUNCTION revoke_marketplace_merchant_connection(p_connection_id uuid, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.revoke_marketplace_merchant_connection(p_connection_id uuid, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.revoke_marketplace_merchant_connection(p_connection_id uuid, p_actor_user_id uuid) TO service_role;


--
-- Name: FUNCTION revoke_visitor_identity_issuer_grants(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.revoke_visitor_identity_issuer_grants() FROM PUBLIC;
GRANT ALL ON FUNCTION public.revoke_visitor_identity_issuer_grants() TO service_role;


--
-- Name: FUNCTION revoke_visitor_session_identity(p_site_id uuid, p_session_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.revoke_visitor_session_identity(p_site_id uuid, p_session_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.revoke_visitor_session_identity(p_site_id uuid, p_session_id uuid) TO service_role;


--
-- Name: FUNCTION robot_instance_requirement_candidates(p_instance_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.robot_instance_requirement_candidates(p_instance_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION rollback_api_keys(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.rollback_api_keys() TO anon;
GRANT ALL ON FUNCTION public.rollback_api_keys() TO authenticated;
GRANT ALL ON FUNCTION public.rollback_api_keys() TO service_role;


--
-- Name: FUNCTION save_credit_auto_top_up_with_billing_card(p_site_id uuid, p_actor_id uuid, p_stripe_customer_id text, p_stripe_payment_method_id text, p_expected_setup_token uuid, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_credit_auto_top_up_with_billing_card(p_site_id uuid, p_actor_id uuid, p_stripe_customer_id text, p_stripe_payment_method_id text, p_expected_setup_token uuid, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_credit_auto_top_up_with_billing_card(p_site_id uuid, p_actor_id uuid, p_stripe_customer_id text, p_stripe_payment_method_id text, p_expected_setup_token uuid, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer) TO service_role;


--
-- Name: FUNCTION save_harness_host_state(p_id uuid, p_site_id uuid, p_owner text, p_expected_version bigint, p_ciphertext text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_harness_host_state(p_id uuid, p_site_id uuid, p_owner text, p_expected_version bigint, p_ciphertext text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_harness_host_state(p_id uuid, p_site_id uuid, p_owner text, p_expected_version bigint, p_ciphertext text) TO service_role;


--
-- Name: FUNCTION save_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_snapshot jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_snapshot jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_snapshot jsonb) TO service_role;


--
-- Name: FUNCTION save_marketplace_integration(p_config jsonb, p_secret_id uuid, p_encrypted_credentials text, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_marketplace_integration(p_config jsonb, p_secret_id uuid, p_encrypted_credentials text, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_marketplace_integration(p_config jsonb, p_secret_id uuid, p_encrypted_credentials text, p_actor_user_id uuid) TO service_role;


--
-- Name: FUNCTION save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_summary text, p_embedding public.vector); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_summary text, p_embedding public.vector) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_summary text, p_embedding public.vector) TO service_role;


--
-- Name: FUNCTION save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_summary text, p_embedding public.vector); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_summary text, p_embedding public.vector) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_record_aggregate_embedding(p_record_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_summary text, p_embedding public.vector) TO service_role;


--
-- Name: FUNCTION save_record_diagram(p_record_id uuid, p_expected_revision bigint, p_viewport jsonb, p_nodes jsonb, p_edges jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_record_diagram(p_record_id uuid, p_expected_revision bigint, p_viewport jsonb, p_nodes jsonb, p_edges jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_record_diagram(p_record_id uuid, p_expected_revision bigint, p_viewport jsonb, p_nodes jsonb, p_edges jsonb) TO service_role;


--
-- Name: FUNCTION save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_embedding_source_hash text, p_embedding public.vector, p_embedding_model text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_embedding_source_hash text, p_embedding public.vector, p_embedding_model text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_embedding_source_hash text, p_embedding public.vector, p_embedding_model text) TO service_role;


--
-- Name: FUNCTION save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_embedding_source_hash text, p_new_embedding_source_hash text, p_embedding public.vector, p_embedding_model text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_embedding_source_hash text, p_new_embedding_source_hash text, p_embedding public.vector, p_embedding_model text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.save_record_diagram_node_embedding(p_record_id uuid, p_node_id uuid, p_diagram_revision bigint, p_record_revision bigint, p_embedding_source_hash text, p_new_embedding_source_hash text, p_embedding public.vector, p_embedding_model text) TO service_role;


--
-- Name: FUNCTION set_credit_auto_top_up_settings(p_site_id uuid, p_enabled boolean, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer, p_actor_id uuid, p_stripe_payment_method_id text, p_state text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.set_credit_auto_top_up_settings(p_site_id uuid, p_enabled boolean, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer, p_actor_id uuid, p_stripe_payment_method_id text, p_state text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_credit_auto_top_up_settings(p_site_id uuid, p_enabled boolean, p_minimum_credits numeric, p_target_credits numeric, p_max_monthly_spend_cents integer, p_actor_id uuid, p_stripe_payment_method_id text, p_state text) TO service_role;


--
-- Name: FUNCTION set_current_timestamp_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.set_current_timestamp_updated_at() TO anon;
GRANT ALL ON FUNCTION public.set_current_timestamp_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.set_current_timestamp_updated_at() TO service_role;


--
-- Name: FUNCTION set_dislike(command_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.set_dislike(command_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_dislike(command_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.set_dislike(command_id uuid) TO service_role;


--
-- Name: FUNCTION set_like(command_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.set_like(command_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_like(command_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.set_like(command_id uuid) TO service_role;


--
-- Name: FUNCTION set_site_agent_channel_enabled(p_site_id uuid, p_connection_id text, p_enabled boolean, p_actor_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.set_site_agent_channel_enabled(p_site_id uuid, p_connection_id text, p_enabled boolean, p_actor_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_site_agent_channel_enabled(p_site_id uuid, p_connection_id text, p_enabled boolean, p_actor_id uuid) TO service_role;


--
-- Name: FUNCTION set_site_member_enabled(p_site_id uuid, p_member_id uuid, p_enabled boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.set_site_member_enabled(p_site_id uuid, p_member_id uuid, p_enabled boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_site_member_enabled(p_site_id uuid, p_member_id uuid, p_enabled boolean) TO service_role;


--
-- Name: FUNCTION set_task_priority_from_serial(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.set_task_priority_from_serial() TO anon;
GRANT ALL ON FUNCTION public.set_task_priority_from_serial() TO authenticated;
GRANT ALL ON FUNCTION public.set_task_priority_from_serial() TO service_role;


--
-- Name: FUNCTION set_task_serial_id(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.set_task_serial_id() FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_task_serial_id() TO authenticated;
GRANT ALL ON FUNCTION public.set_task_serial_id() TO service_role;


--
-- Name: FUNCTION set_updated_at(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.set_updated_at() FROM PUBLIC;
GRANT ALL ON FUNCTION public.set_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.set_updated_at() TO service_role;


--
-- Name: FUNCTION settle_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_cost numeric, p_generation_id text, p_model text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.settle_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_cost numeric, p_generation_id text, p_model text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.settle_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_cost numeric, p_generation_id text, p_model text) TO service_role;


--
-- Name: FUNCTION settle_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_count integer, p_generation_id text, p_model text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.settle_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_count integer, p_generation_id text, p_model text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.settle_image_generation_reservation(p_site_id uuid, p_operation_id text, p_token uuid, p_count integer, p_generation_id text, p_model text) TO service_role;


--
-- Name: FUNCTION settle_stripe_sale_checkout(p_sale_id uuid, p_order_id uuid, p_session_id text, p_amount_minor bigint, p_currency text, p_payment_intent_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.settle_stripe_sale_checkout(p_sale_id uuid, p_order_id uuid, p_session_id text, p_amount_minor bigint, p_currency text, p_payment_intent_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.settle_stripe_sale_checkout(p_sale_id uuid, p_order_id uuid, p_session_id text, p_amount_minor bigint, p_currency text, p_payment_intent_id text) TO service_role;


--
-- Name: FUNCTION settle_stripe_subscription_invoice(p_invoice jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.settle_stripe_subscription_invoice(p_invoice jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.settle_stripe_subscription_invoice(p_invoice jsonb) TO service_role;


--
-- Name: FUNCTION shop_category_offsets(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.shop_category_offsets(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.shop_category_offsets(p_site_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.shop_category_offsets(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION simulate_user_creation(test_email text, test_name text, test_referral_code text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.simulate_user_creation(test_email text, test_name text, test_referral_code text) TO anon;
GRANT ALL ON FUNCTION public.simulate_user_creation(test_email text, test_name text, test_referral_code text) TO authenticated;
GRANT ALL ON FUNCTION public.simulate_user_creation(test_email text, test_name text, test_referral_code text) TO service_role;


--
-- Name: FUNCTION site_member_has_effective_license(p_member_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.site_member_has_effective_license(p_member_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION site_owner_has_platform_payment(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.site_owner_has_platform_payment(p_site_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION site_owner_license_changed(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.site_owner_license_changed() FROM PUBLIC;


--
-- Name: FUNCTION site_plan_credit_allowance(p_plan text, p_addons integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.site_plan_credit_allowance(p_plan text, p_addons integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.site_plan_credit_allowance(p_plan text, p_addons integer) TO service_role;


--
-- Name: FUNCTION site_user_has_effective_access(p_site_id uuid, p_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.site_user_has_effective_access(p_site_id uuid, p_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.site_user_has_effective_access(p_site_id uuid, p_user_id uuid) TO service_role;


--
-- Name: FUNCTION stamp_requirement_review_quarantine(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.stamp_requirement_review_quarantine() TO anon;
