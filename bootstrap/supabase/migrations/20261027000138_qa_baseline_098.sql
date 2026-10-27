SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: site_members license_25_member_sync; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_25_member_sync AFTER INSERT OR DELETE OR UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.sync_site_members_to_settings();


--
-- Name: settings license_99_enforce_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_99_enforce_settings BEFORE INSERT OR UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.enforce_settings_license();


--
-- Name: sites license_site_owner_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER license_site_owner_changed AFTER UPDATE OF user_id, archived_at ON public.sites FOR EACH ROW EXECUTE FUNCTION public.site_owner_license_changed();


--
-- Name: accounting_sale_refunds location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.accounting_sale_refunds FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_accounting_sale_refunds();


--
-- Name: deal_owners location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.deal_owners FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_deal_owners();


--
-- Name: invoice_reminders location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.invoice_reminders FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_invoice_reminders();


--
-- Name: messages location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_messages();


--
-- Name: pos_register_movements location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.pos_register_movements FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_pos_register_movements();


--
-- Name: pos_register_receipts location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.pos_register_receipts FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_pos_register_receipts();


--
-- Name: purchase_items location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.purchase_items FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_purchase_items();


--
-- Name: quotation_items location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.quotation_items FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_quotation_items();


--
-- Name: quotations location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.quotations FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_quotations();


--
-- Name: reservations location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_reservations();


--
-- Name: sale_order_item_units location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.sale_order_item_units FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_sale_order_item_units();


--
-- Name: sale_order_items location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_sale_order_items();


--
-- Name: sale_orders location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_sale_orders();


--
-- Name: sales location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_sales();


--
-- Name: shipment_location_pings location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.shipment_location_pings FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_shipment_location_pings();


--
-- Name: shipments location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.shipments FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_shipments();


--
-- Name: task_categories location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.task_categories FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_task_categories();


--
-- Name: task_comments location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.task_comments FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_task_comments();


--
-- Name: tasks location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_tasks();


--
-- Name: transactions location_acl_10_visible; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_10_visible BEFORE INSERT OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.location_acl_visible_transactions();


--
-- Name: conversations location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: deals location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.deals FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: inventory_levels location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.inventory_levels FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: locations location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.locations FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: pos_register_sessions location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.pos_register_sessions FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: purchases location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.purchases FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: quotations location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.quotations FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: records location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.records FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: reservations location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: sale_orders location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: sales location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: shipments location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.shipments FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: subscriptions location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: tasks location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: transactions location_acl_20_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_20_immutable BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.location_acl_guard_root_scope();


--
-- Name: accounting_sale_refunds location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.accounting_sale_refunds FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: deal_owners location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.deal_owners FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: invoice_reminders location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.invoice_reminders FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: messages location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: pos_register_movements location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.pos_register_movements FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: pos_register_receipts location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.pos_register_receipts FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: purchase_items location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.purchase_items FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: quotation_items location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.quotation_items FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: quotations location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.quotations FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: reservations location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: sale_order_item_units location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.sale_order_item_units FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: sale_order_items location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: sale_orders location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: sales location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: shipment_location_pings location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.shipment_location_pings FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: shipments location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.shipments FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: task_categories location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.task_categories FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: task_comments location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.task_comments FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: tasks location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: transactions location_acl_inherit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER location_acl_inherit BEFORE INSERT OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.location_acl_inherit_scope();


--
-- Name: assets log_asset_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER log_asset_insert_trigger BEFORE INSERT ON public.assets FOR EACH ROW EXECUTE FUNCTION public.log_asset_insert();


--
-- Name: marketplace_integrations marketplace_integration_identity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_integration_identity BEFORE INSERT OR UPDATE ON public.marketplace_integrations FOR EACH ROW EXECUTE FUNCTION public.validate_marketplace_integration();


--
-- Name: marketplace_merchant_connections marketplace_merchant_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_merchant_binding BEFORE INSERT OR UPDATE ON public.marketplace_merchant_connections FOR EACH ROW EXECUTE FUNCTION public.validate_marketplace_consent();


--
-- Name: sale_order_item_units marketplace_native_ownership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_native_ownership BEFORE INSERT OR DELETE OR UPDATE ON public.sale_order_item_units FOR EACH ROW EXECUTE FUNCTION public.guard_marketplace_native_write();


--
-- Name: sale_order_items marketplace_native_ownership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_native_ownership BEFORE INSERT OR DELETE OR UPDATE ON public.sale_order_items FOR EACH ROW EXECUTE FUNCTION public.guard_marketplace_native_write();


--
-- Name: sale_orders marketplace_native_ownership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_native_ownership BEFORE INSERT OR DELETE OR UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.guard_marketplace_native_write();


--
-- Name: sales marketplace_native_ownership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_native_ownership BEFORE INSERT OR DELETE OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.guard_marketplace_native_write();


--
-- Name: shipment_location_pings marketplace_native_ownership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_native_ownership BEFORE INSERT OR DELETE OR UPDATE ON public.shipment_location_pings FOR EACH ROW EXECUTE FUNCTION public.guard_marketplace_native_write();


--
-- Name: shipments marketplace_native_ownership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_native_ownership BEFORE INSERT OR DELETE OR UPDATE ON public.shipments FOR EACH ROW EXECUTE FUNCTION public.guard_marketplace_native_write();


--
-- Name: site_secrets marketplace_native_ownership; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_native_ownership BEFORE INSERT OR DELETE OR UPDATE ON public.site_secrets FOR EACH ROW EXECUTE FUNCTION public.guard_marketplace_native_write();


--
-- Name: marketplace_oauth_sessions marketplace_oauth_binding; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_oauth_binding BEFORE INSERT OR UPDATE ON public.marketplace_oauth_sessions FOR EACH ROW EXECUTE FUNCTION public.validate_marketplace_consent();


--
-- Name: site_secrets marketplace_secret_identity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER marketplace_secret_identity BEFORE DELETE OR UPDATE ON public.site_secrets FOR EACH ROW EXECUTE FUNCTION public.preserve_marketplace_secret_identity();
