SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: calendar_blocks Users can delete their site's calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their site's calendar blocks" ON public.calendar_blocks FOR DELETE USING ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid()))));


--
-- Name: content_performance Users can insert content_performance for their accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert content_performance for their accessible sites" ON public.content_performance FOR INSERT WITH CHECK (public.user_can(site_id, 'insert'::text));


--
-- Name: requirement_status Users can insert requirement status for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert requirement status for their sites" ON public.requirement_status FOR INSERT WITH CHECK ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));


--
-- Name: site_secrets Users can insert secrets to accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert secrets to accessible sites" ON public.site_secrets FOR INSERT TO authenticated WITH CHECK ((site_id IN ( SELECT get_my_accessible_sites.id
   FROM public.get_my_accessible_sites() get_my_accessible_sites(id, name, url, description, logo_url, resource_urls, user_id, created_at, updated_at, tracking, command_id))));


--
-- Name: remote_sessions Users can insert their own remote sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own remote sessions" ON public.remote_sessions FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_site_notifications Users can insert their own site notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own site notifications" ON public.user_site_notifications FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: secure_tokens Users can insert their own tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own tokens" ON public.secure_tokens FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: user_shortcuts Users can insert their site shortcuts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their site shortcuts" ON public.user_shortcuts FOR INSERT TO authenticated WITH CHECK (((( SELECT auth.uid() AS uid) = user_id) AND (public.current_user_site_role(site_id) IS NOT NULL)));


--
-- Name: calendar_blocks Users can insert their site's calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their site's calendar blocks" ON public.calendar_blocks FOR INSERT WITH CHECK ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid()))));


--
-- Name: campaign_segments Users can manage campaign segments for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage campaign segments for their sites" ON public.campaign_segments USING ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_segments.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_segments.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: campaign_subtasks Users can manage campaign subtasks for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage campaign subtasks for their sites" ON public.campaign_subtasks USING ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_subtasks.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_subtasks.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: sale_orders Users can manage sale orders for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage sale orders for their sites" ON public.sale_orders USING ((EXISTS ( SELECT 1
   FROM (public.sales s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = sale_orders.sale_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.sales s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = sale_orders.sale_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: task_categories Users can manage task categories for their tasks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage task categories for their tasks" ON public.task_categories USING ((EXISTS ( SELECT 1
   FROM (public.tasks t
     JOIN public.site_members sm ON ((sm.site_id = t.site_id)))
  WHERE ((t.id = task_categories.task_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (public.tasks t
     JOIN public.site_members sm ON ((sm.site_id = t.site_id)))
  WHERE ((t.id = task_categories.task_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: referral_code_uses Users can manage their own referral code uses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own referral code uses" ON public.referral_code_uses USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: transactions Users can manage transactions for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage transactions for their sites" ON public.transactions USING ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = transactions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = transactions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: content_performance Users can update content_performance for their accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update content_performance for their accessible sites" ON public.content_performance FOR UPDATE USING (public.user_can(site_id, 'update'::text)) WITH CHECK (public.user_can(site_id, 'update'::text));


--
-- Name: requirement_status Users can update requirement status for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update requirement status for their sites" ON public.requirement_status FOR UPDATE USING ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));


--
-- Name: site_secrets Users can update secrets of accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update secrets of accessible sites" ON public.site_secrets FOR UPDATE TO authenticated USING ((site_id IN ( SELECT get_my_accessible_sites.id
   FROM public.get_my_accessible_sites() get_my_accessible_sites(id, name, url, description, logo_url, resource_urls, user_id, created_at, updated_at, tracking, command_id))));


--
-- Name: api_keys Users can update their own API keys; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own API keys" ON public.api_keys FOR UPDATE USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: remote_sessions Users can update their own remote sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own remote sessions" ON public.remote_sessions FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_site_notifications Users can update their own site notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own site notifications" ON public.user_site_notifications FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: site_ownership Users can update their own site ownership; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own site ownership" ON public.site_ownership FOR UPDATE USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: secure_tokens Users can update their own tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own tokens" ON public.secure_tokens FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: user_shortcuts Users can update their site shortcuts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their site shortcuts" ON public.user_shortcuts FOR UPDATE TO authenticated USING (((( SELECT auth.uid() AS uid) = user_id) AND (public.current_user_site_role(site_id) IS NOT NULL))) WITH CHECK (((( SELECT auth.uid() AS uid) = user_id) AND (public.current_user_site_role(site_id) IS NOT NULL)));


--
-- Name: calendar_blocks Users can update their site's calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their site's calendar blocks" ON public.calendar_blocks FOR UPDATE USING ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid()))));


--
-- Name: billing Users can view billing for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view billing for their sites" ON public.billing FOR SELECT USING ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = auth.uid()) AND (site_members.status = 'active'::text))
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));


--
-- Name: content_performance Users can view content_performance for their accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view content_performance for their accessible sites" ON public.content_performance FOR SELECT USING (public.user_can(site_id, 'select'::text));


--
-- Name: credit_transactions Users can view credit transactions for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view credit transactions for their sites" ON public.credit_transactions FOR SELECT USING ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = auth.uid()) AND (site_members.status = 'active'::text))
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));


--
-- Name: instance_artifacts Users can view instance artifacts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view instance artifacts" ON public.instance_artifacts FOR SELECT TO authenticated USING (((auth.uid() = user_id) OR (instance_id IN ( SELECT remote_instances.id
   FROM public.remote_instances
  WHERE (remote_instances.user_id = auth.uid()))) OR (site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid()))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_artifacts.site_id) AND (site_members.user_id = auth.uid()) AND (site_members.status = 'active'::text))))));


--
-- Name: requirement_status Users can view requirement status for their sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view requirement status for their sites" ON public.requirement_status FOR SELECT USING ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));


--
-- Name: site_secrets Users can view secrets of accessible sites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view secrets of accessible sites" ON public.site_secrets FOR SELECT TO authenticated USING ((site_id IN ( SELECT get_my_accessible_sites.id
   FROM public.get_my_accessible_sites() get_my_accessible_sites(id, name, url, description, logo_url, resource_urls, user_id, created_at, updated_at, tracking, command_id))));


--
-- Name: api_keys Users can view their own API keys; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own API keys" ON public.api_keys FOR SELECT USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: partner_licenses Users can view their own partner licenses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own partner licenses" ON public.partner_licenses FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: remote_sessions Users can view their own remote sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own remote sessions" ON public.remote_sessions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_site_notifications Users can view their own site notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own site notifications" ON public.user_site_notifications FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: secure_tokens Users can view their own tokens; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own tokens" ON public.secure_tokens FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: user_shortcuts Users can view their site shortcuts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their site shortcuts" ON public.user_shortcuts FOR SELECT TO authenticated USING (((( SELECT auth.uid() AS uid) = user_id) AND (public.current_user_site_role(site_id) IS NOT NULL)));


--
-- Name: calendar_blocks Users can view their site's calendar blocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their site's calendar blocks" ON public.calendar_blocks FOR SELECT USING ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid()))));


--
-- Name: accounting_accounts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.accounting_accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: accounting_accounts accounting_accounts_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY accounting_accounts_delete ON public.accounting_accounts FOR DELETE TO authenticated USING (public.user_can(site_id, 'delete'::text));


--
-- Name: accounting_accounts accounting_accounts_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY accounting_accounts_insert ON public.accounting_accounts FOR INSERT TO authenticated WITH CHECK (public.user_can(site_id, 'insert'::text));


--
-- Name: accounting_accounts accounting_accounts_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY accounting_accounts_select ON public.accounting_accounts FOR SELECT TO authenticated USING (public.user_can(site_id, 'select'::text));


--
-- Name: accounting_accounts accounting_accounts_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY accounting_accounts_update ON public.accounting_accounts FOR UPDATE TO authenticated USING (public.user_can(site_id, 'update'::text)) WITH CHECK (public.user_can(site_id, 'update'::text));


--
-- Name: accounting_sale_refunds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.accounting_sale_refunds ENABLE ROW LEVEL SECURITY;

--
-- Name: accounting_sale_refunds accounting_sale_refunds_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY accounting_sale_refunds_select ON public.accounting_sale_refunds FOR SELECT TO authenticated USING (public.user_can(site_id, 'select'::text));


--
-- Name: activity; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.activity ENABLE ROW LEVEL SECURITY;

--
-- Name: agent_assets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agent_assets ENABLE ROW LEVEL SECURITY;

--
-- Name: agent_assets agent_assets_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY agent_assets_unified ON public.agent_assets USING (((EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_members sm ON ((sm.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_ownership so ON ((so.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (s.user_id = ( SELECT auth.uid() AS uid))))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_members sm ON ((sm.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_ownership so ON ((so.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (s.user_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: agent_channel_activation_context; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agent_channel_activation_context ENABLE ROW LEVEL SECURITY;

--
-- Name: agent_memories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agent_memories ENABLE ROW LEVEL SECURITY;

--
-- Name: agent_memories agent_memories_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY agent_memories_optimized_policy ON public.agent_memories USING ((EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = agent_memories.agent_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: agents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
