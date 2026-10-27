SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: TABLE pos_checkout_attempts; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.pos_checkout_attempts TO service_role;


--
-- Name: TABLE pos_client_mutations; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pos_client_mutations TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pos_client_mutations TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.pos_client_mutations TO service_role;


--
-- Name: TABLE pos_register_movements; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.pos_register_movements TO authenticated;


--
-- Name: TABLE pos_register_receipts; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.pos_register_receipts TO authenticated;
GRANT SELECT ON TABLE public.pos_register_receipts TO service_role;


--
-- Name: TABLE pos_register_sessions; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.pos_register_sessions TO authenticated;


--
-- Name: TABLE price_list_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.price_list_items TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.price_list_items TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.price_list_items TO service_role;


--
-- Name: TABLE price_lists; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.price_lists TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.price_lists TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.price_lists TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.profiles TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.profiles TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.profiles TO service_role;


--
-- Name: TABLE promotion_catalog_categories; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_catalog_categories TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_catalog_categories TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_catalog_categories TO service_role;


--
-- Name: TABLE promotion_catalog_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_catalog_items TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_catalog_items TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_catalog_items TO service_role;


--
-- Name: TABLE promotion_required_categories; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_required_categories TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_required_categories TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_required_categories TO service_role;


--
-- Name: TABLE promotion_required_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_required_items TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_required_items TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotion_required_items TO service_role;


--
-- Name: TABLE promotions; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotions TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotions TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.promotions TO service_role;


--
-- Name: TABLE purchase_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.purchase_items TO service_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.purchase_items TO authenticated;


--
-- Name: TABLE purchases; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.purchases TO service_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.purchases TO authenticated;


--
-- Name: TABLE quotation_items; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.quotation_items TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.quotation_items TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.quotation_items TO service_role;


--
-- Name: TABLE quotations; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.quotations TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.quotations TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.quotations TO service_role;


--
-- Name: TABLE record_categories; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.record_categories TO anon;
GRANT SELECT,REFERENCES,DELETE,TRIGGER,TRUNCATE ON TABLE public.record_categories TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.record_categories TO service_role;


--
-- Name: COLUMN record_categories.site_id; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(site_id) ON TABLE public.record_categories TO authenticated;


--
-- Name: COLUMN record_categories.name; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(name),UPDATE(name) ON TABLE public.record_categories TO authenticated;


--
-- Name: COLUMN record_categories.description; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(description),UPDATE(description) ON TABLE public.record_categories TO authenticated;


--
-- Name: COLUMN record_categories.icon; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(icon),UPDATE(icon) ON TABLE public.record_categories TO authenticated;


--
-- Name: COLUMN record_categories.template_fields; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(template_fields),UPDATE(template_fields) ON TABLE public.record_categories TO authenticated;


--
-- Name: COLUMN record_categories.parent_category_id; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(parent_category_id),UPDATE(parent_category_id) ON TABLE public.record_categories TO authenticated;


--
-- Name: TABLE record_diagram_edges; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.record_diagram_edges TO service_role;
GRANT SELECT ON TABLE public.record_diagram_edges TO authenticated;


--
-- Name: TABLE record_diagram_nodes; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.record_diagram_nodes TO service_role;
GRANT SELECT ON TABLE public.record_diagram_nodes TO authenticated;


--
-- Name: TABLE record_diagrams; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.record_diagrams TO service_role;
GRANT SELECT ON TABLE public.record_diagrams TO authenticated;


--
-- Name: TABLE records; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.records TO anon;
GRANT SELECT,REFERENCES,DELETE,TRIGGER,TRUNCATE ON TABLE public.records TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.records TO service_role;


--
-- Name: COLUMN records.site_id; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(site_id) ON TABLE public.records TO authenticated;


--
-- Name: COLUMN records.category_id; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(category_id),UPDATE(category_id) ON TABLE public.records TO authenticated;


--
-- Name: COLUMN records.title; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(title),UPDATE(title) ON TABLE public.records TO authenticated;


--
-- Name: COLUMN records.description; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(description),UPDATE(description) ON TABLE public.records TO authenticated;


--
-- Name: COLUMN records.data; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(data),UPDATE(data) ON TABLE public.records TO authenticated;


--
-- Name: COLUMN records.relations; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(relations),UPDATE(relations) ON TABLE public.records TO authenticated;


--
-- Name: COLUMN records.status; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(status),UPDATE(status) ON TABLE public.records TO authenticated;


--
-- Name: COLUMN records.location_id; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(location_id) ON TABLE public.records TO authenticated;


--
-- Name: TABLE referral_code_uses; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referral_code_uses TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referral_code_uses TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referral_code_uses TO service_role;


--
-- Name: TABLE referral_codes; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referral_codes TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referral_codes TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.referral_codes TO service_role;


--
-- Name: TABLE remote_instances; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.remote_instances TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.remote_instances TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.remote_instances TO service_role;


--
-- Name: TABLE remote_sessions; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.remote_sessions TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.remote_sessions TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.remote_sessions TO service_role;


--
-- Name: TABLE requirement_archived_runner_reassignments; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_archived_runner_reassignments TO service_role;


--
-- Name: TABLE requirement_campaigns; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_campaigns TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_campaigns TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_campaigns TO service_role;


--
-- Name: TABLE requirement_commands; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_commands TO service_role;


--
-- Name: TABLE requirement_cron_cycle_outcomes; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_cron_cycle_outcomes TO service_role;


--
-- Name: TABLE requirement_harness_decisions; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_harness_decisions TO service_role;


--
-- Name: COLUMN requirement_harness_decisions.email_state; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(email_state) ON TABLE public.requirement_harness_decisions TO service_role;


--
-- Name: COLUMN requirement_harness_decisions.email_attempted_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(email_attempted_at) ON TABLE public.requirement_harness_decisions TO service_role;


--
-- Name: COLUMN requirement_harness_decisions.email_error; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(email_error) ON TABLE public.requirement_harness_decisions TO service_role;


--
-- Name: TABLE requirement_migration_diagnostics; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_migration_diagnostics TO service_role;


--
-- Name: TABLE requirement_migration_execution_handoffs; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_migration_execution_handoffs TO service_role;


--
-- Name: TABLE requirement_migration_reconciliation_resumes; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_migration_reconciliation_resumes TO service_role;


--
-- Name: TABLE requirement_migration_reconciliations; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_migration_reconciliations TO service_role;


--
-- Name: TABLE requirement_migration_retirements; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_migration_retirements TO service_role;


--
-- Name: TABLE requirement_segments; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_segments TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_segments TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_segments TO service_role;


--
-- Name: TABLE requirement_source_checkpoints; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.requirement_source_checkpoints TO service_role;


--
-- Name: TABLE requirement_status; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_status TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_status TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_status TO service_role;


--
-- Name: TABLE requirement_user_action_receipts; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.requirement_user_action_receipts TO service_role;


--
-- Name: TABLE reservation_schedules; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.reservation_schedules TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.reservation_schedules TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.reservation_schedules TO service_role;


--
-- Name: TABLE reservations; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.reservations TO anon;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.reservations TO authenticated;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.reservations TO service_role;


--
-- Name: TABLE role_queries; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.role_queries TO service_role;


--
-- Name: TABLE role_query_segments; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.role_query_segments TO service_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.role_query_segments TO authenticated;


--
-- Name: TABLE sale_order_item_units; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.sale_order_item_units TO service_role;
GRANT SELECT ON TABLE public.sale_order_item_units TO authenticated;
