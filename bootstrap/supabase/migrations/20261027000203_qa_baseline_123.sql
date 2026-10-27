SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: requirement_migration_lifecycle location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_migration_lifecycle AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_migration_reconciliation_resumes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_migration_reconciliation_resumes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_migration_reconciliations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_migration_reconciliations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_migration_retirements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_migration_retirements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_segments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_segments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_status location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_status AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirement_user_action_receipts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirement_user_action_receipts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: requirements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.requirements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: reservation_schedules location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.reservation_schedules AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: reservations location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.reservations AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: role_queries location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.role_queries AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: role_query_segments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.role_query_segments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: sale_order_item_units location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.sale_order_item_units AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: sale_order_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.sale_order_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: sale_orders location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.sale_orders AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: sales location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.sales AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: sandbox_billing_resources location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.sandbox_billing_resources AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: sandbox_billing_sessions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.sandbox_billing_sessions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: sections location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.sections AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: secure_tokens location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.secure_tokens AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: segments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.segments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: session_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.session_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: session_recording_chunks location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.session_recording_chunks AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: settings location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.settings AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: setup_email_delivery_receipts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.setup_email_delivery_receipts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: shipment_location_pings location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.shipment_location_pings AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: shipments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.shipments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_member_location_restriction_audit location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_member_location_restriction_audit AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_member_location_restrictions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_member_location_restrictions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_members location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_members AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_ownership location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_ownership AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_retired_stripe_subscriptions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_retired_stripe_subscriptions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_secrets location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_secrets AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_skills location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_skills AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_startup_trials location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_startup_trials AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: site_subscription_checkout_leases location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.site_subscription_checkout_leases AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: social_comment_sync_state location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.social_comment_sync_state AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: states location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.states AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: stripe_sale_checkout_effects location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.stripe_sale_checkout_effects AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: stripe_subscription_invoice_settlements location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.stripe_subscription_invoice_settlements AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: subscription_plan_items location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.subscription_plan_items AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: subscriptions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.subscriptions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: synced_objects location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.synced_objects AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: system_memories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.system_memories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: system_status location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.system_status AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: system_status_runs location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.system_status_runs AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: system_telemetry location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.system_telemetry AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: task_categories location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.task_categories AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: task_comments location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.task_comments AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: tasks location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.tasks AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: taxes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.taxes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: tenant_users location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.tenant_users AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: transactions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.transactions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: transitions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.transitions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: user_shortcuts location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.user_shortcuts AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: user_site_notifications location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.user_site_notifications AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: variants location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.variants AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitor_external_identities location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitor_external_identities AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitor_identity_attributes location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitor_identity_attributes AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitor_identity_challenges location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitor_identity_challenges AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitor_identity_session_state location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitor_identity_session_state AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitor_identity_token_redemptions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitor_identity_token_redemptions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitor_session_identity_grants location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitor_session_identity_grants AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitor_sessions location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitor_sessions AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: visitors location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.visitors AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: voice_call_deliveries location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.voice_call_deliveries AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: waitlist location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.waitlist AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: webhook_events location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.webhook_events AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: webhooks_deliveries location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.webhooks_deliveries AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);


--
-- Name: webhooks_endpoints location_acl_private_anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY location_acl_private_anon ON public.webhooks_endpoints AS RESTRICTIVE TO anon USING (false) WITH CHECK (false);
