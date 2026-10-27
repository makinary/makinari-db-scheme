SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;



--
-- Name: role_queries trg_role_queries_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_role_queries_updated_at BEFORE UPDATE ON public.role_queries FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: role_query_segments trg_rqs_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_rqs_updated_at BEFORE UPDATE ON public.role_query_segments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: user_site_notifications trg_user_site_notifications_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_user_site_notifications_set_updated_at BEFORE UPDATE ON public.user_site_notifications FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: activity trigger_activity_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_activity_updated_at BEFORE UPDATE ON public.activity FOR EACH ROW EXECUTE FUNCTION public.update_activity_updated_at();


--
-- Name: agent_assets trigger_delete_protection_agent_assets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_agent_assets BEFORE DELETE ON public.agent_assets FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: agent_memories trigger_delete_protection_agent_memories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_agent_memories BEFORE DELETE ON public.agent_memories FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: agents trigger_delete_protection_agents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_agents BEFORE DELETE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: allowed_domains trigger_delete_protection_allowed_domains; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_allowed_domains BEFORE DELETE ON public.allowed_domains FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: analysis trigger_delete_protection_analysis; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_analysis BEFORE DELETE ON public.analysis FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: api_keys trigger_delete_protection_api_keys; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_api_keys BEFORE DELETE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: assets trigger_delete_protection_assets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_assets BEFORE DELETE ON public.assets FOR EACH ROW EXECUTE FUNCTION public.guard_robot_deletion_child_authority();


--
-- Name: billing trigger_delete_protection_billing; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_billing BEFORE DELETE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: campaign_requirements trigger_delete_protection_campaign_requirements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_campaign_requirements BEFORE DELETE ON public.campaign_requirements FOR EACH ROW EXECUTE FUNCTION public.guard_robot_deletion_child_authority();


--
-- Name: campaign_segments trigger_delete_protection_campaign_segments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_campaign_segments BEFORE DELETE ON public.campaign_segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: campaign_subtasks trigger_delete_protection_campaign_subtasks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_campaign_subtasks BEFORE DELETE ON public.campaign_subtasks FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: campaigns trigger_delete_protection_campaigns; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_campaigns BEFORE DELETE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: categories trigger_delete_protection_categories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_categories BEFORE DELETE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: content trigger_delete_protection_content; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_content BEFORE DELETE ON public.content FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: conversations trigger_delete_protection_conversations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_conversations BEFORE DELETE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: experiment_segments trigger_delete_protection_experiment_segments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_experiment_segments BEFORE DELETE ON public.experiment_segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: experiments trigger_delete_protection_experiments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_experiments BEFORE DELETE ON public.experiments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: external_resources trigger_delete_protection_external_resources; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_external_resources BEFORE DELETE ON public.external_resources FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: kpis trigger_delete_protection_kpis; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_kpis BEFORE DELETE ON public.kpis FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: leads trigger_delete_protection_leads; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_leads BEFORE DELETE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: messages trigger_delete_protection_messages; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_messages BEFORE DELETE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: notifications trigger_delete_protection_notifications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_notifications BEFORE DELETE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: payments trigger_delete_protection_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_payments BEFORE DELETE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: requirement_segments trigger_delete_protection_requirement_segments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_requirement_segments BEFORE DELETE ON public.requirement_segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: sale_orders trigger_delete_protection_sale_orders; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_sale_orders BEFORE DELETE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: sales trigger_delete_protection_sales; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_sales BEFORE DELETE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: secure_tokens trigger_delete_protection_secure_tokens; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_secure_tokens BEFORE DELETE ON public.secure_tokens FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: segments trigger_delete_protection_segments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_segments BEFORE DELETE ON public.segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: session_events trigger_delete_protection_session_events; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_session_events BEFORE DELETE ON public.session_events FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: settings trigger_delete_protection_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_settings BEFORE DELETE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: site_members trigger_delete_protection_site_members; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_site_members BEFORE DELETE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: task_categories trigger_delete_protection_task_categories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_task_categories BEFORE DELETE ON public.task_categories FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: task_comments trigger_delete_protection_task_comments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_task_comments BEFORE DELETE ON public.task_comments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: tasks trigger_delete_protection_tasks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_tasks BEFORE DELETE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: transactions trigger_delete_protection_transactions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_transactions BEFORE DELETE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: visitor_sessions trigger_delete_protection_visitor_sessions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_visitor_sessions BEFORE DELETE ON public.visitor_sessions FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: visitors trigger_delete_protection_visitors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_delete_protection_visitors BEFORE DELETE ON public.visitors FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();


--
-- Name: agents trigger_insert_permission_agents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_agents BEFORE INSERT ON public.agents FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: campaigns trigger_insert_permission_campaigns; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_campaigns BEFORE INSERT ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: content trigger_insert_permission_content; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_content BEFORE INSERT ON public.content FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: experiments trigger_insert_permission_experiments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_experiments BEFORE INSERT ON public.experiments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: leads trigger_insert_permission_leads; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_leads BEFORE INSERT ON public.leads FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: messages trigger_insert_permission_messages; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_messages BEFORE INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: notifications trigger_insert_permission_notifications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_notifications BEFORE INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: requirements trigger_insert_permission_requirements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_requirements BEFORE INSERT ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: sales trigger_insert_permission_sales; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_sales BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: segments trigger_insert_permission_segments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_segments BEFORE INSERT ON public.segments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: tasks trigger_insert_permission_tasks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_tasks BEFORE INSERT ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: visitor_sessions trigger_insert_permission_visitor_sessions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_visitor_sessions BEFORE INSERT ON public.visitor_sessions FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: visitors trigger_insert_permission_visitors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_insert_permission_visitors BEFORE INSERT ON public.visitors FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: tasks trigger_set_task_priority; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_set_task_priority BEFORE INSERT ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_task_priority_from_serial();


--
-- Name: tasks trigger_set_task_serial_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_set_task_serial_id BEFORE INSERT ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_task_serial_id();


--
-- Name: copywriting trigger_update_copywriting_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_copywriting_updated_at BEFORE UPDATE ON public.copywriting FOR EACH ROW EXECUTE FUNCTION public.update_copywriting_updated_at();


--
-- Name: cron_status trigger_update_cron_status_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_cron_status_updated_at BEFORE UPDATE ON public.cron_status FOR EACH ROW EXECUTE FUNCTION public.update_cron_status_updated_at();


--
-- Name: lead_analysis trigger_update_lead_analysis_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_lead_analysis_updated_at BEFORE UPDATE ON public.lead_analysis FOR EACH ROW EXECUTE FUNCTION public.update_lead_analysis_updated_at();


--
-- Name: agents trigger_update_permission_agents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_agents BEFORE UPDATE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: campaigns trigger_update_permission_campaigns; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_campaigns BEFORE UPDATE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: content trigger_update_permission_content; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_content BEFORE UPDATE ON public.content FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: experiments trigger_update_permission_experiments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_experiments BEFORE UPDATE ON public.experiments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: leads trigger_update_permission_leads; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_leads BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: messages trigger_update_permission_messages; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_messages BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: notifications trigger_update_permission_notifications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_notifications BEFORE UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: requirements trigger_update_permission_requirements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_requirements BEFORE UPDATE ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: sales trigger_update_permission_sales; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_sales BEFORE UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: segments trigger_update_permission_segments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_segments BEFORE UPDATE ON public.segments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();


--
-- Name: tasks trigger_update_permission_tasks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_permission_tasks BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();
