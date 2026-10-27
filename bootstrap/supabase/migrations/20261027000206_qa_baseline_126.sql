SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;


--
-- Name: requirement_segments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_segments ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_segments requirement_segments_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_segments_optimized_policy ON public.requirement_segments USING ((EXISTS ( SELECT 1
   FROM (public.requirements r
     JOIN public.sites s ON ((s.id = r.site_id)))
  WHERE ((r.id = requirement_segments.requirement_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: requirement_source_checkpoints; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_source_checkpoints ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_status; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_status ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_user_action_receipts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirement_user_action_receipts ENABLE ROW LEVEL SECURITY;

--
-- Name: requirement_user_action_receipts requirement_user_action_receipts_service_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirement_user_action_receipts_service_role ON public.requirement_user_action_receipts TO service_role USING (true) WITH CHECK (true);


--
-- Name: requirements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requirements ENABLE ROW LEVEL SECURITY;

--
-- Name: requirements requirements_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY requirements_optimized_policy ON public.requirements USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = requirements.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (requirements.user_id = auth.uid()))))))))));


--
-- Name: reservation_schedules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reservation_schedules ENABLE ROW LEVEL SECURITY;

--
-- Name: reservation_schedules reservation_schedules_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservation_schedules_unified ON public.reservation_schedules USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = reservation_schedules.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: reservations reservations_buyer_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_buyer_read ON public.reservations FOR SELECT USING (((buyer_user_id = auth.uid()) OR ((owner_site_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = reservations.owner_site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))));


--
-- Name: reservations reservations_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_unified ON public.reservations USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = reservations.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (reservations.assignee_user_id = auth.uid())))))))))));


--
-- Name: role_queries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.role_queries ENABLE ROW LEVEL SECURITY;

--
-- Name: role_query_segments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.role_query_segments ENABLE ROW LEVEL SECURITY;

--
-- Name: role_query_segments role_query_segments - authenticated can delete in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "role_query_segments - authenticated can delete in site" ON public.role_query_segments FOR DELETE TO authenticated USING (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));


--
-- Name: role_query_segments role_query_segments - authenticated can insert in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "role_query_segments - authenticated can insert in site" ON public.role_query_segments FOR INSERT TO authenticated WITH CHECK (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));


--
-- Name: role_query_segments role_query_segments - authenticated can select in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "role_query_segments - authenticated can select in site" ON public.role_query_segments FOR SELECT TO authenticated USING (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));


--
-- Name: role_query_segments role_query_segments - authenticated can update in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "role_query_segments - authenticated can update in site" ON public.role_query_segments FOR UPDATE TO authenticated USING (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));


--
-- Name: role_query_segments role_query_segments - service_role can do anything; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "role_query_segments - service_role can do anything" ON public.role_query_segments TO service_role USING (true) WITH CHECK (true);


--
-- Name: sale_order_item_units; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sale_order_item_units ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_order_item_units sale_order_item_units_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sale_order_item_units_select ON public.sale_order_item_units FOR SELECT TO authenticated USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites site
  WHERE ((site.id = sale_order_item_units.site_id) AND (site.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM public.site_ownership ownership
  WHERE ((ownership.site_id = sale_order_item_units.site_id) AND (ownership.user_id = auth.uid())))) OR (public.user_can(site_id, 'select'::text) AND (EXISTS ( SELECT 1
   FROM public.site_members member
  WHERE ((member.site_id = sale_order_item_units.site_id) AND (member.user_id = auth.uid()) AND (member.status = 'active'::text) AND ((NOT COALESCE(member.restrict_to_assigned_only, false)) OR (sale_order_item_units.assigned_to = auth.uid()))))))));


--
-- Name: sale_order_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sale_order_items ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_order_items sale_order_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sale_order_items_unified ON public.sale_order_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = sale_order_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: sale_orders; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sale_orders ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_orders sale_orders_buyer_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sale_orders_buyer_read ON public.sale_orders FOR SELECT USING (((buyer_user_id = auth.uid()) OR ((owner_site_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = sale_orders.owner_site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))));


--
-- Name: sale_orders sale_orders_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sale_orders_unified ON public.sale_orders USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = sale_orders.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (sale_orders.user_id = auth.uid())))))))))));


--
-- Name: sales; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

--
-- Name: sales sales_buyer_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sales_buyer_read ON public.sales FOR SELECT USING (((buyer_user_id = auth.uid()) OR ((owner_site_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = sales.owner_site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))));


--
-- Name: sales sales_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sales_unified ON public.sales USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = sales.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (sales.user_id = auth.uid())))))))))));


--
-- Name: sandbox_billing_resources; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sandbox_billing_resources ENABLE ROW LEVEL SECURITY;

--
-- Name: sandbox_billing_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sandbox_billing_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sandbox_billing_resources sandbox_resources_service; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sandbox_resources_service ON public.sandbox_billing_resources FOR SELECT TO service_role USING (true);


--
-- Name: sandbox_billing_sessions sandbox_sessions_service; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sandbox_sessions_service ON public.sandbox_billing_sessions FOR SELECT TO service_role USING (true);


--
-- Name: sections; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;

--
-- Name: sections sections_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sections_delete_owner_admin ON public.sections FOR DELETE USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: sections sections_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sections_insert_owner_admin ON public.sections FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: sections sections_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sections_select_owner_admin ON public.sections FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: sections sections_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sections_update_owner_admin ON public.sections FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: secure_tokens; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.secure_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: segments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.segments ENABLE ROW LEVEL SECURITY;

--
-- Name: segments segments_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY segments_unified ON public.segments USING (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = segments.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (segments.user_id = auth.uid())))))))))));


--
-- Name: self_service_inventory_releases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.self_service_inventory_releases ENABLE ROW LEVEL SECURITY;

--
-- Name: activity service_role_activity_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_activity_access ON public.activity TO service_role USING (true);


--
-- Name: instance_nodes service_role_full_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_full_access ON public.instance_nodes USING (((( SELECT (auth.jwt() ->> 'role'::text)) = 'service_role'::text) OR (CURRENT_USER = 'service_role'::name)));


--
-- Name: sites service_role_full_access_sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY service_role_full_access_sites ON public.sites TO service_role USING (true) WITH CHECK (true);


--
-- Name: session_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.session_events ENABLE ROW LEVEL SECURITY;

--
-- Name: session_recording_chunks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.session_recording_chunks ENABLE ROW LEVEL SECURITY;

--
-- Name: session_recording_chunks session_recording_chunks_service_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY session_recording_chunks_service_role ON public.session_recording_chunks TO service_role USING (true) WITH CHECK (true);


--
-- Name: settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

--
-- Name: settings settings_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY settings_optimized_policy ON public.settings USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = settings.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: setup_email_delivery_receipts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.setup_email_delivery_receipts ENABLE ROW LEVEL SECURITY;

--
-- Name: shipment_location_pings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.shipment_location_pings ENABLE ROW LEVEL SECURITY;

--
-- Name: shipment_location_pings shipment_location_pings_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY shipment_location_pings_unified ON public.shipment_location_pings USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = shipment_location_pings.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: shipments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;

--
-- Name: shipments shipments_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY shipments_unified ON public.shipments USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = shipments.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (shipments.user_id = auth.uid()) OR (shipments.assigned_to = auth.uid())))))))))));
