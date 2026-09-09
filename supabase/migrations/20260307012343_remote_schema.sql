drop trigger if exists "trigger_activity_updated_at" on "public"."activity";

drop trigger if exists "trigger_delete_protection_agent_assets" on "public"."agent_assets";

drop trigger if exists "trigger_delete_protection_agent_memories" on "public"."agent_memories";

drop trigger if exists "trigger_delete_protection_agents" on "public"."agents";

drop trigger if exists "trigger_insert_permission_agents" on "public"."agents";

drop trigger if exists "trigger_update_permission_agents" on "public"."agents";

drop trigger if exists "trigger_delete_protection_allowed_domains" on "public"."allowed_domains";

drop trigger if exists "set_updated_at" on "public"."analysis";

drop trigger if exists "trigger_delete_protection_analysis" on "public"."analysis";

drop trigger if exists "check_expired_api_keys" on "public"."api_keys";

drop trigger if exists "trigger_delete_protection_api_keys" on "public"."api_keys";

drop trigger if exists "update_api_keys_updated_at" on "public"."api_keys";

drop trigger if exists "log_asset_insert_trigger" on "public"."assets";

drop trigger if exists "trigger_delete_protection_assets" on "public"."assets";

drop trigger if exists "update_automation_auth_sessions_updated_at" on "public"."automation_auth_sessions";

drop trigger if exists "billing_timestamp_trigger" on "public"."billing";

drop trigger if exists "trigger_delete_protection_billing" on "public"."billing";

drop trigger if exists "trigger_delete_protection_campaign_requirements" on "public"."campaign_requirements";

drop trigger if exists "trigger_delete_protection_campaign_segments" on "public"."campaign_segments";

drop trigger if exists "trigger_delete_protection_campaign_subtasks" on "public"."campaign_subtasks";

drop trigger if exists "campaign_cascade_delete_trigger" on "public"."campaigns";

drop trigger if exists "trigger_delete_protection_campaigns" on "public"."campaigns";

drop trigger if exists "trigger_insert_permission_campaigns" on "public"."campaigns";

drop trigger if exists "trigger_update_permission_campaigns" on "public"."campaigns";

drop trigger if exists "trigger_delete_protection_categories" on "public"."categories";

drop trigger if exists "on_command_insert" on "public"."commands";

drop trigger if exists "on_command_update" on "public"."commands";

drop trigger if exists "validate_performance_bitmask_trigger" on "public"."commands";

drop trigger if exists "update_companies_updated_at" on "public"."companies";

drop trigger if exists "trigger_delete_protection_content" on "public"."content";

drop trigger if exists "trigger_insert_permission_content" on "public"."content";

drop trigger if exists "trigger_update_permission_content" on "public"."content";

drop trigger if exists "trigger_delete_protection_conversations" on "public"."conversations";

drop trigger if exists "trigger_update_copywriting_updated_at" on "public"."copywriting";

drop trigger if exists "trigger_update_cron_status_updated_at" on "public"."cron_status";

drop trigger if exists "trigger_delete_protection_experiment_segments" on "public"."experiment_segments";

drop trigger if exists "trigger_delete_protection_experiments" on "public"."experiments";

drop trigger if exists "trigger_insert_permission_experiments" on "public"."experiments";

drop trigger if exists "trigger_update_permission_experiments" on "public"."experiments";

drop trigger if exists "trigger_delete_protection_external_resources" on "public"."external_resources";

drop trigger if exists "trg_icp_mining_set_updated_at" on "public"."icp_mining";

drop trigger if exists "update_instance_plans_updated_at" on "public"."instance_plans";

drop trigger if exists "trigger_delete_protection_kpis" on "public"."kpis";

drop trigger if exists "trigger_update_lead_analysis_updated_at" on "public"."lead_analysis";

drop trigger if exists "trigger_delete_protection_leads" on "public"."leads";

drop trigger if exists "trigger_insert_permission_leads" on "public"."leads";

drop trigger if exists "trigger_update_permission_leads" on "public"."leads";

drop trigger if exists "on_message_insert" on "public"."messages";

drop trigger if exists "trigger_delete_protection_messages" on "public"."messages";

drop trigger if exists "trigger_insert_permission_messages" on "public"."messages";

drop trigger if exists "trigger_update_permission_messages" on "public"."messages";

drop trigger if exists "trigger_delete_protection_notifications" on "public"."notifications";

drop trigger if exists "trigger_insert_permission_notifications" on "public"."notifications";

drop trigger if exists "trigger_update_permission_notifications" on "public"."notifications";

drop trigger if exists "payments_timestamp_trigger" on "public"."payments";

drop trigger if exists "trigger_delete_protection_payments" on "public"."payments";

drop trigger if exists "trg_persons_updated_at" on "public"."persons";

drop trigger if exists "activate_pending_memberships_trigger" on "public"."profiles";

drop trigger if exists "update_referral_codes_updated_at" on "public"."referral_codes";

drop trigger if exists "update_remote_instances_updated_at" on "public"."remote_instances";

drop trigger if exists "trigger_delete_protection_requirement_segments" on "public"."requirement_segments";

drop trigger if exists "trigger_delete_protection_requirements" on "public"."requirements";

drop trigger if exists "trigger_insert_permission_requirements" on "public"."requirements";

drop trigger if exists "trigger_update_permission_requirements" on "public"."requirements";

drop trigger if exists "trg_role_queries_updated_at" on "public"."role_queries";

drop trigger if exists "trg_rqs_updated_at" on "public"."role_query_segments";

drop trigger if exists "trigger_delete_protection_sale_orders" on "public"."sale_orders";

drop trigger if exists "trigger_update_sale_orders_updated_at" on "public"."sale_orders";

drop trigger if exists "trigger_delete_protection_sales" on "public"."sales";

drop trigger if exists "trigger_insert_permission_sales" on "public"."sales";

drop trigger if exists "trigger_update_permission_sales" on "public"."sales";

drop trigger if exists "trigger_delete_protection_secure_tokens" on "public"."secure_tokens";

drop trigger if exists "trigger_delete_protection_segments" on "public"."segments";

drop trigger if exists "trigger_insert_permission_segments" on "public"."segments";

drop trigger if exists "trigger_update_permission_segments" on "public"."segments";

drop trigger if exists "on_event_insert" on "public"."session_events";

drop trigger if exists "session_events_updated_at_trigger" on "public"."session_events";

drop trigger if exists "trigger_delete_protection_session_events" on "public"."session_events";

drop trigger if exists "settings_updated_at" on "public"."settings";

drop trigger if exists "trigger_delete_protection_settings" on "public"."settings";

drop trigger if exists "prevent_last_admin_deletion_trigger" on "public"."site_members";

drop trigger if exists "prevent_last_admin_role_change_trigger" on "public"."site_members";

drop trigger if exists "sync_members_to_settings" on "public"."site_members";

drop trigger if exists "sync_site_members_trigger" on "public"."site_members";

drop trigger if exists "trigger_delete_protection_site_members" on "public"."site_members";

drop trigger if exists "sync_ownership_on_site_change" on "public"."sites";

drop trigger if exists "trigger_update_synced_objects_updated_at" on "public"."synced_objects";

drop trigger if exists "trigger_delete_protection_task_categories" on "public"."task_categories";

drop trigger if exists "trigger_delete_protection_task_comments" on "public"."task_comments";

drop trigger if exists "set_tasks_updated_at" on "public"."tasks";

drop trigger if exists "trigger_delete_protection_tasks" on "public"."tasks";

drop trigger if exists "trigger_insert_permission_tasks" on "public"."tasks";

drop trigger if exists "trigger_set_task_priority" on "public"."tasks";

drop trigger if exists "trigger_set_task_serial_id" on "public"."tasks";

drop trigger if exists "trigger_update_permission_tasks" on "public"."tasks";

drop trigger if exists "trigger_delete_protection_transactions" on "public"."transactions";

drop trigger if exists "trigger_delete_protection_visitor_sessions" on "public"."visitor_sessions";

drop trigger if exists "trigger_insert_permission_visitor_sessions" on "public"."visitor_sessions";

drop trigger if exists "trigger_update_permission_visitor_sessions" on "public"."visitor_sessions";

drop trigger if exists "trigger_delete_protection_visitors" on "public"."visitors";

drop trigger if exists "trigger_insert_permission_visitors" on "public"."visitors";

drop trigger if exists "trigger_update_permission_visitors" on "public"."visitors";

drop trigger if exists "update_waitlist_updated_at" on "public"."waitlist";

drop trigger if exists "webhook_events_updated_at_trigger" on "public"."webhook_events";

drop trigger if exists "set_timestamp_webhooks_deliveries" on "public"."webhooks_deliveries";

drop trigger if exists "set_timestamp_webhooks_endpoints" on "public"."webhooks_endpoints";

drop trigger if exists "set_timestamp_webhooks_subscriptions" on "public"."webhooks_subscriptions";

drop trigger if exists "increment_template_usage_trigger" on "public"."whatsapp_templates";

drop trigger if exists "trigger_update_whatsapp_templates_updated_at" on "public"."whatsapp_templates";

drop policy "authenticated_read_activity" on "public"."activity";

drop policy "site_owners_delete_activity" on "public"."activity";

drop policy "site_owners_update_activity" on "public"."activity";

drop policy "agent_assets_unified" on "public"."agent_assets";

drop policy "agent_memories_optimized_policy" on "public"."agent_memories";

drop policy "agents_optimized_policy" on "public"."agents";

drop policy "allowed_domains_access_policy" on "public"."allowed_domains";

drop policy "assets_optimized_policy" on "public"."assets";

drop policy "automation_auth_sessions_access_policy" on "public"."automation_auth_sessions";

drop policy "billing_optimized_policy" on "public"."billing";

drop policy "campaign_requirements_optimized_policy" on "public"."campaign_requirements";

drop policy "Users can manage campaign segments for their sites" on "public"."campaign_segments";

drop policy "Users can manage campaign subtasks for their sites" on "public"."campaign_subtasks";

drop policy "campaigns_unified" on "public"."campaigns";

drop policy "categories_for_owned_sites" on "public"."categories";

drop policy "commands_site_access_policy" on "public"."commands";

drop policy "content_unified_access_policy" on "public"."content";

drop policy "content_assets_unified_policy" on "public"."content_assets";

drop policy "copywriting_site_access_policy" on "public"."copywriting";

drop policy "Only superadmin can delete cron status" on "public"."cron_status";

drop policy "Only superadmin can insert cron status" on "public"."cron_status";

drop policy "Only superadmin can update cron status" on "public"."cron_status";

drop policy "Only superadmin can view cron status" on "public"."cron_status";

drop policy "customizations_delete_owner_admin" on "public"."customizations";

drop policy "customizations_insert_owner_admin" on "public"."customizations";

drop policy "customizations_select_owner_admin" on "public"."customizations";

drop policy "customizations_update_owner_admin" on "public"."customizations";

drop policy "debug_logs_optimized_policy" on "public"."debug_logs";

drop policy "editor_delete_owner_admin" on "public"."editor";

drop policy "editor_insert_owner_admin" on "public"."editor";

drop policy "editor_select_owner_admin" on "public"."editor";

drop policy "editor_update_owner_admin" on "public"."editor";

drop policy "elements_delete_owner_admin" on "public"."elements";

drop policy "elements_insert_owner_admin" on "public"."elements";

drop policy "elements_select_owner_admin" on "public"."elements";

drop policy "elements_update_owner_admin" on "public"."elements";

drop policy "experiment_segments_emergency" on "public"."experiment_segments";

drop policy "experiments_unified" on "public"."experiments";

drop policy "external_resources_optimized_policy" on "public"."external_resources";

drop policy "icp_mining - authenticated can delete in site" on "public"."icp_mining";

drop policy "icp_mining - authenticated can insert in site" on "public"."icp_mining";

drop policy "icp_mining - authenticated can select in site" on "public"."icp_mining";

drop policy "icp_mining - authenticated can update in site" on "public"."icp_mining";

drop policy "instance_logs_access_policy" on "public"."instance_logs";

drop policy "instance_plans_access_policy" on "public"."instance_plans";

drop policy "kpis_optimized_policy" on "public"."kpis";

drop policy "layers_delete_owner_admin" on "public"."layers";

drop policy "layers_insert_owner_admin" on "public"."layers";

drop policy "layers_select_owner_admin" on "public"."layers";

drop policy "layers_update_owner_admin" on "public"."layers";

drop policy "leads_unified" on "public"."leads";

drop policy "payments_select_optimized" on "public"."payments";

drop policy "remote_instances_access_policy" on "public"."remote_instances";

drop policy "requirement_segments_optimized_policy" on "public"."requirement_segments";

drop policy "requirements_optimized_policy" on "public"."requirements";

drop policy "role_query_segments - authenticated can delete in site" on "public"."role_query_segments";

drop policy "role_query_segments - authenticated can insert in site" on "public"."role_query_segments";

drop policy "role_query_segments - authenticated can select in site" on "public"."role_query_segments";

drop policy "role_query_segments - authenticated can update in site" on "public"."role_query_segments";

drop policy "Users can manage sale orders for their sites" on "public"."sale_orders";

drop policy "sales_unified" on "public"."sales";

drop policy "sections_delete_owner_admin" on "public"."sections";

drop policy "sections_insert_owner_admin" on "public"."sections";

drop policy "sections_select_owner_admin" on "public"."sections";

drop policy "sections_update_owner_admin" on "public"."sections";

drop policy "Users can delete their own tokens" on "public"."secure_tokens";

drop policy "Users can insert their own tokens" on "public"."secure_tokens";

drop policy "Users can update their own tokens" on "public"."secure_tokens";

drop policy "Users can view their own tokens" on "public"."secure_tokens";

drop policy "segments_unified" on "public"."segments";

drop policy "settings_optimized_policy" on "public"."settings";

drop policy "site_members_final_policy" on "public"."site_members";

drop policy "sites_select_policy" on "public"."sites";

drop policy "sites_update_policy" on "public"."sites";

drop policy "states_delete_owner_admin" on "public"."states";

drop policy "states_insert_owner_admin" on "public"."states";

drop policy "states_select_owner_admin" on "public"."states";

drop policy "states_update_owner_admin" on "public"."states";

drop policy "Users can manage task categories for their tasks" on "public"."task_categories";

drop policy "task_comments_final_policy" on "public"."task_comments";

drop policy "tasks_unified" on "public"."tasks";

drop policy "Users can manage transactions for their sites" on "public"."transactions";

drop policy "transitions_delete_owner_admin" on "public"."transitions";

drop policy "transitions_insert_owner_admin" on "public"."transitions";

drop policy "transitions_select_owner_admin" on "public"."transitions";

drop policy "transitions_update_owner_admin" on "public"."transitions";

drop policy "variants_delete_owner_admin" on "public"."variants";

drop policy "variants_insert_owner_admin" on "public"."variants";

drop policy "variants_select_owner_admin" on "public"."variants";

drop policy "variants_update_owner_admin" on "public"."variants";

drop policy "visitor_sessions_unified" on "public"."visitor_sessions";

drop policy "visitors_optimized" on "public"."visitors";

drop policy "webhook_events_users_policy" on "public"."webhook_events";

drop policy "webhooks_deliveries_unified" on "public"."webhooks_deliveries";

drop policy "webhooks_endpoints_unified" on "public"."webhooks_endpoints";

drop policy "webhooks_subscriptions_unified" on "public"."webhooks_subscriptions";

alter table "public"."activity" drop constraint "activity_site_id_fkey";

alter table "public"."agent_assets" drop constraint "agent_assets_agent_id_fkey";

alter table "public"."agent_assets" drop constraint "agent_assets_asset_id_fkey";

alter table "public"."agent_assets" drop constraint "fk_command_agent_assets";

alter table "public"."agent_memories" drop constraint "fk_command_agent_memories";

alter table "public"."agents" drop constraint "agents_site_id_fkey";

alter table "public"."agents" drop constraint "agents_supervisor_fkey";

alter table "public"."agents" drop constraint "fk_command_agents";

alter table "public"."allowed_domains" drop constraint "allowed_domains_site_id_fkey";

alter table "public"."analysis" drop constraint "analysis_site_id_fkey";

alter table "public"."analysis" drop constraint "fk_command_analysis";

alter table "public"."api_keys" drop constraint "fk_site";

alter table "public"."assets" drop constraint "assets_instance_id_fkey";

alter table "public"."assets" drop constraint "assets_site_id_fkey";

alter table "public"."assets" drop constraint "fk_command_assets";

alter table "public"."automation_auth_sessions" drop constraint "automation_auth_sessions_instance_id_fkey";

alter table "public"."automation_auth_sessions" drop constraint "automation_auth_sessions_site_id_fkey";

alter table "public"."billing" drop constraint "billing_site_id_fkey";

alter table "public"."billing" drop constraint "fk_command_billing";

alter table "public"."campaign_requirements" drop constraint "campaign_requirements_campaign_id_fkey";

alter table "public"."campaign_requirements" drop constraint "campaign_requirements_requirement_id_fkey";

alter table "public"."campaign_requirements" drop constraint "fk_command_campaign_requirements";

alter table "public"."campaign_segments" drop constraint "campaign_segments_campaign_id_fkey";

alter table "public"."campaign_segments" drop constraint "campaign_segments_segment_id_fkey";

alter table "public"."campaign_segments" drop constraint "fk_command_campaign_segments";

alter table "public"."campaign_subtasks" drop constraint "campaign_subtasks_campaign_id_fkey";

alter table "public"."campaign_subtasks" drop constraint "fk_command_campaign_subtasks";

alter table "public"."campaigns" drop constraint "campaigns_site_id_fkey";

alter table "public"."campaigns" drop constraint "fk_command_campaigns";

alter table "public"."categories" drop constraint "categories_site_id_fkey";

alter table "public"."commands" drop constraint "commands_agent_id_fkey";

alter table "public"."commands" drop constraint "commands_site_id_fkey";

alter table "public"."companies" drop constraint "companies_acquired_by_id_fkey";

alter table "public"."companies" drop constraint "companies_parent_company_id_fkey";

alter table "public"."content" drop constraint "content_campaign_id_fkey";

alter table "public"."content" drop constraint "content_command_id_fkey";

alter table "public"."content" drop constraint "content_segment_id_fkey";

alter table "public"."content" drop constraint "content_site_id_fkey";

alter table "public"."content_assets" drop constraint "content_assets_asset_id_fkey";

alter table "public"."content_assets" drop constraint "content_assets_content_id_fkey";

alter table "public"."conversations" drop constraint "conversations_agent_id_fkey";

alter table "public"."conversations" drop constraint "conversations_delegate_id_fkey";

alter table "public"."conversations" drop constraint "conversations_lead_id_fkey";

alter table "public"."conversations" drop constraint "conversations_site_id_fkey";

alter table "public"."conversations" drop constraint "fk_command_conversations";

alter table "public"."conversations" drop constraint "fk_visitor";

alter table "public"."copywriting" drop constraint "copywriting_site_id_fkey";

alter table "public"."cron_status" drop constraint "cron_status_site_id_fkey";

alter table "public"."customizations" drop constraint "customizations_element_id_fkey";

alter table "public"."debug_logs" drop constraint "fk_command_debug_logs";

alter table "public"."editor" drop constraint "editor_site_id_fkey";

alter table "public"."elements" drop constraint "elements_layer_id_fkey";

alter table "public"."experiment_segments" drop constraint "experiment_segments_experiment_id_fkey";

alter table "public"."experiment_segments" drop constraint "experiment_segments_segment_id_fkey";

alter table "public"."experiment_segments" drop constraint "fk_command_experiment_segments";

alter table "public"."experiments" drop constraint "experiments_campaign_id_fkey";

alter table "public"."experiments" drop constraint "experiments_site_id_fkey";

alter table "public"."experiments" drop constraint "fk_command_experiments";

alter table "public"."external_resources" drop constraint "external_resources_site_id_fkey";

alter table "public"."external_resources" drop constraint "fk_command_external_resources";

alter table "public"."icp_mining" drop constraint "icp_mining_role_query_id_fkey";

alter table "public"."icp_mining" drop constraint "icp_mining_site_id_fkey";

alter table "public"."instance_logs" drop constraint "fk_command_instance_logs";

alter table "public"."instance_logs" drop constraint "instance_logs_agent_id_fkey";

alter table "public"."instance_logs" drop constraint "instance_logs_instance_id_fkey";

alter table "public"."instance_logs" drop constraint "instance_logs_parent_log_id_fkey";

alter table "public"."instance_logs" drop constraint "instance_logs_site_id_fkey";

alter table "public"."instance_plans" drop constraint "fk_command_instance_plans";

alter table "public"."instance_plans" drop constraint "instance_plans_agent_id_fkey";

alter table "public"."instance_plans" drop constraint "instance_plans_instance_id_fkey";

alter table "public"."instance_plans" drop constraint "instance_plans_parent_plan_id_fkey";

alter table "public"."instance_plans" drop constraint "instance_plans_site_id_fkey";

alter table "public"."kpis" drop constraint "fk_command_kpis";

alter table "public"."kpis" drop constraint "kpis_segment_id_fkey";

alter table "public"."kpis" drop constraint "kpis_site_id_fkey";

alter table "public"."layers" drop constraint "layers_state_id_fkey";

alter table "public"."lead_analysis" drop constraint "lead_analysis_site_id_fkey";

alter table "public"."leads" drop constraint "fk_command_leads";

alter table "public"."leads" drop constraint "leads_campaign_id_fkey";

alter table "public"."leads" drop constraint "leads_company_id_fkey";

alter table "public"."leads" drop constraint "leads_person_id_fkey";

alter table "public"."leads" drop constraint "leads_referral_lead_id_fkey";

alter table "public"."leads" drop constraint "leads_segment_id_fkey";

alter table "public"."leads" drop constraint "leads_site_id_fkey";

alter table "public"."messages" drop constraint "fk_command_messages";

alter table "public"."messages" drop constraint "fk_conversation";

alter table "public"."messages" drop constraint "fk_lead";

alter table "public"."messages" drop constraint "fk_visitor";

alter table "public"."notifications" drop constraint "fk_command_notifications";

alter table "public"."notifications" drop constraint "notifications_site_id_fkey";

alter table "public"."payments" drop constraint "fk_command_payments";

alter table "public"."payments" drop constraint "payments_site_id_fkey";

alter table "public"."persons" drop constraint "persons_role_query_id_fkey";

alter table "public"."profiles" drop constraint "fk_command_profiles";

alter table "public"."profiles" drop constraint "valid_notifications";

alter table "public"."referral_code_uses" drop constraint "referral_code_uses_referral_code_id_fkey";

alter table "public"."remote_instances" drop constraint "fk_command_remote_instances";

alter table "public"."remote_instances" drop constraint "remote_instances_agent_id_fkey";

alter table "public"."remote_instances" drop constraint "remote_instances_site_id_fkey";

alter table "public"."requirement_segments" drop constraint "fk_command_requirement_segments";

alter table "public"."requirement_segments" drop constraint "requirement_segments_requirement_id_fkey";

alter table "public"."requirement_segments" drop constraint "requirement_segments_segment_id_fkey";

alter table "public"."requirements" drop constraint "fk_command_requirements";

alter table "public"."requirements" drop constraint "requirements_site_id_fkey";

alter table "public"."role_query_segments" drop constraint "role_query_segments_role_query_id_fkey";

alter table "public"."role_query_segments" drop constraint "role_query_segments_segment_id_fkey";

alter table "public"."sale_orders" drop constraint "sale_orders_sale_id_fkey";

alter table "public"."sale_orders" drop constraint "sale_orders_site_id_fkey";

alter table "public"."sales" drop constraint "fk_command_sales";

alter table "public"."sales" drop constraint "sales_campaign_id_fkey";

alter table "public"."sales" drop constraint "sales_lead_id_fkey";

alter table "public"."sales" drop constraint "sales_segment_id_fkey";

alter table "public"."sales" drop constraint "sales_site_id_fkey";

alter table "public"."sections" drop constraint "sections_site_id_fkey";

alter table "public"."secure_tokens" drop constraint "secure_tokens_site_id_fkey";

alter table "public"."segments" drop constraint "fk_command_segments";

alter table "public"."segments" drop constraint "segments_audience_check";

alter table "public"."segments" drop constraint "segments_language_check";

alter table "public"."segments" drop constraint "segments_site_id_fkey";

alter table "public"."session_events" drop constraint "fk_command_session_events";

alter table "public"."session_events" drop constraint "fk_visitor_session";

alter table "public"."session_events" drop constraint "session_events_segment_id_fkey";

alter table "public"."session_events" drop constraint "session_events_visitor_id_fkey";

alter table "public"."settings" drop constraint "fk_command_settings";

alter table "public"."settings" drop constraint "settings_site_id_fkey";

alter table "public"."site_members" drop constraint "site_members_site_id_fkey";

alter table "public"."site_ownership" drop constraint "site_ownership_site_id_fkey";

alter table "public"."sites" drop constraint "fk_command_sites";

alter table "public"."states" drop constraint "states_section_id_fkey";

alter table "public"."system_memories" drop constraint "fk_command_system_memories";

alter table "public"."system_memories" drop constraint "system_memories_site_id_fkey";

alter table "public"."task_categories" drop constraint "task_categories_category_id_fkey";

alter table "public"."task_categories" drop constraint "task_categories_task_id_fkey";

alter table "public"."task_comments" drop constraint "task_comments_task_id_fkey";

alter table "public"."tasks" drop constraint "fk_command_tasks";

alter table "public"."tasks" drop constraint "tasks_conversation_id_fkey";

alter table "public"."tasks" drop constraint "tasks_lead_id_fkey";

alter table "public"."tasks" drop constraint "tasks_site_id_fkey";

alter table "public"."transactions" drop constraint "fk_command_transactions";

alter table "public"."transactions" drop constraint "transactions_campaign_id_fkey";

alter table "public"."transactions" drop constraint "transactions_site_id_fkey";

alter table "public"."transitions" drop constraint "transitions_from_state_id_fkey";

alter table "public"."transitions" drop constraint "transitions_to_state_id_fkey";

alter table "public"."variants" drop constraint "variants_state_id_fkey";

alter table "public"."visitor_sessions" drop constraint "fk_command_visitor_sessions";

alter table "public"."visitor_sessions" drop constraint "visitor_sessions_lead_id_fkey";

alter table "public"."visitor_sessions" drop constraint "visitor_sessions_visitor_id_fkey";

alter table "public"."visitors" drop constraint "fk_command_visitors";

alter table "public"."visitors" drop constraint "visitors_campaign_id_fkey";

alter table "public"."visitors" drop constraint "visitors_experiment_id_fkey";

alter table "public"."visitors" drop constraint "visitors_segment_id_fkey";

alter table "public"."webhooks_deliveries" drop constraint "webhooks_deliveries_endpoint_id_fkey";

alter table "public"."webhooks_deliveries" drop constraint "webhooks_deliveries_site_id_fkey";

alter table "public"."webhooks_deliveries" drop constraint "webhooks_deliveries_subscription_id_fkey";

alter table "public"."webhooks_endpoints" drop constraint "webhooks_endpoints_site_id_fkey";

alter table "public"."webhooks_subscriptions" drop constraint "webhooks_subscriptions_endpoint_id_fkey";

alter table "public"."webhooks_subscriptions" drop constraint "webhooks_subscriptions_site_id_fkey";

drop view if exists "public"."commands_dislikes";

drop view if exists "public"."commands_flags";

drop view if exists "public"."commands_likes";

drop index if exists "public"."idx_companies_name";


  create table "public"."remote_sessions" (
    "id" uuid not null default gen_random_uuid(),
    "phone_number" text not null,
    "user_id" uuid,
    "site_id" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."remote_sessions" enable row level security;


  create table "public"."requirement_status" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "site_id" uuid not null,
    "instance_id" uuid not null,
    "asset_id" uuid not null,
    "requirement_id" uuid not null,
    "repo_url" text,
    "status" text not null,
    "message" text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."requirement_status" enable row level security;

alter table "public"."api_keys" alter column "status" set default 'active'::public.key_status;

alter table "public"."api_keys" alter column "status" set data type public.key_status using "status"::text::public.key_status;

alter table "public"."billing" alter column "id" set default extensions.uuid_generate_v4();

alter table "public"."campaigns" alter column "priority" set default 'medium'::public.campaign_priority;

alter table "public"."campaigns" alter column "priority" set data type public.campaign_priority using "priority"::text::public.campaign_priority;

alter table "public"."campaigns" alter column "status" set default 'pending'::public.campaign_status;

alter table "public"."campaigns" alter column "status" set data type public.campaign_status using "status"::text::public.campaign_status;

alter table "public"."commands" alter column "status" set default 'pending'::public.command_status;

alter table "public"."commands" alter column "status" set data type public.command_status using "status"::text::public.command_status;

alter table "public"."content" alter column "id" set default extensions.uuid_generate_v4();

-- alter table "public"."icp_mining" alter column "icp_hash" set default encode(extensions.digest((icp_criteria)::text, 'sha256'::text), 'hex'::text);

alter table "public"."payments" alter column "id" set default extensions.uuid_generate_v4();

alter table "public"."requirements" alter column "type" set default 'task'::public.requirement_type;

alter table "public"."requirements" alter column "type" set data type public.requirement_type using "type"::text::public.requirement_type;

-- alter table "public"."role_queries" alter column "query_hash" set default encode(extensions.digest((query)::text, 'sha256'::text), 'hex'::text);

alter table "public"."sale_orders" alter column "id" set default extensions.uuid_generate_v4();

alter table "public"."secure_tokens" alter column "id" set default extensions.uuid_generate_v4();

alter table "public"."segments" alter column "audience" set data type public.segment_audience using "audience"::text::public.segment_audience;

alter table "public"."segments" alter column "language" set default 'en'::public.segment_language;

alter table "public"."segments" alter column "language" set data type public.segment_language using "language"::text::public.segment_language;

CREATE INDEX idx_req_status_instance_id ON public.requirement_status USING btree (instance_id);

CREATE INDEX idx_req_status_requirement_id ON public.requirement_status USING btree (requirement_id);

CREATE INDEX idx_req_status_site_id ON public.requirement_status USING btree (site_id);

CREATE UNIQUE INDEX remote_sessions_phone_number_key ON public.remote_sessions USING btree (phone_number);

CREATE UNIQUE INDEX remote_sessions_pkey ON public.remote_sessions USING btree (id);

CREATE UNIQUE INDEX requirement_status_pkey ON public.requirement_status USING btree (id);

CREATE INDEX idx_companies_name ON public.companies USING gin (name extensions.gin_trgm_ops);

alter table "public"."remote_sessions" add constraint "remote_sessions_pkey" PRIMARY KEY using index "remote_sessions_pkey";

alter table "public"."requirement_status" add constraint "requirement_status_pkey" PRIMARY KEY using index "requirement_status_pkey";

alter table "public"."remote_sessions" add constraint "remote_sessions_phone_number_key" UNIQUE using index "remote_sessions_phone_number_key";

alter table "public"."remote_sessions" add constraint "remote_sessions_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE SET NULL not valid;

alter table "public"."remote_sessions" validate constraint "remote_sessions_site_id_fkey";

alter table "public"."remote_sessions" add constraint "remote_sessions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."remote_sessions" validate constraint "remote_sessions_user_id_fkey";

alter table "public"."requirement_status" add constraint "fk_requirement_status_requirement" FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE not valid;

alter table "public"."requirement_status" validate constraint "fk_requirement_status_requirement";

alter table "public"."requirement_status" add constraint "fk_requirement_status_site" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."requirement_status" validate constraint "fk_requirement_status_site";

alter table "public"."activity" add constraint "activity_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."activity" validate constraint "activity_site_id_fkey";

alter table "public"."agent_assets" add constraint "agent_assets_agent_id_fkey" FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE not valid;

alter table "public"."agent_assets" validate constraint "agent_assets_agent_id_fkey";

alter table "public"."agent_assets" add constraint "agent_assets_asset_id_fkey" FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE not valid;

alter table "public"."agent_assets" validate constraint "agent_assets_asset_id_fkey";

alter table "public"."agent_assets" add constraint "fk_command_agent_assets" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."agent_assets" validate constraint "fk_command_agent_assets";

alter table "public"."agent_memories" add constraint "fk_command_agent_memories" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."agent_memories" validate constraint "fk_command_agent_memories";

alter table "public"."agents" add constraint "agents_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."agents" validate constraint "agents_site_id_fkey";

alter table "public"."agents" add constraint "agents_supervisor_fkey" FOREIGN KEY (supervisor) REFERENCES public.agents(id) not valid;

alter table "public"."agents" validate constraint "agents_supervisor_fkey";

alter table "public"."agents" add constraint "fk_command_agents" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."agents" validate constraint "fk_command_agents";

alter table "public"."allowed_domains" add constraint "allowed_domains_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."allowed_domains" validate constraint "allowed_domains_site_id_fkey";

alter table "public"."analysis" add constraint "analysis_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."analysis" validate constraint "analysis_site_id_fkey";

alter table "public"."analysis" add constraint "fk_command_analysis" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."analysis" validate constraint "fk_command_analysis";

alter table "public"."api_keys" add constraint "fk_site" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."api_keys" validate constraint "fk_site";

alter table "public"."assets" add constraint "assets_instance_id_fkey" FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."assets" validate constraint "assets_instance_id_fkey";

alter table "public"."assets" add constraint "assets_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."assets" validate constraint "assets_site_id_fkey";

alter table "public"."assets" add constraint "fk_command_assets" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."assets" validate constraint "fk_command_assets";

alter table "public"."automation_auth_sessions" add constraint "automation_auth_sessions_instance_id_fkey" FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE SET NULL not valid;

alter table "public"."automation_auth_sessions" validate constraint "automation_auth_sessions_instance_id_fkey";

alter table "public"."automation_auth_sessions" add constraint "automation_auth_sessions_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."automation_auth_sessions" validate constraint "automation_auth_sessions_site_id_fkey";

alter table "public"."billing" add constraint "billing_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."billing" validate constraint "billing_site_id_fkey";

alter table "public"."billing" add constraint "fk_command_billing" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."billing" validate constraint "fk_command_billing";

alter table "public"."campaign_requirements" add constraint "campaign_requirements_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_requirements" validate constraint "campaign_requirements_campaign_id_fkey";

alter table "public"."campaign_requirements" add constraint "campaign_requirements_requirement_id_fkey" FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_requirements" validate constraint "campaign_requirements_requirement_id_fkey";

alter table "public"."campaign_requirements" add constraint "fk_command_campaign_requirements" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_requirements" validate constraint "fk_command_campaign_requirements";

alter table "public"."campaign_segments" add constraint "campaign_segments_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_segments" validate constraint "campaign_segments_campaign_id_fkey";

alter table "public"."campaign_segments" add constraint "campaign_segments_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_segments" validate constraint "campaign_segments_segment_id_fkey";

alter table "public"."campaign_segments" add constraint "fk_command_campaign_segments" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_segments" validate constraint "fk_command_campaign_segments";

alter table "public"."campaign_subtasks" add constraint "campaign_subtasks_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_subtasks" validate constraint "campaign_subtasks_campaign_id_fkey";

alter table "public"."campaign_subtasks" add constraint "fk_command_campaign_subtasks" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."campaign_subtasks" validate constraint "fk_command_campaign_subtasks";

alter table "public"."campaigns" add constraint "campaigns_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."campaigns" validate constraint "campaigns_site_id_fkey";

alter table "public"."campaigns" add constraint "fk_command_campaigns" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."campaigns" validate constraint "fk_command_campaigns";

alter table "public"."categories" add constraint "categories_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."categories" validate constraint "categories_site_id_fkey";

alter table "public"."commands" add constraint "commands_agent_id_fkey" FOREIGN KEY (agent_id) REFERENCES public.agents(id) not valid;

alter table "public"."commands" validate constraint "commands_agent_id_fkey";

alter table "public"."commands" add constraint "commands_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."commands" validate constraint "commands_site_id_fkey";

alter table "public"."companies" add constraint "companies_acquired_by_id_fkey" FOREIGN KEY (acquired_by_id) REFERENCES public.companies(id) not valid;

alter table "public"."companies" validate constraint "companies_acquired_by_id_fkey";

alter table "public"."companies" add constraint "companies_parent_company_id_fkey" FOREIGN KEY (parent_company_id) REFERENCES public.companies(id) not valid;

alter table "public"."companies" validate constraint "companies_parent_company_id_fkey";

alter table "public"."content" add constraint "content_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL not valid;

alter table "public"."content" validate constraint "content_campaign_id_fkey";

alter table "public"."content" add constraint "content_command_id_fkey" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."content" validate constraint "content_command_id_fkey";

alter table "public"."content" add constraint "content_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) not valid;

alter table "public"."content" validate constraint "content_segment_id_fkey";

alter table "public"."content" add constraint "content_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."content" validate constraint "content_site_id_fkey";

alter table "public"."content_assets" add constraint "content_assets_asset_id_fkey" FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE not valid;

alter table "public"."content_assets" validate constraint "content_assets_asset_id_fkey";

alter table "public"."content_assets" add constraint "content_assets_content_id_fkey" FOREIGN KEY (content_id) REFERENCES public.content(id) ON DELETE CASCADE not valid;

alter table "public"."content_assets" validate constraint "content_assets_content_id_fkey";

alter table "public"."conversations" add constraint "conversations_agent_id_fkey" FOREIGN KEY (agent_id) REFERENCES public.agents(id) not valid;

alter table "public"."conversations" validate constraint "conversations_agent_id_fkey";

alter table "public"."conversations" add constraint "conversations_delegate_id_fkey" FOREIGN KEY (delegate_id) REFERENCES public.agents(id) not valid;

alter table "public"."conversations" validate constraint "conversations_delegate_id_fkey";

alter table "public"."conversations" add constraint "conversations_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."conversations" validate constraint "conversations_lead_id_fkey";

alter table "public"."conversations" add constraint "conversations_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."conversations" validate constraint "conversations_site_id_fkey";

alter table "public"."conversations" add constraint "fk_command_conversations" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."conversations" validate constraint "fk_command_conversations";

alter table "public"."conversations" add constraint "fk_visitor" FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE SET NULL not valid;

alter table "public"."conversations" validate constraint "fk_visitor";

alter table "public"."copywriting" add constraint "copywriting_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."copywriting" validate constraint "copywriting_site_id_fkey";

alter table "public"."cron_status" add constraint "cron_status_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."cron_status" validate constraint "cron_status_site_id_fkey";

alter table "public"."customizations" add constraint "customizations_element_id_fkey" FOREIGN KEY (element_id) REFERENCES public.elements(id) ON DELETE CASCADE not valid;

alter table "public"."customizations" validate constraint "customizations_element_id_fkey";

alter table "public"."debug_logs" add constraint "fk_command_debug_logs" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."debug_logs" validate constraint "fk_command_debug_logs";

alter table "public"."editor" add constraint "editor_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."editor" validate constraint "editor_site_id_fkey";

alter table "public"."elements" add constraint "elements_layer_id_fkey" FOREIGN KEY (layer_id) REFERENCES public.layers(id) ON DELETE CASCADE not valid;

alter table "public"."elements" validate constraint "elements_layer_id_fkey";

alter table "public"."experiment_segments" add constraint "experiment_segments_experiment_id_fkey" FOREIGN KEY (experiment_id) REFERENCES public.experiments(id) ON DELETE CASCADE not valid;

alter table "public"."experiment_segments" validate constraint "experiment_segments_experiment_id_fkey";

alter table "public"."experiment_segments" add constraint "experiment_segments_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE not valid;

alter table "public"."experiment_segments" validate constraint "experiment_segments_segment_id_fkey";

alter table "public"."experiment_segments" add constraint "fk_command_experiment_segments" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."experiment_segments" validate constraint "fk_command_experiment_segments";

alter table "public"."experiments" add constraint "experiments_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL not valid;

alter table "public"."experiments" validate constraint "experiments_campaign_id_fkey";

alter table "public"."experiments" add constraint "experiments_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."experiments" validate constraint "experiments_site_id_fkey";

alter table "public"."experiments" add constraint "fk_command_experiments" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."experiments" validate constraint "fk_command_experiments";

alter table "public"."external_resources" add constraint "external_resources_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."external_resources" validate constraint "external_resources_site_id_fkey";

alter table "public"."external_resources" add constraint "fk_command_external_resources" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."external_resources" validate constraint "fk_command_external_resources";

alter table "public"."icp_mining" add constraint "icp_mining_role_query_id_fkey" FOREIGN KEY (role_query_id) REFERENCES public.role_queries(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."icp_mining" validate constraint "icp_mining_role_query_id_fkey";

alter table "public"."icp_mining" add constraint "icp_mining_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."icp_mining" validate constraint "icp_mining_site_id_fkey";

alter table "public"."instance_logs" add constraint "fk_command_instance_logs" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE SET NULL not valid;

alter table "public"."instance_logs" validate constraint "fk_command_instance_logs";

alter table "public"."instance_logs" add constraint "instance_logs_agent_id_fkey" FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE SET NULL not valid;

alter table "public"."instance_logs" validate constraint "instance_logs_agent_id_fkey";

alter table "public"."instance_logs" add constraint "instance_logs_instance_id_fkey" FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE not valid;

alter table "public"."instance_logs" validate constraint "instance_logs_instance_id_fkey";

alter table "public"."instance_logs" add constraint "instance_logs_parent_log_id_fkey" FOREIGN KEY (parent_log_id) REFERENCES public.instance_logs(id) ON DELETE SET NULL not valid;

alter table "public"."instance_logs" validate constraint "instance_logs_parent_log_id_fkey";

alter table "public"."instance_logs" add constraint "instance_logs_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."instance_logs" validate constraint "instance_logs_site_id_fkey";

alter table "public"."instance_plans" add constraint "fk_command_instance_plans" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE SET NULL not valid;

alter table "public"."instance_plans" validate constraint "fk_command_instance_plans";

alter table "public"."instance_plans" add constraint "instance_plans_agent_id_fkey" FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE SET NULL not valid;

alter table "public"."instance_plans" validate constraint "instance_plans_agent_id_fkey";

alter table "public"."instance_plans" add constraint "instance_plans_instance_id_fkey" FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE CASCADE not valid;

alter table "public"."instance_plans" validate constraint "instance_plans_instance_id_fkey";

alter table "public"."instance_plans" add constraint "instance_plans_parent_plan_id_fkey" FOREIGN KEY (parent_plan_id) REFERENCES public.instance_plans(id) ON DELETE CASCADE not valid;

alter table "public"."instance_plans" validate constraint "instance_plans_parent_plan_id_fkey";

alter table "public"."instance_plans" add constraint "instance_plans_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."instance_plans" validate constraint "instance_plans_site_id_fkey";

alter table "public"."kpis" add constraint "fk_command_kpis" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."kpis" validate constraint "fk_command_kpis";

alter table "public"."kpis" add constraint "kpis_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE SET NULL not valid;

alter table "public"."kpis" validate constraint "kpis_segment_id_fkey";

alter table "public"."kpis" add constraint "kpis_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."kpis" validate constraint "kpis_site_id_fkey";

alter table "public"."layers" add constraint "layers_state_id_fkey" FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE not valid;

alter table "public"."layers" validate constraint "layers_state_id_fkey";

alter table "public"."lead_analysis" add constraint "lead_analysis_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE SET NULL not valid;

alter table "public"."lead_analysis" validate constraint "lead_analysis_site_id_fkey";

alter table "public"."leads" add constraint "fk_command_leads" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."leads" validate constraint "fk_command_leads";

alter table "public"."leads" add constraint "leads_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) not valid;

alter table "public"."leads" validate constraint "leads_campaign_id_fkey";

alter table "public"."leads" add constraint "leads_company_id_fkey" FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL not valid;

alter table "public"."leads" validate constraint "leads_company_id_fkey";

alter table "public"."leads" add constraint "leads_person_id_fkey" FOREIGN KEY (person_id) REFERENCES public.persons(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."leads" validate constraint "leads_person_id_fkey";

alter table "public"."leads" add constraint "leads_referral_lead_id_fkey" FOREIGN KEY (referral_lead_id) REFERENCES public.leads(id) not valid;

alter table "public"."leads" validate constraint "leads_referral_lead_id_fkey";

alter table "public"."leads" add constraint "leads_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) not valid;

alter table "public"."leads" validate constraint "leads_segment_id_fkey";

alter table "public"."leads" add constraint "leads_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."leads" validate constraint "leads_site_id_fkey";

alter table "public"."messages" add constraint "fk_command_messages" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "fk_command_messages";

alter table "public"."messages" add constraint "fk_conversation" FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "fk_conversation";

alter table "public"."messages" add constraint "fk_lead" FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL not valid;

alter table "public"."messages" validate constraint "fk_lead";

alter table "public"."messages" add constraint "fk_visitor" FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE SET NULL not valid;

alter table "public"."messages" validate constraint "fk_visitor";

alter table "public"."notifications" add constraint "fk_command_notifications" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "fk_command_notifications";

alter table "public"."notifications" add constraint "notifications_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "notifications_site_id_fkey";

alter table "public"."payments" add constraint "fk_command_payments" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."payments" validate constraint "fk_command_payments";

alter table "public"."payments" add constraint "payments_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."payments" validate constraint "payments_site_id_fkey";

alter table "public"."persons" add constraint "persons_role_query_id_fkey" FOREIGN KEY (role_query_id) REFERENCES public.role_queries(id) ON DELETE SET NULL not valid;

alter table "public"."persons" validate constraint "persons_role_query_id_fkey";

alter table "public"."profiles" add constraint "fk_command_profiles" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."profiles" validate constraint "fk_command_profiles";

alter table "public"."profiles" add constraint "valid_notifications" CHECK (public.validate_notifications(notifications)) not valid;

alter table "public"."profiles" validate constraint "valid_notifications";

alter table "public"."referral_code_uses" add constraint "referral_code_uses_referral_code_id_fkey" FOREIGN KEY (referral_code_id) REFERENCES public.referral_codes(id) ON DELETE CASCADE not valid;

alter table "public"."referral_code_uses" validate constraint "referral_code_uses_referral_code_id_fkey";

alter table "public"."remote_instances" add constraint "fk_command_remote_instances" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE SET NULL not valid;

alter table "public"."remote_instances" validate constraint "fk_command_remote_instances";

alter table "public"."remote_instances" add constraint "remote_instances_agent_id_fkey" FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE SET NULL not valid;

alter table "public"."remote_instances" validate constraint "remote_instances_agent_id_fkey";

alter table "public"."remote_instances" add constraint "remote_instances_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."remote_instances" validate constraint "remote_instances_site_id_fkey";

alter table "public"."requirement_segments" add constraint "fk_command_requirement_segments" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."requirement_segments" validate constraint "fk_command_requirement_segments";

alter table "public"."requirement_segments" add constraint "requirement_segments_requirement_id_fkey" FOREIGN KEY (requirement_id) REFERENCES public.requirements(id) ON DELETE CASCADE not valid;

alter table "public"."requirement_segments" validate constraint "requirement_segments_requirement_id_fkey";

alter table "public"."requirement_segments" add constraint "requirement_segments_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE not valid;

alter table "public"."requirement_segments" validate constraint "requirement_segments_segment_id_fkey";

alter table "public"."requirements" add constraint "fk_command_requirements" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."requirements" validate constraint "fk_command_requirements";

alter table "public"."requirements" add constraint "requirements_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."requirements" validate constraint "requirements_site_id_fkey";

alter table "public"."role_query_segments" add constraint "role_query_segments_role_query_id_fkey" FOREIGN KEY (role_query_id) REFERENCES public.role_queries(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."role_query_segments" validate constraint "role_query_segments_role_query_id_fkey";

alter table "public"."role_query_segments" add constraint "role_query_segments_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE not valid;

alter table "public"."role_query_segments" validate constraint "role_query_segments_segment_id_fkey";

alter table "public"."sale_orders" add constraint "sale_orders_sale_id_fkey" FOREIGN KEY (sale_id) REFERENCES public.sales(id) ON DELETE CASCADE not valid;

alter table "public"."sale_orders" validate constraint "sale_orders_sale_id_fkey";

alter table "public"."sale_orders" add constraint "sale_orders_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."sale_orders" validate constraint "sale_orders_site_id_fkey";

alter table "public"."sales" add constraint "fk_command_sales" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."sales" validate constraint "fk_command_sales";

alter table "public"."sales" add constraint "sales_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL not valid;

alter table "public"."sales" validate constraint "sales_campaign_id_fkey";

alter table "public"."sales" add constraint "sales_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL not valid;

alter table "public"."sales" validate constraint "sales_lead_id_fkey";

alter table "public"."sales" add constraint "sales_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE SET NULL not valid;

alter table "public"."sales" validate constraint "sales_segment_id_fkey";

alter table "public"."sales" add constraint "sales_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."sales" validate constraint "sales_site_id_fkey";

alter table "public"."sections" add constraint "sections_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."sections" validate constraint "sections_site_id_fkey";

alter table "public"."secure_tokens" add constraint "secure_tokens_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."secure_tokens" validate constraint "secure_tokens_site_id_fkey";

alter table "public"."segments" add constraint "fk_command_segments" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."segments" validate constraint "fk_command_segments";

alter table "public"."segments" add constraint "segments_audience_check" CHECK ((audience = ANY (ARRAY['enterprise'::public.segment_audience, 'smb'::public.segment_audience, 'startup'::public.segment_audience, 'b2b_saas'::public.segment_audience, 'e_commerce'::public.segment_audience, 'tech'::public.segment_audience, 'finance'::public.segment_audience, 'healthcare'::public.segment_audience, 'education'::public.segment_audience, 'manufacturing'::public.segment_audience, 'retail'::public.segment_audience, 'real_estate'::public.segment_audience, 'hospitality'::public.segment_audience, 'automotive'::public.segment_audience, 'media'::public.segment_audience, 'telecom'::public.segment_audience, 'energy'::public.segment_audience, 'agriculture'::public.segment_audience, 'construction'::public.segment_audience, 'logistics'::public.segment_audience, 'professional'::public.segment_audience, 'government'::public.segment_audience, 'nonprofit'::public.segment_audience, 'legal'::public.segment_audience, 'pharma'::public.segment_audience, 'insurance'::public.segment_audience, 'consulting'::public.segment_audience, 'research'::public.segment_audience, 'aerospace'::public.segment_audience, 'gaming'::public.segment_audience]))) not valid;

alter table "public"."segments" validate constraint "segments_audience_check";

alter table "public"."segments" add constraint "segments_language_check" CHECK ((language = ANY (ARRAY['en'::public.segment_language, 'zh'::public.segment_language, 'hi'::public.segment_language, 'es'::public.segment_language, 'ar'::public.segment_language, 'bn'::public.segment_language, 'pt'::public.segment_language, 'ru'::public.segment_language, 'ja'::public.segment_language, 'de'::public.segment_language, 'fr'::public.segment_language, 'ur'::public.segment_language, 'id'::public.segment_language, 'tr'::public.segment_language, 'it'::public.segment_language, 'th'::public.segment_language, 'vi'::public.segment_language, 'ko'::public.segment_language, 'fa'::public.segment_language, 'pl'::public.segment_language, 'uk'::public.segment_language, 'ro'::public.segment_language, 'nl'::public.segment_language, 'el'::public.segment_language, 'cs'::public.segment_language, 'sv'::public.segment_language, 'hu'::public.segment_language, 'da'::public.segment_language, 'fi'::public.segment_language, 'no'::public.segment_language]))) not valid;

alter table "public"."segments" validate constraint "segments_language_check";

alter table "public"."segments" add constraint "segments_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."segments" validate constraint "segments_site_id_fkey";

alter table "public"."session_events" add constraint "fk_command_session_events" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."session_events" validate constraint "fk_command_session_events";

alter table "public"."session_events" add constraint "fk_visitor_session" FOREIGN KEY (session_id) REFERENCES public.visitor_sessions(id) ON DELETE CASCADE not valid;

alter table "public"."session_events" validate constraint "fk_visitor_session";

alter table "public"."session_events" add constraint "session_events_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE not valid;

alter table "public"."session_events" validate constraint "session_events_segment_id_fkey";

alter table "public"."session_events" add constraint "session_events_visitor_id_fkey" FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE CASCADE not valid;

alter table "public"."session_events" validate constraint "session_events_visitor_id_fkey";

alter table "public"."settings" add constraint "fk_command_settings" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."settings" validate constraint "fk_command_settings";

alter table "public"."settings" add constraint "settings_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."settings" validate constraint "settings_site_id_fkey";

alter table "public"."site_members" add constraint "site_members_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."site_members" validate constraint "site_members_site_id_fkey";

alter table "public"."site_ownership" add constraint "site_ownership_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."site_ownership" validate constraint "site_ownership_site_id_fkey";

alter table "public"."sites" add constraint "fk_command_sites" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."sites" validate constraint "fk_command_sites";

alter table "public"."states" add constraint "states_section_id_fkey" FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE not valid;

alter table "public"."states" validate constraint "states_section_id_fkey";

alter table "public"."system_memories" add constraint "fk_command_system_memories" FOREIGN KEY (command_id) REFERENCES public.commands(id) not valid;

alter table "public"."system_memories" validate constraint "fk_command_system_memories";

alter table "public"."system_memories" add constraint "system_memories_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."system_memories" validate constraint "system_memories_site_id_fkey";

alter table "public"."task_categories" add constraint "task_categories_category_id_fkey" FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE not valid;

alter table "public"."task_categories" validate constraint "task_categories_category_id_fkey";

alter table "public"."task_categories" add constraint "task_categories_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_categories" validate constraint "task_categories_task_id_fkey";

alter table "public"."task_comments" add constraint "task_comments_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_comments" validate constraint "task_comments_task_id_fkey";

alter table "public"."tasks" add constraint "fk_command_tasks" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."tasks" validate constraint "fk_command_tasks";

alter table "public"."tasks" add constraint "tasks_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."tasks" validate constraint "tasks_conversation_id_fkey";

alter table "public"."tasks" add constraint "tasks_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."tasks" validate constraint "tasks_lead_id_fkey";

alter table "public"."tasks" add constraint "tasks_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."tasks" validate constraint "tasks_site_id_fkey";

alter table "public"."transactions" add constraint "fk_command_transactions" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."transactions" validate constraint "fk_command_transactions";

alter table "public"."transactions" add constraint "transactions_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE not valid;

alter table "public"."transactions" validate constraint "transactions_campaign_id_fkey";

alter table "public"."transactions" add constraint "transactions_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."transactions" validate constraint "transactions_site_id_fkey";

alter table "public"."transitions" add constraint "transitions_from_state_id_fkey" FOREIGN KEY (from_state_id) REFERENCES public.states(id) ON DELETE CASCADE not valid;

alter table "public"."transitions" validate constraint "transitions_from_state_id_fkey";

alter table "public"."transitions" add constraint "transitions_to_state_id_fkey" FOREIGN KEY (to_state_id) REFERENCES public.states(id) ON DELETE CASCADE not valid;

alter table "public"."transitions" validate constraint "transitions_to_state_id_fkey";

alter table "public"."variants" add constraint "variants_state_id_fkey" FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE not valid;

alter table "public"."variants" validate constraint "variants_state_id_fkey";

alter table "public"."visitor_sessions" add constraint "fk_command_visitor_sessions" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_sessions" validate constraint "fk_command_visitor_sessions";

alter table "public"."visitor_sessions" add constraint "visitor_sessions_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_sessions" validate constraint "visitor_sessions_lead_id_fkey";

alter table "public"."visitor_sessions" add constraint "visitor_sessions_visitor_id_fkey" FOREIGN KEY (visitor_id) REFERENCES public.visitors(id) ON DELETE CASCADE not valid;

alter table "public"."visitor_sessions" validate constraint "visitor_sessions_visitor_id_fkey";

alter table "public"."visitors" add constraint "fk_command_visitors" FOREIGN KEY (command_id) REFERENCES public.commands(id) ON DELETE CASCADE not valid;

alter table "public"."visitors" validate constraint "fk_command_visitors";

alter table "public"."visitors" add constraint "visitors_campaign_id_fkey" FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL not valid;

alter table "public"."visitors" validate constraint "visitors_campaign_id_fkey";

alter table "public"."visitors" add constraint "visitors_experiment_id_fkey" FOREIGN KEY (experiment_id) REFERENCES public.experiments(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."visitors" validate constraint "visitors_experiment_id_fkey";

alter table "public"."visitors" add constraint "visitors_segment_id_fkey" FOREIGN KEY (segment_id) REFERENCES public.segments(id) ON DELETE CASCADE not valid;

alter table "public"."visitors" validate constraint "visitors_segment_id_fkey";

alter table "public"."webhooks_deliveries" add constraint "webhooks_deliveries_endpoint_id_fkey" FOREIGN KEY (endpoint_id) REFERENCES public.webhooks_endpoints(id) ON DELETE CASCADE not valid;

alter table "public"."webhooks_deliveries" validate constraint "webhooks_deliveries_endpoint_id_fkey";

alter table "public"."webhooks_deliveries" add constraint "webhooks_deliveries_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."webhooks_deliveries" validate constraint "webhooks_deliveries_site_id_fkey";

alter table "public"."webhooks_deliveries" add constraint "webhooks_deliveries_subscription_id_fkey" FOREIGN KEY (subscription_id) REFERENCES public.webhooks_subscriptions(id) ON DELETE SET NULL not valid;

alter table "public"."webhooks_deliveries" validate constraint "webhooks_deliveries_subscription_id_fkey";

alter table "public"."webhooks_endpoints" add constraint "webhooks_endpoints_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."webhooks_endpoints" validate constraint "webhooks_endpoints_site_id_fkey";

alter table "public"."webhooks_subscriptions" add constraint "webhooks_subscriptions_endpoint_id_fkey" FOREIGN KEY (endpoint_id) REFERENCES public.webhooks_endpoints(id) ON DELETE CASCADE not valid;

alter table "public"."webhooks_subscriptions" validate constraint "webhooks_subscriptions_endpoint_id_fkey";

alter table "public"."webhooks_subscriptions" add constraint "webhooks_subscriptions_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."webhooks_subscriptions" validate constraint "webhooks_subscriptions_site_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_user_by_phone(phone_variants text[])
 RETURNS TABLE(id uuid, phone text, raw_user_meta_data jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  SELECT au.id, au.phone::text, au.raw_user_meta_data
  FROM auth.users au
  WHERE au.phone = ANY(phone_variants)
     OR au.raw_user_meta_data->>'phone' = ANY(phone_variants);
END;
$function$
;

create or replace view "public"."commands_dislikes" as  SELECT id,
    task,
    status,
    description,
    results,
    targets,
    tools,
    context,
    supervisor,
    created_at,
    updated_at,
    completion_date,
    duration,
    model,
    agent_id,
    user_id,
    output_tokens,
    input_tokens,
    site_id,
    agent_background,
    functions,
    performance
   FROM public.commands
  WHERE ((performance & 2) = 2);


create or replace view "public"."commands_flags" as  SELECT id,
    task,
    status,
    description,
    results,
    targets,
    tools,
    context,
    supervisor,
    created_at,
    updated_at,
    completion_date,
    duration,
    model,
    agent_id,
    user_id,
    output_tokens,
    input_tokens,
    site_id,
    agent_background,
    functions,
    performance
   FROM public.commands
  WHERE ((performance & 4) = 4);


create or replace view "public"."commands_likes" as  SELECT id,
    task,
    status,
    description,
    results,
    targets,
    tools,
    context,
    supervisor,
    created_at,
    updated_at,
    completion_date,
    duration,
    model,
    agent_id,
    user_id,
    output_tokens,
    input_tokens,
    site_id,
    agent_background,
    functions,
    performance
   FROM public.commands
  WHERE ((performance & 1) = 1);


CREATE OR REPLACE FUNCTION public.handle_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

create or replace view "public"."lead_analysis_summary" as  SELECT id,
    company_name,
    industry,
    company_size,
    annual_revenue,
    status,
    completion_percentage,
    ((current_kpis ->> 'monthlyRevenue'::text))::numeric AS monthly_revenue,
    ((current_kpis ->> 'customerAcquisitionCost'::text))::numeric AS cac,
    ((current_kpis ->> 'customerLifetimeValue'::text))::numeric AS ltv,
    ((current_kpis ->> 'conversionRate'::text))::numeric AS conversion_rate,
    ((analysis_results ->> 'currentROI'::text))::numeric AS current_roi,
    ((analysis_results ->> 'projectedROI'::text))::numeric AS projected_roi,
    ((analysis_results ->> 'potentialIncrease'::text))::numeric AS potential_increase,
    (contact_info ->> 'email'::text) AS contact_email,
    (contact_info ->> 'name'::text) AS contact_name,
    source,
    utm_source,
    utm_campaign,
    created_at,
    updated_at,
    completed_at
   FROM public.lead_analysis;


create or replace view "public"."requirement_campaigns" as  SELECT requirement_id,
    campaign_id
   FROM public.campaign_requirements;


grant delete on table "public"."remote_sessions" to "anon";

grant insert on table "public"."remote_sessions" to "anon";

grant references on table "public"."remote_sessions" to "anon";

grant select on table "public"."remote_sessions" to "anon";

grant trigger on table "public"."remote_sessions" to "anon";

grant truncate on table "public"."remote_sessions" to "anon";

grant update on table "public"."remote_sessions" to "anon";

grant delete on table "public"."remote_sessions" to "authenticated";

grant insert on table "public"."remote_sessions" to "authenticated";

grant references on table "public"."remote_sessions" to "authenticated";

grant select on table "public"."remote_sessions" to "authenticated";

grant trigger on table "public"."remote_sessions" to "authenticated";

grant truncate on table "public"."remote_sessions" to "authenticated";

grant update on table "public"."remote_sessions" to "authenticated";

grant delete on table "public"."remote_sessions" to "service_role";

grant insert on table "public"."remote_sessions" to "service_role";

grant references on table "public"."remote_sessions" to "service_role";

grant select on table "public"."remote_sessions" to "service_role";

grant trigger on table "public"."remote_sessions" to "service_role";

grant truncate on table "public"."remote_sessions" to "service_role";

grant update on table "public"."remote_sessions" to "service_role";

grant delete on table "public"."requirement_status" to "anon";

grant insert on table "public"."requirement_status" to "anon";

grant references on table "public"."requirement_status" to "anon";

grant select on table "public"."requirement_status" to "anon";

grant trigger on table "public"."requirement_status" to "anon";

grant truncate on table "public"."requirement_status" to "anon";

grant update on table "public"."requirement_status" to "anon";

grant delete on table "public"."requirement_status" to "authenticated";

grant insert on table "public"."requirement_status" to "authenticated";

grant references on table "public"."requirement_status" to "authenticated";

grant select on table "public"."requirement_status" to "authenticated";

grant trigger on table "public"."requirement_status" to "authenticated";

grant truncate on table "public"."requirement_status" to "authenticated";

grant update on table "public"."requirement_status" to "authenticated";

grant delete on table "public"."requirement_status" to "service_role";

grant insert on table "public"."requirement_status" to "service_role";

grant references on table "public"."requirement_status" to "service_role";

grant select on table "public"."requirement_status" to "service_role";

grant trigger on table "public"."requirement_status" to "service_role";

grant truncate on table "public"."requirement_status" to "service_role";

grant update on table "public"."requirement_status" to "service_role";


  create policy "Users can insert their own remote sessions"
  on "public"."remote_sessions"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can update their own remote sessions"
  on "public"."remote_sessions"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "Users can view their own remote sessions"
  on "public"."remote_sessions"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can delete requirement status for their sites"
  on "public"."requirement_status"
  as permissive
  for delete
  to public
using ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));



  create policy "Users can insert requirement status for their sites"
  on "public"."requirement_status"
  as permissive
  for insert
  to public
with check ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));



  create policy "Users can update requirement status for their sites"
  on "public"."requirement_status"
  as permissive
  for update
  to public
using ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));



  create policy "Users can view requirement status for their sites"
  on "public"."requirement_status"
  as permissive
  for select
  to public
using ((site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = auth.uid())
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));



  create policy "authenticated_read_activity"
  on "public"."activity"
  as permissive
  for select
  to authenticated
using ((((( SELECT auth.jwt() AS jwt) ->> 'role'::text) <> 'service_role'::text) AND ((( SELECT auth.jwt() AS jwt) ->> 'role'::text) = 'authenticated'::text) AND ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid)))) OR (site_id IN ( SELECT site_members.site_id
   FROM public.site_members
  WHERE (site_members.user_id = ( SELECT auth.uid() AS uid)))))));



  create policy "site_owners_delete_activity"
  on "public"."activity"
  as permissive
  for delete
  to authenticated
using ((((( SELECT auth.jwt() AS jwt) ->> 'role'::text) <> 'service_role'::text) AND ((( SELECT auth.jwt() AS jwt) ->> 'role'::text) = 'authenticated'::text) AND (site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "site_owners_update_activity"
  on "public"."activity"
  as permissive
  for update
  to authenticated
using ((((( SELECT auth.jwt() AS jwt) ->> 'role'::text) <> 'service_role'::text) AND ((( SELECT auth.jwt() AS jwt) ->> 'role'::text) = 'authenticated'::text) AND (site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "agent_assets_unified"
  on "public"."agent_assets"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_members sm ON ((sm.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_ownership so ON ((so.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (s.user_id = ( SELECT auth.uid() AS uid)))))))
with check (((EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_members sm ON ((sm.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.site_ownership so ON ((so.site_id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = agent_assets.agent_id) AND (s.user_id = ( SELECT auth.uid() AS uid)))))));



  create policy "agent_memories_optimized_policy"
  on "public"."agent_memories"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.agents a
     JOIN public.sites s ON ((s.id = a.site_id)))
  WHERE ((a.id = agent_memories.agent_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "agents_optimized_policy"
  on "public"."agents"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = agents.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "allowed_domains_access_policy"
  on "public"."allowed_domains"
  as permissive
  for all
  to authenticated
using ((site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))))
with check ((site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))));



  create policy "assets_optimized_policy"
  on "public"."assets"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = assets.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "automation_auth_sessions_access_policy"
  on "public"."automation_auth_sessions"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = automation_auth_sessions.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = automation_auth_sessions.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))))
with check ((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = automation_auth_sessions.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "billing_optimized_policy"
  on "public"."billing"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = billing.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "campaign_requirements_optimized_policy"
  on "public"."campaign_requirements"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.sites s ON ((s.id = c.site_id)))
  WHERE ((c.id = campaign_requirements.campaign_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "Users can manage campaign segments for their sites"
  on "public"."campaign_segments"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_segments.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))
with check ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_segments.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "Users can manage campaign subtasks for their sites"
  on "public"."campaign_subtasks"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_subtasks.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))
with check ((EXISTS ( SELECT 1
   FROM (public.campaigns c
     JOIN public.site_members sm ON ((sm.site_id = c.site_id)))
  WHERE ((c.id = campaign_subtasks.campaign_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "campaigns_unified"
  on "public"."campaigns"
  as permissive
  for all
  to public
using (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = campaigns.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));



  create policy "categories_for_owned_sites"
  on "public"."categories"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = categories.site_id) AND (s.user_id = ( SELECT auth.uid() AS uid))))))
with check ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = categories.site_id) AND (s.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "commands_site_access_policy"
  on "public"."commands"
  as permissive
  for all
  to authenticated
using (((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = commands.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))))) OR (user_id = ( SELECT auth.uid() AS uid))))
with check (((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = commands.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text)))))))) OR (user_id = ( SELECT auth.uid() AS uid))));



  create policy "content_unified_access_policy"
  on "public"."content"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = content.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))) OR (user_id = ( SELECT auth.uid() AS uid)) OR (author_id = ( SELECT auth.uid() AS uid))));



  create policy "content_assets_unified_policy"
  on "public"."content_assets"
  as permissive
  for all
  to authenticated
using (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM (public.content c
     JOIN public.sites s ON ((s.id = c.site_id)))
  WHERE ((c.id = content_assets.content_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))))))))
with check (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM (public.content c
     JOIN public.sites s ON ((s.id = c.site_id)))
  WHERE ((c.id = content_assets.content_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))))))));



  create policy "copywriting_site_access_policy"
  on "public"."copywriting"
  as permissive
  for all
  to authenticated
using ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))))
with check ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = ( SELECT auth.uid() AS uid))
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text)))));



  create policy "Only superadmin can delete cron status"
  on "public"."cron_status"
  as permissive
  for delete
  to public
using (public.is_superadmin());



  create policy "Only superadmin can insert cron status"
  on "public"."cron_status"
  as permissive
  for insert
  to public
with check (public.is_superadmin());



  create policy "Only superadmin can update cron status"
  on "public"."cron_status"
  as permissive
  for update
  to public
using (public.is_superadmin())
with check (public.is_superadmin());



  create policy "Only superadmin can view cron status"
  on "public"."cron_status"
  as permissive
  for select
  to public
using (public.is_superadmin());



  create policy "customizations_delete_owner_admin"
  on "public"."customizations"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "customizations_insert_owner_admin"
  on "public"."customizations"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "customizations_select_owner_admin"
  on "public"."customizations"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "customizations_update_owner_admin"
  on "public"."customizations"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((((public.elements e
     JOIN public.layers l ON ((l.id = e.layer_id)))
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((e.id = customizations.element_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "debug_logs_optimized_policy"
  on "public"."debug_logs"
  as permissive
  for select
  to public
using (((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = debug_logs.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));



  create policy "editor_delete_owner_admin"
  on "public"."editor"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "editor_insert_owner_admin"
  on "public"."editor"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "editor_select_owner_admin"
  on "public"."editor"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "editor_update_owner_admin"
  on "public"."editor"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = editor.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = editor.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "elements_delete_owner_admin"
  on "public"."elements"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "elements_insert_owner_admin"
  on "public"."elements"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "elements_select_owner_admin"
  on "public"."elements"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "elements_update_owner_admin"
  on "public"."elements"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (((public.layers l
     JOIN public.states st ON ((st.id = l.state_id)))
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((l.id = elements.layer_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "experiment_segments_emergency"
  on "public"."experiment_segments"
  as permissive
  for all
  to public
using (((( SELECT auth.uid() AS uid) IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.experiments
  WHERE (experiments.id = experiment_segments.experiment_id)))))
with check (((( SELECT auth.uid() AS uid) IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.experiments
  WHERE (experiments.id = experiment_segments.experiment_id)))));



  create policy "experiments_unified"
  on "public"."experiments"
  as permissive
  for all
  to public
using (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = experiments.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));



  create policy "external_resources_optimized_policy"
  on "public"."external_resources"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = external_resources.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "icp_mining - authenticated can delete in site"
  on "public"."icp_mining"
  as permissive
  for delete
  to authenticated
using (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id)))));



  create policy "icp_mining - authenticated can insert in site"
  on "public"."icp_mining"
  as permissive
  for insert
  to authenticated
with check (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = rqs.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = rqs.role_query_id)))));



  create policy "icp_mining - authenticated can select in site"
  on "public"."icp_mining"
  as permissive
  for select
  to authenticated
using (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id)))));



  create policy "icp_mining - authenticated can update in site"
  on "public"."icp_mining"
  as permissive
  for update
  to authenticated
using (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = icp_mining.role_query_id)))))
with check (((EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (rqs.role_query_id = rqs.role_query_id))) OR (EXISTS ( SELECT 1
   FROM ((public.role_query_segments rqs
     JOIN public.segments s ON ((s.id = rqs.segment_id)))
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (rqs.role_query_id = rqs.role_query_id)))));



  create policy "instance_logs_access_policy"
  on "public"."instance_logs"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_logs.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_logs.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))))
with check (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_logs.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_logs.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))));



  create policy "instance_plans_access_policy"
  on "public"."instance_plans"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_plans.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = instance_plans.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))))
with check ((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = instance_plans.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "kpis_optimized_policy"
  on "public"."kpis"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = kpis.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "layers_delete_owner_admin"
  on "public"."layers"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "layers_insert_owner_admin"
  on "public"."layers"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "layers_select_owner_admin"
  on "public"."layers"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "layers_update_owner_admin"
  on "public"."layers"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = layers.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "leads_unified"
  on "public"."leads"
  as permissive
  for all
  to public
using (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = leads.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));



  create policy "payments_select_optimized"
  on "public"."payments"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = payments.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "remote_instances_access_policy"
  on "public"."remote_instances"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = remote_instances.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = remote_instances.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))))
with check (((EXISTS ( SELECT 1
   FROM public.site_ownership
  WHERE ((site_ownership.site_id = remote_instances.site_id) AND (site_ownership.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members
  WHERE ((site_members.site_id = remote_instances.site_id) AND (site_members.user_id = ( SELECT auth.uid() AS uid)) AND (site_members.status = 'active'::text))))));



  create policy "requirement_segments_optimized_policy"
  on "public"."requirement_segments"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.requirements r
     JOIN public.sites s ON ((s.id = r.site_id)))
  WHERE ((r.id = requirement_segments.requirement_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "requirements_optimized_policy"
  on "public"."requirements"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = requirements.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "role_query_segments - authenticated can delete in site"
  on "public"."role_query_segments"
  as permissive
  for delete
  to authenticated
using (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));



  create policy "role_query_segments - authenticated can insert in site"
  on "public"."role_query_segments"
  as permissive
  for insert
  to authenticated
with check (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));



  create policy "role_query_segments - authenticated can select in site"
  on "public"."role_query_segments"
  as permissive
  for select
  to authenticated
using (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));



  create policy "role_query_segments - authenticated can update in site"
  on "public"."role_query_segments"
  as permissive
  for update
  to authenticated
using (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))))
with check (((EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_ownership so ON (((so.site_id = s.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid)))))
  WHERE (s.id = role_query_segments.segment_id))) OR (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON (((sm.site_id = s.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))
  WHERE (s.id = role_query_segments.segment_id)))));



  create policy "Users can manage sale orders for their sites"
  on "public"."sale_orders"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.sales s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = sale_orders.sale_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))
with check ((EXISTS ( SELECT 1
   FROM (public.sales s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = sale_orders.sale_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "sales_unified"
  on "public"."sales"
  as permissive
  for all
  to public
using (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = sales.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));



  create policy "sections_delete_owner_admin"
  on "public"."sections"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "sections_insert_owner_admin"
  on "public"."sections"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "sections_select_owner_admin"
  on "public"."sections"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "sections_update_owner_admin"
  on "public"."sections"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = sections.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sections.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "Users can delete their own tokens"
  on "public"."secure_tokens"
  as permissive
  for delete
  to public
using ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "Users can insert their own tokens"
  on "public"."secure_tokens"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "Users can update their own tokens"
  on "public"."secure_tokens"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "Users can view their own tokens"
  on "public"."secure_tokens"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = secure_tokens.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "segments_unified"
  on "public"."segments"
  as permissive
  for all
  to public
using (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = segments.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));



  create policy "settings_optimized_policy"
  on "public"."settings"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = settings.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "site_members_final_policy"
  on "public"."site_members"
  as permissive
  for all
  to authenticated
using (((user_id = ( SELECT auth.uid() AS uid)) OR (site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid))))))
with check ((site_id IN ( SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = ( SELECT auth.uid() AS uid)))));



  create policy "sites_select_policy"
  on "public"."sites"
  as permissive
  for select
  to authenticated
using (((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sites.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));



  create policy "sites_update_policy"
  on "public"."sites"
  as permissive
  for update
  to public
using (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sites.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])))))))
with check (((user_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = sites.id) AND (sm.user_id = auth.uid()) AND (sm.status = 'active'::text) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])))))));



  create policy "states_delete_owner_admin"
  on "public"."states"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "states_insert_owner_admin"
  on "public"."states"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "states_select_owner_admin"
  on "public"."states"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "states_update_owner_admin"
  on "public"."states"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM (public.sections s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = states.section_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "Users can manage task categories for their tasks"
  on "public"."task_categories"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM (public.tasks t
     JOIN public.site_members sm ON ((sm.site_id = t.site_id)))
  WHERE ((t.id = task_categories.task_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))
with check ((EXISTS ( SELECT 1
   FROM (public.tasks t
     JOIN public.site_members sm ON ((sm.site_id = t.site_id)))
  WHERE ((t.id = task_categories.task_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "task_comments_final_policy"
  on "public"."task_comments"
  as permissive
  for all
  to public
using (((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = task_comments.task_id) AND ((t.user_id = ( SELECT auth.uid() AS uid)) OR (t.assignee = ( SELECT auth.uid() AS uid))))))));



  create policy "tasks_unified"
  on "public"."tasks"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = tasks.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))))));



  create policy "Users can manage transactions for their sites"
  on "public"."transactions"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = transactions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))))
with check ((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = transactions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "transitions_delete_owner_admin"
  on "public"."transitions"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "transitions_insert_owner_admin"
  on "public"."transitions"
  as permissive
  for insert
  to public
with check ((((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = transitions.from_state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = transitions.from_state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))) AND ((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = transitions.to_state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = transitions.to_state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text)))))));



  create policy "transitions_select_owner_admin"
  on "public"."transitions"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "transitions_update_owner_admin"
  on "public"."transitions"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE (((st.id = transitions.from_state_id) OR (st.id = transitions.to_state_id)) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "variants_delete_owner_admin"
  on "public"."variants"
  as permissive
  for delete
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "variants_insert_owner_admin"
  on "public"."variants"
  as permissive
  for insert
  to public
with check (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "variants_select_owner_admin"
  on "public"."variants"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "variants_update_owner_admin"
  on "public"."variants"
  as permissive
  for update
  to public
using (((EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_ownership so ON ((so.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM ((public.states st
     JOIN public.sections s ON ((s.id = st.section_id)))
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((st.id = variants.state_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.role = ANY (ARRAY['owner'::text, 'admin'::text])) AND (sm.status = 'active'::text))))));



  create policy "visitor_sessions_unified"
  on "public"."visitor_sessions"
  as permissive
  for all
  to public
using (app_auth.is_service_role_or_user_condition((EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = visitor_sessions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));



  create policy "visitors_optimized"
  on "public"."visitors"
  as permissive
  for all
  to public
using ((public.is_service_role() OR ((public.auth_user_id() IS NOT NULL) AND (((segment_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.segments s
     JOIN public.site_members sm ON ((sm.site_id = s.site_id)))
  WHERE ((s.id = visitors.segment_id) AND (sm.user_id = public.auth_user_id()) AND (sm.status = 'active'::text))))) OR ((lead_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.leads l
     JOIN public.site_members sm ON ((sm.site_id = l.site_id)))
  WHERE ((l.id = visitors.lead_id) AND (sm.user_id = public.auth_user_id()) AND (sm.status = 'active'::text))))) OR (EXISTS ( SELECT 1
   FROM (public.visitor_sessions vs
     JOIN public.site_members sm ON ((sm.site_id = vs.site_id)))
  WHERE ((vs.visitor_id = visitors.id) AND (sm.user_id = public.auth_user_id()) AND (sm.status = 'active'::text))))))));



  create policy "webhook_events_users_policy"
  on "public"."webhook_events"
  as permissive
  for select
  to authenticated
using (((site_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = webhook_events.site_id) AND ((s.user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = ( SELECT auth.uid() AS uid)))))))))));



  create policy "webhooks_deliveries_unified"
  on "public"."webhooks_deliveries"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_deliveries.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_deliveries.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))))
with check (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_deliveries.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_deliveries.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));



  create policy "webhooks_endpoints_unified"
  on "public"."webhooks_endpoints"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_endpoints.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_endpoints.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))))
with check (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_endpoints.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_endpoints.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));



  create policy "webhooks_subscriptions_unified"
  on "public"."webhooks_subscriptions"
  as permissive
  for all
  to public
using (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_subscriptions.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_subscriptions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))))
with check (((EXISTS ( SELECT 1
   FROM public.site_ownership so
  WHERE ((so.site_id = webhooks_subscriptions.site_id) AND (so.user_id = ( SELECT auth.uid() AS uid))))) OR (EXISTS ( SELECT 1
   FROM public.site_members sm
  WHERE ((sm.site_id = webhooks_subscriptions.site_id) AND (sm.user_id = ( SELECT auth.uid() AS uid)) AND (sm.status = 'active'::text))))));


CREATE TRIGGER update_remote_sessions_updated_at BEFORE UPDATE ON public.remote_sessions FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trigger_activity_updated_at BEFORE UPDATE ON public.activity FOR EACH ROW EXECUTE FUNCTION public.update_activity_updated_at();

CREATE TRIGGER trigger_delete_protection_agent_assets BEFORE DELETE ON public.agent_assets FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_agent_memories BEFORE DELETE ON public.agent_memories FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_agents BEFORE DELETE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_agents BEFORE INSERT ON public.agents FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_agents BEFORE UPDATE ON public.agents FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_allowed_domains BEFORE DELETE ON public.allowed_domains FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.analysis FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trigger_delete_protection_analysis BEFORE DELETE ON public.analysis FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER check_expired_api_keys BEFORE INSERT OR UPDATE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.ensure_api_key_not_expired();

CREATE TRIGGER trigger_delete_protection_api_keys BEFORE DELETE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON public.api_keys FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER log_asset_insert_trigger BEFORE INSERT ON public.assets FOR EACH ROW EXECUTE FUNCTION public.log_asset_insert();

CREATE TRIGGER trigger_delete_protection_assets BEFORE DELETE ON public.assets FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER update_automation_auth_sessions_updated_at BEFORE UPDATE ON public.automation_auth_sessions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER billing_timestamp_trigger BEFORE UPDATE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER trigger_delete_protection_billing BEFORE DELETE ON public.billing FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_campaign_requirements BEFORE DELETE ON public.campaign_requirements FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_campaign_segments BEFORE DELETE ON public.campaign_segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_campaign_subtasks BEFORE DELETE ON public.campaign_subtasks FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER campaign_cascade_delete_trigger BEFORE DELETE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.handle_campaign_deletion();

CREATE TRIGGER trigger_delete_protection_campaigns BEFORE DELETE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_campaigns BEFORE INSERT ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_campaigns BEFORE UPDATE ON public.campaigns FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_categories BEFORE DELETE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER on_command_insert BEFORE INSERT ON public.commands FOR EACH ROW EXECUTE FUNCTION public.handle_command_insert();

CREATE TRIGGER on_command_update BEFORE UPDATE ON public.commands FOR EACH ROW EXECUTE FUNCTION public.handle_command_update();

CREATE TRIGGER validate_performance_bitmask_trigger BEFORE INSERT OR UPDATE ON public.commands FOR EACH ROW EXECUTE FUNCTION public.validate_performance_bitmask();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_delete_protection_content BEFORE DELETE ON public.content FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_content BEFORE INSERT ON public.content FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_content BEFORE UPDATE ON public.content FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_conversations BEFORE DELETE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_update_copywriting_updated_at BEFORE UPDATE ON public.copywriting FOR EACH ROW EXECUTE FUNCTION public.update_copywriting_updated_at();

CREATE TRIGGER trigger_update_cron_status_updated_at BEFORE UPDATE ON public.cron_status FOR EACH ROW EXECUTE FUNCTION public.update_cron_status_updated_at();

CREATE TRIGGER trigger_delete_protection_experiment_segments BEFORE DELETE ON public.experiment_segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_experiments BEFORE DELETE ON public.experiments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_experiments BEFORE INSERT ON public.experiments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_experiments BEFORE UPDATE ON public.experiments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_external_resources BEFORE DELETE ON public.external_resources FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trg_icp_mining_set_updated_at BEFORE UPDATE ON public.icp_mining FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER update_instance_plans_updated_at BEFORE UPDATE ON public.instance_plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_delete_protection_kpis BEFORE DELETE ON public.kpis FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_update_lead_analysis_updated_at BEFORE UPDATE ON public.lead_analysis FOR EACH ROW EXECUTE FUNCTION public.update_lead_analysis_updated_at();

CREATE TRIGGER trigger_delete_protection_leads BEFORE DELETE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_leads BEFORE INSERT ON public.leads FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_leads BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER on_message_insert AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message_time();

CREATE TRIGGER trigger_delete_protection_messages BEFORE DELETE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_messages BEFORE INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_messages BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_notifications BEFORE DELETE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_notifications BEFORE INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_notifications BEFORE UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER payments_timestamp_trigger BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER trigger_delete_protection_payments BEFORE DELETE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trg_persons_updated_at BEFORE UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER activate_pending_memberships_trigger AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.activate_pending_site_memberships();

CREATE TRIGGER update_referral_codes_updated_at BEFORE UPDATE ON public.referral_codes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_remote_instances_updated_at BEFORE UPDATE ON public.remote_instances FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_delete_protection_requirement_segments BEFORE DELETE ON public.requirement_segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_requirements BEFORE DELETE ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_requirements BEFORE INSERT ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_requirements BEFORE UPDATE ON public.requirements FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trg_role_queries_updated_at BEFORE UPDATE ON public.role_queries FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_rqs_updated_at BEFORE UPDATE ON public.role_query_segments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trigger_delete_protection_sale_orders BEFORE DELETE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_update_sale_orders_updated_at BEFORE UPDATE ON public.sale_orders FOR EACH ROW EXECUTE FUNCTION public.update_sale_orders_updated_at();

CREATE TRIGGER trigger_delete_protection_sales BEFORE DELETE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_sales BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_sales BEFORE UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_secure_tokens BEFORE DELETE ON public.secure_tokens FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_segments BEFORE DELETE ON public.segments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_segments BEFORE INSERT ON public.segments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_segments BEFORE UPDATE ON public.segments FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER on_event_insert BEFORE INSERT ON public.session_events FOR EACH ROW EXECUTE FUNCTION public.handle_event_insert();

CREATE TRIGGER session_events_updated_at_trigger BEFORE UPDATE ON public.session_events FOR EACH ROW EXECUTE FUNCTION public.handle_session_events_updated_at();

CREATE TRIGGER trigger_delete_protection_session_events BEFORE DELETE ON public.session_events FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER trigger_delete_protection_settings BEFORE DELETE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER prevent_last_admin_deletion_trigger BEFORE DELETE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_deletion();

CREATE TRIGGER prevent_last_admin_role_change_trigger BEFORE UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_role_change();

CREATE TRIGGER sync_members_to_settings AFTER INSERT OR DELETE OR UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.sync_site_members_to_settings();

CREATE TRIGGER sync_site_members_trigger AFTER INSERT OR DELETE OR UPDATE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.sync_site_members_to_team_members();

CREATE TRIGGER trigger_delete_protection_site_members BEFORE DELETE ON public.site_members FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER sync_ownership_on_site_change AFTER INSERT OR DELETE OR UPDATE OF user_id ON public.sites FOR EACH ROW EXECUTE FUNCTION public.sync_site_ownership();

CREATE TRIGGER trigger_update_synced_objects_updated_at BEFORE UPDATE ON public.synced_objects FOR EACH ROW EXECUTE FUNCTION public.update_synced_objects_updated_at();

CREATE TRIGGER trigger_delete_protection_task_categories BEFORE DELETE ON public.task_categories FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_task_comments BEFORE DELETE ON public.task_comments FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER set_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER trigger_delete_protection_tasks BEFORE DELETE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_tasks BEFORE INSERT ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_set_task_priority BEFORE INSERT ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_task_priority_from_serial();

CREATE TRIGGER trigger_set_task_serial_id BEFORE INSERT ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_task_serial_id();

CREATE TRIGGER trigger_update_permission_tasks BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_transactions BEFORE DELETE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_delete_protection_visitor_sessions BEFORE DELETE ON public.visitor_sessions FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_visitor_sessions BEFORE INSERT ON public.visitor_sessions FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_visitor_sessions BEFORE UPDATE ON public.visitor_sessions FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_delete_protection_visitors BEFORE DELETE ON public.visitors FOR EACH ROW EXECUTE FUNCTION public.check_delete_permission();

CREATE TRIGGER trigger_insert_permission_visitors BEFORE INSERT ON public.visitors FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER trigger_update_permission_visitors BEFORE UPDATE ON public.visitors FOR EACH ROW EXECUTE FUNCTION public.check_create_update_permission();

CREATE TRIGGER update_waitlist_updated_at BEFORE UPDATE ON public.waitlist FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER webhook_events_updated_at_trigger BEFORE UPDATE ON public.webhook_events FOR EACH ROW EXECUTE FUNCTION public.update_webhook_events_updated_at();

CREATE TRIGGER set_timestamp_webhooks_deliveries BEFORE UPDATE ON public.webhooks_deliveries FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_timestamp_webhooks_endpoints BEFORE UPDATE ON public.webhooks_endpoints FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER set_timestamp_webhooks_subscriptions BEFORE UPDATE ON public.webhooks_subscriptions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER increment_template_usage_trigger AFTER UPDATE ON public.whatsapp_templates FOR EACH ROW WHEN (((old.usage_count IS DISTINCT FROM new.usage_count) OR (old.last_used IS DISTINCT FROM new.last_used))) EXECUTE FUNCTION public.increment_template_usage();

CREATE TRIGGER trigger_update_whatsapp_templates_updated_at BEFORE UPDATE ON public.whatsapp_templates FOR EACH ROW EXECUTE FUNCTION public.update_whatsapp_templates_updated_at();

drop trigger if exists "on_auth_user_created" on "auth"."users";

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

drop policy "Usuarios pueden acceder a archivos de sus tareas" on "storage"."objects";


  create policy "Usuarios pueden acceder a archivos de sus tareas"
  on "storage"."objects"
  as permissive
  for all
  to public
using (((bucket_id = 'task_files'::text) AND (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = ((regexp_match(objects.name, '^([^/]+)/'::text))[1])::uuid) AND ((t.user_id = auth.uid()) OR (t.assignee = auth.uid())))))));



