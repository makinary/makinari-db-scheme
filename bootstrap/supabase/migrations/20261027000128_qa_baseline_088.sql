SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: idx_activity_workflow_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_workflow_type ON public.activity USING btree (workflow_type);


--
-- Name: idx_agent_assets_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_assets_agent_id ON public.agent_assets USING btree (agent_id);


--
-- Name: idx_agent_assets_asset_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_assets_asset_id_new ON public.agent_assets USING btree (asset_id);


--
-- Name: idx_agent_assets_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_assets_command_id_new ON public.agent_assets USING btree (command_id);


--
-- Name: idx_agent_memories_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_memories_command_id ON public.agent_memories USING btree (command_id);


--
-- Name: idx_agents_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_command_id ON public.agents USING btree (command_id);


--
-- Name: idx_agents_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_site_id ON public.agents USING btree (site_id);


--
-- Name: idx_agents_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_status ON public.agents USING btree (status);


--
-- Name: idx_agents_supervisor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_supervisor ON public.agents USING btree (supervisor);


--
-- Name: idx_agents_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agents_user_id ON public.agents USING btree (user_id);


--
-- Name: idx_allowed_domains_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_allowed_domains_site_id ON public.allowed_domains USING btree (site_id);


--
-- Name: idx_analysis_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_analysis_command_id_new ON public.analysis USING btree (command_id);


--
-- Name: idx_analysis_site_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_analysis_site_id_new ON public.analysis USING btree (site_id);


--
-- Name: idx_api_keys_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_prefix ON public.api_keys USING btree (prefix);


--
-- Name: idx_api_keys_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_site_id ON public.api_keys USING btree (site_id);


--
-- Name: idx_api_keys_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_status ON public.api_keys USING btree (status);


--
-- Name: idx_api_keys_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_user_id ON public.api_keys USING btree (user_id);


--
-- Name: idx_assets_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_command_id_new ON public.assets USING btree (command_id);


--
-- Name: idx_assets_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_site_id ON public.assets USING btree (site_id);


--
-- Name: idx_assets_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_user_id ON public.assets USING btree (user_id);


--
-- Name: idx_audience_leads_page; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audience_leads_page ON public.audience_leads USING btree (audience_id, page_number);


--
-- Name: idx_audience_leads_send; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audience_leads_send ON public.audience_leads USING btree (audience_id, send_status) WHERE (send_status = 'pending'::text);


--
-- Name: idx_automation_auth_sessions_auth_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_auth_type ON public.automation_auth_sessions USING btree (auth_type);


--
-- Name: idx_automation_auth_sessions_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_domain ON public.automation_auth_sessions USING btree (domain);


--
-- Name: idx_automation_auth_sessions_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_expires_at ON public.automation_auth_sessions USING btree (expires_at);


--
-- Name: idx_automation_auth_sessions_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_instance_id ON public.automation_auth_sessions USING btree (instance_id);


--
-- Name: idx_automation_auth_sessions_is_valid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_is_valid ON public.automation_auth_sessions USING btree (is_valid);


--
-- Name: idx_automation_auth_sessions_last_used_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_last_used_at ON public.automation_auth_sessions USING btree (last_used_at);


--
-- Name: idx_automation_auth_sessions_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_site_id ON public.automation_auth_sessions USING btree (site_id);


--
-- Name: idx_automation_auth_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_automation_auth_sessions_user_id ON public.automation_auth_sessions USING btree (user_id);


--
-- Name: idx_billing_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_billing_command_id ON public.billing USING btree (command_id);


--
-- Name: idx_billing_plan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_billing_plan ON public.billing USING btree (plan);


--
-- Name: idx_billing_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_billing_site_id ON public.billing USING btree (site_id);


--
-- Name: idx_billing_stripe_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_billing_stripe_customer_id ON public.billing USING btree (stripe_customer_id);


--
-- Name: idx_calendar_blocks_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_blocks_entity_id ON public.calendar_blocks USING btree (entity_id);


--
-- Name: idx_calendar_blocks_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_blocks_site_id ON public.calendar_blocks USING btree (site_id);


--
-- Name: idx_calendar_blocks_time_range; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_blocks_time_range ON public.calendar_blocks USING btree (start_time, end_time);


--
-- Name: idx_campaign_requirements_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_requirements_campaign_id ON public.campaign_requirements USING btree (campaign_id);


--
-- Name: idx_campaign_requirements_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_requirements_command_id ON public.campaign_requirements USING btree (command_id);


--
-- Name: idx_campaign_requirements_requirement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_requirements_requirement_id ON public.campaign_requirements USING btree (requirement_id);


--
-- Name: idx_campaign_segments_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_segments_command_id_new ON public.campaign_segments USING btree (command_id);


--
-- Name: idx_campaign_segments_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_segments_segment_id ON public.campaign_segments USING btree (segment_id);


--
-- Name: idx_campaign_subtasks_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_subtasks_campaign_id ON public.campaign_subtasks USING btree (campaign_id);


--
-- Name: idx_campaign_subtasks_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_subtasks_command_id_new ON public.campaign_subtasks USING btree (command_id);


--
-- Name: idx_campaigns_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_command_id ON public.campaigns USING btree (command_id);


--
-- Name: idx_campaigns_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_site_id ON public.campaigns USING btree (site_id);


--
-- Name: idx_campaigns_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_status ON public.campaigns USING btree (status);


--
-- Name: idx_campaigns_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_user_id ON public.campaigns USING btree (user_id);


--
-- Name: idx_catalog_categories_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_categories_site ON public.catalog_categories USING btree (site_id);


--
-- Name: idx_catalog_categories_site_sort_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_categories_site_sort_order ON public.catalog_categories USING btree (site_id, sort_order);


--
-- Name: idx_catalog_item_modifier_groups_host; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_modifier_groups_host ON public.catalog_item_modifier_groups USING btree (catalog_item_id);


--
-- Name: idx_catalog_item_modifier_groups_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_modifier_groups_site ON public.catalog_item_modifier_groups USING btree (site_id);


--
-- Name: idx_catalog_item_requirements_instance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_requirements_instance ON public.catalog_item_requirements USING btree (instance_id);


--
-- Name: idx_catalog_item_requirements_requirement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_requirements_requirement ON public.catalog_item_requirements USING btree (requirement_id);


--
-- Name: idx_catalog_item_requirements_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_requirements_site ON public.catalog_item_requirements USING btree (site_id);


--
-- Name: idx_catalog_item_specs_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_specs_item ON public.catalog_item_specs USING btree (catalog_item_id);


--
-- Name: idx_catalog_item_specs_spec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_specs_spec ON public.catalog_item_specs USING btree (item_spec_id);


--
-- Name: idx_catalog_item_taxes_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_taxes_item ON public.catalog_item_taxes USING btree (catalog_item_id);


--
-- Name: idx_catalog_item_taxes_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_taxes_site ON public.catalog_item_taxes USING btree (site_id);


--
-- Name: idx_catalog_item_taxes_tax; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_item_taxes_tax ON public.catalog_item_taxes USING btree (tax_id);


--
-- Name: idx_catalog_items_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_items_parent_id ON public.catalog_items USING btree (site_id, parent_id);


--
-- Name: idx_catalog_items_site_availability; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_items_site_availability ON public.catalog_items USING btree (site_id, availability_status);


--
-- Name: idx_catalog_items_site_dynamic_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_items_site_dynamic_price ON public.catalog_items USING btree (site_id, is_dynamic_price) WHERE (is_dynamic_price = true);


--
-- Name: idx_catalog_items_site_kind_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_items_site_kind_status ON public.catalog_items USING btree (site_id, kind, status);


--
-- Name: idx_catalog_items_site_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_items_site_name ON public.catalog_items USING btree (site_id, name);


--
-- Name: idx_catalog_items_site_sku; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_catalog_items_site_sku ON public.catalog_items USING btree (site_id, sku) WHERE (sku IS NOT NULL);


--
-- Name: idx_catalog_items_site_sort_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_catalog_items_site_sort_order ON public.catalog_items USING btree (site_id, sort_order);


--
-- Name: idx_categories_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_site_id ON public.categories USING btree (site_id);


--
-- Name: idx_categories_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_user_id ON public.categories USING btree (user_id);


--
-- Name: idx_commands_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commands_agent_id ON public.commands USING btree (agent_id);
