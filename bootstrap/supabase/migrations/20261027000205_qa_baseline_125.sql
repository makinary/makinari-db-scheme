SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;


--
-- Name: profiles profiles_delete_optimized; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_delete_optimized ON public.profiles FOR DELETE USING ((id = ( SELECT auth.uid() AS uid)));


--
-- Name: profiles profiles_insert_optimized; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_insert_optimized ON public.profiles FOR INSERT WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));


--
-- Name: profiles profiles_select_optimized; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_select_optimized ON public.profiles FOR SELECT USING (true);


--
-- Name: profiles profiles_update_optimized; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_update_optimized ON public.profiles FOR UPDATE USING ((id = ( SELECT auth.uid() AS uid)));


--
-- Name: promotion_catalog_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.promotion_catalog_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: promotion_catalog_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.promotion_catalog_items ENABLE ROW LEVEL SECURITY;

--
-- Name: promotion_catalog_items promotion_catalog_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY promotion_catalog_items_unified ON public.promotion_catalog_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = promotion_catalog_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: promotion_required_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.promotion_required_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: promotion_required_categories promotion_required_categories_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY promotion_required_categories_unified ON public.promotion_required_categories USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = promotion_required_categories.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: promotion_required_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.promotion_required_items ENABLE ROW LEVEL SECURITY;

--
-- Name: promotion_required_items promotion_required_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY promotion_required_items_unified ON public.promotion_required_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = promotion_required_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: promotions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

--
-- Name: promotions promotions_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY promotions_unified ON public.promotions USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = promotions.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: purchase_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_items purchase_items_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchase_items_delete ON public.purchase_items FOR DELETE TO authenticated USING ((public.user_can(site_id, 'delete'::text) AND (EXISTS ( SELECT 1
   FROM public.purchases p
  WHERE ((p.id = purchase_items.purchase_id) AND (p.site_id = purchase_items.site_id))))));


--
-- Name: purchase_items purchase_items_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchase_items_insert ON public.purchase_items FOR INSERT TO authenticated WITH CHECK ((public.user_can(site_id, 'insert'::text) AND (EXISTS ( SELECT 1
   FROM public.purchases p
  WHERE ((p.id = purchase_items.purchase_id) AND (p.site_id = purchase_items.site_id))))));


--
-- Name: purchase_items purchase_items_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchase_items_select ON public.purchase_items FOR SELECT TO authenticated USING ((public.user_can(site_id, 'select'::text) AND (EXISTS ( SELECT 1
   FROM public.purchases p
  WHERE ((p.id = purchase_items.purchase_id) AND (p.site_id = purchase_items.site_id))))));


--
-- Name: purchase_items purchase_items_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchase_items_update ON public.purchase_items FOR UPDATE TO authenticated USING ((public.user_can(site_id, 'update'::text) AND (EXISTS ( SELECT 1
   FROM public.purchases p
  WHERE ((p.id = purchase_items.purchase_id) AND (p.site_id = purchase_items.site_id)))))) WITH CHECK ((public.user_can(site_id, 'update'::text) AND (EXISTS ( SELECT 1
   FROM public.purchases p
  WHERE ((p.id = purchase_items.purchase_id) AND (p.site_id = purchase_items.site_id))))));


--
-- Name: purchases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;

--
-- Name: purchases purchases_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchases_delete ON public.purchases FOR DELETE TO authenticated USING (public.user_can(site_id, 'delete'::text));


--
-- Name: purchases purchases_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchases_insert ON public.purchases FOR INSERT TO authenticated WITH CHECK (public.user_can(site_id, 'insert'::text));


--
-- Name: purchases purchases_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchases_select ON public.purchases FOR SELECT TO authenticated USING (public.user_can(site_id, 'select'::text));


--
-- Name: purchases purchases_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchases_update ON public.purchases FOR UPDATE TO authenticated USING (public.user_can(site_id, 'update'::text)) WITH CHECK (public.user_can(site_id, 'update'::text));


--
-- Name: quotation_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.quotation_items ENABLE ROW LEVEL SECURITY;

--
-- Name: quotation_items quotation_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quotation_items_unified ON public.quotation_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.quotations q
  WHERE ((q.id = quotation_items.quotation_id) AND ((q.buyer_user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.sites s
          WHERE ((s.id = q.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
                   FROM public.site_members sm
                  WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))))))));


--
-- Name: quotations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;

--
-- Name: quotations quotations_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quotations_unified ON public.quotations USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (buyer_user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = quotations.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: record_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.record_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: record_categories record_categories_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_categories_delete ON public.record_categories FOR DELETE TO authenticated USING (public.user_can(site_id, 'delete'::text));


--
-- Name: record_categories record_categories_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_categories_insert ON public.record_categories FOR INSERT TO authenticated WITH CHECK (public.user_can(site_id, 'insert'::text));


--
-- Name: record_categories record_categories_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_categories_select ON public.record_categories FOR SELECT TO authenticated USING (public.user_can(site_id, 'select'::text));


--
-- Name: record_categories record_categories_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_categories_update ON public.record_categories FOR UPDATE TO authenticated USING (public.user_can(site_id, 'update'::text)) WITH CHECK (public.user_can(site_id, 'update'::text));


--
-- Name: record_diagram_edges; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.record_diagram_edges ENABLE ROW LEVEL SECURITY;

--
-- Name: record_diagram_edges record_diagram_edges_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_diagram_edges_select ON public.record_diagram_edges FOR SELECT TO authenticated USING (public.can_access_record_diagram(record_id, site_id, 'select'::text));


--
-- Name: record_diagram_nodes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.record_diagram_nodes ENABLE ROW LEVEL SECURITY;

--
-- Name: record_diagram_nodes record_diagram_nodes_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_diagram_nodes_select ON public.record_diagram_nodes FOR SELECT TO authenticated USING (public.can_access_record_diagram(record_id, site_id, 'select'::text));


--
-- Name: record_diagrams; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.record_diagrams ENABLE ROW LEVEL SECURITY;

--
-- Name: record_diagrams record_diagrams_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_diagrams_select ON public.record_diagrams FOR SELECT TO authenticated USING (public.can_access_record_diagram(record_id, site_id, 'select'::text));


--
-- Name: record_embedding_jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.record_embedding_jobs ENABLE ROW LEVEL SECURITY;

--
-- Name: record_embedding_jobs record_embedding_jobs_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY record_embedding_jobs_select ON public.record_embedding_jobs FOR SELECT TO authenticated USING (public.can_access_record_diagram(record_id, site_id, 'select'::text));


--
-- Name: records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.records ENABLE ROW LEVEL SECURITY;

--
-- Name: records records_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY records_delete ON public.records FOR DELETE TO authenticated USING ((public.user_can(site_id, 'delete'::text) AND public.can_access_record_values(site_id, relations)));


--
-- Name: records records_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY records_insert ON public.records FOR INSERT TO authenticated WITH CHECK ((public.user_can(site_id, 'insert'::text) AND public.can_access_record_values(site_id, relations)));


--
-- Name: records records_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY records_select ON public.records FOR SELECT TO authenticated USING ((public.user_can(site_id, 'select'::text) AND public.can_access_record_values(site_id, relations)));


--
-- Name: records records_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY records_update ON public.records FOR UPDATE TO authenticated USING ((public.user_can(site_id, 'update'::text) AND public.can_access_record_values(site_id, relations))) WITH CHECK ((public.user_can(site_id, 'update'::text) AND public.can_access_record_values(site_id, relations)));


--
-- Name: referral_code_uses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.referral_code_uses ENABLE ROW LEVEL SECURITY;

--
-- Name: referral_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: remote_instances; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.remote_instances ENABLE ROW LEVEL SECURITY;

--
-- Name: remote_instances remote_instances_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY remote_instances_access_policy ON public.remote_instances USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = remote_instances.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text)))))))))) WITH CHECK (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = remote_instances.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text))))))))));


--
-- Name: remote_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.remote_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_archived_runner_reassignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_archived_runner_reassignments ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_commands; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_commands ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_commands requirement_commands_service_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_commands_service_role ON public.requirement_commands TO service_role USING (true) WITH CHECK (true);


--
-- Name: requirement_cron_cycle_outcomes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_cron_cycle_outcomes ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_cron_cycle_outcomes requirement_cron_cycle_outcomes_service_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_cron_cycle_outcomes_service_role ON public.requirement_cron_cycle_outcomes TO service_role USING (true) WITH CHECK (true);


--
-- Name: requirement_economic_pauses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_economic_pauses ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_harness_decisions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_harness_decisions ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_harness_decisions requirement_harness_decisions_service_delivery; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_harness_decisions_service_delivery ON public.requirement_harness_decisions FOR UPDATE TO service_role USING (true) WITH CHECK (true);


--
-- Name: requirement_harness_decisions requirement_harness_decisions_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_harness_decisions_service_read ON public.requirement_harness_decisions FOR SELECT TO service_role USING (true);


--
-- Name: requirement_migration_diagnostics; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_migration_diagnostics ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_migration_diagnostics requirement_migration_diagnostics_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_migration_diagnostics_service_read ON public.requirement_migration_diagnostics FOR SELECT TO service_role USING (true);


--
-- Name: requirement_migration_execution_handoffs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_migration_execution_handoffs ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_migration_lifecycle; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_migration_lifecycle ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_migration_lifecycle requirement_migration_lifecycle_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_migration_lifecycle_service_read ON public.requirement_migration_lifecycle FOR SELECT TO service_role USING (true);


--
-- Name: requirement_migration_reconciliation_resumes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_migration_reconciliation_resumes ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_migration_reconciliations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_migration_reconciliations ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_migration_retirements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_migration_retirements ENABLE ROW LEVEL SECURITY;
