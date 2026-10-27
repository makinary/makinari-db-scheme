SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: visitor_identity_token_redemptions visitor_identity_token_redemptions_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_token_redemptions
    ADD CONSTRAINT visitor_identity_token_redemptions_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_token_redemptions visitor_identity_token_redemptions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_token_redemptions
    ADD CONSTRAINT visitor_identity_token_redemptions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: visitor_identity_token_redemptions visitor_identity_token_redemptions_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_identity_token_redemptions
    ADD CONSTRAINT visitor_identity_token_redemptions_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE CASCADE;


--
-- Name: visitor_session_identity_grants visitor_session_identity_grants_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_session_identity_grants
    ADD CONSTRAINT visitor_session_identity_grants_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: visitor_session_identity_grants visitor_session_identity_grants_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_session_identity_grants
    ADD CONSTRAINT visitor_session_identity_grants_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE;


--
-- Name: visitor_session_identity_grants visitor_session_identity_grants_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_session_identity_grants
    ADD CONSTRAINT visitor_session_identity_grants_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: visitor_session_identity_grants visitor_session_identity_grants_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_session_identity_grants
    ADD CONSTRAINT visitor_session_identity_grants_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE CASCADE;


--
-- Name: visitor_sessions visitor_sessions_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_sessions
    ADD CONSTRAINT visitor_sessions_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: visitor_sessions visitor_sessions_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitor_sessions
    ADD CONSTRAINT visitor_sessions_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE CASCADE;


--
-- Name: visitors visitors_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitors
    ADD CONSTRAINT visitors_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: visitors visitors_experiment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitors
    ADD CONSTRAINT visitors_experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES public.experiments(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: visitors visitors_segment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visitors
    ADD CONSTRAINT visitors_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE;


--
-- Name: voice_call_deliveries voice_call_deliveries_audience_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_call_deliveries
    ADD CONSTRAINT voice_call_deliveries_audience_id_fkey FOREIGN KEY (audience_id) REFERENCES public.audiences(id) ON DELETE SET NULL;


--
-- Name: voice_call_deliveries voice_call_deliveries_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_call_deliveries
    ADD CONSTRAINT voice_call_deliveries_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- Name: voice_call_deliveries voice_call_deliveries_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_call_deliveries
    ADD CONSTRAINT voice_call_deliveries_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: voice_call_deliveries voice_call_deliveries_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_call_deliveries
    ADD CONSTRAINT voice_call_deliveries_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: voice_call_deliveries voice_call_deliveries_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voice_call_deliveries
    ADD CONSTRAINT voice_call_deliveries_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: webhooks_deliveries webhooks_deliveries_endpoint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_deliveries
    ADD CONSTRAINT webhooks_deliveries_endpoint_id_fkey FOREIGN KEY (endpoint_id) REFERENCES public.webhooks_endpoints(id) ON DELETE CASCADE;


--
-- Name: webhooks_deliveries webhooks_deliveries_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_deliveries
    ADD CONSTRAINT webhooks_deliveries_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: webhooks_deliveries webhooks_deliveries_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_deliveries
    ADD CONSTRAINT webhooks_deliveries_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.webhooks_subscriptions(id) ON DELETE SET NULL;


--
-- Name: webhooks_endpoints webhooks_endpoints_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_endpoints
    ADD CONSTRAINT webhooks_endpoints_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: webhooks_subscriptions webhooks_subscriptions_endpoint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_subscriptions
    ADD CONSTRAINT webhooks_subscriptions_endpoint_id_fkey FOREIGN KEY (endpoint_id) REFERENCES public.webhooks_endpoints(id) ON DELETE CASCADE;


--
-- Name: webhooks_subscriptions webhooks_subscriptions_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks_subscriptions
    ADD CONSTRAINT webhooks_subscriptions_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: workflow_runs workflow_runs_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: workflow_runs workflow_runs_run_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_run_plan_id_fkey FOREIGN KEY (run_plan_id) REFERENCES public.instance_plans(id) ON DELETE CASCADE;


--
-- Name: workflow_runs workflow_runs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: workflow_runs workflow_runs_template_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_template_plan_id_fkey FOREIGN KEY (template_plan_id) REFERENCES public.instance_plans(id) ON DELETE SET NULL;


--
-- Name: workflow_runs workflow_runs_trigger_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_trigger_id_fkey FOREIGN KEY (trigger_id) REFERENCES public.workflow_triggers(id) ON DELETE SET NULL;


--
-- Name: workflow_runs workflow_runs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_runs
    ADD CONSTRAINT workflow_runs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: workflow_triggers workflow_triggers_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_triggers
    ADD CONSTRAINT workflow_triggers_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE;


--
-- Name: workflow_triggers workflow_triggers_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_triggers
    ADD CONSTRAINT workflow_triggers_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE;


--
-- Name: workflow_triggers workflow_triggers_template_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_triggers
    ADD CONSTRAINT workflow_triggers_template_plan_id_fkey FOREIGN KEY (template_plan_id) REFERENCES public.instance_plans(id) ON DELETE SET NULL;


--
-- Name: workflow_triggers workflow_triggers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_triggers
    ADD CONSTRAINT workflow_triggers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: policy_originals; Type: ROW SECURITY; Schema: commerce_rls_private; Owner: -
--

ALTER TABLE commerce_rls_private.policy_originals ENABLE ROW LEVEL SECURITY;

--
-- Name: links; Type: ROW SECURITY; Schema: location_acl_private; Owner: -
--

ALTER TABLE location_acl_private.links ENABLE ROW LEVEL SECURITY;

--
-- Name: roots; Type: ROW SECURITY; Schema: location_acl_private; Owner: -
--

ALTER TABLE location_acl_private.roots ENABLE ROW LEVEL SECURITY;

--
-- Name: scope_assignments; Type: ROW SECURITY; Schema: location_acl_private; Owner: -
--

ALTER TABLE location_acl_private.scope_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: provider_webhook_events; Type: ROW SECURITY; Schema: private; Owner: -
--

ALTER TABLE private.provider_webhook_events ENABLE ROW LEVEL SECURITY;

--
-- Name: provider_webhook_events provider_webhook_events_service_role; Type: POLICY; Schema: private; Owner: -
--

CREATE POLICY provider_webhook_events_service_role ON private.provider_webhook_events TO service_role USING (true) WITH CHECK (true);


--
-- Name: site_ownership Authenticated users can insert site ownership; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert site ownership" ON public.site_ownership FOR INSERT WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: companies Authenticated users can manage companies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can manage companies" ON public.companies USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));


--
-- Name: site_ownership Authenticated users can view site ownership; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view site ownership" ON public.site_ownership FOR SELECT TO authenticated USING (true);


--
-- Name: session_events Enable insert for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users" ON public.session_events FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: session_events Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public.session_events FOR SELECT TO authenticated USING (true);


--
-- Name: cron_status Only superadmin can delete cron status; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only superadmin can delete cron status" ON public.cron_status FOR DELETE USING (public.is_superadmin());


--
-- Name: cron_status Only superadmin can insert cron status; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only superadmin can insert cron status" ON public.cron_status FOR INSERT WITH CHECK (public.is_superadmin());


--
-- Name: cron_status Only superadmin can update cron status; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only superadmin can update cron status" ON public.cron_status FOR UPDATE USING (public.is_superadmin()) WITH CHECK (public.is_superadmin());


--
-- Name: cron_status Only superadmin can view cron status; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only superadmin can view cron status" ON public.cron_status FOR SELECT USING (public.is_superadmin());


--
-- Name: waitlist Permitir insertar en lista de espera; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Permitir insertar en lista de espera" ON public.waitlist FOR INSERT WITH CHECK (true);


--
-- Name: referral_codes Permitir lectura de códigos de referido activos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Permitir lectura de códigos de referido activos" ON public.referral_codes FOR SELECT USING ((is_active = true));


--
-- Name: partner_licenses Service role can manage all partner licenses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can manage all partner licenses" ON public.partner_licenses TO service_role USING (true) WITH CHECK (true);


--
-- Name: payout_requests Site managers can view payout requests; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Site managers can view payout requests" ON public.payout_requests FOR SELECT TO authenticated USING ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])));


--
-- Name: calendar_blocks Super admin delete calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Super admin delete calendar blocks" ON public.calendar_blocks FOR DELETE TO service_role USING (true);


--
-- Name: calendar_blocks Super admin insert calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Super admin insert calendar blocks" ON public.calendar_blocks FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: calendar_blocks Super admin read calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Super admin read calendar blocks" ON public.calendar_blocks FOR SELECT TO service_role USING (true);


--
-- Name: calendar_blocks Super admin update calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Super admin update calendar blocks" ON public.calendar_blocks FOR UPDATE TO service_role USING (true);


--
-- Name: api_keys Users can create their own API keys; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create their own API keys" ON public.api_keys FOR INSERT WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: content_performance Users can delete content_performance for their accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete content_performance for their accessible sites" ON public.content_performance FOR DELETE USING (public.user_can(site_id, 'delete'::text));


--
-- Name: instance_artifacts Users can delete instance artifacts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete instance artifacts" ON public.instance_artifacts FOR DELETE TO authenticated USING (((auth.uid() = user_id) OR ((site_id IS NOT NULL) AND public.user_can(site_id, 'delete'::text)) OR ((instance_id IS NOT NULL) AND (instance_id IN ( SELECT remote_instances.id
   FROM public.remote_instances
  WHERE (remote_instances.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_artifacts.site_id) AND (site_members.user_id = auth.uid()) AND (site_members.status = 'active'::text))))));


--
-- Name: requirement_status Users can delete requirement status for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete requirement status for their sites" ON public.requirement_status FOR DELETE USING ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));


--
-- Name: site_secrets Users can delete secrets of accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete secrets of accessible sites" ON public.site_secrets FOR DELETE TO authenticated USING ((site_id IN ( SELECT get_my_accessible_sites.id
   FROM public.get_my_accessible_sites() get_my_accessible_sites(id, name, url, description, logo_url, resource_urls, user_id, created_at, updated_at, tracking, command_id))));


--
-- Name: api_keys Users can delete their own API keys; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own API keys" ON public.api_keys FOR DELETE USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: site_ownership Users can delete their own site ownership; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own site ownership" ON public.site_ownership FOR DELETE USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: secure_tokens Users can delete their own tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own tokens" ON public.secure_tokens FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));
