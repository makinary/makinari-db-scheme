SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: deals location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.deals AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: inventory_levels location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.inventory_levels AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: invoice_reminders location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.invoice_reminders AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: locations location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.locations AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: messages location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.messages AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.conversations acl_action_parent
  WHERE ((acl_action_parent.id = messages.conversation_id) AND public.user_can(acl_action_parent.site_id, 'insert'::text))))));


--
-- Name: pos_register_movements location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.pos_register_movements AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: pos_register_receipts location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.pos_register_receipts AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: pos_register_sessions location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.pos_register_sessions AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: purchase_items location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.purchase_items AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: purchases location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.purchases AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: quotation_items location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.quotation_items AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.quotations acl_action_parent
  WHERE ((acl_action_parent.id = quotation_items.quotation_id) AND public.user_can(acl_action_parent.site_id, 'insert'::text))))));


--
-- Name: quotations location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.quotations AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: records location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.records AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: reservations location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.reservations AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: sale_order_item_units location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.sale_order_item_units AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: sale_order_items location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.sale_order_items AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: sale_orders location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.sale_orders AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: sales location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.sales AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: shipment_location_pings location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.shipment_location_pings AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: shipments location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.shipments AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: subscriptions location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.subscriptions AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: task_categories location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.task_categories AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_categories.task_id) AND public.user_can(acl_action_parent.site_id, 'insert'::text))))));


--
-- Name: task_comments location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.task_comments AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_comments.task_id) AND public.user_can(acl_action_parent.site_id, 'insert'::text))))));


--
-- Name: tasks location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.tasks AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: transactions location_acl_action_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_insert ON public.transactions AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'insert'::text)));


--
-- Name: accounting_sale_refunds location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.accounting_sale_refunds AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: conversations location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.conversations AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: deal_owners location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.deal_owners AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.deals acl_action_parent
  WHERE ((acl_action_parent.id = deal_owners.deal_id) AND public.user_can(acl_action_parent.site_id, 'select'::text))))));


--
-- Name: deals location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.deals AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: inventory_levels location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.inventory_levels AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: invoice_reminders location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.invoice_reminders AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: locations location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.locations AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: messages location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.messages AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.conversations acl_action_parent
  WHERE ((acl_action_parent.id = messages.conversation_id) AND public.user_can(acl_action_parent.site_id, 'select'::text))))));


--
-- Name: pos_register_movements location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.pos_register_movements AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: pos_register_receipts location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.pos_register_receipts AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: pos_register_sessions location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.pos_register_sessions AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: purchase_items location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.purchase_items AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: purchases location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.purchases AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: quotation_items location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.quotation_items AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.quotations acl_action_parent
  WHERE ((acl_action_parent.id = quotation_items.quotation_id) AND public.user_can(acl_action_parent.site_id, 'select'::text))))));


--
-- Name: quotations location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.quotations AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: records location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.records AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: reservations location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.reservations AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: sale_order_item_units location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.sale_order_item_units AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: sale_order_items location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.sale_order_items AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: sale_orders location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.sale_orders AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: sales location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.sales AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: shipment_location_pings location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.shipment_location_pings AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: shipments location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.shipments AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: subscriptions location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.subscriptions AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: task_categories location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.task_categories AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_categories.task_id) AND public.user_can(acl_action_parent.site_id, 'select'::text))))));


--
-- Name: task_comments location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.task_comments AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.tasks acl_action_parent
  WHERE ((acl_action_parent.id = task_comments.task_id) AND public.user_can(acl_action_parent.site_id, 'select'::text))))));


--
-- Name: tasks location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.tasks AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: transactions location_acl_action_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_select ON public.transactions AS RESTRICTIVE FOR SELECT TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'select'::text)));


--
-- Name: accounting_sale_refunds location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.accounting_sale_refunds AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: conversations location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.conversations AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: deal_owners location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.deal_owners AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.deals acl_action_parent
  WHERE ((acl_action_parent.id = deal_owners.deal_id) AND public.user_can(acl_action_parent.site_id, 'update'::text)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.deals acl_action_parent
  WHERE ((acl_action_parent.id = deal_owners.deal_id) AND public.user_can(acl_action_parent.site_id, 'update'::text))))));


--
-- Name: deals location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.deals AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: inventory_levels location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.inventory_levels AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: invoice_reminders location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.invoice_reminders AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: locations location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.locations AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: messages location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.messages AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.conversations acl_action_parent
  WHERE ((acl_action_parent.id = messages.conversation_id) AND public.user_can(acl_action_parent.site_id, 'update'::text)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (EXISTS ( SELECT 1
   FROM public.conversations acl_action_parent
  WHERE ((acl_action_parent.id = messages.conversation_id) AND public.user_can(acl_action_parent.site_id, 'update'::text))))));


--
-- Name: pos_register_movements location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.pos_register_movements AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: pos_register_receipts location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.pos_register_receipts AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: pos_register_sessions location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.pos_register_sessions AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: purchase_items location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.purchase_items AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));


--
-- Name: purchases location_acl_action_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_action_update ON public.purchases AS RESTRICTIVE FOR UPDATE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR public.user_can(site_id, 'update'::text)));
