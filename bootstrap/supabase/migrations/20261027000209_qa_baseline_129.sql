SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: FUNCTION original_16718(command_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16718(command_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16719(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16719(p_site_id uuid, p_token_type text, p_identifier text, p_encryption_key text) FROM PUBLIC;


--
-- Name: FUNCTION original_16720(user_id_param uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16720(user_id_param uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16737(visitor_id uuid, last_seen_timestamp bigint); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16737(visitor_id uuid, last_seen_timestamp bigint) FROM PUBLIC;


--
-- Name: FUNCTION original_16738(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16738() FROM PUBLIC;


--
-- Name: FUNCTION original_16739(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16739() FROM PUBLIC;


--
-- Name: FUNCTION original_16750(p_referral_code_id uuid, p_user_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16750(p_referral_code_id uuid, p_user_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16751(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying, p_payment_method character varying, p_details jsonb, p_credits integer); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16751(p_site_id uuid, p_transaction_type character varying, p_amount numeric, p_status character varying, p_payment_method character varying, p_details jsonb, p_credits integer) FROM PUBLIC;


--
-- Name: FUNCTION original_16752(code_param text, user_id_param uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16752(code_param text, user_id_param uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16753(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16753() FROM PUBLIC;


--
-- Name: FUNCTION original_16754(p_table_name text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16754(p_table_name text) FROM PUBLIC;


--
-- Name: FUNCTION original_16758(command_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16758(command_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16759(command_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16759(command_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16764(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16764(p_site_id uuid, p_token_type text, p_token_value text, p_identifier text, p_encryption_key text) FROM PUBLIC;


--
-- Name: FUNCTION original_16765(auth0_id_param text, email_param text, name_param text, picture_param text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16765(auth0_id_param text, email_param text, name_param text, picture_param text) FROM PUBLIC;


--
-- Name: FUNCTION original_16769(command_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16769(command_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16784(p_site_id uuid, p_plan text, p_card_name text, p_masked_card_number text, p_card_expiry text, p_stripe_customer_id text, p_stripe_payment_method_id text, p_stripe_subscription_id text, p_card_address text, p_card_city text, p_card_postal_code text, p_card_country text, p_tax_id text, p_billing_address text, p_billing_city text, p_billing_postal_code text, p_billing_country text, p_auto_renew boolean, p_credits_available integer, p_subscription_status text, p_subscription_current_period_end timestamp without time zone); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16784(p_site_id uuid, p_plan text, p_card_name text, p_masked_card_number text, p_card_expiry text, p_stripe_customer_id text, p_stripe_payment_method_id text, p_stripe_subscription_id text, p_card_address text, p_card_city text, p_card_postal_code text, p_card_country text, p_tax_id text, p_billing_address text, p_billing_city text, p_billing_postal_code text, p_billing_country text, p_auto_renew boolean, p_credits_available integer, p_subscription_status text, p_subscription_current_period_end timestamp without time zone) FROM PUBLIC;


--
-- Name: FUNCTION original_16785(user_id_param uuid, site_id_param uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16785(user_id_param uuid, site_id_param uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16788(code_param text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16788(code_param text) FROM PUBLIC;


--
-- Name: FUNCTION original_2912363(phone_variants text[]); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_2912363(phone_variants text[]) FROM PUBLIC;


--
-- Name: TABLE site_members; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.site_members TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.site_members TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.site_members TO service_role;
GRANT ALL ON TABLE public.site_members TO supabase_auth_admin;


--
-- Name: FUNCTION original_3880809(p_site_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_3880809(p_site_id uuid) FROM PUBLIC;


--
-- Name: TABLE sites; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,UPDATE ON TABLE public.sites TO anon;
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,UPDATE ON TABLE public.sites TO authenticated;
GRANT ALL ON TABLE public.sites TO service_role;
GRANT ALL ON TABLE public.sites TO supabase_auth_admin;


--
-- Name: FUNCTION original_3927106(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_3927106() FROM PUBLIC;


--
-- Name: FUNCTION original_3976648(p_site_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_3976648(p_site_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4106481(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4106481() FROM PUBLIC;


--
-- Name: FUNCTION original_4185985(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid, p_status text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4185985(p_site_id uuid, p_unit_ids uuid[], p_operation text, p_assignee_id uuid, p_status text) FROM PUBLIC;


--
-- Name: FUNCTION original_4228212(p_task_id uuid, p_time_window_hours integer); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4228212(p_task_id uuid, p_time_window_hours integer) FROM PUBLIC;


--
-- Name: FUNCTION original_4228213(p_reservation_id uuid, p_time_window_hours integer); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4228213(p_reservation_id uuid, p_time_window_hours integer) FROM PUBLIC;


--
-- Name: FUNCTION original_4228220(p_message_id uuid, p_conversation_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4228220(p_message_id uuid, p_conversation_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4228221(p_messages jsonb); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4228221(p_messages jsonb) FROM PUBLIC;


--
-- Name: FUNCTION original_4228222(p_cutoff timestamp with time zone, p_limit integer); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4228222(p_cutoff timestamp with time zone, p_limit integer) FROM PUBLIC;


--
-- Name: FUNCTION original_4230473(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4230473(p_plan_id uuid, p_source_step_id text, p_expected_source_generation integer, p_repair_run_id text, p_repair_step jsonb) FROM PUBLIC;


--
-- Name: FUNCTION original_4247935(p_site_ids uuid[], p_limit integer); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4247935(p_site_ids uuid[], p_limit integer) FROM PUBLIC;


--
-- Name: FUNCTION original_4248376(p_site_id uuid, p_account_id text, p_limit integer); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4248376(p_site_id uuid, p_account_id text, p_limit integer) FROM PUBLIC;


--
-- Name: FUNCTION original_4248377(p_site_id uuid, p_account_id text, p_status text, p_job_id text, p_imported integer, p_failed integer); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4248377(p_site_id uuid, p_account_id text, p_status text, p_job_id text, p_imported integer, p_failed integer) FROM PUBLIC;


--
-- Name: FUNCTION original_4249998(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4249998(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean) FROM PUBLIC;


--
-- Name: FUNCTION original_4249999(p_site_id uuid, p_entry_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4249999(p_site_id uuid, p_entry_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4250037(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4250037(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb) FROM PUBLIC;


--
-- Name: FUNCTION original_4250041(p_site_id uuid, p_source_type text, p_source_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4250041(p_site_id uuid, p_source_type text, p_source_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4272421(p_instance_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4272421(p_instance_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4272425(p_instance_id uuid, p_expected_requirement_ids uuid[], p_expected_provider text, p_expected_provider_instance_id text, p_expected_status text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4272425(p_instance_id uuid, p_expected_requirement_ids uuid[], p_expected_provider text, p_expected_provider_instance_id text, p_expected_status text) FROM PUBLIC;


--
-- Name: FUNCTION original_4296760(p_site_id uuid, p_lead_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4296760(p_site_id uuid, p_lead_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4296761(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4296761(p_site_id uuid, p_lead_id uuid, p_request_id uuid, p_version text, p_currency text, p_mode text, p_amount numeric, p_method text, p_notes text) FROM PUBLIC;


--
-- Name: FUNCTION original_4320078(p_site_id uuid, p_category_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4320078(p_site_id uuid, p_category_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4373681(p_site_id uuid, p_location_id uuid, p_currency text, p_opening_amount numeric, p_request_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4373681(p_site_id uuid, p_location_id uuid, p_currency text, p_opening_amount numeric, p_request_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4373682(p_session_id uuid, p_kind text, p_amount numeric, p_reason text, p_request_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4373682(p_session_id uuid, p_kind text, p_amount numeric, p_reason text, p_request_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4373683(p_session_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4373683(p_session_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4373684(p_session_id uuid, p_counted_amount numeric, p_notes text, p_request_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4373684(p_session_id uuid, p_counted_amount numeric, p_notes text, p_request_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4379393(p_plan_id uuid, p_instance_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4379393(p_plan_id uuid, p_instance_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4379420(p_site_id uuid, p_rows jsonb, p_mode text, p_request_id uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4379420(p_site_id uuid, p_rows jsonb, p_mode text, p_request_id uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_4387865(p_site_id uuid, p_names jsonb); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_4387865(p_site_id uuid, p_names jsonb) FROM PUBLIC;


--
-- Name: FUNCTION accounting_delete_manual_journal(p_site_id uuid, p_entry_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_delete_manual_journal(p_site_id uuid, p_entry_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accounting_delete_manual_journal(p_site_id uuid, p_entry_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.accounting_delete_manual_journal(p_site_id uuid, p_entry_id uuid) TO service_role;


--
-- Name: FUNCTION accounting_delete_source(p_site_id uuid, p_source_type text, p_source_id uuid); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_delete_source(p_site_id uuid, p_source_type text, p_source_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accounting_delete_source(p_site_id uuid, p_source_type text, p_source_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.accounting_delete_source(p_site_id uuid, p_source_type text, p_source_id uuid) TO service_role;


--
-- Name: FUNCTION accounting_guard_account(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_guard_account() FROM PUBLIC;


--
-- Name: FUNCTION accounting_guard_purchase_draft(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_guard_purchase_draft() FROM PUBLIC;


--
-- Name: FUNCTION accounting_preserve_legacy_receipt(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_preserve_legacy_receipt() FROM PUBLIC;


--
-- Name: FUNCTION accounting_record_sale_refund(p_sale_id uuid, p_refund_id text, p_amount numeric, p_currency text, p_refunded_at timestamp with time zone); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_record_sale_refund(p_sale_id uuid, p_refund_id text, p_amount numeric, p_currency text, p_refunded_at timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accounting_record_sale_refund(p_sale_id uuid, p_refund_id text, p_amount numeric, p_currency text, p_refunded_at timestamp with time zone) TO service_role;


--
-- Name: FUNCTION accounting_replace_source_journals(p_site_id uuid, p_source_type text, p_source_id uuid, p_entries jsonb, p_source_updated_at timestamp with time zone, p_state text); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_replace_source_journals(p_site_id uuid, p_source_type text, p_source_id uuid, p_entries jsonb, p_source_updated_at timestamp with time zone, p_state text) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accounting_replace_source_journals(p_site_id uuid, p_source_type text, p_source_id uuid, p_entries jsonb, p_source_updated_at timestamp with time zone, p_state text) TO service_role;


--
-- Name: FUNCTION accounting_report_snapshot(p_site_id uuid, p_from timestamp with time zone, p_to_exclusive timestamp with time zone, p_currency text, p_include_opening boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_report_snapshot(p_site_id uuid, p_from timestamp with time zone, p_to_exclusive timestamp with time zone, p_currency text, p_include_opening boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accounting_report_snapshot(p_site_id uuid, p_from timestamp with time zone, p_to_exclusive timestamp with time zone, p_currency text, p_include_opening boolean) TO authenticated;
GRANT ALL ON FUNCTION public.accounting_report_snapshot(p_site_id uuid, p_from timestamp with time zone, p_to_exclusive timestamp with time zone, p_currency text, p_include_opening boolean) TO service_role;


--
-- Name: FUNCTION accounting_save_journal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_save_journal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accounting_save_journal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean) TO authenticated;
GRANT ALL ON FUNCTION public.accounting_save_journal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean) TO service_role;


--
-- Name: FUNCTION accounting_save_journal_internal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean, p_allow_source boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_save_journal_internal(p_site_id uuid, p_entry jsonb, p_lines jsonb, p_entry_id uuid, p_expected_hash text, p_check_version boolean, p_allow_source boolean) FROM PUBLIC;


--
-- Name: FUNCTION accounting_touch_source(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_touch_source() FROM PUBLIC;


--
-- Name: FUNCTION accounting_touch_source_from_child(); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_touch_source_from_child() FROM PUBLIC;


--
-- Name: FUNCTION accounting_update_purchase_items(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_update_purchase_items(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb) FROM PUBLIC;
GRANT ALL ON FUNCTION public.accounting_update_purchase_items(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.accounting_update_purchase_items(p_site_id uuid, p_purchase_id uuid, p_expected_updated_at timestamp with time zone, p_items jsonb, p_update jsonb) TO service_role;


--
-- Name: FUNCTION accounting_validate_journal_lines(p_site_id uuid, p_lines jsonb, p_existing_id uuid, p_allow_dimensions boolean); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.accounting_validate_journal_lines(p_site_id uuid, p_lines jsonb, p_existing_id uuid, p_allow_dimensions boolean) FROM PUBLIC;


--
-- Name: FUNCTION acquire_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text, p_ttl_seconds integer); Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON FUNCTION public.acquire_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text, p_ttl_seconds integer) FROM PUBLIC;
GRANT ALL ON FUNCTION public.acquire_deployment_recovery_scan_lease(p_lease_key text, p_owner_id text, p_ttl_seconds integer) TO service_role;
