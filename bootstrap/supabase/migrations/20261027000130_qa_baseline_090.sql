SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: idx_instance_logs_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_lookup ON public.instance_logs USING btree (instance_id, log_type, created_at DESC);


--
-- Name: idx_instance_logs_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_site_id ON public.instance_logs USING btree (site_id);


--
-- Name: idx_instance_logs_step_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_step_id ON public.instance_logs USING btree (step_id);


--
-- Name: idx_instance_logs_tool_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_tool_name ON public.instance_logs USING btree (tool_name);


--
-- Name: idx_instance_logs_trusted_user_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_trusted_user_action ON public.instance_logs USING btree (instance_id, created_at DESC, id DESC) WHERE ((log_type = 'user_action'::text) AND (trusted_user_action = true));


--
-- Name: idx_instance_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_user_id ON public.instance_logs USING btree (user_id);


--
-- Name: idx_instance_nodes_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_nodes_instance_id ON public.instance_nodes USING btree (instance_id);


--
-- Name: idx_instance_nodes_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_nodes_parent_id ON public.instance_nodes USING btree (parent_node_id);


--
-- Name: idx_instance_nodes_parent_log; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_nodes_parent_log ON public.instance_nodes USING btree (parent_instance_log_id);


--
-- Name: idx_instance_nodes_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_nodes_site_id ON public.instance_nodes USING btree (site_id);


--
-- Name: idx_instance_pending_work_instance_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_pending_work_instance_status_created ON public.instance_pending_work USING btree (instance_id, status, created_at);


--
-- Name: idx_instance_plans_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_agent_id ON public.instance_plans USING btree (agent_id);


--
-- Name: idx_instance_plans_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_command_id ON public.instance_plans USING btree (command_id);


--
-- Name: idx_instance_plans_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_created_at ON public.instance_plans USING btree (created_at);


--
-- Name: idx_instance_plans_due_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_due_at ON public.instance_plans USING btree (due_at);


--
-- Name: idx_instance_plans_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_instance_id ON public.instance_plans USING btree (instance_id);


--
-- Name: idx_instance_plans_parent_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_parent_plan_id ON public.instance_plans USING btree (parent_plan_id);


--
-- Name: idx_instance_plans_plan_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_plan_type ON public.instance_plans USING btree (plan_type);


--
-- Name: idx_instance_plans_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_priority ON public.instance_plans USING btree (priority);


--
-- Name: idx_instance_plans_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_site_id ON public.instance_plans USING btree (site_id);


--
-- Name: idx_instance_plans_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_status ON public.instance_plans USING btree (status);


--
-- Name: idx_instance_plans_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_plans_user_id ON public.instance_plans USING btree (user_id);


--
-- Name: idx_item_spec_categories_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_item_spec_categories_site ON public.item_spec_categories USING btree (site_id);


--
-- Name: idx_item_specs_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_item_specs_category ON public.item_specs USING btree (category_id);


--
-- Name: idx_item_specs_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_item_specs_site ON public.item_specs USING btree (site_id);


--
-- Name: idx_journal_lines_campaign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_journal_lines_campaign ON public.journal_lines USING btree (campaign_id);


--
-- Name: idx_journal_lines_catalog_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_journal_lines_catalog_category ON public.journal_lines USING btree (catalog_category_id);


--
-- Name: idx_journal_lines_catalog_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_journal_lines_catalog_item ON public.journal_lines USING btree (catalog_item_id);


--
-- Name: idx_journal_lines_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_journal_lines_company ON public.journal_lines USING btree (company_id);


--
-- Name: idx_journal_lines_lead; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_journal_lines_lead ON public.journal_lines USING btree (lead_id);


--
-- Name: idx_journal_lines_segment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_journal_lines_segment ON public.journal_lines USING btree (segment_id);


--
-- Name: idx_kpis_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kpis_command_id ON public.kpis USING btree (command_id);


--
-- Name: idx_kpis_period_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kpis_period_end ON public.kpis USING btree (period_end);


--
-- Name: idx_kpis_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kpis_segment_id ON public.kpis USING btree (segment_id);


--
-- Name: idx_kpis_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kpis_site_id ON public.kpis USING btree (site_id);


--
-- Name: idx_kpis_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kpis_type ON public.kpis USING btree (type);


--
-- Name: idx_kpis_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_kpis_user_id ON public.kpis USING btree (user_id);


--
-- Name: idx_layers_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_layers_state_id ON public.layers USING btree (state_id);


--
-- Name: idx_layers_state_id_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_layers_state_id_order ON public.layers USING btree (state_id, "order");


--
-- Name: idx_lead_analysis_company_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_company_size ON public.lead_analysis USING btree (company_size);


--
-- Name: idx_lead_analysis_completion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_completion ON public.lead_analysis USING btree (completion_percentage);


--
-- Name: idx_lead_analysis_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_created_at ON public.lead_analysis USING btree (created_at DESC);


--
-- Name: idx_lead_analysis_industry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_industry ON public.lead_analysis USING btree (industry);


--
-- Name: idx_lead_analysis_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_site_id ON public.lead_analysis USING btree (site_id);


--
-- Name: idx_lead_analysis_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_source ON public.lead_analysis USING btree (source);


--
-- Name: idx_lead_analysis_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_status ON public.lead_analysis USING btree (status);


--
-- Name: idx_lead_analysis_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lead_analysis_user_id ON public.lead_analysis USING btree (user_id);


--
-- Name: idx_leads_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_campaign_id ON public.leads USING btree (campaign_id);


--
-- Name: idx_leads_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_command_id ON public.leads USING btree (command_id);


--
-- Name: idx_leads_company_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_company_id_new ON public.leads USING btree (company_id);


--
-- Name: idx_leads_referral_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_referral_lead_id ON public.leads USING btree (referral_lead_id);


--
-- Name: idx_leads_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_segment_id ON public.leads USING btree (segment_id);


--
-- Name: idx_leads_site_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_site_created_at ON public.leads USING btree (site_id, created_at DESC);


--
-- Name: idx_leads_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_site_id ON public.leads USING btree (site_id);


--
-- Name: idx_leads_site_segment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_site_segment ON public.leads USING btree (site_id, segment_id) WHERE (segment_id IS NOT NULL);


--
-- Name: idx_leads_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_status ON public.leads USING btree (status);


--
-- Name: idx_leads_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_user_id ON public.leads USING btree (user_id);


--
-- Name: idx_locations_site_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_locations_site_default ON public.locations USING btree (site_id) WHERE (is_default = true);


--
-- Name: idx_locations_site_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_locations_site_name ON public.locations USING btree (site_id, name);


--
-- Name: idx_memories_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_memories_type ON public.agent_memories USING btree (type);


--
-- Name: idx_messages_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_command_id ON public.messages USING btree (command_id);


--
-- Name: idx_messages_conversation_created_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_conversation_created_desc ON public.messages USING btree (conversation_id, created_at DESC, id DESC);


--
-- Name: idx_messages_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: idx_messages_conversation_moderation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_conversation_moderation ON public.messages USING btree (conversation_id) WHERE ((custom_data ->> 'status'::text) = ANY (ARRAY['pending'::text, 'accepted'::text]));


--
-- Name: idx_messages_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_created_at ON public.messages USING btree (created_at);


--
-- Name: idx_messages_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_lead_id ON public.messages USING btree (lead_id);


--
-- Name: idx_messages_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_role ON public.messages USING btree (role);


--
-- Name: idx_messages_visitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_visitor_id ON public.messages USING btree (visitor_id);


--
-- Name: idx_modifier_group_items_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_modifier_group_items_group_id ON public.modifier_group_items USING btree (modifier_group_id);


--
-- Name: idx_modifier_group_items_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_modifier_group_items_site_id ON public.modifier_group_items USING btree (site_id);
