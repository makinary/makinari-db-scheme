SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: accounting_accounts_site_key_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounting_accounts_site_key_unique ON public.accounting_accounts USING btree (site_id, key) WHERE (key IS NOT NULL);


--
-- Name: accounting_sale_refunds_sale_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accounting_sale_refunds_sale_lookup ON public.accounting_sale_refunds USING btree (site_id, sale_id);


--
-- Name: allowed_domains_domain_lookup_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX allowed_domains_domain_lookup_idx ON public.allowed_domains USING btree (domain);


--
-- Name: allowed_domains_domain_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX allowed_domains_domain_trgm_idx ON public.allowed_domains USING gin (domain extensions.gin_trgm_ops);


--
-- Name: allowed_domains_requirement_site_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX allowed_domains_requirement_site_idx ON public.allowed_domains USING btree (requirement_id, site_id) WHERE (requirement_id IS NOT NULL);


--
-- Name: analysis_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX analysis_user_id_idx ON public.analysis USING btree (user_id);


--
-- Name: api_keys_lookup_hash_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX api_keys_lookup_hash_unique ON public.api_keys USING btree (lookup_hash) WHERE (lookup_hash IS NOT NULL);


--
-- Name: appointments_context_site_start_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_context_site_start_idx ON public.appointments USING btree (context_id, site_id, start_datetime);


--
-- Name: appointments_site_start_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appointments_site_start_idx ON public.appointments USING btree (site_id, start_datetime);


--
-- Name: apps_tenants_requirement_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX apps_tenants_requirement_unique ON public.apps_tenants USING btree (requirement_id);


--
-- Name: apps_tenants_site_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX apps_tenants_site_idx ON public.apps_tenants USING btree (site_id);


--
-- Name: billing_site_id_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX billing_site_id_uidx ON public.billing USING btree (site_id);


--
-- Name: catalog_categories_site_import_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_categories_site_import_name_idx ON public.catalog_categories USING btree (site_id, public.catalog_import_category_key(name)) WHERE (status = 'active'::text);


--
-- Name: catalog_embedding_jobs_expired_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_embedding_jobs_expired_idx ON public.catalog_embedding_jobs USING btree (lease_expires_at, id) WHERE (status = 'leased'::text);


--
-- Name: catalog_embedding_jobs_ready_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_embedding_jobs_ready_idx ON public.catalog_embedding_jobs USING btree (next_attempt_at, id) WHERE (status = ANY (ARRAY['pending'::text, 'retry'::text]));


--
-- Name: catalog_items_name_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_items_name_trgm_idx ON public.catalog_items USING gin (name extensions.gin_trgm_ops);


--
-- Name: catalog_items_site_status_created_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_items_site_status_created_id_idx ON public.catalog_items USING btree (site_id, status, created_at DESC, id);


--
-- Name: catalog_items_site_status_display_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_items_site_status_display_id_idx ON public.catalog_items USING btree (site_id, status, sort_order, created_at DESC, id);


--
-- Name: catalog_items_site_status_updated_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_items_site_status_updated_id_idx ON public.catalog_items USING btree (site_id, status, updated_at DESC, id);


--
-- Name: catalog_items_sku_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_items_sku_trgm_idx ON public.catalog_items USING gin (sku extensions.gin_trgm_ops) WHERE (sku IS NOT NULL);


--
-- Name: catalog_search_documents_fts_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_search_documents_fts_idx ON public.catalog_search_documents USING gin (search_tsv);


--
-- Name: catalog_search_documents_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_search_documents_name_idx ON public.catalog_search_documents USING btree (md5(lower(name_text)));


--
-- Name: catalog_search_documents_site_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_search_documents_site_idx ON public.catalog_search_documents USING btree (site_id, catalog_item_id);


--
-- Name: catalog_search_documents_sku_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_search_documents_sku_idx ON public.catalog_search_documents USING btree (md5(lower(sku_text)));


--
-- Name: catalog_search_documents_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_search_documents_trgm_idx ON public.catalog_search_documents USING gin (document_text extensions.gin_trgm_ops);


--
-- Name: catalog_search_documents_vector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_search_documents_vector_idx ON public.catalog_search_documents USING hnsw (embedding public.vector_cosine_ops) WHERE ((embedding IS NOT NULL) AND (embedding_model = 'openai/text-embedding-3-small'::text) AND (embedding_source_hash = source_hash));


--
-- Name: catalog_search_revision_events_site_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX catalog_search_revision_events_site_idx ON public.catalog_search_revision_events USING btree (site_id, id);


--
-- Name: channel_health_events_recent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX channel_health_events_recent_idx ON public.channel_health_events USING btree (site_id, channel, direction, observed_at DESC);


--
-- Name: content_assets_content_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_assets_content_id_idx ON public.content_assets USING btree (content_id);


--
-- Name: content_outstand_hash_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_outstand_hash_idx ON public.content USING btree (site_id, ((metadata ->> 'source_content_hash'::text)), created_at) WHERE (metadata ? 'source_content_hash'::text);


--
-- Name: content_outstand_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_outstand_tags_idx ON public.content USING gin (tags) WHERE (tags IS NOT NULL);


--
-- Name: content_performance_content_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_performance_content_id_idx ON public.content_performance USING btree (content_id);


--
-- Name: content_performance_fetched_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_performance_fetched_at_idx ON public.content_performance USING btree (fetched_at);


--
-- Name: content_performance_site_fetched_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_performance_site_fetched_at_idx ON public.content_performance USING btree (site_id, fetched_at DESC);


--
-- Name: content_performance_site_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_performance_site_id_idx ON public.content_performance USING btree (site_id);


--
-- Name: content_performance_site_post_fetch_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_performance_site_post_fetch_idx ON public.content_performance USING btree (site_id, outstand_post_id, fetched_at);


--
-- Name: content_public_search_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_public_search_idx ON public.content USING gin (public_search) WHERE (status = 'published'::text);


--
-- Name: content_public_site_type_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_public_site_type_created_idx ON public.content USING btree (site_id, type, created_at DESC) WHERE (status = 'published'::text);


--
-- Name: content_social_analytics_due_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX content_social_analytics_due_idx ON public.content USING btree (site_id, published_at) WHERE ((tags IS NOT NULL) AND ((status = 'published'::text) OR (published_at IS NOT NULL)));


--
-- Name: conversations_outstand_dm_id_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX conversations_outstand_dm_id_uidx ON public.conversations USING btree (site_id, ((custom_data ->> 'outstand_conversation_id'::text))) WHERE ((channel = 'instagram'::text) AND ((custom_data ->> 'source'::text) = 'outstand_dm'::text) AND ((custom_data ->> 'outstand_conversation_id'::text) IS NOT NULL));


--
-- Name: credit_auto_top_up_consent_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_auto_top_up_consent_site ON public.credit_auto_top_up_consent_log USING btree (site_id, recorded_at DESC);


--
-- Name: credit_auto_top_up_enabled_sites; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_auto_top_up_enabled_sites ON public.credit_auto_top_up_settings USING btree (site_id) WHERE (enabled AND (state = 'ready'::text));


--
-- Name: credit_auto_top_up_latest_site_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_auto_top_up_latest_site_attempt ON public.credit_auto_top_up_attempts USING btree (site_id, created_at DESC);


--
-- Name: credit_auto_top_up_monthly_spend; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_auto_top_up_monthly_spend ON public.credit_auto_top_up_attempts USING btree (site_id, created_at) WHERE (status = ANY (ARRAY['pending'::text, 'succeeded'::text]));


--
-- Name: credit_auto_top_up_one_pending_per_site; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX credit_auto_top_up_one_pending_per_site ON public.credit_auto_top_up_attempts USING btree (site_id) WHERE (status = 'pending'::text);


--
-- Name: credit_auto_top_up_pending_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_auto_top_up_pending_due ON public.credit_auto_top_up_attempts USING btree (claim_expires_at, created_at, site_id) WHERE (status = 'pending'::text);


--
-- Name: credit_auto_top_up_settled_spend; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_auto_top_up_settled_spend ON public.credit_auto_top_up_attempts USING btree (site_id, finished_at) WHERE (status = 'succeeded'::text);


--
-- Name: credit_transactions_requirement_cost_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_transactions_requirement_cost_idx ON public.credit_transactions USING btree (site_id, ((metadata ->> 'requirement_id'::text))) INCLUDE (amount) WHERE ((transaction_type)::text <> ALL ((ARRAY['sandbox_usage'::character varying, 'agent_model_reservation'::character varying, 'agent_model_refund'::character varying, 'agent_model_refund_expired'::character varying, 'agent_model_settlement'::character varying, 'agent_model_actual_cost'::character varying])::text[]));


--
-- Name: credit_transactions_session_cost_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX credit_transactions_session_cost_idx ON public.credit_transactions USING btree (site_id, ((metadata ->> 'session_id'::text))) WHERE ((transaction_type)::text <> ALL ((ARRAY['sandbox_usage'::character varying, 'agent_model_reservation'::character varying, 'agent_model_refund'::character varying, 'agent_model_refund_expired'::character varying, 'agent_model_settlement'::character varying, 'agent_model_actual_cost'::character varying])::text[]));


--
-- Name: cron_status_running_updated_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cron_status_running_updated_idx ON public.cron_status USING btree (updated_at) WHERE (status = 'RUNNING'::text);


--
-- Name: cron_status_site_activity_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cron_status_site_activity_uidx ON public.cron_status USING btree (site_id, activity_name);


--
-- Name: harness_model_generation_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX harness_model_generation_once ON public.harness_model_credit_reservations USING btree (generation_id) WHERE (generation_id IS NOT NULL);


--
-- Name: harness_model_one_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX harness_model_one_pending ON public.harness_model_credit_reservations USING btree (session_id) WHERE (state = ANY (ARRAY['reserved'::text, 'dispatched'::text, 'pending'::text]));


--
-- Name: harness_model_requirement_cost_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX harness_model_requirement_cost_idx ON public.harness_model_credit_reservations USING btree (site_id, requirement_id) INCLUDE (state, charged);


--
-- Name: harness_requirement_model_one_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX harness_requirement_model_one_pending ON public.harness_model_credit_reservations USING btree (requirement_id) WHERE ((requirement_id IS NOT NULL) AND (state = ANY (ARRAY['reserved'::text, 'dispatched'::text, 'pending'::text])));


--
-- Name: harness_sessions_active_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX harness_sessions_active_profile ON public.harness_sessions USING btree (site_id, ((snapshot #>> '{request,profile}'::text[]))) WHERE (((snapshot #>> '{request,profile}'::text[]) IS NOT NULL) AND ((snapshot ->> 'status'::text) <> ALL (ARRAY['completed'::text, 'cancelled'::text])));


--
-- Name: harness_sessions_requirement_cost_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX harness_sessions_requirement_cost_idx ON public.harness_sessions USING btree (site_id, ((snapshot #>> '{request,requirementId}'::text[]))) INCLUDE (id);


--
-- Name: harness_sessions_site_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX harness_sessions_site_idx ON public.harness_sessions USING btree (site_id, id);


--
-- Name: icp_dispatch_list_state_site; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX icp_dispatch_list_state_site ON public.icp_dispatch_list_state USING btree (site_id);


--
-- Name: icp_dispatch_runs_budget_day; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX icp_dispatch_runs_budget_day ON public.icp_dispatch_runs USING btree (budget_day);


--
-- Name: icp_dispatch_runs_one_active_site; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX icp_dispatch_runs_one_active_site ON public.icp_dispatch_runs USING btree (site_id) WHERE (state = ANY (ARRAY['reserved'::text, 'running'::text, 'blocked'::text]));


--
-- Name: icp_dispatch_runs_site_budget_day; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX icp_dispatch_runs_site_budget_day ON public.icp_dispatch_runs USING btree (site_id, budget_day);


--
-- Name: idx_activity_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_active ON public.activity USING btree (site_id, workflow_type, status) WHERE ((status)::text = ANY (ARRAY[('STARTED'::character varying)::text, ('RUNNING'::character varying)::text]));


--
-- Name: idx_activity_auth_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_auth_context ON public.activity USING btree (site_id, created_at DESC);


--
-- Name: idx_activity_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_schedule_id ON public.activity USING btree (schedule_id) WHERE (schedule_id IS NOT NULL);


--
-- Name: idx_activity_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_site_id ON public.activity USING btree (site_id);


--
-- Name: idx_activity_site_workflow_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_site_workflow_type ON public.activity USING btree (site_id, workflow_type);


--
-- Name: idx_activity_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_started_at ON public.activity USING btree (started_at);


--
-- Name: idx_activity_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_status ON public.activity USING btree (status);


--
-- Name: idx_activity_workflow_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_workflow_id ON public.activity USING btree (workflow_id);
