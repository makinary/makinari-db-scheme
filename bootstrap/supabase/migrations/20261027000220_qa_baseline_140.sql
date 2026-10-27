SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: TABLE experiment_segments; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.experiment_segments TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.experiment_segments TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.experiment_segments TO service_role;


--
-- Name: TABLE experiments; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.experiments TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.experiments TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.experiments TO service_role;


--
-- Name: TABLE external_resources; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.external_resources TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.external_resources TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.external_resources TO service_role;


--
-- Name: TABLE harness_requirement_runs; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.harness_requirement_runs TO service_role;


--
-- Name: TABLE harness_sessions; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.harness_sessions TO service_role;


--
-- Name: TABLE icp_dispatch_config; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.icp_dispatch_config TO service_role;


--
-- Name: COLUMN icp_dispatch_config.enabled; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(enabled) ON TABLE public.icp_dispatch_config TO service_role;


--
-- Name: COLUMN icp_dispatch_config.max_concurrency; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(max_concurrency) ON TABLE public.icp_dispatch_config TO service_role;


--
-- Name: COLUMN icp_dispatch_config.slice_candidates; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(slice_candidates) ON TABLE public.icp_dispatch_config TO service_role;


--
-- Name: COLUMN icp_dispatch_config.daily_candidate_limit; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(daily_candidate_limit) ON TABLE public.icp_dispatch_config TO service_role;


--
-- Name: TABLE icp_dispatch_list_state; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.icp_dispatch_list_state TO service_role;


--
-- Name: TABLE icp_dispatch_runs; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.icp_dispatch_runs TO service_role;


--
-- Name: TABLE icp_dispatch_site_state; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.icp_dispatch_site_state TO service_role;


--
-- Name: TABLE icp_mining; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.icp_mining TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.icp_mining TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.icp_mining TO service_role;


--
-- Name: TABLE icypeas_email_searches; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.icypeas_email_searches TO service_role;


--
-- Name: TABLE image_generation_credit_reservations; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.image_generation_credit_reservations TO service_role;


--
-- Name: TABLE instance_artifacts; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.instance_artifacts TO service_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.instance_artifacts TO authenticated;


--
-- Name: TABLE instance_context_memories; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_context_memories TO service_role;


--
-- Name: TABLE instance_context_state; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_context_state TO service_role;
GRANT SELECT ON TABLE public.instance_context_state TO authenticated;


--
-- Name: TABLE instance_logs; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_logs TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_logs TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_logs TO service_role;


--
-- Name: TABLE instance_node_contexts; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_node_contexts TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_node_contexts TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_node_contexts TO service_role;


--
-- Name: TABLE instance_nodes; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_nodes TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_nodes TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_nodes TO service_role;


--
-- Name: TABLE instance_plan_step_infrastructure_events; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_plan_step_infrastructure_events TO service_role;


--
-- Name: TABLE instance_plans; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_plans TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_plans TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.instance_plans TO service_role;


--
-- Name: TABLE inventory_levels; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.inventory_levels TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.inventory_levels TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.inventory_levels TO service_role;


--
-- Name: TABLE invoice_reminders; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.invoice_reminders TO service_role;


--
-- Name: TABLE item_spec_categories; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.item_spec_categories TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.item_spec_categories TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.item_spec_categories TO service_role;


--
-- Name: TABLE item_specs; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.item_specs TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.item_specs TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.item_specs TO service_role;


--
-- Name: TABLE journal_entries; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.journal_entries TO authenticated;
GRANT SELECT ON TABLE public.journal_entries TO service_role;


--
-- Name: TABLE journal_lines; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.journal_lines TO authenticated;
GRANT SELECT ON TABLE public.journal_lines TO service_role;


--
-- Name: TABLE kpis; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.kpis TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.kpis TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.kpis TO service_role;


--
-- Name: TABLE layers; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.layers TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.layers TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.layers TO service_role;


--
-- Name: TABLE lead_analysis; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lead_analysis TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lead_analysis TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lead_analysis TO service_role;


--
-- Name: TABLE lead_analysis_summary; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lead_analysis_summary TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lead_analysis_summary TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lead_analysis_summary TO service_role;


--
-- Name: TABLE lead_invoice_payment_requests; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.lead_invoice_payment_requests TO service_role;
GRANT SELECT ON TABLE public.lead_invoice_payment_requests TO authenticated;


--
-- Name: TABLE leads; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.leads TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.leads TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.leads TO service_role;


--
-- Name: TABLE locations; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.locations TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.locations TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.locations TO service_role;


--
-- Name: TABLE marketplace_actions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_actions TO service_role;


--
-- Name: TABLE marketplace_events; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_events TO service_role;


--
-- Name: TABLE marketplace_integrations; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_integrations TO service_role;
GRANT SELECT ON TABLE public.marketplace_integrations TO authenticated;


--
-- Name: TABLE marketplace_merchant_connections; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_merchant_connections TO service_role;


--
-- Name: TABLE marketplace_oauth_sessions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_oauth_sessions TO service_role;


--
-- Name: TABLE marketplace_platform_apps; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_platform_apps TO service_role;


--
-- Name: TABLE marketplace_provider_webhook_keys; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_provider_webhook_keys TO service_role;


--
-- Name: TABLE marketplace_webhook_registration_apps; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_webhook_registration_apps TO service_role;


--
-- Name: TABLE marketplace_webhook_registrations; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.marketplace_webhook_registrations TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.messages TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.messages TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.messages TO service_role;


--
-- Name: TABLE modifier_group_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.modifier_group_items TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.modifier_group_items TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.modifier_group_items TO service_role;


--
-- Name: TABLE modifier_groups; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.modifier_groups TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.modifier_groups TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.modifier_groups TO service_role;


--
-- Name: TABLE notifications; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.notifications TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.notifications TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.notifications TO service_role;


--
-- Name: TABLE outstand_initial_imports; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.outstand_initial_imports TO service_role;


--
-- Name: TABLE partner_licenses; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.partner_licenses TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.partner_licenses TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.partner_licenses TO service_role;


--
-- Name: TABLE pass_redeemable_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pass_redeemable_items TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pass_redeemable_items TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pass_redeemable_items TO service_role;


--
-- Name: TABLE pass_round_robin_state; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pass_round_robin_state TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pass_round_robin_state TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pass_round_robin_state TO service_role;


--
-- Name: TABLE payments; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.payments TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.payments TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.payments TO service_role;


--
-- Name: TABLE payout_requests; Type: ACL; Schema: public; Owner: -
--

GRANT REFERENCES,TRIGGER,TRUNCATE ON TABLE public.payout_requests TO anon;
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE ON TABLE public.payout_requests TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.payout_requests TO service_role;


--
-- Name: TABLE persons; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.persons TO service_role;


--
-- Name: TABLE platform_audit_log; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.platform_audit_log TO service_role;


--
-- Name: TABLE platform_quotas; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.platform_quotas TO service_role;


--
-- Name: TABLE platform_tracking_events; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.platform_tracking_events TO service_role;


--
-- Name: TABLE platform_user_roles; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.platform_user_roles TO service_role;
