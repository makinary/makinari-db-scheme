SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;

GRANT ALL ON FUNCTION public.stamp_requirement_review_quarantine() TO authenticated;
GRANT ALL ON FUNCTION public.stamp_requirement_review_quarantine() TO service_role;


--
-- Name: FUNCTION start_site_startup_trial(p_site_id uuid, p_actor_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.start_site_startup_trial(p_site_id uuid, p_actor_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.start_site_startup_trial(p_site_id uuid, p_actor_id uuid) TO service_role;


--
-- Name: FUNCTION status_observed_state(status text, checks jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.status_observed_state(status text, checks jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.status_observed_state(status text, checks jsonb) TO service_role;


--
-- Name: FUNCTION store_secure_token(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.store_secure_token(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.store_secure_token(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text) TO authenticated;
GRANT ALL ON FUNCTION public.store_secure_token(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text) TO service_role;


--
-- Name: FUNCTION stripe_amount_to_minor(p_amount numeric, p_currency text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.stripe_amount_to_minor(p_amount numeric, p_currency text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.stripe_amount_to_minor(p_amount numeric, p_currency text) TO service_role;


--
-- Name: FUNCTION submit_requirement_command(p_requirement_id uuid, p_site_id uuid, p_user_id uuid, p_instance_id uuid, p_action_id uuid, p_patch jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.submit_requirement_command(p_requirement_id uuid, p_site_id uuid, p_user_id uuid, p_instance_id uuid, p_action_id uuid, p_patch jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.submit_requirement_command(p_requirement_id uuid, p_site_id uuid, p_user_id uuid, p_instance_id uuid, p_action_id uuid, p_patch jsonb) TO service_role;


--
-- Name: FUNCTION subscription_monthly_credit_window(p_start timestamp with time zone, p_end timestamp with time zone, p_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.subscription_monthly_credit_window(p_start timestamp with time zone, p_end timestamp with time zone, p_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.subscription_monthly_credit_window(p_start timestamp with time zone, p_end timestamp with time zone, p_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION sync_auth0_user(auth0_id_param text, email_param text, name_param text, picture_param text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_auth0_user(auth0_id_param text, email_param text, name_param text, picture_param text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.sync_auth0_user(auth0_id_param text, email_param text, name_param text, picture_param text) TO authenticated;
GRANT ALL ON FUNCTION public.sync_auth0_user(auth0_id_param text, email_param text, name_param text, picture_param text) TO service_role;


--
-- Name: FUNCTION sync_order_line_unit_delivery(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_order_line_unit_delivery() FROM PUBLIC;
GRANT ALL ON FUNCTION public.sync_order_line_unit_delivery() TO service_role;


--
-- Name: FUNCTION sync_order_lines_from_order_status(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_order_lines_from_order_status() FROM PUBLIC;
GRANT ALL ON FUNCTION public.sync_order_lines_from_order_status() TO service_role;


--
-- Name: FUNCTION sync_sale_order_item_status_from_units(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_sale_order_item_status_from_units() FROM PUBLIC;
GRANT ALL ON FUNCTION public.sync_sale_order_item_status_from_units() TO service_role;


--
-- Name: FUNCTION sync_sale_order_item_units_from_line(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_sale_order_item_units_from_line() FROM PUBLIC;
GRANT ALL ON FUNCTION public.sync_sale_order_item_units_from_line() TO service_role;


--
-- Name: FUNCTION sync_site_members_license_json(p_site_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_site_members_license_json(p_site_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION sync_site_members_to_settings(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_site_members_to_settings() FROM PUBLIC;


--
-- Name: FUNCTION sync_site_members_to_team_members(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_site_members_to_team_members() FROM PUBLIC;


--
-- Name: FUNCTION sync_site_ownership(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.sync_site_ownership() TO anon;
GRANT ALL ON FUNCTION public.sync_site_ownership() TO authenticated;
GRANT ALL ON FUNCTION public.sync_site_ownership() TO service_role;


--
-- Name: FUNCTION sync_stripe_subscription_state(p_site_id uuid, p_customer_id text, p_subscription_id text, p_expected_subscription_id text, p_status text, p_current_period_end timestamp with time zone, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_auto_renew boolean, p_invoice_id text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.sync_stripe_subscription_state(p_site_id uuid, p_customer_id text, p_subscription_id text, p_expected_subscription_id text, p_status text, p_current_period_end timestamp with time zone, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_auto_renew boolean, p_invoice_id text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.sync_stripe_subscription_state(p_site_id uuid, p_customer_id text, p_subscription_id text, p_expected_subscription_id text, p_status text, p_current_period_end timestamp with time zone, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_auto_renew boolean, p_invoice_id text) TO service_role;


--
-- Name: FUNCTION tenant_id_from_jwt(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.tenant_id_from_jwt() TO anon;
GRANT ALL ON FUNCTION public.tenant_id_from_jwt() TO authenticated;
GRANT ALL ON FUNCTION public.tenant_id_from_jwt() TO service_role;


--
-- Name: FUNCTION toggle_flag(command_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.toggle_flag(command_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.toggle_flag(command_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.toggle_flag(command_id uuid) TO service_role;


--
-- Name: FUNCTION touch_sale_order_item_unit(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.touch_sale_order_item_unit() FROM PUBLIC;
GRANT ALL ON FUNCTION public.touch_sale_order_item_unit() TO service_role;


--
-- Name: FUNCTION track_requirement_economic_pause(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.track_requirement_economic_pause() FROM PUBLIC;


--
-- Name: FUNCTION transfer_location_inventory(p_site_id uuid, p_catalog_item_id uuid, p_from_location_id uuid, p_to_location_id uuid, p_quantity numeric); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.transfer_location_inventory(p_site_id uuid, p_catalog_item_id uuid, p_from_location_id uuid, p_to_location_id uuid, p_quantity numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION public.transfer_location_inventory(p_site_id uuid, p_catalog_item_id uuid, p_from_location_id uuid, p_to_location_id uuid, p_quantity numeric) TO authenticated;


--
-- Name: FUNCTION transfer_requirement_migration_execution(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.transfer_requirement_migration_execution(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.transfer_requirement_migration_execution(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_instance_id uuid, p_request_id uuid, p_operator_id text, p_reason text, p_evidence jsonb) TO service_role;


--
-- Name: FUNCTION transition_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_value jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.transition_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_value jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.transition_requirement_migration(p_requirement_id uuid, p_file text, p_expected_version integer, p_expected_execution_generation integer, p_value jsonb) TO service_role;


--
-- Name: FUNCTION update_activity_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_activity_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_activity_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_activity_updated_at() TO service_role;


--
-- Name: FUNCTION update_api_key_last_used(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_api_key_last_used() TO anon;
GRANT ALL ON FUNCTION public.update_api_key_last_used() TO authenticated;
GRANT ALL ON FUNCTION public.update_api_key_last_used() TO service_role;


--
-- Name: FUNCTION update_content_performance_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_content_performance_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_content_performance_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_content_performance_updated_at() TO service_role;


--
-- Name: FUNCTION update_conversation_last_message_time(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.update_conversation_last_message_time() FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_conversation_last_message_time() TO authenticated;
GRANT ALL ON FUNCTION public.update_conversation_last_message_time() TO service_role;


--
-- Name: FUNCTION update_copywriting_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_copywriting_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_copywriting_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_copywriting_updated_at() TO service_role;


--
-- Name: FUNCTION update_cron_status_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_cron_status_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_cron_status_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_cron_status_updated_at() TO service_role;


--
-- Name: FUNCTION update_instance_plan_step_status_atomic(p_plan_id uuid, p_step_id text, p_status text, p_error_message text, p_expected_generation integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.update_instance_plan_step_status_atomic(p_plan_id uuid, p_step_id text, p_status text, p_error_message text, p_expected_generation integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.update_instance_plan_step_status_atomic(p_plan_id uuid, p_step_id text, p_status text, p_error_message text, p_expected_generation integer) TO service_role;


--
-- Name: FUNCTION update_lead_analysis_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_lead_analysis_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_lead_analysis_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_lead_analysis_updated_at() TO service_role;


--
-- Name: FUNCTION update_lead_research_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_lead_research_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_lead_research_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_lead_research_updated_at() TO service_role;


--
-- Name: FUNCTION update_modified_column(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_modified_column() TO anon;
GRANT ALL ON FUNCTION public.update_modified_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_modified_column() TO service_role;


--
-- Name: FUNCTION update_sale_orders_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_sale_orders_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_sale_orders_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_sale_orders_updated_at() TO service_role;


--
-- Name: FUNCTION update_site_secrets_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_site_secrets_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_site_secrets_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_site_secrets_updated_at() TO service_role;


--
-- Name: FUNCTION update_synced_objects_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_synced_objects_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_synced_objects_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_synced_objects_updated_at() TO service_role;


--
-- Name: FUNCTION update_timestamp(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_timestamp() TO anon;
GRANT ALL ON FUNCTION public.update_timestamp() TO authenticated;
GRANT ALL ON FUNCTION public.update_timestamp() TO service_role;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO service_role;


--
-- Name: FUNCTION update_webhook_events_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_webhook_events_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_webhook_events_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_webhook_events_updated_at() TO service_role;


--
-- Name: FUNCTION update_whatsapp_template_tracking_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_whatsapp_template_tracking_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_whatsapp_template_tracking_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_whatsapp_template_tracking_updated_at() TO service_role;


--
-- Name: FUNCTION update_whatsapp_templates_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_whatsapp_templates_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_whatsapp_templates_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_whatsapp_templates_updated_at() TO service_role;


--
-- Name: FUNCTION upsert_billing(p_site_id uuid, p_plan text, p_card_name text, p_masked_card_number text, p_card_expiry text, p_stripe_customer_id text, p_stripe_payment_method_id text, p_stripe_subscription_id text, p_card_address text, p_card_city text, p_card_postal_code text, p_card_country text, p_tax_id text, p_billing_address text, p_billing_city text, p_billing_postal_code text, p_billing_country text, p_auto_renew boolean, p_credits_available integer, p_subscription_status text, p_subscription_current_period_end timestamp without time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.upsert_billing(p_site_id uuid, p_plan text, p_card_name text, p_masked_card_number text, p_card_expiry text, p_stripe_customer_id text, p_stripe_payment_method_id text, p_stripe_subscription_id text, p_card_address text, p_card_city text, p_card_postal_code text, p_card_country text, p_tax_id text, p_billing_address text, p_billing_city text, p_billing_postal_code text, p_billing_country text, p_auto_renew boolean, p_credits_available integer, p_subscription_status text, p_subscription_current_period_end timestamp without time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.upsert_billing(p_site_id uuid, p_plan text, p_card_name text, p_masked_card_number text, p_card_expiry text, p_stripe_customer_id text, p_stripe_payment_method_id text, p_stripe_subscription_id text, p_card_address text, p_card_city text, p_card_postal_code text, p_card_country text, p_tax_id text, p_billing_address text, p_billing_city text, p_billing_postal_code text, p_billing_country text, p_auto_renew boolean, p_credits_available integer, p_subscription_status text, p_subscription_current_period_end timestamp without time zone) TO authenticated;
GRANT ALL ON FUNCTION public.upsert_billing(p_site_id uuid, p_plan text, p_card_name text, p_masked_card_number text, p_card_expiry text, p_stripe_customer_id text, p_stripe_payment_method_id text, p_stripe_subscription_id text, p_card_address text, p_card_city text, p_card_postal_code text, p_card_country text, p_tax_id text, p_billing_address text, p_billing_city text, p_billing_postal_code text, p_billing_country text, p_auto_renew boolean, p_credits_available integer, p_subscription_status text, p_subscription_current_period_end timestamp without time zone) TO service_role;


--
-- Name: FUNCTION user_can(p_site_id uuid, p_command text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.user_can(p_site_id uuid, p_command text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.user_can(p_site_id uuid, p_command text) TO anon;
GRANT ALL ON FUNCTION public.user_can(p_site_id uuid, p_command text) TO authenticated;
GRANT ALL ON FUNCTION public.user_can(p_site_id uuid, p_command text) TO service_role;


--
-- Name: FUNCTION user_can_access_location(p_site_id uuid, p_location_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.user_can_access_location(p_site_id uuid, p_location_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.user_can_access_location(p_site_id uuid, p_location_id uuid) TO authenticated;


--
-- Name: FUNCTION user_has_access_to_site(user_id_param uuid, site_id_param uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.user_has_access_to_site(user_id_param uuid, site_id_param uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.user_has_access_to_site(user_id_param uuid, site_id_param uuid) TO authenticated;
GRANT ALL ON FUNCTION public.user_has_access_to_site(user_id_param uuid, site_id_param uuid) TO service_role;


--
-- Name: FUNCTION valid_harness_snapshot(s jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.valid_harness_snapshot(s jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.valid_harness_snapshot(s jsonb) TO service_role;


--
-- Name: FUNCTION validate_marketplace_consent(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.validate_marketplace_consent() FROM PUBLIC;
GRANT ALL ON FUNCTION public.validate_marketplace_consent() TO service_role;


--
-- Name: FUNCTION validate_marketplace_integration(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.validate_marketplace_integration() FROM PUBLIC;
GRANT ALL ON FUNCTION public.validate_marketplace_integration() TO service_role;


--
-- Name: FUNCTION validate_marketplace_webhook_app_lease(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.validate_marketplace_webhook_app_lease() FROM PUBLIC;
GRANT ALL ON FUNCTION public.validate_marketplace_webhook_app_lease() TO service_role;


--
-- Name: FUNCTION validate_marketplace_webhook_registration(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.validate_marketplace_webhook_registration() FROM PUBLIC;
GRANT ALL ON FUNCTION public.validate_marketplace_webhook_registration() TO service_role;


--
-- Name: FUNCTION validate_notifications(notifications jsonb); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.validate_notifications(notifications jsonb) TO anon;
GRANT ALL ON FUNCTION public.validate_notifications(notifications jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.validate_notifications(notifications jsonb) TO service_role;


--
-- Name: FUNCTION validate_performance_bitmask(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.validate_performance_bitmask() TO anon;
GRANT ALL ON FUNCTION public.validate_performance_bitmask() TO authenticated;
GRANT ALL ON FUNCTION public.validate_performance_bitmask() TO service_role;


--
-- Name: FUNCTION validate_referral_code(code_param text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.validate_referral_code(code_param text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.validate_referral_code(code_param text) TO authenticated;
GRANT ALL ON FUNCTION public.validate_referral_code(code_param text) TO service_role;


--
-- Name: FUNCTION validate_sale_order_attribution(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.validate_sale_order_attribution() TO anon;
GRANT ALL ON FUNCTION public.validate_sale_order_attribution() TO authenticated;
GRANT ALL ON FUNCTION public.validate_sale_order_attribution() TO service_role;


--
-- Name: FUNCTION verify_consume_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_is_match boolean, p_trusted_token_hash text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.verify_consume_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_is_match boolean, p_trusted_token_hash text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.verify_consume_visitor_identity_challenge(p_challenge_id uuid, p_site_id uuid, p_session_id uuid, p_is_match boolean, p_trusted_token_hash text) TO service_role;


--
-- Name: TABLE accounting_accounts; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.accounting_accounts TO authenticated;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.accounting_accounts TO service_role;


--
-- Name: TABLE accounting_sale_refunds; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.accounting_sale_refunds TO authenticated;
GRANT SELECT ON TABLE public.accounting_sale_refunds TO service_role;
