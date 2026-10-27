SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: requirement_harness_support_snapshot_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirement_harness_support_snapshot_idx ON public.requirement_harness_decisions USING btree (requirement_id, item_id) WHERE (decision = 'escalate_support'::text);


--
-- Name: requirement_status_instance_created_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirement_status_instance_created_id_idx ON public.requirement_status USING btree (instance_id, created_at, id);


--
-- Name: requirement_status_site_requirement_recent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirement_status_site_requirement_recent_idx ON public.requirement_status USING btree (site_id, requirement_id, created_at DESC, id DESC);


--
-- Name: requirements_active_cron_lease_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirements_active_cron_lease_idx ON public.requirements USING btree (cron_lock_expires_at) WHERE (cron_lock_active = true);


--
-- Name: requirements_cron_lock_expires_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirements_cron_lock_expires_at_idx ON public.requirements USING btree (cron_lock_expires_at) WHERE (cron_lock_expires_at IS NOT NULL);


--
-- Name: requirements_domain_provenance_id_site_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX requirements_domain_provenance_id_site_idx ON public.requirements USING btree (id, site_id);


--
-- Name: reservations_active_start_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservations_active_start_time_idx ON public.reservations USING btree (start_time) WHERE (status = ANY (ARRAY['confirmed'::text, 'active'::text, 'scheduled'::text, 'pending'::text]));


--
-- Name: reservations_site_time_window_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservations_site_time_window_idx ON public.reservations USING btree (site_id, start_time, id) INCLUDE (end_time);


--
-- Name: sale_order_item_units_site_assignee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_order_item_units_site_assignee_idx ON public.sale_order_item_units USING btree (site_id, assigned_to) WHERE (assigned_to IS NOT NULL);


--
-- Name: sale_order_item_units_site_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_order_item_units_site_created_idx ON public.sale_order_item_units USING btree (site_id, created_at DESC, sale_order_item_id, unit_index);


--
-- Name: sale_order_item_units_site_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_order_item_units_site_status_idx ON public.sale_order_item_units USING btree (site_id, status);


--
-- Name: sale_order_items_marketplace_external_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sale_order_items_marketplace_external_key ON public.sale_order_items USING btree (sale_order_id, ((metadata #>> '{marketplace,external_id}'::text[]))) WHERE ((metadata #>> '{marketplace,external_id}'::text[]) IS NOT NULL);


--
-- Name: sale_order_items_site_assignee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_order_items_site_assignee_idx ON public.sale_order_items USING btree (site_id, assigned_to) WHERE (assigned_to IS NOT NULL);


--
-- Name: sale_order_items_site_name_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_order_items_site_name_trgm_idx ON public.sale_order_items USING gin (name extensions.gin_trgm_ops);


--
-- Name: sale_orders_marketplace_external_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sale_orders_marketplace_external_key ON public.sale_orders USING btree (marketplace_integration_id, external_order_id) WHERE (marketplace_integration_id IS NOT NULL);


--
-- Name: sale_orders_public_access_token_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sale_orders_public_access_token_uidx ON public.sale_orders USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: sale_orders_public_access_token_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sale_orders_public_access_token_unique ON public.sale_orders USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: sale_orders_quotation_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sale_orders_quotation_id_unique ON public.sale_orders USING btree (quotation_id) WHERE (quotation_id IS NOT NULL);


--
-- Name: sale_orders_site_created_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_orders_site_created_by_idx ON public.sale_orders USING btree (site_id, created_by_user_id) WHERE (created_by_user_id IS NOT NULL);


--
-- Name: sale_orders_site_created_recent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_orders_site_created_recent_idx ON public.sale_orders USING btree (site_id, created_at DESC, id DESC);


--
-- Name: sale_orders_site_order_number_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_orders_site_order_number_trgm_idx ON public.sale_orders USING gin (order_number extensions.gin_trgm_ops);


--
-- Name: sale_orders_site_requested_by_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_orders_site_requested_by_idx ON public.sale_orders USING btree (site_id, requested_by_lead_id) WHERE (requested_by_lead_id IS NOT NULL);


--
-- Name: sale_orders_site_seller_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_orders_site_seller_idx ON public.sale_orders USING btree (site_id, seller_user_id) WHERE (seller_user_id IS NOT NULL);


--
-- Name: sale_orders_site_updated_recent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_orders_site_updated_recent_idx ON public.sale_orders USING btree (site_id, updated_at DESC, id DESC);


--
-- Name: sales_public_access_token_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sales_public_access_token_uidx ON public.sales USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: sales_public_access_token_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sales_public_access_token_unique ON public.sales USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: sales_quotation_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sales_quotation_id_unique ON public.sales USING btree (quotation_id) WHERE (quotation_id IS NOT NULL);


--
-- Name: sales_site_subscription_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sales_site_subscription_date_idx ON public.sales USING btree (site_id, subscription_id, sale_date DESC) WHERE (subscription_id IS NOT NULL);


--
-- Name: sales_site_unpaid_due_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sales_site_unpaid_due_date_idx ON public.sales USING btree (site_id, due_date, id) WHERE ((due_date IS NOT NULL) AND (amount_due > (0)::numeric) AND (status = 'pending'::text));


--
-- Name: sales_stripe_checkout_session_id_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sales_stripe_checkout_session_id_uidx ON public.sales USING btree (stripe_checkout_session_id) WHERE (stripe_checkout_session_id IS NOT NULL);


--
-- Name: sandbox_resources_requirement_cost_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sandbox_resources_requirement_cost_idx ON public.sandbox_billing_resources USING btree (site_id, owner_id) INCLUDE (sandbox_name) WHERE (owner_kind = 'requirement'::text);


--
-- Name: sandbox_sessions_resource_cost_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sandbox_sessions_resource_cost_idx ON public.sandbox_billing_sessions USING btree (sandbox_name) INCLUDE (credits_charged);


--
-- Name: secure_tokens_type_identifier_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX secure_tokens_type_identifier_idx ON public.secure_tokens USING btree (token_type, identifier);


--
-- Name: session_recording_chunks_session_hash_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX session_recording_chunks_session_hash_uidx ON public.session_recording_chunks USING btree (session_id, content_hash);


--
-- Name: settings_email_enabled_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX settings_email_enabled_idx ON public.settings USING btree (site_id) WHERE (((channels -> 'email'::text) ->> 'enabled'::text) = 'true'::text);


--
-- Name: settings_site_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX settings_site_id_idx ON public.settings USING btree (site_id);


--
-- Name: shipments_marketplace_external_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX shipments_marketplace_external_key ON public.shipments USING btree (marketplace_integration_id, external_delivery_id) WHERE (external_delivery_id IS NOT NULL);


--
-- Name: shipments_marketplace_order_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX shipments_marketplace_order_key ON public.shipments USING btree (sale_order_id) WHERE (marketplace_integration_id IS NOT NULL);


--
-- Name: shipments_stripe_checkout_session_id_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX shipments_stripe_checkout_session_id_uidx ON public.shipments USING btree (stripe_checkout_session_id) WHERE (stripe_checkout_session_id IS NOT NULL);


--
-- Name: site_members_location_acl_site_id_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX site_members_location_acl_site_id_id ON public.site_members USING btree (site_id, id);


--
-- Name: site_secrets_instance_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX site_secrets_instance_idx ON public.site_secrets USING btree (site_id, instance_id, provider, use_case) WHERE (instance_id IS NOT NULL);


--
-- Name: site_secrets_site_only_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX site_secrets_site_only_idx ON public.site_secrets USING btree (site_id, provider, use_case) WHERE (instance_id IS NULL);


--
-- Name: site_skills_site_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_skills_site_created_idx ON public.site_skills USING btree (site_id, created_at DESC);


--
-- Name: site_skills_source_url_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX site_skills_source_url_unique ON public.site_skills USING btree (site_id, source_url) WHERE (source_url IS NOT NULL);


--
-- Name: sites_active_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sites_active_owner_idx ON public.sites USING btree (user_id) WHERE (archived_at IS NULL);


--
-- Name: sites_url_lookup_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sites_url_lookup_idx ON public.sites USING btree (url);


--
-- Name: sites_url_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sites_url_trgm_idx ON public.sites USING gin (url extensions.gin_trgm_ops);


--
-- Name: stripe_subscription_invoice_settlements_site_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX stripe_subscription_invoice_settlements_site_idx ON public.stripe_subscription_invoice_settlements USING btree (site_id);


--
-- Name: subscriptions_active_next_billing_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_active_next_billing_idx ON public.subscriptions USING btree (next_billing_date) WHERE (status = 'active'::text);


--
-- Name: synced_objects_processing_expiry_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX synced_objects_processing_expiry_idx ON public.synced_objects USING btree (site_id, object_type, external_id, claim_expires_at) WHERE (status = 'processing'::text);


--
-- Name: system_status_system_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX system_status_system_created_idx ON public.system_status USING btree (system_key, created_at DESC) INCLUDE (status);


--
-- Name: tasks_active_scheduled_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_active_scheduled_date_idx ON public.tasks USING btree (scheduled_date) WHERE (status = ANY (ARRAY['pending'::text, 'in_progress'::text]));


--
-- Name: tasks_site_scheduled_window_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_site_scheduled_window_idx ON public.tasks USING btree (site_id, scheduled_date, id) WHERE (scheduled_date IS NOT NULL);


--
-- Name: tasks_site_status_kanban_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tasks_site_status_kanban_idx ON public.tasks USING btree (site_id, status, priority DESC, scheduled_date, id);


--
-- Name: uq_icp_mining_active_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_icp_mining_active_unique ON public.icp_mining USING btree (role_query_id, icp_hash) WHERE (status = ANY (ARRAY['pending'::text, 'running'::text]));


--
-- Name: visitor_identity_challenges_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_identity_challenges_active_idx ON public.visitor_identity_challenges USING btree (session_id, created_at DESC) WHERE ((consumed_at IS NULL) AND (cancelled_at IS NULL));


--
-- Name: visitor_identity_challenges_email_rate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_identity_challenges_email_rate_idx ON public.visitor_identity_challenges USING btree (site_id, normalized_email, created_at DESC);


--
-- Name: visitor_identity_challenges_ip_rate_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_identity_challenges_ip_rate_idx ON public.visitor_identity_challenges USING btree (site_id, request_ip_hash, created_at DESC) WHERE (request_ip_hash IS NOT NULL);


--
-- Name: visitor_identity_challenges_lookup_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_identity_challenges_lookup_idx ON public.visitor_identity_challenges USING btree (site_id, session_id, id);


--
-- Name: visitor_identity_redemptions_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_identity_redemptions_key_idx ON public.visitor_identity_token_redemptions USING btree (issuer_key_id) WHERE (issuer_key_id IS NOT NULL);


--
-- Name: visitor_identity_redemptions_session_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_identity_redemptions_session_idx ON public.visitor_identity_token_redemptions USING btree (session_id);


--
-- Name: visitor_session_identity_grants_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_session_identity_grants_active_idx ON public.visitor_session_identity_grants USING btree (site_id, visitor_id, lead_id) WHERE (revoked_at IS NULL);


--
-- Name: visitor_session_identity_grants_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_session_identity_grants_token_idx ON public.visitor_session_identity_grants USING btree (trusted_token_hash) WHERE ((trusted_token_hash IS NOT NULL) AND (revoked_at IS NULL));


--
-- Name: visitor_sessions_site_visitor_started_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX visitor_sessions_site_visitor_started_idx ON public.visitor_sessions USING btree (site_id, visitor_id, started_at DESC);


--
-- Name: voice_call_deliveries_audience_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX voice_call_deliveries_audience_idx ON public.voice_call_deliveries USING btree (audience_id, created_at DESC) WHERE (audience_id IS NOT NULL);


--
-- Name: voice_call_deliveries_one_active_recipient_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX voice_call_deliveries_one_active_recipient_idx ON public.voice_call_deliveries USING btree (recipient_phone) WHERE (status = ANY (ARRAY['placing'::text, 'placement_unknown'::text, 'queued'::text, 'ringing'::text, 'in_progress'::text]));


--
-- Name: voice_call_deliveries_site_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX voice_call_deliveries_site_status_idx ON public.voice_call_deliveries USING btree (site_id, status, created_at DESC);


--
-- Name: voice_call_deliveries_zavu_call_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX voice_call_deliveries_zavu_call_unique ON public.voice_call_deliveries USING btree (zavu_call_id) WHERE (zavu_call_id IS NOT NULL);


--
-- Name: workflow_runs_active_claim_expiry_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_runs_active_claim_expiry_idx ON public.workflow_runs USING btree (claim_expires_at) WHERE (status = 'in_progress'::text);


--
-- Name: workflow_runs_idempotency_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX workflow_runs_idempotency_uidx ON public.workflow_runs USING btree (site_id, idempotency_key) WHERE (idempotency_key IS NOT NULL);
