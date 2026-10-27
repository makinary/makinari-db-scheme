SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: idx_requirements_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_priority ON public.requirements USING btree (priority);


--
-- Name: idx_requirements_site_completion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_site_completion ON public.requirements USING btree (site_id, completion_status);


--
-- Name: idx_requirements_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_site_id ON public.requirements USING btree (site_id);


--
-- Name: idx_requirements_site_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_site_priority ON public.requirements USING btree (site_id, priority);


--
-- Name: idx_requirements_site_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_site_status ON public.requirements USING btree (site_id, status);


--
-- Name: idx_requirements_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_status ON public.requirements USING btree (status);


--
-- Name: idx_requirements_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_type ON public.requirements USING btree (type);


--
-- Name: idx_requirements_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requirements_user_id ON public.requirements USING btree (user_id);


--
-- Name: idx_reservation_schedules_catalog_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_schedules_catalog_item_id ON public.reservation_schedules USING btree (catalog_item_id);


--
-- Name: idx_reservation_schedules_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_schedules_site_id ON public.reservation_schedules USING btree (site_id);


--
-- Name: idx_reservations_assignee_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_assignee_user_id ON public.reservations USING btree (assignee_user_id);


--
-- Name: idx_reservations_catalog_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_catalog_item_id ON public.reservations USING btree (catalog_item_id);


--
-- Name: idx_reservations_catalog_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_catalog_time ON public.reservations USING btree (catalog_item_id, start_time, end_time);


--
-- Name: idx_reservations_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_channel ON public.reservations USING btree (site_id, channel);


--
-- Name: idx_reservations_entitlement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_entitlement_id ON public.reservations USING btree (entitlement_id);


--
-- Name: idx_reservations_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_lead_id ON public.reservations USING btree (lead_id);


--
-- Name: idx_reservations_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_location_id ON public.reservations USING btree (location_id);


--
-- Name: idx_reservations_site_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_site_status ON public.reservations USING btree (site_id, status);


--
-- Name: idx_reservations_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservations_start_time ON public.reservations USING btree (start_time);


--
-- Name: idx_role_queries_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_queries_created_at ON public.role_queries USING btree (created_at);


--
-- Name: idx_role_queries_query_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_queries_query_gin ON public.role_queries USING gin (query);


--
-- Name: idx_role_queries_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_queries_status ON public.role_queries USING btree (status);


--
-- Name: idx_rqs_role_query_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rqs_role_query_id ON public.role_query_segments USING btree (role_query_id);


--
-- Name: idx_rqs_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rqs_segment_id ON public.role_query_segments USING btree (segment_id);


--
-- Name: idx_sale_order_items_order_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_order_items_order_status ON public.sale_order_items USING btree (sale_order_id, status);


--
-- Name: idx_sale_order_items_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_order_items_parent ON public.sale_order_items USING btree (sale_order_id, parent_sale_order_item_id);


--
-- Name: idx_sale_order_items_shipment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_order_items_shipment_id ON public.sale_order_items USING btree (shipment_id);


--
-- Name: idx_sale_orders_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_orders_sale_id ON public.sale_orders USING btree (sale_id);


--
-- Name: idx_sale_orders_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_orders_site_id ON public.sale_orders USING btree (site_id);


--
-- Name: idx_sales_accounting_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_accounting_state ON public.sales USING btree (site_id, accounting_state);


--
-- Name: idx_sales_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_campaign_id ON public.sales USING btree (campaign_id);


--
-- Name: idx_sales_command_id_new; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_command_id_new ON public.sales USING btree (command_id);


--
-- Name: idx_sales_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_company ON public.sales USING btree (company_id);


--
-- Name: idx_sales_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_lead_id ON public.sales USING btree (lead_id);


--
-- Name: idx_sales_lead_id_not_null; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_lead_id_not_null ON public.sales USING btree (lead_id) WHERE (lead_id IS NOT NULL);


--
-- Name: idx_sales_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_location_id ON public.sales USING btree (location_id);


--
-- Name: idx_sales_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_segment_id ON public.sales USING btree (segment_id);


--
-- Name: idx_sales_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_site_id ON public.sales USING btree (site_id);


--
-- Name: idx_sales_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_status ON public.sales USING btree (status);


--
-- Name: idx_sales_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_user_id ON public.sales USING btree (user_id);


--
-- Name: idx_sections_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sections_site_id ON public.sections USING btree (site_id);


--
-- Name: idx_sections_site_id_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sections_site_id_order ON public.sections USING btree (site_id, "order");


--
-- Name: idx_segments_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_segments_command_id ON public.segments USING btree (command_id);


--
-- Name: idx_segments_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_segments_site_id ON public.segments USING btree (site_id);


--
-- Name: idx_segments_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_segments_user_id ON public.segments USING btree (user_id);


--
-- Name: idx_session_events_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_command_id ON public.session_events USING btree (command_id);


--
-- Name: idx_session_events_recording_ordered; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_recording_ordered ON public.session_events USING btree (session_id, created_at, id) WHERE ((event_type = 'session_recording'::text) AND (session_id IS NOT NULL));


--
-- Name: idx_session_events_retention_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_retention_created_at ON public.session_events USING btree (created_at, id);


--
-- Name: idx_session_events_segment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_segment_id ON public.session_events USING btree (segment_id);


--
-- Name: idx_session_events_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_session_id ON public.session_events USING btree (session_id);


--
-- Name: idx_session_events_site_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_site_date ON public.session_events USING btree (site_id, event_type, created_at);


--
-- Name: idx_session_events_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_site_id ON public.session_events USING btree (site_id);


--
-- Name: idx_session_events_site_type_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_site_type_date ON public.session_events USING btree (site_id, event_type, created_at DESC);


--
-- Name: idx_session_events_visitor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_events_visitor_id ON public.session_events USING btree (visitor_id);


--
-- Name: idx_session_recording_chunks_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_recording_chunks_event ON public.session_recording_chunks USING btree (recording_event_id);


--
-- Name: idx_session_recording_chunks_session_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_session_recording_chunks_session_time ON public.session_recording_chunks USING btree (session_id, chunk_timestamp, chunk_id);


--
-- Name: idx_settings_command_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settings_command_id ON public.settings USING btree (command_id);


--
-- Name: idx_shipment_location_pings_shipment_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipment_location_pings_shipment_time ON public.shipment_location_pings USING btree (shipment_id, recorded_at DESC);


--
-- Name: idx_shipments_assigned_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipments_assigned_to ON public.shipments USING btree (site_id, assigned_to);


--
-- Name: idx_shipments_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipments_lead_id ON public.shipments USING btree (lead_id);


--
-- Name: idx_shipments_sale_order_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipments_sale_order_id ON public.shipments USING btree (sale_order_id);


--
-- Name: idx_shipments_site_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipments_site_created_at ON public.shipments USING btree (site_id, created_at DESC);


--
-- Name: idx_shipments_site_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipments_site_status ON public.shipments USING btree (site_id, status);


--
-- Name: idx_shipments_tracking_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipments_tracking_number ON public.shipments USING btree (tracking_number) WHERE (tracking_number IS NOT NULL);


--
-- Name: idx_site_members_added_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_added_by ON public.site_members USING btree (added_by);


--
-- Name: idx_site_members_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_email ON public.site_members USING btree (email);


--
-- Name: idx_site_members_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_role ON public.site_members USING btree (role);


--
-- Name: idx_site_members_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_site_id ON public.site_members USING btree (site_id);


--
-- Name: idx_site_members_site_user_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_site_user_status ON public.site_members USING btree (site_id, user_id, status) WHERE (status = 'active'::text);


--
-- Name: idx_site_members_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_members_user_id ON public.site_members USING btree (user_id);
