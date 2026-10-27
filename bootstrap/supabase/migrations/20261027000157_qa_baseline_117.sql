SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: quotation_items location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.quotation_items AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.quotations acl_action_parent
  WHERE ((acl_action_parent.id = quotation_items.quotation_id) AND public.user_can(acl_action_parent.site_id, 'update'::text)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.quotations acl_action_parent
  WHERE ((acl_action_parent.id = quotation_items.quotation_id) AND public.user_can(acl_action_parent.site_id, 'update'::text))))));


--
-- Name: quotations location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.quotations AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: records location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.records AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: reservations location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.reservations AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: sale_order_item_units location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.sale_order_item_units AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: sale_order_items location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.sale_order_items AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: sale_orders location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.sale_orders AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: sales location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.sales AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: shipment_location_pings location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.shipment_location_pings AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: shipments location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.shipments AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: subscriptions location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.subscriptions AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: task_categories location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.task_categories AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_categories.task_id) AND public.user_can(acl_action_parent.site_id, 'update'::text)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_categories.task_id) AND public.user_can(acl_action_parent.site_id, 'update'::text))))));


--
-- Name: task_comments location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.task_comments AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_comments.task_id) AND public.user_can(acl_action_parent.site_id, 'update'::text)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_comments.task_id) AND public.user_can(acl_action_parent.site_id, 'update'::text))))));


--
-- Name: tasks location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.tasks AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: transactions location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.transactions AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: catalog_categories location_acl_central_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_delete ON public.catalog_categories AS RESTRICTIVE FOR DELETE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: catalog_items location_acl_central_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_delete ON public.catalog_items AS RESTRICTIVE FOR DELETE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: locations location_acl_central_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_delete ON public.locations AS RESTRICTIVE FOR DELETE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: price_list_items location_acl_central_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_delete ON public.price_list_items AS RESTRICTIVE FOR DELETE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: price_lists location_acl_central_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_delete ON public.price_lists AS RESTRICTIVE FOR DELETE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: promotions location_acl_central_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_delete ON public.promotions AS RESTRICTIVE FOR DELETE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: catalog_categories location_acl_central_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_insert ON public.catalog_categories AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: catalog_items location_acl_central_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_insert ON public.catalog_items AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: locations location_acl_central_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_insert ON public.locations AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: price_list_items location_acl_central_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_insert ON public.price_list_items AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: price_lists location_acl_central_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_insert ON public.price_lists AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: promotions location_acl_central_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_insert ON public.promotions AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: catalog_categories location_acl_central_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_update ON public.catalog_categories AS RESTRICTIVE FOR UPDATE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions))) WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: catalog_items location_acl_central_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_update ON public.catalog_items AS RESTRICTIVE FOR UPDATE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions))) WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: locations location_acl_central_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_update ON public.locations AS RESTRICTIVE FOR UPDATE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions))) WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: price_list_items location_acl_central_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_update ON public.price_list_items AS RESTRICTIVE FOR UPDATE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions))) WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: price_lists location_acl_central_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_update ON public.price_lists AS RESTRICTIVE FOR UPDATE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions))) WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: promotions location_acl_central_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_central_update ON public.promotions AS RESTRICTIVE FOR UPDATE TO authenticated USING ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions))) WITH CHECK ((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)));


--
-- Name: accounting_accounts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.accounting_accounts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: accounting_sale_refunds location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.accounting_sale_refunds AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = accounting_sale_refunds.sale_id) AND (acl_parent.site_id = accounting_sale_refunds.site_id)))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = accounting_sale_refunds.sale_id) AND (acl_parent.site_id = accounting_sale_refunds.site_id))))))));


--
-- Name: activity location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.activity AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: agent_assets location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.agent_assets AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: agent_memories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.agent_memories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: agents location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.agents AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: allowed_domains location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.allowed_domains AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: analysis location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.analysis AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: api_keys location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.api_keys AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: appointments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.appointments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: apps_tenants location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.apps_tenants AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: assets location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.assets AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: audience_leads location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.audience_leads AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: audiences location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.audiences AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: automation_auth_sessions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.automation_auth_sessions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: billing location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.billing AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: billing_credit_grant_keys location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.billing_credit_grant_keys AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: billing_credit_migration_audit location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.billing_credit_migration_audit AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: calendar_blocks location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.calendar_blocks AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: campaign_requirements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.campaign_requirements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: campaign_segments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.campaign_segments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: campaign_subtasks location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.campaign_subtasks AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: campaigns location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.campaigns AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_embedding_jobs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_embedding_jobs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_import_batches location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_import_batches AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_item_modifier_groups location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_item_modifier_groups AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_item_requirements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_item_requirements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_item_specs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_item_specs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_item_taxes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_item_taxes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_search_documents location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_search_documents AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_search_refresh_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_search_refresh_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_search_revision_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_search_revision_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: catalog_search_revisions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.catalog_search_revisions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: categories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.categories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));
