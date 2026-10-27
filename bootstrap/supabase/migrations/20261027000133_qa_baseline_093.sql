SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: idx_site_members_user_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_user_site ON public.site_members USING btree (user_id, site_id);


--
-- Name: idx_site_members_user_site_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_user_site_status ON public.site_members USING btree (user_id, site_id, status) WHERE (status = 'active'::text);


--
-- Name: idx_site_ownership_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_ownership_user_id ON public.site_ownership USING btree (user_id);


--
-- Name: idx_sites_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sites_command_id_new ON public.sites USING btree (command_id);


--
-- Name: idx_sites_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sites_user_id ON public.sites USING btree (user_id);


--
-- Name: idx_states_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_states_section_id ON public.states USING btree (section_id);


--
-- Name: idx_states_section_id_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_states_section_id_order ON public.states USING btree (section_id, "order");


--
-- Name: idx_subscriptions_catalog_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_catalog_item_id ON public.subscriptions USING btree (catalog_item_id);


--
-- Name: idx_subscriptions_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_lead_id ON public.subscriptions USING btree (lead_id);


--
-- Name: idx_subscriptions_site_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_site_status ON public.subscriptions USING btree (site_id, status);


--
-- Name: idx_synced_objects_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_external_id ON public.synced_objects USING btree (external_id);


--
-- Name: idx_synced_objects_external_site_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_external_site_type ON public.synced_objects USING btree (external_id, site_id, object_type);


--
-- Name: idx_synced_objects_object_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_object_type ON public.synced_objects USING btree (object_type);


--
-- Name: idx_synced_objects_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_provider ON public.synced_objects USING btree (provider);


--
-- Name: idx_synced_objects_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_site_id ON public.synced_objects USING btree (site_id);


--
-- Name: idx_synced_objects_site_object_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_site_object_type ON public.synced_objects USING btree (site_id, object_type);


--
-- Name: idx_synced_objects_site_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_site_status ON public.synced_objects USING btree (site_id, status);


--
-- Name: idx_synced_objects_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_synced_objects_status ON public.synced_objects USING btree (status);


--
-- Name: idx_synced_objects_unique_external_site_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_synced_objects_unique_external_site_type ON public.synced_objects USING btree (external_id, site_id, object_type);


--
-- Name: idx_system_memories_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_memories_command_id ON public.system_memories USING btree (command_id);


--
-- Name: idx_system_memories_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_memories_expires_at ON public.system_memories USING btree (expires_at);


--
-- Name: idx_system_memories_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_memories_key ON public.system_memories USING btree (key);


--
-- Name: idx_system_memories_last_accessed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_memories_last_accessed ON public.system_memories USING btree (last_accessed);


--
-- Name: idx_system_memories_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_memories_site_id ON public.system_memories USING btree (site_id);


--
-- Name: idx_system_memories_system_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_memories_system_type ON public.system_memories USING btree (system_type);


--
-- Name: idx_system_status_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_status_created_at ON public.system_status USING btree (created_at DESC);


--
-- Name: idx_system_status_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_status_run_id ON public.system_status USING btree (run_id);


--
-- Name: idx_system_status_runs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_status_runs_created_at ON public.system_status_runs USING btree (created_at DESC);


--
-- Name: idx_system_telemetry_system_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_telemetry_system_created ON public.system_telemetry USING btree (system_key, created_at DESC);


--
-- Name: idx_task_categories_category_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_categories_category_id_new ON public.task_categories USING btree (category_id);


--
-- Name: idx_task_categories_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_categories_task_id ON public.task_categories USING btree (task_id);


--
-- Name: idx_task_comments_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_comments_task_id ON public.task_comments USING btree (task_id);


--
-- Name: idx_task_comments_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_task_comments_user_id ON public.task_comments USING btree (user_id);


--
-- Name: idx_tasks_assignee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_assignee ON public.tasks USING btree (assignee);


--
-- Name: idx_tasks_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_command_id_new ON public.tasks USING btree (command_id);


--
-- Name: idx_tasks_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_lead_id ON public.tasks USING btree (lead_id);


--
-- Name: idx_tasks_pending_conversation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_pending_conversation ON public.tasks USING btree (conversation_id) WHERE ((status = 'pending'::text) AND (conversation_id IS NOT NULL));


--
-- Name: idx_tasks_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_priority ON public.tasks USING btree (priority);


--
-- Name: idx_tasks_serial_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_serial_id ON public.tasks USING btree (serial_id);


--
-- Name: idx_tasks_serial_id_site_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_tasks_serial_id_site_unique ON public.tasks USING btree (site_id, serial_id);


--
-- Name: idx_tasks_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_site_id ON public.tasks USING btree (site_id);


--
-- Name: idx_tasks_site_pending_conversation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_site_pending_conversation ON public.tasks USING btree (site_id, conversation_id) WHERE ((status = 'pending'::text) AND (conversation_id IS NOT NULL));


--
-- Name: idx_tasks_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tasks_user_id ON public.tasks USING btree (user_id);


--
-- Name: idx_taxes_site_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_taxes_site_active ON public.taxes USING btree (site_id, is_active);


--
-- Name: idx_transactions_accounting_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_accounting_state ON public.transactions USING btree (site_id, accounting_state);


--
-- Name: idx_transactions_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_campaign_id ON public.transactions USING btree (campaign_id);


--
-- Name: idx_transactions_catalog_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_catalog_category ON public.transactions USING btree (catalog_category_id);


--
-- Name: idx_transactions_catalog_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_catalog_item ON public.transactions USING btree (catalog_item_id);


--
-- Name: idx_transactions_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_command_id_new ON public.transactions USING btree (command_id);


--
-- Name: idx_transactions_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_company ON public.transactions USING btree (company_id);


--
-- Name: idx_transactions_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_lead ON public.transactions USING btree (lead_id);


--
-- Name: idx_transactions_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_location_id ON public.transactions USING btree (location_id);


--
-- Name: idx_transactions_sale_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_sale_order_id ON public.transactions USING btree (sale_order_id) WHERE (sale_order_id IS NOT NULL);


--
-- Name: idx_transactions_sale_order_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_transactions_sale_order_id_unique ON public.transactions USING btree (sale_order_id) WHERE (sale_order_id IS NOT NULL);


--
-- Name: idx_transactions_segment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_segment ON public.transactions USING btree (segment_id);


--
-- Name: idx_transactions_site_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_site_created_at ON public.transactions USING btree (site_id, created_at DESC);


--
-- Name: idx_transactions_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_site_id ON public.transactions USING btree (site_id);


--
-- Name: idx_transactions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_user_id ON public.transactions USING btree (user_id);


--
-- Name: idx_transitions_from_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transitions_from_state_id ON public.transitions USING btree (from_state_id);


--
-- Name: idx_transitions_from_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transitions_from_to ON public.transitions USING btree (from_state_id, to_state_id);


--
-- Name: idx_transitions_to_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transitions_to_state_id ON public.transitions USING btree (to_state_id);


--
-- Name: idx_variants_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variants_state_id ON public.variants USING btree (state_id);


--
-- Name: idx_visitor_sessions_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitor_sessions_command_id ON public.visitor_sessions USING btree (command_id);


--
-- Name: idx_visitor_sessions_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitor_sessions_is_active ON public.visitor_sessions USING btree (is_active);


--
-- Name: idx_visitor_sessions_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitor_sessions_lead_id ON public.visitor_sessions USING btree (lead_id);


--
-- Name: idx_visitor_sessions_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitor_sessions_site_id ON public.visitor_sessions USING btree (site_id);


--
-- Name: idx_visitor_sessions_visitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitor_sessions_visitor_id ON public.visitor_sessions USING btree (visitor_id);


--
-- Name: idx_visitors_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitors_campaign_id ON public.visitors USING btree (campaign_id);


--
-- Name: idx_visitors_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitors_command_id ON public.visitors USING btree (command_id);


--
-- Name: idx_visitors_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visitors_device_id ON public.visitors USING btree (fingerprint);
