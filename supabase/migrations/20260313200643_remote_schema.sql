create extension if not exists "moddatetime" with schema "public";

alter table "public"."experiments" drop constraint "experiments_user_id_fkey";

alter table "public"."sales" drop constraint "sales_user_id_fkey";


  create table "public"."credit_transactions" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "site_id" uuid not null,
    "amount" numeric(10,4) not null,
    "transaction_type" character varying not null,
    "description" text,
    "metadata" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."credit_transactions" enable row level security;


  create table "public"."deal_leads" (
    "id" uuid not null default gen_random_uuid(),
    "deal_id" uuid,
    "lead_id" uuid,
    "role" text,
    "is_primary" boolean default false,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
      );


alter table "public"."deal_leads" enable row level security;


  create table "public"."deal_owners" (
    "id" uuid not null default gen_random_uuid(),
    "deal_id" uuid,
    "user_id" uuid,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
      );


alter table "public"."deal_owners" enable row level security;


  create table "public"."deals" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "amount" numeric,
    "currency" text default 'USD'::text,
    "stage" text not null default 'prospecting'::text,
    "status" text not null default 'open'::text,
    "company_id" uuid,
    "site_id" uuid,
    "expected_close_date" date,
    "notes" text,
    "qualification_score" numeric default 0,
    "qualification_criteria" jsonb default '{}'::jsonb,
    "sales_order_id" uuid,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now()),
    "updated_at" timestamp with time zone not null default timezone('utc'::text, now())
      );


alter table "public"."deals" enable row level security;

alter table "public"."billing" alter column "credits_available" set data type numeric(10,4) using "credits_available"::numeric(10,4);

alter table "public"."billing" alter column "credits_used" set data type numeric(10,4) using "credits_used"::numeric(10,4);

alter table "public"."remote_sessions" add column "instance_id" uuid;

alter table "public"."requirement_status" add column "preview_url" text;

alter table "public"."requirement_status" alter column "asset_id" drop not null;

alter table "public"."requirement_status" alter column "instance_id" drop not null;

alter table "public"."tasks" add column "deal_id" uuid;

alter table "public"."tasks" alter column "lead_id" drop not null;

CREATE UNIQUE INDEX credit_transactions_pkey ON public.credit_transactions USING btree (id);

CREATE UNIQUE INDEX deal_leads_deal_id_lead_id_key ON public.deal_leads USING btree (deal_id, lead_id);

CREATE UNIQUE INDEX deal_leads_pkey ON public.deal_leads USING btree (id);

CREATE UNIQUE INDEX deal_owners_deal_id_user_id_key ON public.deal_owners USING btree (deal_id, user_id);

CREATE UNIQUE INDEX deal_owners_pkey ON public.deal_owners USING btree (id);

CREATE UNIQUE INDEX deals_pkey ON public.deals USING btree (id);

CREATE INDEX idx_credit_transactions_site_id ON public.credit_transactions USING btree (site_id);

CREATE INDEX idx_leads_site_created_at ON public.leads USING btree (site_id, created_at DESC);

CREATE INDEX idx_leads_site_segment ON public.leads USING btree (site_id, segment_id) WHERE (segment_id IS NOT NULL);

CREATE INDEX idx_remote_sessions_instance_id ON public.remote_sessions USING btree (instance_id);

CREATE INDEX idx_sales_lead_id_not_null ON public.sales USING btree (lead_id) WHERE (lead_id IS NOT NULL);

CREATE INDEX idx_session_events_site_date ON public.session_events USING btree (site_id, event_type, created_at);

CREATE INDEX idx_session_events_site_type_date ON public.session_events USING btree (site_id, event_type, created_at DESC);

CREATE INDEX idx_transactions_site_created_at ON public.transactions USING btree (site_id, created_at DESC);

alter table "public"."credit_transactions" add constraint "credit_transactions_pkey" PRIMARY KEY using index "credit_transactions_pkey";

alter table "public"."deal_leads" add constraint "deal_leads_pkey" PRIMARY KEY using index "deal_leads_pkey";

alter table "public"."deal_owners" add constraint "deal_owners_pkey" PRIMARY KEY using index "deal_owners_pkey";

alter table "public"."deals" add constraint "deals_pkey" PRIMARY KEY using index "deals_pkey";

alter table "public"."credit_transactions" add constraint "credit_transactions_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."credit_transactions" validate constraint "credit_transactions_site_id_fkey";

alter table "public"."deal_leads" add constraint "deal_leads_deal_id_fkey" FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON DELETE CASCADE not valid;

alter table "public"."deal_leads" validate constraint "deal_leads_deal_id_fkey";

alter table "public"."deal_leads" add constraint "deal_leads_deal_id_lead_id_key" UNIQUE using index "deal_leads_deal_id_lead_id_key";

alter table "public"."deal_leads" add constraint "deal_leads_lead_id_fkey" FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE not valid;

alter table "public"."deal_leads" validate constraint "deal_leads_lead_id_fkey";

alter table "public"."deal_owners" add constraint "deal_owners_deal_id_fkey" FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON DELETE CASCADE not valid;

alter table "public"."deal_owners" validate constraint "deal_owners_deal_id_fkey";

alter table "public"."deal_owners" add constraint "deal_owners_deal_id_user_id_key" UNIQUE using index "deal_owners_deal_id_user_id_key";

alter table "public"."deal_owners" add constraint "deal_owners_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."deal_owners" validate constraint "deal_owners_user_id_fkey";

alter table "public"."deals" add constraint "deals_company_id_fkey" FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL not valid;

alter table "public"."deals" validate constraint "deals_company_id_fkey";

alter table "public"."deals" add constraint "deals_sales_order_id_fkey" FOREIGN KEY (sales_order_id) REFERENCES public.sales(id) ON DELETE SET NULL not valid;

alter table "public"."deals" validate constraint "deals_sales_order_id_fkey";

alter table "public"."deals" add constraint "deals_site_id_fkey" FOREIGN KEY (site_id) REFERENCES public.sites(id) ON DELETE CASCADE not valid;

alter table "public"."deals" validate constraint "deals_site_id_fkey";

alter table "public"."remote_sessions" add constraint "remote_sessions_instance_id_fkey" FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON DELETE SET NULL not valid;

alter table "public"."remote_sessions" validate constraint "remote_sessions_instance_id_fkey";

alter table "public"."requirement_status" add constraint "requirement_status_asset_id_fkey" FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."requirement_status" validate constraint "requirement_status_asset_id_fkey";

alter table "public"."requirement_status" add constraint "requirement_status_instance_id_fkey" FOREIGN KEY (instance_id) REFERENCES public.remote_instances(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."requirement_status" validate constraint "requirement_status_instance_id_fkey";

alter table "public"."tasks" add constraint "tasks_deal_id_fkey" FOREIGN KEY (deal_id) REFERENCES public.deals(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."tasks" validate constraint "tasks_deal_id_fkey";

alter table "public"."experiments" add constraint "experiments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."experiments" validate constraint "experiments_user_id_fkey";

alter table "public"."sales" add constraint "sales_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."sales" validate constraint "sales_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.add_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_available numeric;
  v_new_available numeric;
BEGIN
  -- Lock the row for update
  SELECT credits_available
  INTO v_available
  FROM public.billing
  WHERE site_id = p_site_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Billing record not found');
  END IF;

  v_new_available := COALESCE(v_available, 0) + p_amount;

  -- Update billing
  UPDATE public.billing
  SET credits_available = v_new_available,
      updated_at = now()
  WHERE site_id = p_site_id;

  -- Insert transaction log
  INSERT INTO public.credit_transactions (
    site_id, amount, transaction_type, description, metadata
  ) VALUES (
    p_site_id, p_amount, p_type, p_description, p_metadata
  );

  RETURN jsonb_build_object('success', true, 'new_balance', v_new_available);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.deduct_credits(p_site_id uuid, p_amount numeric, p_type text, p_description text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_available numeric;
  v_used numeric;
  v_new_available numeric;
  v_new_used numeric;
BEGIN
  -- Lock the row for update to prevent race conditions
  SELECT credits_available, credits_used 
  INTO v_available, v_used
  FROM public.billing
  WHERE site_id = p_site_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Billing record not found');
  END IF;

  IF v_available < p_amount THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient credits', 'available', v_available, 'required', p_amount);
  END IF;

  v_new_available := COALESCE(v_available, 0) - p_amount;
  v_new_used := COALESCE(v_used, 0) + p_amount;

  -- Update billing
  UPDATE public.billing
  SET credits_available = v_new_available,
      credits_used = v_new_used,
      updated_at = now()
  WHERE site_id = p_site_id;

  -- Insert transaction log
  INSERT INTO public.credit_transactions (
    site_id, amount, transaction_type, description, metadata
  ) VALUES (
    p_site_id, -p_amount, p_type, p_description, p_metadata
  );

  RETURN jsonb_build_object('success', true, 'remaining', v_new_available);
END;
$function$
;

grant delete on table "public"."credit_transactions" to "anon";

grant insert on table "public"."credit_transactions" to "anon";

grant references on table "public"."credit_transactions" to "anon";

grant select on table "public"."credit_transactions" to "anon";

grant trigger on table "public"."credit_transactions" to "anon";

grant truncate on table "public"."credit_transactions" to "anon";

grant update on table "public"."credit_transactions" to "anon";

grant delete on table "public"."credit_transactions" to "authenticated";

grant insert on table "public"."credit_transactions" to "authenticated";

grant references on table "public"."credit_transactions" to "authenticated";

grant select on table "public"."credit_transactions" to "authenticated";

grant trigger on table "public"."credit_transactions" to "authenticated";

grant truncate on table "public"."credit_transactions" to "authenticated";

grant update on table "public"."credit_transactions" to "authenticated";

grant delete on table "public"."credit_transactions" to "service_role";

grant insert on table "public"."credit_transactions" to "service_role";

grant references on table "public"."credit_transactions" to "service_role";

grant select on table "public"."credit_transactions" to "service_role";

grant trigger on table "public"."credit_transactions" to "service_role";

grant truncate on table "public"."credit_transactions" to "service_role";

grant update on table "public"."credit_transactions" to "service_role";

grant delete on table "public"."deal_leads" to "anon";

grant insert on table "public"."deal_leads" to "anon";

grant references on table "public"."deal_leads" to "anon";

grant select on table "public"."deal_leads" to "anon";

grant trigger on table "public"."deal_leads" to "anon";

grant truncate on table "public"."deal_leads" to "anon";

grant update on table "public"."deal_leads" to "anon";

grant delete on table "public"."deal_leads" to "authenticated";

grant insert on table "public"."deal_leads" to "authenticated";

grant references on table "public"."deal_leads" to "authenticated";

grant select on table "public"."deal_leads" to "authenticated";

grant trigger on table "public"."deal_leads" to "authenticated";

grant truncate on table "public"."deal_leads" to "authenticated";

grant update on table "public"."deal_leads" to "authenticated";

grant delete on table "public"."deal_leads" to "service_role";

grant insert on table "public"."deal_leads" to "service_role";

grant references on table "public"."deal_leads" to "service_role";

grant select on table "public"."deal_leads" to "service_role";

grant trigger on table "public"."deal_leads" to "service_role";

grant truncate on table "public"."deal_leads" to "service_role";

grant update on table "public"."deal_leads" to "service_role";

grant delete on table "public"."deal_owners" to "anon";

grant insert on table "public"."deal_owners" to "anon";

grant references on table "public"."deal_owners" to "anon";

grant select on table "public"."deal_owners" to "anon";

grant trigger on table "public"."deal_owners" to "anon";

grant truncate on table "public"."deal_owners" to "anon";

grant update on table "public"."deal_owners" to "anon";

grant delete on table "public"."deal_owners" to "authenticated";

grant insert on table "public"."deal_owners" to "authenticated";

grant references on table "public"."deal_owners" to "authenticated";

grant select on table "public"."deal_owners" to "authenticated";

grant trigger on table "public"."deal_owners" to "authenticated";

grant truncate on table "public"."deal_owners" to "authenticated";

grant update on table "public"."deal_owners" to "authenticated";

grant delete on table "public"."deal_owners" to "service_role";

grant insert on table "public"."deal_owners" to "service_role";

grant references on table "public"."deal_owners" to "service_role";

grant select on table "public"."deal_owners" to "service_role";

grant trigger on table "public"."deal_owners" to "service_role";

grant truncate on table "public"."deal_owners" to "service_role";

grant update on table "public"."deal_owners" to "service_role";

grant delete on table "public"."deals" to "anon";

grant insert on table "public"."deals" to "anon";

grant references on table "public"."deals" to "anon";

grant select on table "public"."deals" to "anon";

grant trigger on table "public"."deals" to "anon";

grant truncate on table "public"."deals" to "anon";

grant update on table "public"."deals" to "anon";

grant delete on table "public"."deals" to "authenticated";

grant insert on table "public"."deals" to "authenticated";

grant references on table "public"."deals" to "authenticated";

grant select on table "public"."deals" to "authenticated";

grant trigger on table "public"."deals" to "authenticated";

grant truncate on table "public"."deals" to "authenticated";

grant update on table "public"."deals" to "authenticated";

grant delete on table "public"."deals" to "service_role";

grant insert on table "public"."deals" to "service_role";

grant references on table "public"."deals" to "service_role";

grant select on table "public"."deals" to "service_role";

grant trigger on table "public"."deals" to "service_role";

grant truncate on table "public"."deals" to "service_role";

grant update on table "public"."deals" to "service_role";


  create policy "Users can view billing for their sites"
  on "public"."billing"
  as permissive
  for select
  to public
using ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = auth.uid()) AND (site_members.status = 'active'::text))
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));



  create policy "Users can view credit transactions for their sites"
  on "public"."credit_transactions"
  as permissive
  for select
  to public
using ((site_id IN ( SELECT sites.id
   FROM public.sites
  WHERE (sites.user_id = auth.uid())
UNION
 SELECT site_members.site_id
   FROM public.site_members
  WHERE ((site_members.user_id = auth.uid()) AND (site_members.status = 'active'::text))
UNION
 SELECT site_ownership.site_id
   FROM public.site_ownership
  WHERE (site_ownership.user_id = auth.uid()))));



  create policy "deal_leads_unified"
  on "public"."deal_leads"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.deals d
  WHERE ((d.id = deal_leads.deal_id) AND ((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
           FROM public.sites s
          WHERE ((s.id = d.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
                   FROM public.site_members sm
                  WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))))));



  create policy "deal_owners_unified"
  on "public"."deal_owners"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.deals d
  WHERE ((d.id = deal_owners.deal_id) AND ((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
           FROM public.sites s
          WHERE ((s.id = d.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
                   FROM public.site_members sm
                  WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid())))))))))))));



  create policy "deals_unified"
  on "public"."deals"
  as permissive
  for all
  to public
using (((current_setting('role'::text, true) = 'service_role'::text) OR ((auth.jwt() ->> 'role'::text) = 'service_role'::text) OR (EXISTS ( SELECT 1
   FROM public.sites s
  WHERE ((s.id = deals.site_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.site_members sm
          WHERE ((sm.site_id = s.id) AND (sm.user_id = auth.uid()))))))))));


CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.deals FOR EACH ROW EXECUTE FUNCTION public.moddatetime('updated_at');


