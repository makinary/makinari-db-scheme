SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: marketplace_webhook_registration_apps marketplace_webhook_app_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_webhook_app_binding BEFORE INSERT OR UPDATE ON public.marketplace_webhook_registration_apps FOR EACH ROW EXECUTE FUNCTION public.validate_marketplace_webhook_app_lease();


--
-- Name: marketplace_provider_webhook_keys marketplace_webhook_key_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_webhook_key_binding BEFORE INSERT OR UPDATE ON public.marketplace_provider_webhook_keys FOR EACH ROW EXECUTE FUNCTION public.validate_marketplace_consent();


--
-- Name: marketplace_webhook_registrations marketplace_webhook_registration_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_webhook_registration_binding BEFORE INSERT OR UPDATE ON public.marketplace_webhook_registrations FOR EACH ROW EXECUTE FUNCTION public.validate_marketplace_webhook_registration();


--
-- Name: messages messages_refresh_conversation_summary; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_refresh_conversation_summary AFTER INSERT OR DELETE OR UPDATE OF content, role, created_at, conversation_id ON public.messages FOR EACH ROW EXECUTE FUNCTION public.refresh_conversation_message_summary();


--
-- Name: requirement_migration_execution_handoffs migration_execution_handoffs_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER migration_execution_handoffs_append_only BEFORE UPDATE OR TRUNCATE ON public.requirement_migration_execution_handoffs FOR EACH STATEMENT EXECUTE FUNCTION public.reject_migration_execution_handoff_mutation();


--
-- Name: requirement_migration_execution_handoffs migration_execution_handoffs_root_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER migration_execution_handoffs_root_delete BEFORE DELETE ON public.requirement_migration_execution_handoffs FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_owned_receipt_delete();


--
-- Name: requirement_migration_reconciliation_resumes migration_reconciliation_resumes_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER migration_reconciliation_resumes_append_only BEFORE UPDATE OR TRUNCATE ON public.requirement_migration_reconciliation_resumes FOR EACH STATEMENT EXECUTE FUNCTION public.reject_migration_reconciliation_mutation();


--
-- Name: requirement_migration_reconciliation_resumes migration_reconciliation_resumes_root_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER migration_reconciliation_resumes_root_delete BEFORE DELETE ON public.requirement_migration_reconciliation_resumes FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_owned_receipt_delete();


--
-- Name: requirement_migration_reconciliations migration_reconciliations_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER migration_reconciliations_append_only BEFORE UPDATE OR TRUNCATE ON public.requirement_migration_reconciliations FOR EACH STATEMENT EXECUTE FUNCTION public.reject_migration_reconciliation_mutation();


--
-- Name: requirement_migration_reconciliations migration_reconciliations_root_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER migration_reconciliations_root_delete BEFORE DELETE ON public.requirement_migration_reconciliations FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_owned_receipt_delete();


--
-- Name: requirement_migration_retirements migration_retirements_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER migration_retirements_append_only BEFORE DELETE OR UPDATE OR TRUNCATE ON public.requirement_migration_retirements FOR EACH STATEMENT EXECUTE FUNCTION public.reject_migration_retirement_mutation();


--
-- Name: billing normalize_billing_plan_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER normalize_billing_plan_names BEFORE INSERT OR UPDATE OF plan ON public.billing FOR EACH ROW EXECUTE FUNCTION public.normalize_billing_plan_names();


--
-- Name: settings observe_email_sync_channel_health; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER observe_email_sync_channel_health AFTER INSERT OR UPDATE OF channels ON public.settings FOR EACH ROW EXECUTE FUNCTION public.observe_email_sync_channel_health();


--
-- Name: messages observe_message_channel_health; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER observe_message_channel_health AFTER INSERT OR UPDATE OF custom_data ON public.messages FOR EACH ROW EXECUTE FUNCTION public.observe_message_channel_health();


--
-- Name: commands on_command_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_command_insert BEFORE INSERT ON public.commands FOR EACH ROW EXECUTE FUNCTION public.handle_command_insert();


--
-- Name: commands on_command_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_command_update BEFORE UPDATE ON public.commands FOR EACH ROW EXECUTE FUNCTION public.handle_command_update();


--
-- Name: session_events on_event_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_event_insert BEFORE INSERT ON public.session_events FOR EACH ROW EXECUTE FUNCTION public.handle_event_insert();


--
-- Name: messages on_message_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_message_insert AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message_time();


--
-- Name: payments payments_timestamp_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER payments_timestamp_trigger BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: api_keys platform_key_requirement_binding_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER platform_key_requirement_binding_guard BEFORE INSERT OR UPDATE OF metadata, site_id, status ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.guard_platform_key_requirement_binding();


--
-- Name: sales pos_register_capture_sale_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pos_register_capture_sale_payments AFTER INSERT OR DELETE OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.pos_register_capture_sale_payments();


--
-- Name: pos_register_movements pos_register_movements_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pos_register_movements_immutable BEFORE DELETE OR UPDATE ON public.pos_register_movements FOR EACH ROW EXECUTE FUNCTION public.pos_register_immutable_ledger();


--
-- Name: pos_register_receipts pos_register_receipts_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pos_register_receipts_immutable BEFORE DELETE OR UPDATE ON public.pos_register_receipts FOR EACH ROW EXECUTE FUNCTION public.pos_register_immutable_ledger();


--
-- Name: pos_register_sessions pos_register_sessions_preserve; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pos_register_sessions_preserve BEFORE DELETE OR UPDATE ON public.pos_register_sessions FOR EACH ROW EXECUTE FUNCTION public.pos_register_preserve_session();


--
-- Name: sale_orders preserve_sale_order_creator; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER preserve_sale_order_creator BEFORE UPDATE OF created_by_user_id ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.preserve_sale_order_creator();


--
-- Name: sale_orders prevent_cancelled_order_reopen_before_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_cancelled_order_reopen_before_update BEFORE UPDATE OF status ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.prevent_cancelled_order_reopen();


--
-- Name: site_members prevent_last_admin_deletion_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_last_admin_deletion_trigger BEFORE DELETE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_deletion();


--
-- Name: site_members prevent_last_admin_role_change_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_last_admin_role_change_trigger BEFORE UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_role_change();


--
-- Name: records queue_record_embedding_on_record_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_record_embedding_on_record_change AFTER INSERT OR UPDATE OF title, description, category_id, data, relations, status ON public.records FOR EACH ROW EXECUTE FUNCTION public.queue_record_embedding_on_record_change();


--
-- Name: quotations quotations_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER quotations_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.quotations FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: requirements requirement_deletion_authority; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_deletion_authority BEFORE DELETE ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_deletion_authority();


--
-- Name: requirement_status requirement_economic_pause_capture; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_economic_pause_capture AFTER INSERT ON public.requirement_status FOR EACH ROW EXECUTE FUNCTION public.track_requirement_economic_pause();


--
-- Name: requirements requirement_economic_pause_invalidate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_economic_pause_invalidate AFTER UPDATE OF status ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.track_requirement_economic_pause();


--
-- Name: requirements requirement_instance_binding_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_instance_binding_guard BEFORE INSERT OR UPDATE OF metadata, site_id ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_instance_binding();


--
-- Name: requirement_migration_lifecycle requirement_migration_execution_handoff_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_migration_execution_handoff_guard AFTER INSERT OR DELETE OR UPDATE ON public.requirement_migration_lifecycle FOR EACH ROW EXECUTE FUNCTION public.guard_migration_execution_handoff();


--
-- Name: requirement_migration_lifecycle requirement_migration_hold_visibility; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_migration_hold_visibility AFTER INSERT OR UPDATE ON public.requirement_migration_lifecycle FOR EACH ROW EXECUTE FUNCTION public.publish_requirement_migration_hold();


--
-- Name: requirements requirement_migration_status_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_migration_status_guard AFTER UPDATE ON public.requirements FOR EACH ROW WHEN ((old.status IS DISTINCT FROM new.status)) EXECUTE FUNCTION public.guard_requirement_migration_status();


--
-- Name: requirements requirement_pending_migration_reconciliation_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_pending_migration_reconciliation_guard AFTER UPDATE ON public.requirements FOR EACH ROW WHEN ((old.status IS DISTINCT FROM new.status)) EXECUTE FUNCTION public.guard_pending_migration_reconciliation();


--
-- Name: requirements requirement_sandbox_cleanup_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_sandbox_cleanup_guard BEFORE UPDATE OF status ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_sandbox_cleanup();


--
-- Name: requirement_status requirement_status_instance_binding_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirement_status_instance_binding_guard BEFORE INSERT OR UPDATE OF requirement_id, instance_id, site_id ON public.requirement_status FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_status_instance_binding();


--
-- Name: requirements requirements_review_quarantine_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirements_review_quarantine_guard BEFORE UPDATE OF backlog ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.enforce_requirement_review_quarantine();


--
-- Name: requirements requirements_review_quarantine_stamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER requirements_review_quarantine_stamp BEFORE UPDATE OF backlog ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.stamp_requirement_review_quarantine();


--
-- Name: reservations reservations_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reservations_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: settings reset_channel_health_on_reconfiguration; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reset_channel_health_on_reconfiguration AFTER UPDATE OF channels ON public.settings FOR EACH ROW EXECUTE FUNCTION public.reset_channel_health_on_reconfiguration();


--
-- Name: api_keys revoke_visitor_identity_issuer_grants; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER revoke_visitor_identity_issuer_grants BEFORE DELETE OR UPDATE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.revoke_visitor_identity_issuer_grants();


--
-- Name: sales sales_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sales_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: sandbox_billing_resources sandbox_cleanup_registration_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sandbox_cleanup_registration_guard BEFORE UPDATE OF deletion_requested_at, retired_at ON public.sandbox_billing_resources FOR EACH ROW EXECUTE FUNCTION public.guard_sandbox_cleanup_registration();


--
-- Name: sale_order_items self_service_line_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER self_service_line_guard BEFORE INSERT OR UPDATE ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.guard_self_service_line();


--
-- Name: sale_orders self_service_order_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER self_service_order_guard BEFORE INSERT OR UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.guard_self_service_order();


--
-- Name: sale_order_item_units self_service_unit_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER self_service_unit_guard BEFORE INSERT OR UPDATE ON public.sale_order_item_units FOR EACH ROW EXECUTE FUNCTION public.guard_self_service_unit();


--
-- Name: session_events session_events_updated_at_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER session_events_updated_at_trigger BEFORE UPDATE ON public.session_events FOR EACH ROW EXECUTE FUNCTION public.handle_session_events_updated_at();


--
-- Name: tasks set_tasks_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: webhooks_deliveries set_timestamp_webhooks_deliveries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_timestamp_webhooks_deliveries BEFORE UPDATE ON public.webhooks_deliveries FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: webhooks_endpoints set_timestamp_webhooks_endpoints; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_timestamp_webhooks_endpoints BEFORE UPDATE ON public.webhooks_endpoints FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: webhooks_subscriptions set_timestamp_webhooks_subscriptions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_timestamp_webhooks_subscriptions BEFORE UPDATE ON public.webhooks_subscriptions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();


--
-- Name: analysis set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.analysis FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


--
-- Name: payout_requests set_updated_at_payout_requests; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at_payout_requests BEFORE UPDATE ON public.payout_requests FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


--
-- Name: settings settings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: site_members sync_members_to_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_members_to_settings AFTER INSERT OR DELETE OR UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.sync_site_members_to_settings();


--
-- Name: shipments sync_order_line_unit_delivery_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_order_line_unit_delivery_after_update AFTER UPDATE OF status, delivered_at ON public.shipments FOR EACH ROW WHEN (((old.status IS DISTINCT FROM new.status) OR (old.delivered_at IS DISTINCT FROM new.delivered_at))) EXECUTE FUNCTION public.sync_order_line_unit_delivery();


--
-- Name: sale_orders sync_order_lines_from_order_status_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_order_lines_from_order_status_after_update AFTER UPDATE OF status ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.sync_order_lines_from_order_status();


--
-- Name: sites sync_ownership_on_site_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_ownership_on_site_change AFTER INSERT OR DELETE OR UPDATE OF user_id ON public.sites FOR EACH ROW EXECUTE FUNCTION public.sync_site_ownership();


--
-- Name: sale_order_item_units sync_sale_order_item_status_after_unit_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_sale_order_item_status_after_unit_update AFTER UPDATE OF status ON public.sale_order_item_units FOR EACH ROW EXECUTE FUNCTION public.sync_sale_order_item_status_from_units();


--
-- Name: sale_order_items sync_sale_order_item_units_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_sale_order_item_units_after_insert AFTER INSERT ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.sync_sale_order_item_units_from_line();


--
-- Name: sale_order_items sync_sale_order_item_units_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_sale_order_item_units_after_update AFTER UPDATE OF site_id, quantity, status, shipment_id, sent_at, parent_sale_order_item_id ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.sync_sale_order_item_units_from_line();


--
-- Name: site_members sync_site_members_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_site_members_trigger AFTER INSERT OR DELETE OR UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.sync_site_members_to_team_members();


--
-- Name: tasks tasks_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tasks_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: sale_order_item_units touch_sale_order_item_unit_before_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER touch_sale_order_item_unit_before_update BEFORE UPDATE ON public.sale_order_item_units FOR EACH ROW EXECUTE FUNCTION public.touch_sale_order_item_unit();


--
-- Name: icp_mining trg_icp_mining_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_icp_mining_set_updated_at BEFORE UPDATE ON public.icp_mining FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: persons trg_persons_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_persons_updated_at BEFORE UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
