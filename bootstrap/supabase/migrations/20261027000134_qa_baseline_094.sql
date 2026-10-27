SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: idx_visitors_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitors_lead_id ON public.visitors USING btree (lead_id);


--
-- Name: idx_visitors_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitors_segment_id ON public.visitors USING btree (segment_id);


--
-- Name: idx_webhook_events_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_events_event_type ON public.webhook_events USING btree (event_type);


--
-- Name: idx_webhook_events_processed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_events_processed_at ON public.webhook_events USING btree (processed_at);


--
-- Name: idx_webhook_events_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_events_site_id ON public.webhook_events USING btree (site_id);


--
-- Name: idx_webhook_events_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_events_status ON public.webhook_events USING btree (status);


--
-- Name: idx_webhook_events_stripe_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhook_events_stripe_event_id ON public.webhook_events USING btree (stripe_event_id);


--
-- Name: idx_webhooks_deliveries_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_deliveries_created_at ON public.webhooks_deliveries USING btree (created_at);


--
-- Name: idx_webhooks_deliveries_endpoint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_deliveries_endpoint ON public.webhooks_deliveries USING btree (endpoint_id);


--
-- Name: idx_webhooks_deliveries_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_deliveries_event ON public.webhooks_deliveries USING btree (event_type);


--
-- Name: idx_webhooks_deliveries_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_deliveries_site ON public.webhooks_deliveries USING btree (site_id);


--
-- Name: idx_webhooks_deliveries_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_deliveries_status ON public.webhooks_deliveries USING btree (status);


--
-- Name: idx_webhooks_endpoints_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_endpoints_site ON public.webhooks_endpoints USING btree (site_id);


--
-- Name: idx_webhooks_endpoints_site_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_endpoints_site_active ON public.webhooks_endpoints USING btree (site_id, is_active);


--
-- Name: idx_webhooks_subscriptions_endpoint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_subscriptions_endpoint ON public.webhooks_subscriptions USING btree (endpoint_id);


--
-- Name: idx_webhooks_subscriptions_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_subscriptions_event ON public.webhooks_subscriptions USING btree (event_type);


--
-- Name: idx_webhooks_subscriptions_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_webhooks_subscriptions_site ON public.webhooks_subscriptions USING btree (site_id);


--
-- Name: idx_whatsapp_templates_account_sid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_whatsapp_templates_account_sid ON public.whatsapp_templates USING btree (account_sid);


--
-- Name: idx_whatsapp_templates_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_whatsapp_templates_created_at ON public.whatsapp_templates USING btree (created_at);


--
-- Name: idx_whatsapp_templates_last_used; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_whatsapp_templates_last_used ON public.whatsapp_templates USING btree (last_used);


--
-- Name: idx_whatsapp_templates_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_whatsapp_templates_site_id ON public.whatsapp_templates USING btree (site_id);


--
-- Name: idx_whatsapp_templates_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_whatsapp_templates_status ON public.whatsapp_templates USING btree (status);


--
-- Name: idx_whatsapp_templates_templated_body; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_whatsapp_templates_templated_body ON public.whatsapp_templates USING btree (site_id, account_sid, templated_body);


--
-- Name: image_generation_pending_audit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX image_generation_pending_audit ON public.image_generation_credit_reservations USING btree (created_at) WHERE (state = ANY (ARRAY['reserved'::text, 'dispatched'::text, 'pending'::text]));


--
-- Name: image_generation_receipt_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX image_generation_receipt_once ON public.image_generation_credit_reservations USING btree (generation_id) WHERE (generation_id IS NOT NULL);


--
-- Name: instance_context_memories_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_context_memories_scope_idx ON public.instance_context_memories USING btree (site_id, instance_id, end_at DESC);


--
-- Name: instance_context_memories_vector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_context_memories_vector_idx ON public.instance_context_memories USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: instance_logs_deletion_details_requirement_camel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_logs_deletion_details_requirement_camel_idx ON public.instance_logs USING btree (lower((details ->> 'requirementId'::text))) WHERE ((details ->> 'requirementId'::text) IS NOT NULL);


--
-- Name: instance_logs_deletion_details_requirement_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_logs_deletion_details_requirement_idx ON public.instance_logs USING btree (lower((details ->> 'requirement_id'::text))) WHERE ((details ->> 'requirement_id'::text) IS NOT NULL);


--
-- Name: instance_logs_deletion_tool_requirement_camel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_logs_deletion_tool_requirement_camel_idx ON public.instance_logs USING btree (lower((tool_args ->> 'requirementId'::text))) WHERE ((tool_args ->> 'requirementId'::text) IS NOT NULL);


--
-- Name: instance_logs_deletion_tool_requirement_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_logs_deletion_tool_requirement_idx ON public.instance_logs USING btree (lower((tool_args ->> 'requirement_id'::text))) WHERE ((tool_args ->> 'requirement_id'::text) IS NOT NULL);


--
-- Name: instance_logs_instance_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_logs_instance_id_idx ON public.instance_logs USING btree (instance_id);


--
-- Name: instance_logs_parent_log_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_logs_parent_log_id_idx ON public.instance_logs USING btree (parent_log_id) WHERE (parent_log_id IS NOT NULL);


--
-- Name: instance_logs_user_action_requirement_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_logs_user_action_requirement_created_idx ON public.instance_logs USING btree (instance_id, ((details ->> 'requirement_id'::text)), created_at DESC, id DESC) WHERE (log_type = 'user_action'::text);


--
-- Name: instance_node_contexts_context_node_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_node_contexts_context_node_id_idx ON public.instance_node_contexts USING btree (context_node_id);


--
-- Name: instance_nodes_instance_created_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_nodes_instance_created_id_idx ON public.instance_nodes USING btree (instance_id, created_at, id);


--
-- Name: instance_plans_one_active_per_instance_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX instance_plans_one_active_per_instance_idx ON public.instance_plans USING btree (instance_id) WHERE ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'active'::text, 'paused'::text])) AND (NULLIF((metadata ->> 'requirement_id'::text), ''::text) IS NOT NULL));


--
-- Name: invoice_reminders_sale_receipts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoice_reminders_sale_receipts ON public.invoice_reminders USING btree (site_id, sale_id, created_at DESC);


--
-- Name: journal_entries_source_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_entries_source_lookup ON public.journal_entries USING btree (site_id, source_type, source_id);


--
-- Name: journal_lines_entry_account_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_lines_entry_account_lookup ON public.journal_lines USING btree (entry_id, account_code);


--
-- Name: location_acl_accounting_sale_refunds_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_accounting_sale_refunds_sale_id ON public.accounting_sale_refunds USING btree (sale_id);


--
-- Name: location_acl_catalog_item_site_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_catalog_item_site_key ON public.catalog_items USING btree (site_id, id);


--
-- Name: location_acl_conversations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_conversations ON public.conversations USING btree (site_id, location_id);


--
-- Name: location_acl_conversations_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_conversations_parent_key ON public.conversations USING btree (site_id, id);


--
-- Name: location_acl_conversations_scope_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_conversations_scope_key ON public.conversations USING btree (site_id, id, location_id);


--
-- Name: location_acl_deal_owners_deal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_deal_owners_deal_id ON public.deal_owners USING btree (deal_id);


--
-- Name: location_acl_deals; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_deals ON public.deals USING btree (site_id, location_id);


--
-- Name: location_acl_deals_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_deals_parent_key ON public.deals USING btree (site_id, id);


--
-- Name: location_acl_deals_scope_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_deals_scope_key ON public.deals USING btree (site_id, id, location_id);


--
-- Name: location_acl_inventory_levels; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_inventory_levels ON public.inventory_levels USING btree (site_id, location_id);


--
-- Name: location_acl_invoice_reminders_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_invoice_reminders_sale_id ON public.invoice_reminders USING btree (sale_id);


--
-- Name: location_acl_leads_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_leads_parent_key ON public.leads USING btree (site_id, id);


--
-- Name: location_acl_messages_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_messages_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: location_acl_pos_register_movements_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_pos_register_movements_session_id ON public.pos_register_movements USING btree (session_id);


--
-- Name: location_acl_pos_register_receipts_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_pos_register_receipts_sale_id ON public.pos_register_receipts USING btree (sale_id);


--
-- Name: location_acl_pos_register_receipts_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_pos_register_receipts_session_id ON public.pos_register_receipts USING btree (session_id);


--
-- Name: location_acl_pos_register_sessions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_pos_register_sessions ON public.pos_register_sessions USING btree (site_id, location_id);


--
-- Name: location_acl_pos_register_sessions_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_pos_register_sessions_parent_key ON public.pos_register_sessions USING btree (site_id, id);


--
-- Name: location_acl_purchase_items_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_purchase_items_purchase_id ON public.purchase_items USING btree (purchase_id);


--
-- Name: location_acl_purchases; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_purchases ON public.purchases USING btree (site_id, location_id);


--
-- Name: location_acl_purchases_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_purchases_parent_key ON public.purchases USING btree (site_id, id);


--
-- Name: location_acl_quotation_items_quotation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_quotation_items_quotation_id ON public.quotation_items USING btree (quotation_id);


--
-- Name: location_acl_quotations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_quotations ON public.quotations USING btree (site_id, location_id);


--
-- Name: location_acl_quotations_deal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_quotations_deal_id ON public.quotations USING btree (deal_id);


--
-- Name: location_acl_quotations_parent_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_quotations_parent_key ON public.quotations USING btree (site_id, id);


--
-- Name: location_acl_quotations_scope_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX location_acl_quotations_scope_key ON public.quotations USING btree (site_id, id, location_id);


--
-- Name: location_acl_records; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_records ON public.records USING btree (site_id, location_id);


--
-- Name: location_acl_reservations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_reservations ON public.reservations USING btree (site_id, operating_location_id);


--
-- Name: location_acl_reservations_sale_order_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_reservations_sale_order_item_id ON public.reservations USING btree (sale_order_item_id);


--
-- Name: location_acl_sale_order_item_units_sale_order_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX location_acl_sale_order_item_units_sale_order_item_id ON public.sale_order_item_units USING btree (sale_order_item_id);
