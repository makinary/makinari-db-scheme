SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION bump_record_embedding_revision(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.bump_record_embedding_revision() TO anon;
GRANT ALL ON FUNCTION public.bump_record_embedding_revision() TO authenticated;
GRANT ALL ON FUNCTION public.bump_record_embedding_revision() TO service_role;


--
-- Name: FUNCTION calculate_kpis_from_events(site_id_param uuid, kpi_type_param text, period_start_param timestamp with time zone, period_end_param timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.calculate_kpis_from_events(site_id_param uuid, kpi_type_param text, period_start_param timestamp with time zone, period_end_param timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.calculate_kpis_from_events(site_id_param uuid, kpi_type_param text, period_start_param timestamp with time zone, period_end_param timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_kpis_from_events(site_id_param uuid, kpi_type_param text, period_start_param timestamp with time zone, period_end_param timestamp with time zone) TO service_role;


--
-- Name: FUNCTION can_access_record_diagram(p_record_id uuid, p_site_id uuid, p_command text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.can_access_record_diagram(p_record_id uuid, p_site_id uuid, p_command text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.can_access_record_diagram(p_record_id uuid, p_site_id uuid, p_command text) TO authenticated;
GRANT ALL ON FUNCTION public.can_access_record_diagram(p_record_id uuid, p_site_id uuid, p_command text) TO service_role;


--
-- Name: FUNCTION can_access_record_values(p_site_id uuid, p_relations jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.can_access_record_values(p_site_id uuid, p_relations jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.can_access_record_values(p_site_id uuid, p_relations jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.can_access_record_values(p_site_id uuid, p_relations jsonb) TO service_role;


--
-- Name: FUNCTION cancel_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_reason text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.cancel_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_reason text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_harness_model_reservation(p_session_id uuid, p_event_id uuid, p_reason text) TO service_role;


--
-- Name: FUNCTION cancel_quiescent_instance_plan(p_plan_id uuid, p_instance_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.cancel_quiescent_instance_plan(p_plan_id uuid, p_instance_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_quiescent_instance_plan(p_plan_id uuid, p_instance_id uuid) TO authenticated;


--
-- Name: FUNCTION cancel_requirement_plan_steps_for_backlog_items(p_requirement_id uuid, p_item_ids text[], p_reason text, p_instance_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.cancel_requirement_plan_steps_for_backlog_items(p_requirement_id uuid, p_item_ids text[], p_reason text, p_instance_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_requirement_plan_steps_for_backlog_items(p_requirement_id uuid, p_item_ids text[], p_reason text, p_instance_id uuid) TO service_role;


--
-- Name: FUNCTION cancel_stale_invoice_reminder(p_site_id uuid, p_sale_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.cancel_stale_invoice_reminder(p_site_id uuid, p_sale_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_stale_invoice_reminder(p_site_id uuid, p_sale_id uuid) TO service_role;


--
-- Name: FUNCTION cancel_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.cancel_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.cancel_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid) TO service_role;


--
-- Name: FUNCTION capture_requirement_economic_pause(p_status_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.capture_requirement_economic_pause(p_status_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION cascade_catalog_category_archive(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.cascade_catalog_category_archive() FROM PUBLIC;


--
-- Name: FUNCTION catalog_archive_lock_site(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_archive_lock_site(p_site_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION catalog_category_archive_item_ids(p_site_id uuid, p_category_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_category_archive_item_ids(p_site_id uuid, p_category_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION catalog_import_category_key(p_name text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_import_category_key(p_name text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.catalog_import_category_key(p_name text) TO authenticated;
GRANT ALL ON FUNCTION public.catalog_import_category_key(p_name text) TO service_role;


--
-- Name: FUNCTION catalog_search_bump_revision(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_bump_revision(p_site_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_candidates(p_site_id uuid, p_channel text, p_query text, p_filters jsonb, p_mode text, p_embedding public.vector, p_limit integer, p_min_similarity double precision); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_candidates(p_site_id uuid, p_channel text, p_query text, p_filters jsonb, p_mode text, p_embedding public.vector, p_limit integer, p_min_similarity double precision) FROM PUBLIC;
GRANT ALL ON FUNCTION public.catalog_search_candidates(p_site_id uuid, p_channel text, p_query text, p_filters jsonb, p_mode text, p_embedding public.vector, p_limit integer, p_min_similarity double precision) TO service_role;


--
-- Name: FUNCTION catalog_search_claim_embedding_jobs(p_limit integer, p_lease_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_claim_embedding_jobs(p_limit integer, p_lease_seconds integer) FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_commerce_changed(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_commerce_changed() FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_document_text(p_item_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_document_text(p_item_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_drain_refresh_events(p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_drain_refresh_events(p_limit integer) FROM PUBLIC;


--
-- Name: TABLE catalog_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.catalog_items TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.catalog_items TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.catalog_items TO service_role;


--
-- Name: FUNCTION catalog_search_eligible(i public.catalog_items, p_site_id uuid, p_channel text, p_filters jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_eligible(i public.catalog_items, p_site_id uuid, p_channel text, p_filters jsonb) FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_index_pending(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_index_pending() FROM PUBLIC;
GRANT ALL ON FUNCTION public.catalog_search_index_pending() TO service_role;


--
-- Name: FUNCTION catalog_search_item_changed(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_item_changed() FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_refresh_batch(p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_refresh_batch(p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.catalog_search_refresh_batch(p_limit integer) TO service_role;


--
-- Name: FUNCTION catalog_search_relationship_changed(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_relationship_changed() FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_revision(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_revision(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.catalog_search_revision(p_site_id uuid) TO service_role;


--
-- Name: FUNCTION catalog_search_validate(p_site_id uuid, p_channel text, p_filters jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_validate(p_site_id uuid, p_channel text, p_filters jsonb) FROM PUBLIC;


--
-- Name: FUNCTION catalog_search_visible_ids(p_ids uuid[], p_site_id uuid, p_channel text, p_filters jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.catalog_search_visible_ids(p_ids uuid[], p_site_id uuid, p_channel text, p_filters jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.catalog_search_visible_ids(p_ids uuid[], p_site_id uuid, p_channel text, p_filters jsonb) TO service_role;


--
-- Name: FUNCTION check_billing_system(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.check_billing_system() FROM PUBLIC;
GRANT ALL ON FUNCTION public.check_billing_system() TO authenticated;
GRANT ALL ON FUNCTION public.check_billing_system() TO service_role;


--
-- Name: FUNCTION check_create_update_permission(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.check_create_update_permission() FROM PUBLIC;
GRANT ALL ON FUNCTION public.check_create_update_permission() TO authenticated;
GRANT ALL ON FUNCTION public.check_create_update_permission() TO service_role;


--
-- Name: FUNCTION check_delete_permission(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.check_delete_permission() FROM PUBLIC;
GRANT ALL ON FUNCTION public.check_delete_permission() TO authenticated;
GRANT ALL ON FUNCTION public.check_delete_permission() TO service_role;


--
-- Name: FUNCTION check_delete_protection_status(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.check_delete_protection_status() FROM PUBLIC;
GRANT ALL ON FUNCTION public.check_delete_protection_status() TO authenticated;
GRANT ALL ON FUNCTION public.check_delete_protection_status() TO service_role;


--
-- Name: FUNCTION check_referral_system_status(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.check_referral_system_status() TO anon;
GRANT ALL ON FUNCTION public.check_referral_system_status() TO authenticated;
GRANT ALL ON FUNCTION public.check_referral_system_status() TO service_role;


--
-- Name: FUNCTION check_role_restrictions_status(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.check_role_restrictions_status() FROM PUBLIC;
GRANT ALL ON FUNCTION public.check_role_restrictions_status() TO authenticated;
GRANT ALL ON FUNCTION public.check_role_restrictions_status() TO service_role;


--
-- Name: FUNCTION checkpoint_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_version integer, p_processed integer, p_found integer, p_page integer, p_offset integer, p_total integer, p_status text, p_snapshot jsonb, p_errors jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.checkpoint_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_version integer, p_processed integer, p_found integer, p_page integer, p_offset integer, p_total integer, p_status text, p_snapshot jsonb, p_errors jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.checkpoint_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_version integer, p_processed integer, p_found integer, p_page integer, p_offset integer, p_total integer, p_status text, p_snapshot jsonb, p_errors jsonb) TO service_role;


--
-- Name: FUNCTION checkpoint_platform_quota_usage(p_site_id uuid, p_capability text, p_period text, p_used integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.checkpoint_platform_quota_usage(p_site_id uuid, p_capability text, p_period text, p_used integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.checkpoint_platform_quota_usage(p_site_id uuid, p_capability text, p_period text, p_used integer) TO service_role;


--
-- Name: FUNCTION claim_agent_requirement_run(p_excluded_ids uuid[], p_max_concurrent integer, p_ttl_seconds integer, p_scheduled_ids uuid[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_agent_requirement_run(p_excluded_ids uuid[], p_max_concurrent integer, p_ttl_seconds integer, p_scheduled_ids uuid[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_agent_requirement_run(p_excluded_ids uuid[], p_max_concurrent integer, p_ttl_seconds integer, p_scheduled_ids uuid[]) TO service_role;


--
-- Name: FUNCTION claim_agent_requirement_run_before_commands(p_excluded_ids uuid[], p_max_concurrent integer, p_ttl_seconds integer, p_scheduled_ids uuid[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_agent_requirement_run_before_commands(p_excluded_ids uuid[], p_max_concurrent integer, p_ttl_seconds integer, p_scheduled_ids uuid[]) FROM PUBLIC;


--
-- Name: FUNCTION claim_approved_message(p_message_id uuid, p_conversation_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_approved_message(p_message_id uuid, p_conversation_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_approved_message(p_message_id uuid, p_conversation_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.claim_approved_message(p_message_id uuid, p_conversation_id uuid) TO service_role;


--
-- Name: FUNCTION claim_approved_messages_batch(p_messages jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_approved_messages_batch(p_messages jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_approved_messages_batch(p_messages jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.claim_approved_messages_batch(p_messages jsonb) TO service_role;


--
-- Name: FUNCTION claim_catalog_embedding_jobs(p_limit integer, p_lease_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_catalog_embedding_jobs(p_limit integer, p_lease_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_catalog_embedding_jobs(p_limit integer, p_lease_seconds integer) TO service_role;


--
-- Name: FUNCTION claim_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_harness_session(p_id uuid, p_site_id uuid, p_owner text, p_ttl_seconds integer) TO service_role;


--
-- Name: FUNCTION claim_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_workflow_id text, p_previous_run_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_workflow_id text, p_previous_run_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_icp_mining_execution(p_id uuid, p_site_id uuid, p_run_id uuid, p_workflow_id text, p_previous_run_id uuid) TO service_role;


--
-- Name: FUNCTION claim_insufficient_credit_email(p_site_id uuid, p_recipient_hash text, p_owner_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_insufficient_credit_email(p_site_id uuid, p_recipient_hash text, p_owner_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_insufficient_credit_email(p_site_id uuid, p_recipient_hash text, p_owner_id uuid) TO service_role;


--
-- Name: FUNCTION claim_invoice_reminder(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_invoice_reminder(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_invoice_reminder(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer) TO service_role;


--
-- Name: FUNCTION claim_invoice_reminder_with_cooldown(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer, p_mode text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_invoice_reminder_with_cooldown(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer, p_mode text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_invoice_reminder_with_cooldown(p_site_id uuid, p_sale_id uuid, p_reminder_key text, p_local_day date, p_interval_days integer, p_mode text) TO service_role;


--
-- Name: FUNCTION claim_marketplace_action(p_order_id uuid, p_action text, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_action(p_order_id uuid, p_action text, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_marketplace_action(p_order_id uuid, p_action text, p_actor_user_id uuid) TO service_role;


--
-- Name: FUNCTION claim_marketplace_action_active(p_order_id uuid, p_action text, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_action_active(p_order_id uuid, p_action text, p_actor_user_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION claim_marketplace_oauth(p_state_hash text, p_provider text, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_oauth(p_state_hash text, p_provider text, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_marketplace_oauth(p_state_hash text, p_provider text, p_actor_user_id uuid) TO service_role;


--
-- Name: FUNCTION claim_marketplace_poll(p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_poll(p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_marketplace_poll(p_limit integer) TO service_role;


--
-- Name: FUNCTION claim_marketplace_provisioning(p_integration_id uuid, p_operation text, p_actor_user_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_provisioning(p_integration_id uuid, p_operation text, p_actor_user_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_marketplace_provisioning(p_integration_id uuid, p_operation text, p_actor_user_id uuid) TO service_role;


--
-- Name: FUNCTION claim_marketplace_webhook_registration(p_scope jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_webhook_registration(p_scope jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_marketplace_webhook_registration(p_scope jsonb) TO service_role;


--
-- Name: FUNCTION claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text) TO service_role;


--
-- Name: FUNCTION claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text, p_actor_user_id uuid, p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text, p_actor_user_id uuid, p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_marketplace_webhook_registration(p_app_hash text, p_provider text, p_environment text, p_country text, p_actor_user_id uuid, p_site_id uuid) TO service_role;


--
-- Name: FUNCTION claim_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_migration_diagnostic(p_requirement_id uuid, p_file text, p_expected_version integer, p_execution_generation integer, p_run_id text) TO service_role;


--
-- Name: FUNCTION claim_outstand_initial_import(p_site_id uuid, p_account_id text, p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_outstand_initial_import(p_site_id uuid, p_account_id text, p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_outstand_initial_import(p_site_id uuid, p_account_id text, p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.claim_outstand_initial_import(p_site_id uuid, p_account_id text, p_limit integer) TO service_role;


--
-- Name: FUNCTION claim_provider_webhook_event(p_provider text, p_event_id text, p_event_type text, p_claim_token uuid, p_lease_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_provider_webhook_event(p_provider text, p_event_id text, p_event_type text, p_claim_token uuid, p_lease_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_provider_webhook_event(p_provider text, p_event_id text, p_event_type text, p_claim_token uuid, p_lease_seconds integer) TO service_role;


--
-- Name: FUNCTION claim_quotation_checkout(p_quotation_id uuid, p_site_id uuid, p_claim_id uuid, p_buyer_user_id uuid, p_public_access_token text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_quotation_checkout(p_quotation_id uuid, p_site_id uuid, p_claim_id uuid, p_buyer_user_id uuid, p_public_access_token text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_quotation_checkout(p_quotation_id uuid, p_site_id uuid, p_claim_id uuid, p_buyer_user_id uuid, p_public_access_token text) TO service_role;


--
-- Name: TABLE record_embedding_jobs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.record_embedding_jobs TO service_role;


--
-- Name: FUNCTION claim_record_embedding_jobs(p_record_id uuid, p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.claim_record_embedding_jobs(p_record_id uuid, p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.claim_record_embedding_jobs(p_record_id uuid, p_limit integer) TO service_role;
