SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: sandbox_billing_sessions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.sandbox_billing_sessions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: sections location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.sections AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: secure_tokens location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.secure_tokens AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: segments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.segments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: session_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.session_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: session_recording_chunks location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.session_recording_chunks AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: settings location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.settings AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: setup_email_delivery_receipts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.setup_email_delivery_receipts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: shipment_location_pings location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.shipment_location_pings AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.shipments acl_parent
  WHERE ((acl_parent.id = shipment_location_pings.shipment_id) AND (acl_parent.site_id = shipment_location_pings.site_id)))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.shipments acl_parent
  WHERE ((acl_parent.id = shipment_location_pings.shipment_id) AND (acl_parent.site_id = shipment_location_pings.site_id))))))));


--
-- Name: shipments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.shipments AS RESTRICTIVE TO authenticated USING (commerce_rls_private.shipments_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, sale_order_id, sale_id, origin_location_id)) WITH CHECK (commerce_rls_private.shipments_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, sale_order_id, sale_id, origin_location_id));


--
-- Name: site_retired_stripe_subscriptions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.site_retired_stripe_subscriptions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: site_secrets location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.site_secrets AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: site_skills location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.site_skills AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: site_startup_trials location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.site_startup_trials AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: site_subscription_checkout_leases location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.site_subscription_checkout_leases AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: social_comment_sync_state location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.social_comment_sync_state AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: states location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.states AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: stripe_sale_checkout_effects location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.stripe_sale_checkout_effects AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: stripe_subscription_invoice_settlements location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.stripe_subscription_invoice_settlements AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: subscription_plan_items location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.subscription_plan_items AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: subscriptions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.subscriptions AS RESTRICTIVE TO authenticated USING (commerce_rls_private.subscriptions_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, location_id)) WITH CHECK (commerce_rls_private.subscriptions_location_check(( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions), site_id, location_id));


--
-- Name: synced_objects location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.synced_objects AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: system_memories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.system_memories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: system_status location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.system_status AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: system_status_runs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.system_status_runs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: system_telemetry location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.system_telemetry AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: task_categories location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.task_categories AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.tasks acl_parent
  WHERE (acl_parent.id = task_categories.task_id)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.tasks acl_parent
  WHERE (acl_parent.id = task_categories.task_id))))));


--
-- Name: task_comments location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.task_comments AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.tasks acl_parent
  WHERE (acl_parent.id = task_comments.task_id)))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR (true AND (EXISTS ( SELECT 1
   FROM public.tasks acl_parent
  WHERE (acl_parent.id = task_comments.task_id))))));


--
-- Name: tasks location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.tasks AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((conversation_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.conversations acl_parent
  WHERE ((acl_parent.id = tasks.conversation_id) AND (acl_parent.site_id = tasks.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM tasks.location_id)))))) AND ((deal_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.deals acl_parent
  WHERE ((acl_parent.id = tasks.deal_id) AND (acl_parent.site_id = tasks.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM tasks.location_id)))))) AND ((lead_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.leads acl_parent
  WHERE ((acl_parent.id = tasks.lead_id) AND (acl_parent.site_id = tasks.site_id))))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((conversation_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.conversations acl_parent
  WHERE ((acl_parent.id = tasks.conversation_id) AND (acl_parent.site_id = tasks.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM tasks.location_id)))))) AND ((deal_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.deals acl_parent
  WHERE ((acl_parent.id = tasks.deal_id) AND (acl_parent.site_id = tasks.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM tasks.location_id)))))) AND ((lead_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.leads acl_parent
  WHERE ((acl_parent.id = tasks.lead_id) AND (acl_parent.site_id = tasks.site_id)))))))));


--
-- Name: taxes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.taxes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: tenant_users location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.tenant_users AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: transactions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.transactions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((sale_order_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.sale_orders acl_parent
  WHERE ((acl_parent.id = transactions.sale_order_id) AND (acl_parent.site_id = transactions.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM transactions.location_id)))))))))) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((sale_order_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.sale_orders acl_parent
  WHERE ((acl_parent.id = transactions.sale_order_id) AND (acl_parent.site_id = transactions.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM transactions.location_id))))))))));


--
-- Name: transitions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.transitions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: user_shortcuts location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.user_shortcuts AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: user_site_notifications location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.user_site_notifications AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: variants location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.variants AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitor_external_identities location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitor_external_identities AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitor_identity_attributes location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitor_identity_attributes AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitor_identity_challenges location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitor_identity_challenges AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitor_identity_session_state location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitor_identity_session_state AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitor_identity_token_redemptions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitor_identity_token_redemptions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitor_session_identity_grants location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitor_session_identity_grants AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitor_sessions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitor_sessions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: visitors location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.visitors AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: voice_call_deliveries location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.voice_call_deliveries AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: waitlist location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.waitlist AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: webhook_events location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.webhook_events AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: webhooks_deliveries location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.webhooks_deliveries AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: webhooks_endpoints location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.webhooks_endpoints AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: webhooks_subscriptions location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.webhooks_subscriptions AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: whatsapp_templates location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.whatsapp_templates AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: workflow_runs location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.workflow_runs AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: workflow_triggers location_acl_enforcement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_enforcement ON public.workflow_triggers AS RESTRICTIVE TO authenticated USING (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false)) WITH CHECK (((NOT ( SELECT public.current_user_has_location_restrictions() AS current_user_has_location_restrictions)) OR false));


--
-- Name: site_ownership location_acl_ownership_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_ownership_insert ON public.site_ownership AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (public.location_acl_can_manage_ownership(site_id));


--
-- Name: site_ownership location_acl_ownership_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_ownership_update ON public.site_ownership AS RESTRICTIVE FOR UPDATE TO authenticated USING (public.location_acl_can_manage_ownership(site_id)) WITH CHECK (public.location_acl_can_manage_ownership(site_id));


--
-- Name: accounting_accounts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.accounting_accounts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: accounting_sale_refunds location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.accounting_sale_refunds AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: activity location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.activity AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: agent_assets location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.agent_assets AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: agent_memories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.agent_memories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: agents location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.agents AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: allowed_domains location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.allowed_domains AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: analysis location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.analysis AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: api_keys location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.api_keys AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: appointments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.appointments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: apps_tenants location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.apps_tenants AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);
