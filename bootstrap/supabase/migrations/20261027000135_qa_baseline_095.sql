SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: location_acl_sale_order_item_units_shipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sale_order_item_units_shipment_id ON public.sale_order_item_units USING btree (shipment_id);


--
-- Name: location_acl_sale_order_items_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_sale_order_items_parent_key ON public.sale_order_items USING btree (site_id, id);


--
-- Name: location_acl_sale_order_items_sale_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sale_order_items_sale_order_id ON public.sale_order_items USING btree (sale_order_id);


--
-- Name: location_acl_sale_order_items_shipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sale_order_items_shipment_id ON public.sale_order_items USING btree (shipment_id);


--
-- Name: location_acl_sale_orders; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sale_orders ON public.sale_orders USING btree (site_id, location_id);


--
-- Name: location_acl_sale_orders_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_sale_orders_parent_key ON public.sale_orders USING btree (site_id, id);


--
-- Name: location_acl_sale_orders_quotation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sale_orders_quotation_id ON public.sale_orders USING btree (quotation_id);


--
-- Name: location_acl_sale_orders_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sale_orders_sale_id ON public.sale_orders USING btree (sale_id);


--
-- Name: location_acl_sale_orders_scope_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_sale_orders_scope_key ON public.sale_orders USING btree (site_id, id, location_id);


--
-- Name: location_acl_sales; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sales ON public.sales USING btree (site_id, location_id);


--
-- Name: location_acl_sales_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_sales_parent_key ON public.sales USING btree (site_id, id);


--
-- Name: location_acl_sales_quotation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sales_quotation_id ON public.sales USING btree (quotation_id);


--
-- Name: location_acl_sales_scope_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_sales_scope_key ON public.sales USING btree (site_id, id, location_id);


--
-- Name: location_acl_sales_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sales_subscription_id ON public.sales USING btree (subscription_id);


--
-- Name: location_acl_shipment_location_pings_shipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_shipment_location_pings_shipment_id ON public.shipment_location_pings USING btree (shipment_id);


--
-- Name: location_acl_shipments; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_shipments ON public.shipments USING btree (site_id, origin_location_id);


--
-- Name: location_acl_shipments_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_shipments_parent_key ON public.shipments USING btree (site_id, id);


--
-- Name: location_acl_shipments_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_shipments_sale_id ON public.shipments USING btree (sale_id);


--
-- Name: location_acl_shipments_sale_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_shipments_sale_order_id ON public.shipments USING btree (sale_order_id);


--
-- Name: location_acl_subscriptions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_subscriptions ON public.subscriptions USING btree (site_id, location_id);


--
-- Name: location_acl_subscriptions_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_subscriptions_parent_key ON public.subscriptions USING btree (site_id, id);


--
-- Name: location_acl_subscriptions_scope_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_subscriptions_scope_key ON public.subscriptions USING btree (site_id, id, location_id);


--
-- Name: location_acl_task_categories_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_task_categories_task_id ON public.task_categories USING btree (task_id);


--
-- Name: location_acl_task_comments_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_task_comments_task_id ON public.task_comments USING btree (task_id);


--
-- Name: location_acl_tasks; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_tasks ON public.tasks USING btree (site_id, location_id);


--
-- Name: location_acl_tasks_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_tasks_conversation_id ON public.tasks USING btree (conversation_id);


--
-- Name: location_acl_tasks_deal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_tasks_deal_id ON public.tasks USING btree (deal_id);


--
-- Name: location_acl_tasks_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_tasks_lead_id ON public.tasks USING btree (lead_id);


--
-- Name: location_acl_tasks_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_tasks_parent_key ON public.tasks USING btree (site_id, id);


--
-- Name: location_acl_transactions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_transactions ON public.transactions USING btree (site_id, location_id);


--
-- Name: location_acl_transactions_sale_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_transactions_sale_order_id ON public.transactions USING btree (sale_order_id);


--
-- Name: location_restrictions_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_restrictions_location_idx ON public.site_member_location_restrictions USING btree (site_id, location_id);


--
-- Name: locations_location_acl_site_id_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX locations_location_acl_site_id_id ON public.locations USING btree (site_id, id);


--
-- Name: marketplace_actions_unresolved_order; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX marketplace_actions_unresolved_order ON public.marketplace_actions USING btree (order_id) WHERE (status = ANY (ARRAY['pending'::text, 'unknown'::text]));


--
-- Name: marketplace_integration_merchant_connection; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_integration_merchant_connection ON public.marketplace_integrations USING btree (merchant_connection_id) WHERE (merchant_connection_id IS NOT NULL);


--
-- Name: marketplace_merchant_connections_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_merchant_connections_site ON public.marketplace_merchant_connections USING btree (site_id, provider, status);


--
-- Name: messages_accepted_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_accepted_created_at_idx ON public.messages USING btree (created_at) WHERE ((custom_data ->> 'status'::text) = 'accepted'::text);


--
-- Name: messages_conversation_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_conversation_created_at_idx ON public.messages USING btree (conversation_id, created_at DESC);


--
-- Name: messages_outstand_dm_id_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX messages_outstand_dm_id_uidx ON public.messages USING btree (conversation_id, ((custom_data ->> 'outstand_message_id'::text))) WHERE (((custom_data ->> 'source'::text) = 'outstand_dm'::text) AND ((custom_data ->> 'outstand_message_id'::text) IS NOT NULL));


--
-- Name: messages_sending_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_sending_updated_at_idx ON public.messages USING btree (updated_at) WHERE ((custom_data ->> 'status'::text) = 'sending'::text);


--
-- Name: migration_reconciliation_resumes_requirement_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX migration_reconciliation_resumes_requirement_idx ON public.requirement_migration_reconciliation_resumes USING btree (requirement_id, created_at DESC);


--
-- Name: payments_credit_renewal_lookup_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payments_credit_renewal_lookup_idx ON public.payments USING btree (site_id, created_at DESC) WHERE ((payment_method)::text = 'credit_renewal'::text);


--
-- Name: payments_initial_credit_lookup_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payments_initial_credit_lookup_idx ON public.payments USING btree (site_id) WHERE ((payment_method)::text = 'initial_credit'::text);


--
-- Name: payments_transaction_id_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payments_transaction_id_uidx ON public.payments USING btree (transaction_id);


--
-- Name: payout_requests_site_idempotency_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payout_requests_site_idempotency_key_idx ON public.payout_requests USING btree (site_id, idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: platform_audit_log_capability_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX platform_audit_log_capability_idx ON public.platform_audit_log USING btree (capability, status, created_at DESC);


--
-- Name: platform_audit_log_requirement_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX platform_audit_log_requirement_idx ON public.platform_audit_log USING btree (requirement_id, created_at DESC) WHERE (requirement_id IS NOT NULL);


--
-- Name: platform_audit_log_site_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX platform_audit_log_site_created_idx ON public.platform_audit_log USING btree (site_id, created_at DESC);


--
-- Name: platform_quotas_site_capability_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX platform_quotas_site_capability_idx ON public.platform_quotas USING btree (site_id, capability);


--
-- Name: platform_tracking_events_requirement_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX platform_tracking_events_requirement_idx ON public.platform_tracking_events USING btree (requirement_id, created_at DESC) WHERE (requirement_id IS NOT NULL);


--
-- Name: platform_tracking_events_site_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX platform_tracking_events_site_created_idx ON public.platform_tracking_events USING btree (site_id, created_at DESC);


--
-- Name: pos_checkout_one_unresolved_order; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pos_checkout_one_unresolved_order ON public.pos_checkout_attempts USING btree (site_id, order_id) WHERE ((order_id IS NOT NULL) AND (state = ANY (ARRAY['processing'::text, 'writes_started'::text, 'review_required'::text])));


--
-- Name: pos_register_movements_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pos_register_movements_session ON public.pos_register_movements USING btree (session_id, created_at, id);


--
-- Name: pos_register_one_open_location; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pos_register_one_open_location ON public.pos_register_sessions USING btree (site_id, location_id) WHERE (status = 'open'::text);


--
-- Name: pos_register_receipts_sale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pos_register_receipts_sale ON public.pos_register_receipts USING btree (sale_id);


--
-- Name: pos_register_receipts_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pos_register_receipts_session ON public.pos_register_receipts USING btree (session_id, received_at, id);


--
-- Name: pos_register_sessions_closed_history; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pos_register_sessions_closed_history ON public.pos_register_sessions USING btree (site_id, location_id, closed_at DESC, id DESC) WHERE (status = 'closed'::text);


--
-- Name: pos_register_sessions_history; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pos_register_sessions_history ON public.pos_register_sessions USING btree (site_id, opened_at DESC);


--
-- Name: purchases_id_site_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX purchases_id_site_id_key ON public.purchases USING btree (id, site_id);


--
-- Name: purchases_public_access_token_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX purchases_public_access_token_uidx ON public.purchases USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: purchases_public_access_token_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX purchases_public_access_token_unique ON public.purchases USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: quotations_checkout_claimed_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quotations_checkout_claimed_at_idx ON public.quotations USING btree (checkout_claimed_at) WHERE (checkout_claim_id IS NOT NULL);


--
-- Name: quotations_public_access_token_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX quotations_public_access_token_uidx ON public.quotations USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: quotations_public_access_token_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX quotations_public_access_token_unique ON public.quotations USING btree (public_access_token) WHERE (public_access_token IS NOT NULL);


--
-- Name: record_categories_site_system_key_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX record_categories_site_system_key_uidx ON public.record_categories USING btree (site_id, system_key);


--
-- Name: records_site_source_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX records_site_source_uidx ON public.records USING btree (site_id, source_type, source_id);


--
-- Name: requirement_commands_pending_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirement_commands_pending_idx ON public.requirement_commands USING btree (requirement_id, revision) WHERE (applied_at IS NULL);


--
-- Name: requirement_cron_cycle_outcomes_order_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirement_cron_cycle_outcomes_order_idx ON public.requirement_cron_cycle_outcomes USING btree (requirement_id, execution_generation, cycle_started_at DESC, cycle_id DESC);


--
-- Name: requirement_cron_cycle_outcomes_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirement_cron_cycle_outcomes_scope_idx ON public.requirement_cron_cycle_outcomes USING btree (requirement_id, execution_generation, plan_id, step_id, cycle_started_at DESC, cycle_id DESC);


--
-- Name: requirement_economic_pauses_check; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX requirement_economic_pauses_check ON public.requirement_economic_pauses USING btree (checked_at, requirement_id);
