SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: workflow_runs_instance_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_runs_instance_idx ON public.workflow_runs USING btree (instance_id, created_at DESC);


--
-- Name: workflow_triggers_instance_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_triggers_instance_idx ON public.workflow_triggers USING btree (instance_id);


--
-- Name: workflow_triggers_site_kind_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_triggers_site_kind_idx ON public.workflow_triggers USING btree (site_id, kind, enabled);


--
-- Name: billing aa_fence_retired_stripe_subscription_identity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER aa_fence_retired_stripe_subscription_identity BEFORE UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.fence_retired_stripe_subscription_identity();


--
-- Name: purchases accounting_00_purchases_legacy_receipt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_00_purchases_legacy_receipt BEFORE UPDATE OF payments ON public.purchases FOR EACH ROW EXECUTE FUNCTION public.accounting_preserve_legacy_receipt();


--
-- Name: sales accounting_00_sales_legacy_receipt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_00_sales_legacy_receipt BEFORE UPDATE OF payments ON public.sales FOR EACH ROW EXECUTE FUNCTION public.accounting_preserve_legacy_receipt();


--
-- Name: accounting_accounts accounting_account_integrity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_account_integrity BEFORE INSERT OR DELETE OR UPDATE ON public.accounting_accounts FOR EACH ROW EXECUTE FUNCTION public.accounting_guard_account();


--
-- Name: purchases accounting_purchase_draft_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_purchase_draft_guard BEFORE UPDATE OF status ON public.purchases FOR EACH ROW EXECUTE FUNCTION public.accounting_guard_purchase_draft();


--
-- Name: purchase_items accounting_purchase_item_freshness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_purchase_item_freshness AFTER INSERT OR DELETE OR UPDATE ON public.purchase_items FOR EACH ROW EXECUTE FUNCTION public.accounting_touch_source_from_child();


--
-- Name: purchases accounting_purchases_freshness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_purchases_freshness BEFORE UPDATE ON public.purchases FOR EACH ROW EXECUTE FUNCTION public.accounting_touch_source();


--
-- Name: sale_order_items accounting_sale_item_freshness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_sale_item_freshness AFTER INSERT OR DELETE OR UPDATE ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.accounting_touch_source_from_child();


--
-- Name: sale_orders accounting_sale_order_freshness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_sale_order_freshness AFTER INSERT OR DELETE OR UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.accounting_touch_source_from_child();


--
-- Name: sales accounting_sales_freshness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_sales_freshness BEFORE UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.accounting_touch_source();


--
-- Name: transactions accounting_transactions_freshness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER accounting_transactions_freshness BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.accounting_touch_source();


--
-- Name: profiles activate_pending_memberships_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER activate_pending_memberships_trigger AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.activate_pending_site_memberships();


--
-- Name: requirement_archived_runner_reassignments archived_runner_reassignment_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER archived_runner_reassignment_append_only BEFORE DELETE OR UPDATE ON public.requirement_archived_runner_reassignments FOR EACH ROW EXECUTE FUNCTION public.guard_archived_runner_reassignment_history();


--
-- Name: requirement_archived_runner_reassignments archived_runner_reassignment_no_truncate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER archived_runner_reassignment_no_truncate BEFORE TRUNCATE ON public.requirement_archived_runner_reassignments FOR EACH STATEMENT EXECUTE FUNCTION public.guard_archived_runner_reassignment_history();


--
-- Name: sale_order_items authorize_order_item_unit_sync_before_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER authorize_order_item_unit_sync_before_delete BEFORE DELETE ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.authorize_order_item_unit_sync();


--
-- Name: sale_order_items authorize_order_item_unit_sync_before_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER authorize_order_item_unit_sync_before_insert BEFORE INSERT ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.authorize_order_item_unit_sync();


--
-- Name: sale_order_items authorize_order_item_unit_sync_before_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER authorize_order_item_unit_sync_before_update BEFORE UPDATE OF site_id, quantity, status, shipment_id, sent_at, parent_sale_order_item_id ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.authorize_order_item_unit_sync();


--
-- Name: billing billing_timestamp_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER billing_timestamp_trigger BEFORE UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: records bump_record_embedding_revision; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER bump_record_embedding_revision BEFORE UPDATE OF title, description, category_id, data, relations, status ON public.records FOR EACH ROW EXECUTE FUNCTION public.bump_record_embedding_revision();


--
-- Name: campaigns campaign_cascade_delete_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER campaign_cascade_delete_trigger BEFORE DELETE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.handle_campaign_deletion();


--
-- Name: instance_plans cancelled_instance_plan_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cancelled_instance_plan_guard BEFORE UPDATE OF status, steps, completion_reason ON public.instance_plans FOR EACH ROW EXECUTE FUNCTION public.guard_cancelled_instance_plan();


--
-- Name: catalog_categories cascade_catalog_category_archive; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cascade_catalog_category_archive AFTER INSERT OR UPDATE OF status ON public.catalog_categories FOR EACH ROW EXECUTE FUNCTION public.cascade_catalog_category_archive();


--
-- Name: catalog_categories catalog_search_category_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_category_changed AFTER INSERT OR DELETE OR UPDATE ON public.catalog_categories FOR EACH ROW EXECUTE FUNCTION public.catalog_search_relationship_changed();


--
-- Name: inventory_levels catalog_search_inventory_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_inventory_changed AFTER INSERT OR DELETE OR UPDATE ON public.inventory_levels FOR EACH ROW EXECUTE FUNCTION public.catalog_search_commerce_changed();


--
-- Name: catalog_items catalog_search_item_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_item_changed AFTER INSERT OR DELETE OR UPDATE ON public.catalog_items FOR EACH ROW EXECUTE FUNCTION public.catalog_search_item_changed();


--
-- Name: price_list_items catalog_search_price_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_price_changed AFTER INSERT OR DELETE OR UPDATE ON public.price_list_items FOR EACH ROW EXECUTE FUNCTION public.catalog_search_commerce_changed();


--
-- Name: price_lists catalog_search_price_list_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_price_list_changed AFTER INSERT OR DELETE OR UPDATE ON public.price_lists FOR EACH ROW EXECUTE FUNCTION public.catalog_search_commerce_changed();


--
-- Name: sites catalog_search_site_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_site_changed AFTER DELETE OR UPDATE ON public.sites FOR EACH ROW EXECUTE FUNCTION public.catalog_search_commerce_changed();


--
-- Name: item_specs catalog_search_spec_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_spec_changed AFTER INSERT OR DELETE OR UPDATE ON public.item_specs FOR EACH ROW EXECUTE FUNCTION public.catalog_search_relationship_changed();


--
-- Name: catalog_item_specs catalog_search_spec_link_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER catalog_search_spec_link_changed AFTER INSERT OR DELETE OR UPDATE ON public.catalog_item_specs FOR EACH ROW EXECUTE FUNCTION public.catalog_search_relationship_changed();


--
-- Name: api_keys check_expired_api_keys; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_expired_api_keys BEFORE INSERT OR UPDATE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.ensure_api_key_not_expired();


--
-- Name: content content_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER content_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.content FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: conversations conversations_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER conversations_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: credit_auto_top_up_settings credit_auto_top_up_card_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER credit_auto_top_up_card_binding BEFORE INSERT OR UPDATE ON public.credit_auto_top_up_settings FOR EACH ROW EXECUTE FUNCTION public.guard_credit_auto_top_up_card_binding();


--
-- Name: credit_auto_top_up_card_setups credit_auto_top_up_card_source; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER credit_auto_top_up_card_source BEFORE INSERT OR UPDATE ON public.credit_auto_top_up_card_setups FOR EACH ROW EXECUTE FUNCTION public.reset_credit_auto_top_up_card_source();


--
-- Name: credit_auto_top_up_settings credit_auto_top_up_settings_revision; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER credit_auto_top_up_settings_revision BEFORE UPDATE ON public.credit_auto_top_up_settings FOR EACH ROW EXECUTE FUNCTION public.advance_credit_auto_top_up_settings_revision();


--
-- Name: requirement_cron_cycle_outcomes cron_outcome_instance_binding_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cron_outcome_instance_binding_guard BEFORE INSERT OR UPDATE OF requirement_id, runner_instance_id ON public.requirement_cron_cycle_outcomes FOR EACH ROW EXECUTE FUNCTION public.guard_cron_outcome_instance_binding();


--
-- Name: deals deals_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER deals_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.deals FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: voice_call_deliveries enforce_voice_call_concurrency_before_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enforce_voice_call_concurrency_before_insert BEFORE INSERT ON public.voice_call_deliveries FOR EACH ROW EXECUTE FUNCTION public.enforce_voice_call_concurrency();


--
-- Name: allowed_domains guard_allowed_domain_provenance; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_allowed_domain_provenance BEFORE INSERT OR UPDATE ON public.allowed_domains FOR EACH ROW EXECUTE FUNCTION public.guard_allowed_domain_provenance();


--
-- Name: allowed_domains guard_archived_site_domain; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_archived_site_domain BEFORE INSERT OR UPDATE ON public.allowed_domains FOR EACH ROW EXECUTE FUNCTION public.guard_archived_site_domain();


--
-- Name: pass_redeemable_items guard_catalog_archive_redeemable_link; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_catalog_archive_redeemable_link BEFORE INSERT OR UPDATE ON public.pass_redeemable_items FOR EACH ROW EXECUTE FUNCTION public.guard_catalog_archive_redeemable_link();


--
-- Name: catalog_categories guard_catalog_category_archive; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_catalog_category_archive BEFORE INSERT OR UPDATE OF status, id, site_id ON public.catalog_categories FOR EACH ROW EXECUTE FUNCTION public.guard_catalog_category_archive();


--
-- Name: catalog_categories guard_catalog_import_category_name; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_catalog_import_category_name BEFORE INSERT OR DELETE OR UPDATE OF name ON public.catalog_categories FOR EACH ROW EXECUTE FUNCTION public.guard_catalog_import_category_name();


--
-- Name: catalog_items guard_catalog_item_archive_membership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_catalog_item_archive_membership BEFORE INSERT OR DELETE OR UPDATE ON public.catalog_items FOR EACH ROW EXECUTE FUNCTION public.guard_catalog_item_archive_membership();


--
-- Name: visitor_session_identity_grants guard_external_identity_grant; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_external_identity_grant BEFORE INSERT OR UPDATE ON public.visitor_session_identity_grants FOR EACH ROW EXECUTE FUNCTION public.guard_external_identity_grant();


--
-- Name: icp_mining guard_icp_mining_execution_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_icp_mining_execution_update BEFORE UPDATE ON public.icp_mining FOR EACH ROW EXECUTE FUNCTION public.guard_icp_mining_execution_update();


--
-- Name: icypeas_email_searches guard_icypeas_email_search; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_icypeas_email_search BEFORE UPDATE ON public.icypeas_email_searches FOR EACH ROW EXECUTE FUNCTION public.guard_icypeas_email_search();


--
-- Name: instance_logs guard_requirement_assistant_admission; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_requirement_assistant_admission BEFORE INSERT ON public.instance_logs FOR EACH ROW EXECUTE FUNCTION public.guard_requirement_assistant_admission();


--
-- Name: sites guard_site_archive_state; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_site_archive_state BEFORE INSERT OR UPDATE ON public.sites FOR EACH ROW EXECUTE FUNCTION public.guard_site_archive_state();


--
-- Name: api_keys guard_visitor_identity_issuer_scope; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_visitor_identity_issuer_scope BEFORE INSERT OR UPDATE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.guard_visitor_identity_issuer_scope();


--
-- Name: deals handle_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.deals FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');


--
-- Name: harness_sessions harness_sandbox_cleanup_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER harness_sandbox_cleanup_guard BEFORE INSERT OR UPDATE ON public.harness_sessions FOR EACH ROW EXECUTE FUNCTION public.guard_harness_sandbox_cleanup();


--
-- Name: harness_sessions harness_session_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER harness_session_guard BEFORE INSERT OR UPDATE ON public.harness_sessions FOR EACH ROW EXECUTE FUNCTION public.guard_harness_session();


--
-- Name: whatsapp_templates increment_template_usage_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER increment_template_usage_trigger AFTER UPDATE ON public.whatsapp_templates FOR EACH ROW WHEN (((old.usage_count IS DISTINCT FROM new.usage_count) OR (old.last_used IS DISTINCT FROM new.last_used))) EXECUTE FUNCTION public.increment_template_usage();


--
-- Name: api_keys initialize_visitor_identity_issuer_version; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER initialize_visitor_identity_issuer_version BEFORE INSERT ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.revoke_visitor_identity_issuer_grants();


--
-- Name: instance_logs instance_log_requirement_binding_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_log_requirement_binding_guard BEFORE INSERT OR UPDATE OF details, tool_args, site_id ON public.instance_logs FOR EACH ROW EXECUTE FUNCTION public.guard_instance_log_requirement_binding();


--
-- Name: instance_plans instance_plan_requirement_binding_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_plan_requirement_binding_guard BEFORE INSERT OR UPDATE OF metadata, site_id, instance_id ON public.instance_plans FOR EACH ROW EXECUTE FUNCTION public.guard_instance_plan_requirement_binding();


--
-- Name: remote_instances instance_requirement_metadata_binding_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_requirement_metadata_binding_guard BEFORE INSERT OR UPDATE OF metadata, site_id ON public.remote_instances FOR EACH ROW EXECUTE FUNCTION public.guard_instance_requirement_metadata_binding();


--
-- Name: sale_order_items inventory_self_service_release; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER inventory_self_service_release AFTER INSERT OR UPDATE ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.apply_self_service_line_inventory();


--
-- Name: leads leads_webhooks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER leads_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.dispatch_workflow_database_webhook();


--
-- Name: site_members license_00_protect_member; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_00_protect_member BEFORE INSERT OR UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.protect_member_license();


--
-- Name: settings license_00_protect_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_00_protect_settings BEFORE INSERT OR UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.protect_settings_license();


--
-- Name: billing license_10_billing_lock; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_10_billing_lock BEFORE INSERT OR DELETE OR UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.billing_license_changed();


--
-- Name: site_members license_10_guard_member; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_10_guard_member BEFORE INSERT OR DELETE OR UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.guard_member_license();


--
-- Name: billing license_20_billing_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_20_billing_changed AFTER INSERT OR DELETE OR UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.billing_license_changed();


--
-- Name: site_members license_20_member_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_20_member_changed AFTER INSERT OR DELETE OR UPDATE OF status ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.member_license_changed();
