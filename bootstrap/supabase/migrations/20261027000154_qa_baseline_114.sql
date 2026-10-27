SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;


--
-- Name: elements elements_delete_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY elements_delete_owner_admin ON public.elements FOR DELETE USING (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: elements elements_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY elements_insert_owner_admin ON public.elements FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: elements elements_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY elements_select_owner_admin ON public.elements FOR SELECT USING (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: elements elements_update_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY elements_update_owner_admin ON public.elements FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));


--
-- Name: entitlements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.entitlements ENABLE ROW LEVEL SECURITY;

--
-- Name: entitlements entitlements_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY entitlements_unified ON public.entitlements USING (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (buyer_user_id = auth.uid()) OR ((owner_site_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = entitlements.owner_site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = entitlements.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


--
-- Name: experiment_segments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.experiment_segments ENABLE ROW LEVEL SECURITY;

--
-- Name: experiment_segments experiment_segments_emergency; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY experiment_segments_emergency ON public.experiment_segments USING (((( SELECT auth.uid() AS uid) IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.experiments
  WHERE (experiments.id = experiment_segments.experiment_id))))) WITH CHECK (((( SELECT auth.uid() AS uid) IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.experiments
  WHERE (experiments.id = experiment_segments.experiment_id)))));


--
-- Name: experiments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.experiments ENABLE ROW LEVEL SECURITY;

--
-- Name: experiments experiments_unified; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY experiments_unified ON public.experiments USING (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = experiments.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_ownership so
          WHERE ((so.site_id = s.id) AND (so.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND ((sm.restrict_to_assigned_only = false) OR (experiments.user_id = auth.uid())))))))))));


--
-- Name: external_resources; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.external_resources ENABLE ROW LEVEL SECURITY;

--
-- Name: external_resources external_resources_optimized_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY external_resources_optimized_policy ON public.external_resources USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = external_resources.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));


--
-- Name: harness_artifact_reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harness_artifact_reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: harness_artifacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harness_artifacts ENABLE ROW LEVEL SECURITY;

--
-- Name: harness_host_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harness_host_state ENABLE ROW LEVEL SECURITY;

--
-- Name: harness_model_credit_reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harness_model_credit_reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: harness_requirement_credit_reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harness_requirement_credit_reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: harness_requirement_runs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harness_requirement_runs ENABLE ROW LEVEL SECURITY;

--
-- Name: harness_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harness_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: icp_dispatch_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.icp_dispatch_config ENABLE ROW LEVEL SECURITY;

--
-- Name: icp_dispatch_config icp_dispatch_config_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY icp_dispatch_config_read ON public.icp_dispatch_config FOR SELECT TO service_role USING (true);


--
-- Name: icp_dispatch_config icp_dispatch_config_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY icp_dispatch_config_update ON public.icp_dispatch_config FOR UPDATE TO service_role USING (id) WITH CHECK (id);


--
-- Name: icp_dispatch_list_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.icp_dispatch_list_state ENABLE ROW LEVEL SECURITY;

--
-- Name: icp_dispatch_list_state icp_dispatch_list_state_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY icp_dispatch_list_state_read ON public.icp_dispatch_list_state FOR SELECT TO service_role USING (true);


--
-- Name: icp_dispatch_runs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.icp_dispatch_runs ENABLE ROW LEVEL SECURITY;

--
-- Name: icp_dispatch_runs icp_dispatch_runs_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY icp_dispatch_runs_read ON public.icp_dispatch_runs FOR SELECT TO service_role USING (true);


--
-- Name: icp_dispatch_site_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.icp_dispatch_site_state ENABLE ROW LEVEL SECURITY;

--
-- Name: icp_dispatch_site_state icp_dispatch_site_state_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY icp_dispatch_site_state_read ON public.icp_dispatch_site_state FOR SELECT TO service_role USING (true);


--
-- Name: icp_mining; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.icp_mining ENABLE ROW LEVEL SECURITY;

--
-- Name: icp_mining icp_mining - anon can read completed; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "icp_mining - anon can read completed" ON public.icp_mining FOR SELECT TO anon USING ((status = 'completed'::text));


--
-- Name: icp_mining icp_mining - authenticated can delete in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "icp_mining - authenticated can delete in site" ON public.icp_mining FOR DELETE TO authenticated USING (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id)))));


--
-- Name: icp_mining icp_mining - authenticated can insert in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "icp_mining - authenticated can insert in site" ON public.icp_mining FOR INSERT TO authenticated WITH CHECK (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = rqs.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = rqs.role_query_id)))));


--
-- Name: icp_mining icp_mining - authenticated can select in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "icp_mining - authenticated can select in site" ON public.icp_mining FOR SELECT TO authenticated USING (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id)))));


--
-- Name: icp_mining icp_mining - authenticated can update in site; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "icp_mining - authenticated can update in site" ON public.icp_mining FOR UPDATE TO authenticated USING (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = rqs.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = rqs.role_query_id)))));


--
-- Name: icp_mining icp_mining - service_role can do anything; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "icp_mining - service_role can do anything" ON public.icp_mining TO service_role USING (true) WITH CHECK (true);


--
-- Name: icypeas_email_searches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.icypeas_email_searches ENABLE ROW LEVEL SECURITY;

--
-- Name: image_generation_credit_reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.image_generation_credit_reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_artifacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_artifacts ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_context_memories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_context_memories ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_context_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_context_state ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_context_state instance_context_state_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY instance_context_state_read ON public.instance_context_state FOR SELECT TO authenticated USING ((public.current_user_site_role(site_id) IS NOT NULL));


--
-- Name: instance_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_logs instance_logs_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY instance_logs_access_policy ON public.instance_logs USING (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_logs.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_logs.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_logs.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_logs.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))));


--
-- Name: instance_node_contexts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_node_contexts ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_node_contexts instance_node_contexts_site_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY instance_node_contexts_site_access ON public.instance_node_contexts TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = instance_node_contexts.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = instance_node_contexts.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))));


--
-- Name: instance_nodes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_nodes ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_nodes instance_nodes_site_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY instance_nodes_site_access_policy ON public.instance_nodes TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = instance_nodes.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = instance_nodes.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))));


--
-- Name: instance_pending_work; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_pending_work ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_pending_work instance_pending_work_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY instance_pending_work_access_policy ON public.instance_pending_work USING (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_pending_work.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_pending_work.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_pending_work.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_pending_work.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))));


--
-- Name: instance_plan_step_infrastructure_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_plan_step_infrastructure_events ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_plan_step_infrastructure_events instance_plan_step_infrastructure_events_service_role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY instance_plan_step_infrastructure_events_service_role ON public.instance_plan_step_infrastructure_events TO service_role USING (true) WITH CHECK (true);


--
-- Name: instance_plans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.instance_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: instance_plans instance_plans_access_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY instance_plans_access_policy ON public.instance_plans USING (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_plans.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_plans.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_plans.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: insufficient_credit_email_recipient_gates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.insufficient_credit_email_recipient_gates ENABLE ROW LEVEL SECURITY;
