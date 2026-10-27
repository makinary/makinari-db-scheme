SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: webhooks_subscriptions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.webhooks_subscriptions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: whatsapp_templates location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.whatsapp_templates AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: workflow_runs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.workflow_runs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: workflow_triggers location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.workflow_triggers AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_member_location_restriction_audit location_restriction_audit_manager_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_restriction_audit_manager_read ON public.site_member_location_restriction_audit FOR SELECT TO authenticated USING (((auth.uid() IS NOT NULL) AND (public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text]))));


--
-- Name: site_member_location_restrictions location_restrictions_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_restrictions_read ON public.site_member_location_restrictions FOR SELECT TO authenticated USING (((auth.uid() IS NOT NULL) AND ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['collaborator'::text, 'marketing'::text])) AND (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.id = site_member_location_restrictions.site_member_id) AND (sm.site_id = site_member_location_restrictions.site_id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text))))))));


--
-- Name: locations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

--
-- Name: locations locations_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY locations_unified ON public.locations USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = locations.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: marketplace_actions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_actions ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_integrations marketplace_config_member_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY marketplace_config_member_read ON public.marketplace_integrations FOR SELECT TO authenticated USING ((public.current_user_site_role(site_id) IS NOT NULL));


--
-- Name: marketplace_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_events ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_integrations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_integrations ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_merchant_connections; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_merchant_connections ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_oauth_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_oauth_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_platform_apps; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_platform_apps ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_provider_webhook_keys; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_provider_webhook_keys ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_rebind_permits; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_rebind_permits ENABLE ROW LEVEL SECURITY;

--
-- Name: site_secrets marketplace_secret_reserved; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY marketplace_secret_reserved ON public.site_secrets AS RESTRICTIVE TO anon, authenticated USING (((COALESCE(use_case, ''::text) !~~ 'marketplace:%'::text) AND (COALESCE(provider, ''::text) <> ALL (ARRAY['uber_eats'::text, 'rappi'::text])))) WITH CHECK (((COALESCE(use_case, ''::text) !~~ 'marketplace:%'::text) AND (COALESCE(provider, ''::text) <> ALL (ARRAY['uber_eats'::text, 'rappi'::text]))));


--
-- Name: marketplace_webhook_registration_apps; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_webhook_registration_apps ENABLE ROW LEVEL SECURITY;

--
-- Name: marketplace_webhook_registrations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.marketplace_webhook_registrations ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: messages messages_unified_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_unified_access_policy ON public.messages USING (((auth.uid() IS NULL) OR ((auth.uid() IS NOT NULL) AND ((user_id = auth.uid()) OR (visitor_id = auth.uid()) OR (agent_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM (public.conversations c
     JOIN public.sites s ON ((s.id = c.site_id)))
  WHERE ((c.id = messages.conversation_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (c.user_id = auth.uid()) OR (c.agent_id = auth.uid()) OR (c.delegate_id = auth.uid()) OR (EXISTS ( SELECT 1
                   FROM public.leads l
                  WHERE ((l.id = c.lead_id) AND ((l.user_id = auth.uid()) OR (l.assignee_id = auth.uid())))))))))))))))));


--
-- Name: requirement_migration_execution_handoffs migration_execution_handoffs_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY migration_execution_handoffs_service_read ON public.requirement_migration_execution_handoffs FOR SELECT TO service_role USING (true);


--
-- Name: requirement_migration_reconciliation_resumes migration_reconciliation_resumes_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY migration_reconciliation_resumes_service_read ON public.requirement_migration_reconciliation_resumes FOR SELECT TO service_role USING (true);


--
-- Name: requirement_migration_reconciliations migration_reconciliations_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY migration_reconciliations_service_read ON public.requirement_migration_reconciliations FOR SELECT TO service_role USING (true);


--
-- Name: requirement_migration_retirements migration_retirements_service_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY migration_retirements_service_read ON public.requirement_migration_retirements FOR SELECT TO service_role USING (true);


--
-- Name: modifier_group_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.modifier_group_items ENABLE ROW LEVEL SECURITY;

--
-- Name: modifier_group_items modifier_group_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY modifier_group_items_unified ON public.modifier_group_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = modifier_group_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: modifier_groups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.modifier_groups ENABLE ROW LEVEL SECURITY;

--
-- Name: modifier_groups modifier_groups_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY modifier_groups_unified ON public.modifier_groups USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = modifier_groups.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications notifications_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notifications_optimized_policy ON public.notifications USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: openrouter_generation_charges; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.openrouter_generation_charges ENABLE ROW LEVEL SECURITY;

--
-- Name: outstand_initial_imports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.outstand_initial_imports ENABLE ROW LEVEL SECURITY;

--
-- Name: persons p_deny_anon_auth_all_persons; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY p_deny_anon_auth_all_persons ON public.persons TO anon, authenticated USING (false) WITH CHECK (false);


--
-- Name: role_queries p_deny_anon_auth_all_role_queries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY p_deny_anon_auth_all_role_queries ON public.role_queries TO anon, authenticated USING (false) WITH CHECK (false);


--
-- Name: role_query_segments p_deny_anon_auth_all_rqs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY p_deny_anon_auth_all_rqs ON public.role_query_segments TO anon, authenticated USING (false) WITH CHECK (false);


--
-- Name: partner_licenses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.partner_licenses ENABLE ROW LEVEL SECURITY;

--
-- Name: pass_redeemable_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pass_redeemable_items ENABLE ROW LEVEL SECURITY;

--
-- Name: pass_redeemable_items pass_redeemable_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pass_redeemable_items_unified ON public.pass_redeemable_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = pass_redeemable_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: pass_round_robin_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pass_round_robin_state ENABLE ROW LEVEL SECURITY;

--
-- Name: pass_round_robin_state pass_round_robin_state_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pass_round_robin_state_unified ON public.pass_round_robin_state USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = pass_round_robin_state.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: payments payments_insert_optimized; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY payments_insert_optimized ON public.payments FOR INSERT WITH CHECK (true);


--
-- Name: payments payments_select_optimized; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY payments_select_optimized ON public.payments FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = payments.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: payout_requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: persons; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;

--
-- Name: platform_audit_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platform_audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: platform_audit_log platform_audit_log service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "platform_audit_log service only" ON public.platform_audit_log USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: platform_quotas; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platform_quotas ENABLE ROW LEVEL SECURITY;

--
-- Name: platform_quotas platform_quotas service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "platform_quotas service only" ON public.platform_quotas USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: platform_tracking_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platform_tracking_events ENABLE ROW LEVEL SECURITY;

--
-- Name: platform_tracking_events platform_tracking_events service only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "platform_tracking_events service only" ON public.platform_tracking_events USING ((auth.role() = 'service_role'::text)) WITH CHECK ((auth.role() = 'service_role'::text));


--
-- Name: platform_user_roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platform_user_roles ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_checkout_attempts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_checkout_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_client_mutations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_client_mutations ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_client_mutations pos_client_mutations_member_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pos_client_mutations_member_all ON public.pos_client_mutations USING ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = pos_client_mutations.site_id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = pos_client_mutations.site_id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text)))));


--
-- Name: pos_register_movements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_register_movements ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_register_movements pos_register_movements_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pos_register_movements_read ON public.pos_register_movements FOR SELECT TO authenticated USING ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text, 'collaborator'::text])));


--
-- Name: pos_register_receipts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_register_receipts ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_register_receipts pos_register_receipts_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pos_register_receipts_read ON public.pos_register_receipts FOR SELECT TO authenticated USING ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text, 'collaborator'::text])));


--
-- Name: pos_register_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pos_register_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: pos_register_sessions pos_register_sessions_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pos_register_sessions_read ON public.pos_register_sessions FOR SELECT TO authenticated USING ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text, 'collaborator'::text])));


--
-- Name: price_list_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.price_list_items ENABLE ROW LEVEL SECURITY;

--
-- Name: price_list_items price_list_items_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY price_list_items_unified ON public.price_list_items USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = price_list_items.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: price_lists; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.price_lists ENABLE ROW LEVEL SECURITY;

--
-- Name: price_lists price_lists_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY price_lists_unified ON public.price_lists USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = price_lists.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
