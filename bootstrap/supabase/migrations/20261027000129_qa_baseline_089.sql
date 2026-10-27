SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: idx_commands_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commands_created_at ON public.commands USING btree (created_at);


--
-- Name: idx_commands_performance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commands_performance ON public.commands USING btree (performance);


--
-- Name: idx_commands_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commands_site_id ON public.commands USING btree (site_id);


--
-- Name: idx_commands_site_user_composite; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commands_site_user_composite ON public.commands USING btree (site_id, user_id);


--
-- Name: idx_commands_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commands_status ON public.commands USING btree (status);


--
-- Name: idx_commands_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commands_user_id ON public.commands USING btree (user_id);


--
-- Name: idx_companies_acquired_by_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_companies_acquired_by_id_new ON public.companies USING btree (acquired_by_id);


--
-- Name: idx_companies_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_companies_name ON public.companies USING gin (name extensions.gin_trgm_ops);


--
-- Name: idx_companies_parent_company_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_companies_parent_company_id_new ON public.companies USING btree (parent_company_id);


--
-- Name: idx_content_assets_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_assets_asset_id ON public.content_assets USING btree (asset_id);


--
-- Name: idx_content_assets_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_assets_content_id ON public.content_assets USING btree (content_id);


--
-- Name: idx_content_assets_content_id_rls; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_assets_content_id_rls ON public.content_assets USING btree (content_id);


--
-- Name: idx_content_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_author_id ON public.content USING btree (author_id);


--
-- Name: idx_content_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_campaign_id ON public.content USING btree (campaign_id);


--
-- Name: idx_content_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_command_id ON public.content USING btree (command_id);


--
-- Name: idx_content_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_segment_id ON public.content USING btree (segment_id);


--
-- Name: idx_content_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_site_id ON public.content USING btree (site_id);


--
-- Name: idx_content_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_content_user_id ON public.content USING btree (user_id);


--
-- Name: idx_conversations_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_agent_id ON public.conversations USING btree (agent_id);


--
-- Name: idx_conversations_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_command_id ON public.conversations USING btree (command_id);


--
-- Name: idx_conversations_delegate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_delegate_id ON public.conversations USING btree (delegate_id);


--
-- Name: idx_conversations_id_optimized; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_id_optimized ON public.conversations USING btree (id) WHERE (last_message_at IS NOT NULL);


--
-- Name: idx_conversations_last_message_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_last_message_at ON public.conversations USING btree (last_message_at);


--
-- Name: idx_conversations_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_lead_id ON public.conversations USING btree (lead_id);


--
-- Name: idx_conversations_non_pending_site_activity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_non_pending_site_activity ON public.conversations USING btree (site_id, last_message_at DESC NULLS LAST, created_at DESC) WHERE ((is_archived = false) AND (status <> 'pending'::text));


--
-- Name: idx_conversations_pending_site_activity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_pending_site_activity ON public.conversations USING btree (site_id, last_message_at DESC NULLS LAST, created_at DESC) WHERE ((is_archived = false) AND (status = 'pending'::text));


--
-- Name: idx_conversations_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_site_id ON public.conversations USING btree (site_id);


--
-- Name: idx_conversations_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_user_id ON public.conversations USING btree (user_id);


--
-- Name: idx_conversations_visitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_visitor_id ON public.conversations USING btree (visitor_id);


--
-- Name: idx_copywriting_copy_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_copy_type ON public.copywriting USING btree (copy_type);


--
-- Name: idx_copywriting_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_created_at ON public.copywriting USING btree (created_at DESC);


--
-- Name: idx_copywriting_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_site_id ON public.copywriting USING btree (site_id);


--
-- Name: idx_copywriting_site_type_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_site_type_status ON public.copywriting USING btree (site_id, copy_type, status);


--
-- Name: idx_copywriting_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_status ON public.copywriting USING btree (status);


--
-- Name: idx_copywriting_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_tags ON public.copywriting USING gin (tags);


--
-- Name: idx_copywriting_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_user_id ON public.copywriting USING btree (user_id);


--
-- Name: idx_copywriting_user_type_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_copywriting_user_type_created ON public.copywriting USING btree (user_id, copy_type, created_at DESC);


--
-- Name: idx_credit_transactions_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_credit_transactions_site_id ON public.credit_transactions USING btree (site_id);


--
-- Name: idx_cron_status_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cron_status_site_id ON public.cron_status USING btree (site_id);


--
-- Name: idx_customizations_element_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customizations_element_id ON public.customizations USING btree (element_id);


--
-- Name: idx_debug_logs_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_debug_logs_command_id_new ON public.debug_logs USING btree (command_id);


--
-- Name: idx_editor_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_editor_site_id ON public.editor USING btree (site_id);


--
-- Name: idx_elements_layer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_elements_layer_id ON public.elements USING btree (layer_id);


--
-- Name: idx_experiment_segments_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiment_segments_command_id_new ON public.experiment_segments USING btree (command_id);


--
-- Name: idx_experiment_segments_exp_seg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiment_segments_exp_seg ON public.experiment_segments USING btree (experiment_id, segment_id);


--
-- Name: idx_experiment_segments_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiment_segments_experiment_id ON public.experiment_segments USING btree (experiment_id);


--
-- Name: idx_experiment_segments_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiment_segments_segment_id ON public.experiment_segments USING btree (segment_id);


--
-- Name: idx_experiments_campaign_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiments_campaign_id_new ON public.experiments USING btree (campaign_id);


--
-- Name: idx_experiments_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiments_command_id_new ON public.experiments USING btree (command_id);


--
-- Name: idx_experiments_id_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiments_id_site_id ON public.experiments USING btree (id, site_id);


--
-- Name: idx_experiments_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiments_site_id ON public.experiments USING btree (site_id);


--
-- Name: idx_experiments_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_experiments_user_id ON public.experiments USING btree (user_id);


--
-- Name: idx_external_resources_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_resources_command_id ON public.external_resources USING btree (command_id);


--
-- Name: idx_external_resources_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_resources_site_id ON public.external_resources USING btree (site_id);


--
-- Name: idx_external_resources_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_resources_user_id ON public.external_resources USING btree (user_id);


--
-- Name: idx_icp_mining_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_icp_mining_created_at ON public.icp_mining USING btree (created_at);


--
-- Name: idx_icp_mining_icp_criteria_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_icp_mining_icp_criteria_gin ON public.icp_mining USING gin (icp_criteria);


--
-- Name: idx_icp_mining_last_progress_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_icp_mining_last_progress_at ON public.icp_mining USING btree (last_progress_at);


--
-- Name: idx_icp_mining_role_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_icp_mining_role_query_id ON public.icp_mining USING btree (role_query_id);


--
-- Name: idx_icp_mining_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_icp_mining_status ON public.icp_mining USING btree (status);


--
-- Name: idx_instance_artifacts_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_artifacts_instance_id ON public.instance_artifacts USING btree (instance_id);


--
-- Name: idx_instance_artifacts_site_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_artifacts_site_created ON public.instance_artifacts USING btree (site_id, created_at DESC);


--
-- Name: idx_instance_logs_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_agent_id ON public.instance_logs USING btree (agent_id);


--
-- Name: idx_instance_logs_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_command_id ON public.instance_logs USING btree (command_id);


--
-- Name: idx_instance_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_created_at ON public.instance_logs USING btree (created_at);


--
-- Name: idx_instance_logs_instance_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_instance_created_at ON public.instance_logs USING btree (instance_id, created_at DESC);


--
-- Name: idx_instance_logs_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_instance_id ON public.instance_logs USING btree (instance_id);


--
-- Name: idx_instance_logs_is_error; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_is_error ON public.instance_logs USING btree (is_error);


--
-- Name: idx_instance_logs_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_level ON public.instance_logs USING btree (level);


--
-- Name: idx_instance_logs_log_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instance_logs_log_type ON public.instance_logs USING btree (log_type);
