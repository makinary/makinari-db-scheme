SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: transitions transitions_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY transitions_select_owner_admin ON public.transitions FOR SELECT USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: transitions transitions_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY transitions_update_owner_admin ON public.transitions FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: user_shortcuts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_shortcuts ENABLE ROW LEVEL SECURITY;

--
-- Name: user_site_notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_site_notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: variants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.variants ENABLE ROW LEVEL SECURITY;

--
-- Name: variants variants_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY variants_delete_owner_admin ON public.variants FOR DELETE USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: variants variants_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY variants_insert_owner_admin ON public.variants FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: variants variants_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY variants_select_owner_admin ON public.variants FOR SELECT USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: variants variants_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY variants_update_owner_admin ON public.variants FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: visitor_external_identities; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitor_external_identities ENABLE ROW LEVEL SECURITY;

--
-- Name: visitor_identity_attributes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitor_identity_attributes ENABLE ROW LEVEL SECURITY;

--
-- Name: visitor_identity_challenges; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitor_identity_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: visitor_identity_session_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitor_identity_session_state ENABLE ROW LEVEL SECURITY;

--
-- Name: visitor_identity_token_redemptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitor_identity_token_redemptions ENABLE ROW LEVEL SECURITY;

--
-- Name: visitor_session_identity_grants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitor_session_identity_grants ENABLE ROW LEVEL SECURITY;

--
-- Name: visitor_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitor_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: visitor_sessions visitor_sessions_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY visitor_sessions_unified ON public.visitor_sessions USING (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = visitor_sessions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));


--
-- Name: visitors; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visitors ENABLE ROW LEVEL SECURITY;

--
-- Name: visitors visitors_optimized; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY visitors_optimized ON public.visitors USING ((public.is_service_role() OR ((public.auth_user_id() IS NOT NULL) AND (((segment_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = visitors.segment_id) AND (sm.user_id = public.auth_user_id()) AND (sm.status = 'active'::text))))) OR ((lead_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.leads l
     JOIN public.site_members sm ON ((sm.site_id = l.site_id)))
  WHERE ((l.id = visitors.lead_id) AND (sm.user_id = public.auth_user_id()) AND (sm.status = 'active'::text))))) OR (EXISTS ( SELECT 1
   FROM (public.visitor_sessions vs
     JOIN public.site_members sm ON ((sm.site_id = vs.site_id)))
  WHERE ((vs.visitor_id = visitors.id) AND (sm.user_id = public.auth_user_id()) AND (sm.status = 'active'::text))))))));


--
-- Name: voice_call_deliveries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.voice_call_deliveries ENABLE ROW LEVEL SECURITY;

--
-- Name: waitlist; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

--
-- Name: webhook_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.webhook_events ENABLE ROW LEVEL SECURITY;

--
-- Name: webhook_events webhook_events_service_role_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY webhook_events_service_role_policy ON public.webhook_events TO service_role USING (true) WITH CHECK (true);


--
-- Name: webhooks_deliveries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.webhooks_deliveries ENABLE ROW LEVEL SECURITY;

--
-- Name: webhooks_deliveries webhooks_deliveries_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY webhooks_deliveries_unified ON public.webhooks_deliveries USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_deliveries.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_deliveries.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_deliveries.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_deliveries.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));


--
-- Name: webhooks_endpoints; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.webhooks_endpoints ENABLE ROW LEVEL SECURITY;

--
-- Name: webhooks_endpoints webhooks_endpoints_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY webhooks_endpoints_unified ON public.webhooks_endpoints USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_endpoints.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_endpoints.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_endpoints.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_endpoints.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));


--
-- Name: webhooks_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.webhooks_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: webhooks_subscriptions webhooks_subscriptions_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY webhooks_subscriptions_unified ON public.webhooks_subscriptions USING (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_subscriptions.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_subscriptions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_subscriptions.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_subscriptions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));


--
-- Name: whatsapp_templates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.whatsapp_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: activity workflow_insert_activity; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY workflow_insert_activity ON public.activity FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: workflow_runs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workflow_runs ENABLE ROW LEVEL SECURITY;

--
-- Name: workflow_runs workflow_runs_service; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY workflow_runs_service ON public.workflow_runs USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: workflow_runs workflow_runs_site_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY workflow_runs_site_select ON public.workflow_runs FOR SELECT USING (((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid()))) OR (site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())))));


--
-- Name: workflow_triggers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workflow_triggers ENABLE ROW LEVEL SECURITY;

--
-- Name: workflow_triggers workflow_triggers_service; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY workflow_triggers_service ON public.workflow_triggers USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: workflow_triggers workflow_triggers_site_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY workflow_triggers_site_select ON public.workflow_triggers FOR SELECT USING (((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid()))) OR (site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())))));


--
-- Name: SCHEMA commerce_rls_private; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA commerce_rls_private TO authenticated;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;
GRANT USAGE ON SCHEMA public TO apps_migration_coordinator;


--
-- Name: FUNCTION deals_location_check(p_restricted boolean, p_1 uuid, p_2 uuid); Type: ACL; Schema: commerce_rls_private; Owner: -
--

REVOKE ALL ON FUNCTION commerce_rls_private.deals_location_check(p_restricted boolean, p_1 uuid, p_2 uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION commerce_rls_private.deals_location_check(p_restricted boolean, p_1 uuid, p_2 uuid) TO authenticated;


--
-- Name: FUNCTION quotations_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid); Type: ACL; Schema: commerce_rls_private; Owner: -
--

REVOKE ALL ON FUNCTION commerce_rls_private.quotations_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION commerce_rls_private.quotations_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid) TO authenticated;


--
-- Name: FUNCTION sale_order_items_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid, p_5 uuid); Type: ACL; Schema: commerce_rls_private; Owner: -
--

REVOKE ALL ON FUNCTION commerce_rls_private.sale_order_items_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid, p_5 uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION commerce_rls_private.sale_order_items_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid, p_5 uuid) TO authenticated;


--
-- Name: FUNCTION sale_orders_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid); Type: ACL; Schema: commerce_rls_private; Owner: -
--

REVOKE ALL ON FUNCTION commerce_rls_private.sale_orders_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION commerce_rls_private.sale_orders_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) TO authenticated;


--
-- Name: FUNCTION sales_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid); Type: ACL; Schema: commerce_rls_private; Owner: -
--

REVOKE ALL ON FUNCTION commerce_rls_private.sales_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION commerce_rls_private.sales_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) TO authenticated;


--
-- Name: FUNCTION shipments_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid); Type: ACL; Schema: commerce_rls_private; Owner: -
--

REVOKE ALL ON FUNCTION commerce_rls_private.shipments_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION commerce_rls_private.shipments_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) TO authenticated;


--
-- Name: FUNCTION subscriptions_location_check(p_restricted boolean, p_1 uuid, p_2 uuid); Type: ACL; Schema: commerce_rls_private; Owner: -
--

REVOKE ALL ON FUNCTION commerce_rls_private.subscriptions_location_check(p_restricted boolean, p_1 uuid, p_2 uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION commerce_rls_private.subscriptions_location_check(p_restricted boolean, p_1 uuid, p_2 uuid) TO authenticated;


--
-- Name: FUNCTION original_16695(p_table_name text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16695(p_table_name text) FROM PUBLIC;


--
-- Name: FUNCTION original_16696(email_param text, name_param text, referral_code_param text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16696(email_param text, name_param text, referral_code_param text) FROM PUBLIC;


--
-- Name: FUNCTION original_16697(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16697() FROM PUBLIC;


--
-- Name: FUNCTION original_16699(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16699() FROM PUBLIC;


--
-- Name: FUNCTION original_16702(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16702() FROM PUBLIC;


--
-- Name: FUNCTION original_16704(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16704() FROM PUBLIC;


--
-- Name: FUNCTION original_16707(p_visitor_id uuid, p_last_seen_timestamp bigint); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16707(p_visitor_id uuid, p_last_seen_timestamp bigint) FROM PUBLIC;


--
-- Name: FUNCTION original_16708(encrypted_value text, encryption_key text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16708(encrypted_value text, encryption_key text) FROM PUBLIC;


--
-- Name: FUNCTION original_16711(p_site_id uuid, p_token_type text, p_identifier text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16711(p_site_id uuid, p_token_type text, p_identifier text) FROM PUBLIC;


--
-- Name: FUNCTION original_16713(token_value text, encryption_key text); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16713(token_value text, encryption_key text) FROM PUBLIC;


--
-- Name: FUNCTION original_16716(site_uuid uuid); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16716(site_uuid uuid) FROM PUBLIC;


--
-- Name: FUNCTION original_16717(); Type: ACL; Schema: location_acl_private; Owner: -
--

REVOKE ALL ON FUNCTION location_acl_private.original_16717() FROM PUBLIC;
