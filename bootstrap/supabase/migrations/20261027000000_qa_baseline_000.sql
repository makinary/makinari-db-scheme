SET search_path = '';
SET check_function_bodies = false;
SET row_security = off;
-- Fresh QA Supabase only. Never apply this bootstrap to an existing database.
CREATE ROLE apps_migration_coordinator NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS moddatetime WITH SCHEMA public;
--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.11 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: app_auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA app_auth;


--
-- Name: commerce_rls_private; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA commerce_rls_private;


--
-- Name: location_acl_private; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA location_acl_private;


--
-- Name: private; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA private;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- Name: campaign_priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.campaign_priority AS ENUM (
    'high',
    'medium',
    'low'
);


--
-- Name: campaign_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.campaign_status AS ENUM (
    'active',
    'pending',
    'completed'
);


--
-- Name: command_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.command_status AS ENUM (
    'pending',
    'running',
    'completed',
    'failed',
    'cancelled'
);


--
-- Name: key_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.key_status AS ENUM (
    'active',
    'expired',
    'revoked'
);


--
-- Name: requirement_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.requirement_type AS ENUM (
    'content',
    'design',
    'research',
    'follow_up',
    'task',
    'develop',
    'analytics',
    'testing',
    'approval',
    'coordination',
    'strategy',
    'optimization',
    'automation',
    'integration',
    'planning',
    'payment'
);


--
-- Name: segment_audience; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.segment_audience AS ENUM (
    'enterprise',
    'smb',
    'startup',
    'b2b_saas',
    'e_commerce',
    'tech',
    'finance',
    'healthcare',
    'education',
    'manufacturing',
    'retail',
    'real_estate',
    'hospitality',
    'automotive',
    'media',
    'telecom',
    'energy',
    'agriculture',
    'construction',
    'logistics',
    'professional',
    'government',
    'nonprofit',
    'legal',
    'pharma',
    'insurance',
    'consulting',
    'research',
    'aerospace',
    'gaming'
);


--
-- Name: segment_language; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.segment_language AS ENUM (
    'en',
    'zh',
    'hi',
    'es',
    'ar',
    'bn',
    'pt',
    'ru',
    'ja',
    'de',
    'fr',
    'ur',
    'id',
    'tr',
    'it',
    'th',
    'vi',
    'ko',
    'fa',
    'pl',
    'uk',
    'ro',
    'nl',
    'el',
    'cs',
    'sv',
    'hu',
    'da',
    'fi',
    'no'
);


--
-- Name: is_service_role_or_user_condition(boolean); Type: FUNCTION; Schema: app_auth; Owner: -
--

CREATE FUNCTION app_auth.is_service_role_or_user_condition(user_condition boolean) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT CASE 
    WHEN (SELECT current_setting('role', true)) = 'service_role' THEN true
    WHEN (SELECT (auth.jwt() ->> 'role')) = 'service_role' THEN true
    ELSE COALESCE(user_condition, false)
  END;
$$;


--
-- Name: validate_metadata_size(); Type: FUNCTION; Schema: app_auth; Owner: -
--

CREATE FUNCTION app_auth.validate_metadata_size() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
  max_metadata_size_kb INT := 50; -- Límite de 50KB para metadatos
  metadata_size_kb INT;
  picture_data TEXT;
BEGIN
  -- Calcular tamaño de los metadatos
  metadata_size_kb := octet_length(NEW.raw_user_meta_data::text) / 1024;
  
  -- Si los metadatos son demasiado grandes
  IF metadata_size_kb > max_metadata_size_kb THEN
    RAISE WARNING 'Metadatos demasiado grandes (% KB). Limpiando campos problemáticos...', metadata_size_kb;
    
    -- Verificar si hay imagen en base64 en el campo picture
    IF NEW.raw_user_meta_data->>'picture' IS NOT NULL AND 
       length(NEW.raw_user_meta_data->>'picture') > 1000 AND
       NEW.raw_user_meta_data->>'picture' LIKE 'data:%' THEN
       
      RAISE WARNING 'Detectada imagen en base64 en el campo picture. Estableciendo como NULL';
      NEW.raw_user_meta_data = NEW.raw_user_meta_data - 'picture';
    END IF;
    
    -- Revisar otros campos grandes y eliminarlos
    FOR picture_data IN 
      SELECT key FROM jsonb_each_text(NEW.raw_user_meta_data) 
      WHERE length(value) > 1000 AND value LIKE 'data:%'
    LOOP
      RAISE WARNING 'Detectado campo grande en metadatos: %. Eliminando...', picture_data;
      NEW.raw_user_meta_data = NEW.raw_user_meta_data - picture_data;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: deals_location_check(boolean, uuid, uuid); Type: FUNCTION; Schema: commerce_rls_private; Owner: -
--

CREATE FUNCTION commerce_rls_private.deals_location_check(p_restricted boolean, p_1 uuid, p_2 uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$BEGIN
      IF p_restricted IS FALSE THEN RETURN true; END IF;
      RETURN (SELECT (((NOT ( SELECT p_restricted AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id)))) FROM (SELECT p_1 AS site_id, p_2 AS location_id) AS deals);
      END;$$;


--
-- Name: quotations_location_check(boolean, uuid, uuid, uuid); Type: FUNCTION; Schema: commerce_rls_private; Owner: -
--

CREATE FUNCTION commerce_rls_private.quotations_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$BEGIN
      IF p_restricted IS FALSE THEN RETURN true; END IF;
      RETURN (SELECT (((NOT ( SELECT p_restricted AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((deal_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.deals acl_parent
  WHERE ((acl_parent.id = quotations.deal_id) AND (acl_parent.site_id = quotations.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM quotations.location_id)))))))))) FROM (SELECT p_1 AS site_id, p_2 AS deal_id, p_3 AS location_id) AS quotations);
      END;$$;


--
-- Name: sale_order_items_location_check(boolean, uuid, uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: commerce_rls_private; Owner: -
--

CREATE FUNCTION commerce_rls_private.sale_order_items_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid, p_5 uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$BEGIN
      IF p_restricted IS FALSE THEN RETURN true; END IF;
      RETURN (SELECT (((NOT ( SELECT p_restricted AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (true AND (EXISTS ( SELECT 1
   FROM public.sale_orders acl_parent
  WHERE ((acl_parent.id = sale_order_items.sale_order_id) AND (acl_parent.site_id = sale_order_items.site_id)))) AND ((shipment_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.shipments acl_parent
  WHERE ((acl_parent.id = sale_order_items.shipment_id) AND (acl_parent.site_id = sale_order_items.site_id))))) AND ((location_id IS NULL) OR public.user_can_access_location(site_id, location_id)) AND (parent_sale_order_item_id IS NULL))))) FROM (SELECT p_1 AS sale_order_id, p_2 AS site_id, p_3 AS location_id, p_4 AS shipment_id, p_5 AS parent_sale_order_item_id) AS sale_order_items);
      END;$$;


--
-- Name: sale_orders_location_check(boolean, uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: commerce_rls_private; Owner: -
--

CREATE FUNCTION commerce_rls_private.sale_orders_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$BEGIN
      IF p_restricted IS FALSE THEN RETURN true; END IF;
      RETURN (SELECT (((NOT ( SELECT p_restricted AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((quotation_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.quotations acl_parent
  WHERE ((acl_parent.id = sale_orders.quotation_id) AND (acl_parent.site_id = sale_orders.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM sale_orders.location_id)))))) AND ((sale_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = sale_orders.sale_id) AND (acl_parent.site_id = sale_orders.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM sale_orders.location_id)))))))))) FROM (SELECT p_1 AS sale_id, p_2 AS site_id, p_3 AS quotation_id, p_4 AS location_id) AS sale_orders);
      END;$$;


--
-- Name: sales_location_check(boolean, uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: commerce_rls_private; Owner: -
--

CREATE FUNCTION commerce_rls_private.sales_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$BEGIN
      IF p_restricted IS FALSE THEN RETURN true; END IF;
      RETURN (SELECT (((NOT ( SELECT p_restricted AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, location_id) AND ((quotation_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.quotations acl_parent
  WHERE ((acl_parent.id = sales.quotation_id) AND (acl_parent.site_id = sales.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM sales.location_id)))))) AND ((subscription_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.subscriptions acl_parent
  WHERE ((acl_parent.id = sales.subscription_id) AND (acl_parent.site_id = sales.site_id) AND (NOT (acl_parent.location_id IS DISTINCT FROM sales.location_id)))))))))) FROM (SELECT p_1 AS site_id, p_2 AS location_id, p_3 AS subscription_id, p_4 AS quotation_id) AS sales);
      END;$$;


--
-- Name: shipments_location_check(boolean, uuid, uuid, uuid, uuid); Type: FUNCTION; Schema: commerce_rls_private; Owner: -
--

CREATE FUNCTION commerce_rls_private.shipments_location_check(p_restricted boolean, p_1 uuid, p_2 uuid, p_3 uuid, p_4 uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$BEGIN
      IF p_restricted IS FALSE THEN RETURN true; END IF;
      RETURN (SELECT (((NOT ( SELECT p_restricted AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR (public.user_can_access_location(site_id, origin_location_id) AND ((sale_id IS NULL) OR (EXISTS ( SELECT 1
   FROM public.sales acl_parent
  WHERE ((acl_parent.id = shipments.sale_id) AND (acl_parent.site_id = shipments.site_id))))) AND (EXISTS ( SELECT 1
   FROM public.sale_orders acl_parent
  WHERE ((acl_parent.id = shipments.sale_order_id) AND (acl_parent.site_id = shipments.site_id)))))))) FROM (SELECT p_1 AS site_id, p_2 AS sale_order_id, p_3 AS sale_id, p_4 AS origin_location_id) AS shipments);
      END;$$;


--
-- Name: subscriptions_location_check(boolean, uuid, uuid); Type: FUNCTION; Schema: commerce_rls_private; Owner: -
--

CREATE FUNCTION commerce_rls_private.subscriptions_location_check(p_restricted boolean, p_1 uuid, p_2 uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog'
    AS $$BEGIN
      IF p_restricted IS FALSE THEN RETURN true; END IF;
      RETURN (SELECT (((NOT ( SELECT p_restricted AS current_user_has_location_restrictions)) OR ((public.current_user_site_role(site_id) = ANY (ARRAY['owner'::text, 'admin'::text])) OR public.user_can_access_location(site_id, location_id)))) FROM (SELECT p_1 AS site_id, p_2 AS location_id) AS subscriptions);
      END;$$;


--
-- Name: original_16695(text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16695(p_table_name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    trigger_name TEXT;
BEGIN
    trigger_name := 'trigger_delete_protection_' || p_table_name;
    
    -- Drop existing trigger if it exists
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', trigger_name, p_table_name);
    
    -- Create new trigger
    EXECUTE format(
        'CREATE TRIGGER %I 
         BEFORE DELETE ON public.%I 
         FOR EACH ROW 
         EXECUTE FUNCTION public.check_delete_permission()',
        trigger_name, p_table_name
    );
    
    RAISE NOTICE 'Added delete protection trigger to table: %', p_table_name;
END;
$$;


--
-- Name: original_16696(text, text, text); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16696(email_param text, name_param text DEFAULT NULL::text, referral_code_param text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
  waitlist_id UUID;
BEGIN
  INSERT INTO public.waitlist (email, name, referral_code_attempted)
  VALUES (email_param, name_param, referral_code_param)
  RETURNING id INTO waitlist_id;
  
  RETURN waitlist_id;
END;
$$;


--
-- Name: original_16697(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16697() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
  SELECT auth.uid()
$$;


--
-- Name: original_16699(); Type: FUNCTION; Schema: location_acl_private; Owner: -
--

CREATE FUNCTION location_acl_private.original_16699() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  function_count INTEGER;
  table_count INTEGER;
  policy_count INTEGER;
  result JSON;
BEGIN
  -- Verificar funciones
  SELECT COUNT(*) INTO function_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' 
  AND p.proname IN ('upsert_billing', 'add_credits');
  
  -- Verificar tabla billing
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_name = 'billing';
  
  -- Verificar políticas RLS
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'billing';
  
  result := json_build_object(
    'status', 'success',
    'functions_found', function_count,
    'expected_functions', 2,
    'billing_table_exists', table_count > 0,
    'rls_policies_count', policy_count,
    'timestamp', NOW(),
    'warnings_fixed', true
  );
  
  RETURN result;
END;
$$;
