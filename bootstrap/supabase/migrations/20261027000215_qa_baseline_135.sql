SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION load_ready_pending_work(p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.load_ready_pending_work(p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.load_ready_pending_work(p_limit integer) TO service_role;


--
-- Name: FUNCTION location_acl_assert_unscoped_rpc(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_assert_unscoped_rpc() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_can_manage_ownership(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_can_manage_ownership(p_site_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.location_acl_can_manage_ownership(p_site_id uuid) TO authenticated;


--
-- Name: FUNCTION location_acl_guard_root_scope(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_guard_root_scope() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_inherit_scope(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_inherit_scope() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_accounting_sale_refunds(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_accounting_sale_refunds() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_deal_owners(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_deal_owners() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_invoice_reminders(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_invoice_reminders() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_messages(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_messages() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_pos_register_movements(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_pos_register_movements() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_pos_register_receipts(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_pos_register_receipts() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_purchase_items(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_purchase_items() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_quotation_items(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_quotation_items() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_quotations(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_quotations() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_reservations(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_reservations() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_sale_order_item_units(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_sale_order_item_units() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_sale_order_items(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_sale_order_items() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_sale_orders(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_sale_orders() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_sales(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_sales() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_shipment_location_pings(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_shipment_location_pings() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_shipments(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_shipments() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_task_categories(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_task_categories() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_task_comments(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_task_comments() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_tasks(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_tasks() FROM PUBLIC;


--
-- Name: FUNCTION location_acl_visible_transactions(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.location_acl_visible_transactions() FROM PUBLIC;


--
-- Name: FUNCTION lock_harness_host_owner(p_id uuid, p_site_id uuid, p_owner text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.lock_harness_host_owner(p_id uuid, p_site_id uuid, p_owner text) FROM PUBLIC;


--
-- Name: TABLE requirements; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirements TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirements TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirements TO service_role;


--
-- Name: FUNCTION lock_migration_reconciliation_scope(p_requirement_id uuid, p_file text, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_generation integer, p_backlog_revision bigint); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.lock_migration_reconciliation_scope(p_requirement_id uuid, p_file text, p_instance_id uuid, p_plan_id uuid, p_step_id text, p_generation integer, p_backlog_revision bigint) FROM PUBLIC;


--
-- Name: TABLE requirement_migration_lifecycle; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_migration_lifecycle TO service_role;


--
-- Name: FUNCTION lock_requirement_migration_diagnostic_scope(p_requirement_id uuid, p_file text, p_execution_generation integer, p_run_id text, p_require_cron_owner boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.lock_requirement_migration_diagnostic_scope(p_requirement_id uuid, p_file text, p_execution_generation integer, p_run_id text, p_require_cron_owner boolean) FROM PUBLIC;


--
-- Name: FUNCTION lock_site_license(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.lock_site_license(p_site_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION log_asset_insert(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.log_asset_insert() FROM PUBLIC;
GRANT ALL ON FUNCTION public.log_asset_insert() TO authenticated;
GRANT ALL ON FUNCTION public.log_asset_insert() TO service_role;


--
-- Name: FUNCTION log_debug(message text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.log_debug(message text) TO anon;
GRANT ALL ON FUNCTION public.log_debug(message text) TO authenticated;
GRANT ALL ON FUNCTION public.log_debug(message text) TO service_role;


--
-- Name: FUNCTION manually_activate_user_memberships(user_email text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.manually_activate_user_memberships(user_email text) TO anon;
GRANT ALL ON FUNCTION public.manually_activate_user_memberships(user_email text) TO authenticated;
GRANT ALL ON FUNCTION public.manually_activate_user_memberships(user_email text) TO service_role;


--
-- Name: FUNCTION mark_image_generation_reservation_pending(p_site_id uuid, p_operation_id text, p_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.mark_image_generation_reservation_pending(p_site_id uuid, p_operation_id text, p_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.mark_image_generation_reservation_pending(p_site_id uuid, p_operation_id text, p_token uuid) TO service_role;


--
-- Name: FUNCTION mark_reservation_reminder_sent(p_reservation_id uuid, p_time_window_hours integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.mark_reservation_reminder_sent(p_reservation_id uuid, p_time_window_hours integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.mark_reservation_reminder_sent(p_reservation_id uuid, p_time_window_hours integer) TO authenticated;
GRANT ALL ON FUNCTION public.mark_reservation_reminder_sent(p_reservation_id uuid, p_time_window_hours integer) TO service_role;


--
-- Name: FUNCTION mark_task_reminder_sent(p_task_id uuid, p_time_window_hours integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.mark_task_reminder_sent(p_task_id uuid, p_time_window_hours integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.mark_task_reminder_sent(p_task_id uuid, p_time_window_hours integer) TO authenticated;
GRANT ALL ON FUNCTION public.mark_task_reminder_sent(p_task_id uuid, p_time_window_hours integer) TO service_role;


--
-- Name: FUNCTION marketplace_assert_actor(p_site_id uuid, p_actor_user_id uuid, p_manager boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.marketplace_assert_actor(p_site_id uuid, p_actor_user_id uuid, p_manager boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.marketplace_assert_actor(p_site_id uuid, p_actor_user_id uuid, p_manager boolean) TO service_role;


--
-- Name: FUNCTION marketplace_capabilities(p_provider text, p_state text, p_manual_ready boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.marketplace_capabilities(p_provider text, p_state text, p_manual_ready boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.marketplace_capabilities(p_provider text, p_state text, p_manual_ready boolean) TO service_role;


--
-- Name: FUNCTION marketplace_is_backend(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.marketplace_is_backend() FROM PUBLIC;
GRANT ALL ON FUNCTION public.marketplace_is_backend() TO authenticated;
GRANT ALL ON FUNCTION public.marketplace_is_backend() TO service_role;


--
-- Name: FUNCTION marketplace_modifier_nodes(p_item jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.marketplace_modifier_nodes(p_item jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.marketplace_modifier_nodes(p_item jsonb) TO service_role;


--
-- Name: FUNCTION marketplace_native_state(p_state text, p_provider text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.marketplace_native_state(p_state text, p_provider text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.marketplace_native_state(p_state text, p_provider text) TO service_role;


--
-- Name: FUNCTION match_instance_context_memories(p_instance_id uuid, p_site_id uuid, p_embedding public.vector, p_limit integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.match_instance_context_memories(p_instance_id uuid, p_site_id uuid, p_embedding public.vector, p_limit integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.match_instance_context_memories(p_instance_id uuid, p_site_id uuid, p_embedding public.vector, p_limit integer) TO service_role;


--
-- Name: FUNCTION match_record_diagram_nodes(query_embedding public.vector, p_site_id uuid, p_record_id uuid, match_threshold double precision, match_count integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.match_record_diagram_nodes(query_embedding public.vector, p_site_id uuid, p_record_id uuid, match_threshold double precision, match_count integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.match_record_diagram_nodes(query_embedding public.vector, p_site_id uuid, p_record_id uuid, match_threshold double precision, match_count integer) TO authenticated;
GRANT ALL ON FUNCTION public.match_record_diagram_nodes(query_embedding public.vector, p_site_id uuid, p_record_id uuid, match_threshold double precision, match_count integer) TO service_role;


--
-- Name: FUNCTION match_records(query_embedding public.vector, match_threshold double precision, match_count integer, p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.match_records(query_embedding public.vector, match_threshold double precision, match_count integer, p_site_id uuid) TO anon;
GRANT ALL ON FUNCTION public.match_records(query_embedding public.vector, match_threshold double precision, match_count integer, p_site_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.match_records(query_embedding public.vector, match_threshold double precision, match_count integer, p_site_id uuid) TO service_role;


--
-- Name: FUNCTION match_records_vector(query_record_id uuid, match_threshold double precision, match_count integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.match_records_vector(query_record_id uuid, match_threshold double precision, match_count integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.match_records_vector(query_record_id uuid, match_threshold double precision, match_count integer) TO authenticated;
GRANT ALL ON FUNCTION public.match_records_vector(query_record_id uuid, match_threshold double precision, match_count integer) TO service_role;


--
-- Name: FUNCTION member_license_changed(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.member_license_changed() FROM PUBLIC;


--
-- Name: FUNCTION migrate_team_members_to_site_members(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.migrate_team_members_to_site_members() TO anon;
GRANT ALL ON FUNCTION public.migrate_team_members_to_site_members() TO authenticated;
GRANT ALL ON FUNCTION public.migrate_team_members_to_site_members() TO service_role;


--
-- Name: FUNCTION migration_execution_handoff_matches(p_row public.requirement_migration_lifecycle); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.migration_execution_handoff_matches(p_row public.requirement_migration_lifecycle) FROM PUBLIC;


--
-- Name: FUNCTION mutate_sale_order_item_units(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid, p_status text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.mutate_sale_order_item_units(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid, p_status text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.mutate_sale_order_item_units(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid, p_status text) TO authenticated;
GRANT ALL ON FUNCTION public.mutate_sale_order_item_units(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid, p_status text) TO service_role;


--
-- Name: FUNCTION normalize_billing_plan_names(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.normalize_billing_plan_names() FROM PUBLIC;
GRANT ALL ON FUNCTION public.normalize_billing_plan_names() TO service_role;


--
-- Name: FUNCTION observe_email_sync_channel_health(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.observe_email_sync_channel_health() FROM PUBLIC;
GRANT ALL ON FUNCTION public.observe_email_sync_channel_health() TO service_role;


--
-- Name: FUNCTION observe_message_channel_health(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.observe_message_channel_health() FROM PUBLIC;
GRANT ALL ON FUNCTION public.observe_message_channel_health() TO service_role;


--
-- Name: FUNCTION patch_agent_requirement_plan(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_title text, p_steps jsonb, p_expected_backlog_revision bigint); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.patch_agent_requirement_plan(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_title text, p_steps jsonb, p_expected_backlog_revision bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.patch_agent_requirement_plan(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_title text, p_steps jsonb, p_expected_backlog_revision bigint) TO service_role;


--
-- Name: FUNCTION patch_agent_requirement_progress(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_step_id text, p_item_id text, p_status text, p_message text, p_expected_backlog_revision bigint); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.patch_agent_requirement_progress(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_step_id text, p_item_id text, p_status text, p_message text, p_expected_backlog_revision bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION public.patch_agent_requirement_progress(p_requirement_id uuid, p_run_id text, p_generation integer, p_session_id uuid, p_plan_id uuid, p_step_id text, p_item_id text, p_status text, p_message text, p_expected_backlog_revision bigint) TO service_role;


--
-- Name: FUNCTION patch_instance_plan_step_atomic(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_event_id text, p_patch jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.patch_instance_plan_step_atomic(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_event_id text, p_patch jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.patch_instance_plan_step_atomic(p_plan_id uuid, p_step_id text, p_expected_generation integer, p_event_id text, p_patch jsonb) TO service_role;


--
-- Name: FUNCTION patch_requirement_metadata_keys(p_requirement_id uuid, p_patch jsonb, p_remove_keys text[]); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.patch_requirement_metadata_keys(p_requirement_id uuid, p_patch jsonb, p_remove_keys text[]) FROM PUBLIC;
GRANT ALL ON FUNCTION public.patch_requirement_metadata_keys(p_requirement_id uuid, p_patch jsonb, p_remove_keys text[]) TO service_role;


--
-- Name: FUNCTION persist_tracking_event_batch(p_events jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.persist_tracking_event_batch(p_events jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.persist_tracking_event_batch(p_events jsonb) TO service_role;


--
-- Name: FUNCTION pos_checkout_claim(p_site_id uuid, p_mutation_id text, p_actor_id uuid, p_order_id uuid, p_fingerprint text, p_owner_token uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_checkout_claim(p_site_id uuid, p_mutation_id text, p_actor_id uuid, p_order_id uuid, p_fingerprint text, p_owner_token uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pos_checkout_claim(p_site_id uuid, p_mutation_id text, p_actor_id uuid, p_order_id uuid, p_fingerprint text, p_owner_token uuid) TO service_role;


--
-- Name: FUNCTION pos_checkout_commit_order(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_order_id uuid, p_sale_patch jsonb, p_order_patch jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_checkout_commit_order(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_order_id uuid, p_sale_patch jsonb, p_order_patch jsonb) FROM PUBLIC;


--
-- Name: FUNCTION pos_checkout_commit_order(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_order_id uuid, p_sale_patch jsonb, p_order_patch jsonb, p_expected_sale jsonb, p_expected_order jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_checkout_commit_order(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_order_id uuid, p_sale_patch jsonb, p_order_patch jsonb, p_expected_sale jsonb, p_expected_order jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pos_checkout_commit_order(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_order_id uuid, p_sale_patch jsonb, p_order_patch jsonb, p_expected_sale jsonb, p_expected_order jsonb) TO service_role;


--
-- Name: FUNCTION pos_checkout_transition(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_state text, p_order_id uuid, p_sale_id uuid, p_result jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_checkout_transition(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_state text, p_order_id uuid, p_sale_id uuid, p_result jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.pos_checkout_transition(p_site_id uuid, p_mutation_id text, p_owner_token uuid, p_state text, p_order_id uuid, p_sale_id uuid, p_result jsonb) TO service_role;


--
-- Name: FUNCTION pos_register_authorize(p_site_id uuid, p_opened_by uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.pos_register_authorize(p_site_id uuid, p_opened_by uuid) FROM PUBLIC;
