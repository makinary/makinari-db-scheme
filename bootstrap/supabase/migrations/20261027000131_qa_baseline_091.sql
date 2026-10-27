SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: idx_modifier_groups_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_modifier_groups_site_id ON public.modifier_groups USING btree (site_id);


--
-- Name: idx_notifications_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_command_id ON public.notifications USING btree (command_id);


--
-- Name: idx_notifications_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_site_id ON public.notifications USING btree (site_id);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_pass_redeemable_items_pass_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pass_redeemable_items_pass_id ON public.pass_redeemable_items USING btree (pass_catalog_item_id);


--
-- Name: idx_pass_redeemable_items_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pass_redeemable_items_site_id ON public.pass_redeemable_items USING btree (site_id);


--
-- Name: idx_pass_round_robin_state_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pass_round_robin_state_site_id ON public.pass_round_robin_state USING btree (site_id);


--
-- Name: idx_payments_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_command_id ON public.payments USING btree (command_id);


--
-- Name: idx_payments_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payments_site_id ON public.payments USING btree (site_id);


--
-- Name: idx_persons_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_persons_company ON public.persons USING btree (company_name);


--
-- Name: idx_persons_current; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_persons_current ON public.persons USING btree (is_current);


--
-- Name: idx_persons_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_persons_name ON public.persons USING btree (full_name);


--
-- Name: idx_persons_raw_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_persons_raw_gin ON public.persons USING gin (raw_result);


--
-- Name: idx_persons_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_persons_role ON public.persons USING btree (role_title);


--
-- Name: idx_persons_role_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_persons_role_query_id ON public.persons USING btree (role_query_id);


--
-- Name: idx_pos_client_mutations_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pos_client_mutations_site ON public.pos_client_mutations USING btree (site_id);


--
-- Name: idx_price_lists_channels; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_lists_channels ON public.price_lists USING gin (channels);


--
-- Name: idx_price_lists_site_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_price_lists_site_active ON public.price_lists USING btree (site_id, is_active);


--
-- Name: idx_price_lists_site_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_price_lists_site_default ON public.price_lists USING btree (site_id) WHERE (is_default = true);


--
-- Name: idx_profiles_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_command_id_new ON public.profiles USING btree (command_id);


--
-- Name: idx_promotion_required_categories_promotion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotion_required_categories_promotion_id ON public.promotion_required_categories USING btree (promotion_id);


--
-- Name: idx_promotion_required_categories_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotion_required_categories_site_id ON public.promotion_required_categories USING btree (site_id);


--
-- Name: idx_promotion_required_items_promotion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotion_required_items_promotion_id ON public.promotion_required_items USING btree (promotion_id);


--
-- Name: idx_promotion_required_items_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotion_required_items_site_id ON public.promotion_required_items USING btree (site_id);


--
-- Name: idx_promotions_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotions_campaign_id ON public.promotions USING btree (campaign_id);


--
-- Name: idx_promotions_channels; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotions_channels ON public.promotions USING gin (channels);


--
-- Name: idx_promotions_location_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotions_location_ids ON public.promotions USING gin (location_ids);


--
-- Name: idx_promotions_site_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_promotions_site_code ON public.promotions USING btree (site_id, code) WHERE (code IS NOT NULL);


--
-- Name: idx_promotions_site_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_promotions_site_status ON public.promotions USING btree (site_id, status);


--
-- Name: idx_purchase_items_purchase_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_items_purchase_id ON public.purchase_items USING btree (purchase_id);


--
-- Name: idx_purchase_items_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_items_site_id ON public.purchase_items USING btree (site_id);


--
-- Name: idx_purchases_site_accounting_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchases_site_accounting_state ON public.purchases USING btree (site_id, accounting_state);


--
-- Name: idx_purchases_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchases_site_id ON public.purchases USING btree (site_id);


--
-- Name: idx_purchases_vendor_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchases_vendor_company_id ON public.purchases USING btree (vendor_company_id);


--
-- Name: idx_record_categories_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_categories_site_id ON public.record_categories USING btree (site_id);


--
-- Name: idx_record_diagram_edges_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_diagram_edges_record ON public.record_diagram_edges USING btree (record_id);


--
-- Name: idx_record_diagram_edges_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_diagram_edges_source ON public.record_diagram_edges USING btree (source_node_id);


--
-- Name: idx_record_diagram_edges_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_diagram_edges_target ON public.record_diagram_edges USING btree (target_node_id);


--
-- Name: idx_record_diagram_nodes_embedding_hnsw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_diagram_nodes_embedding_hnsw ON public.record_diagram_nodes USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_record_diagram_nodes_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_diagram_nodes_record ON public.record_diagram_nodes USING btree (record_id);


--
-- Name: idx_record_diagram_nodes_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_diagram_nodes_site ON public.record_diagram_nodes USING btree (site_id);


--
-- Name: idx_record_embedding_jobs_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_record_embedding_jobs_pending ON public.record_embedding_jobs USING btree (status, created_at) WHERE (status = ANY (ARRAY['pending'::text, 'failed'::text]));


--
-- Name: idx_records_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_records_category_id ON public.records USING btree (category_id);


--
-- Name: idx_records_embedding_hnsw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_records_embedding_hnsw ON public.records USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: idx_records_relations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_records_relations ON public.records USING gin (relations);


--
-- Name: idx_records_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_records_site_id ON public.records USING btree (site_id);


--
-- Name: idx_referral_code_uses_code_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_code_uses_code_id ON public.referral_code_uses USING btree (referral_code_id);


--
-- Name: idx_referral_code_uses_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_code_uses_user_id ON public.referral_code_uses USING btree (user_id);


--
-- Name: idx_referral_codes_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_codes_code ON public.referral_codes USING btree (code);


--
-- Name: idx_referral_codes_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_referral_codes_created_by ON public.referral_codes USING btree (created_by);


--
-- Name: idx_remote_instances_agent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_agent_id ON public.remote_instances USING btree (agent_id);


--
-- Name: idx_remote_instances_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_command_id ON public.remote_instances USING btree (command_id);


--
-- Name: idx_remote_instances_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_created_at ON public.remote_instances USING btree (created_at);


--
-- Name: idx_remote_instances_instance_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_instance_type ON public.remote_instances USING btree (instance_type);


--
-- Name: idx_remote_instances_last_activity_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_last_activity_at ON public.remote_instances USING btree (last_activity_at);


--
-- Name: idx_remote_instances_provider_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_provider_instance_id ON public.remote_instances USING btree (provider_instance_id);


--
-- Name: idx_remote_instances_site_active_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_site_active_updated ON public.remote_instances USING btree (site_id, updated_at DESC) WHERE (is_archived = false);


--
-- Name: idx_remote_instances_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_site_id ON public.remote_instances USING btree (site_id);


--
-- Name: idx_remote_instances_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_status ON public.remote_instances USING btree (status);


--
-- Name: idx_remote_instances_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_instances_user_id ON public.remote_instances USING btree (user_id);


--
-- Name: idx_remote_sessions_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_remote_sessions_instance_id ON public.remote_sessions USING btree (instance_id);


--
-- Name: idx_req_status_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_req_status_instance_id ON public.requirement_status USING btree (instance_id);


--
-- Name: idx_req_status_requirement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_req_status_requirement_id ON public.requirement_status USING btree (requirement_id);


--
-- Name: idx_req_status_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_req_status_site_id ON public.requirement_status USING btree (site_id);


--
-- Name: idx_requirement_segments_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirement_segments_command_id_new ON public.requirement_segments USING btree (command_id);


--
-- Name: idx_requirement_segments_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirement_segments_segment_id ON public.requirement_segments USING btree (segment_id);


--
-- Name: idx_requirements_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_command_id ON public.requirements USING btree (command_id);


--
-- Name: idx_requirements_completion_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_completion_status ON public.requirements USING btree (completion_status);


--
-- Name: idx_requirements_cron_lock_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_cron_lock_expires_at ON public.requirements USING btree (cron_lock_expires_at) WHERE (cron_lock_expires_at IS NOT NULL);


--
-- Name: idx_requirements_metadata_git; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_metadata_git ON public.requirements USING gin (((metadata -> 'git'::text)));
