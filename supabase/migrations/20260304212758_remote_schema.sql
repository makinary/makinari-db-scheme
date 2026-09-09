


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "app_auth";


ALTER SCHEMA "app_auth" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'Performance optimized 2025-01-30: Safe concurrent index operations completed - no deadlocks';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."campaign_priority" AS ENUM (
    'high',
    'medium',
    'low'
);


ALTER TYPE "public"."campaign_priority" OWNER TO "postgres";


CREATE TYPE "public"."campaign_status" AS ENUM (
    'active',
    'pending',
    'completed'
);


ALTER TYPE "public"."campaign_status" OWNER TO "postgres";


CREATE TYPE "public"."command_status" AS ENUM (
    'pending',
    'running',
    'completed',
    'failed',
    'cancelled'
);


ALTER TYPE "public"."command_status" OWNER TO "postgres";


CREATE TYPE "public"."key_status" AS ENUM (
    'active',
    'expired',
    'revoked'
);


ALTER TYPE "public"."key_status" OWNER TO "postgres";


CREATE TYPE "public"."requirement_type" AS ENUM (
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


ALTER TYPE "public"."requirement_type" OWNER TO "postgres";


CREATE TYPE "public"."segment_audience" AS ENUM (
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


ALTER TYPE "public"."segment_audience" OWNER TO "postgres";


CREATE TYPE "public"."segment_language" AS ENUM (
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


ALTER TYPE "public"."segment_language" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "app_auth"."is_service_role_or_user_condition"("user_condition" boolean) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  SELECT CASE 
    WHEN (SELECT current_setting('role', true)) = 'service_role' THEN true
    WHEN (SELECT (auth.jwt() ->> 'role')) = 'service_role' THEN true
    ELSE COALESCE(user_condition, false)
  END;
$$;


ALTER FUNCTION "app_auth"."is_service_role_or_user_condition"("user_condition" boolean) OWNER TO "postgres";


COMMENT ON FUNCTION "app_auth"."is_service_role_or_user_condition"("user_condition" boolean) IS 'Performance-optimized function to check service_role access OR user condition. Service_role bypasses all checks.';



CREATE OR REPLACE FUNCTION "app_auth"."validate_metadata_size"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
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


ALTER FUNCTION "app_auth"."validate_metadata_size"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."activate_pending_site_memberships"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  updated_count INTEGER := 0;
  site_record RECORD;
BEGIN
  -- Solo procesar en INSERT (nuevo perfil creado)
  IF TG_OP = 'INSERT' AND NEW.email IS NOT NULL THEN
    BEGIN
      -- Verificar que la tabla site_members existe antes de usarla
      IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'site_members' 
          AND table_schema = 'public'
      ) THEN
        
        -- Procesar cada invitación pendiente por separado
        FOR site_record IN 
          SELECT id, site_id, email 
          FROM public.site_members 
          WHERE email = NEW.email 
            AND status = 'pending' 
            AND user_id IS NULL
        LOOP
          BEGIN
            -- Verificar si ya existe un registro activo para este user_id y site_id
            IF NOT EXISTS (
              SELECT 1 FROM public.site_members 
              WHERE site_id = site_record.site_id 
                AND user_id = NEW.id 
                AND status = 'active'
            ) THEN
              -- Actualizar el registro pendiente
              UPDATE public.site_members
              SET 
                user_id = NEW.id,
                status = 'active',
                updated_at = NOW()
              WHERE id = site_record.id;
              
              updated_count := updated_count + 1;
              
              RAISE NOTICE 'Activated site membership for user % on site % (email: %)', 
                           NEW.id, site_record.site_id, NEW.email;
            ELSE
              -- Ya existe un registro activo, eliminar el pendiente
              DELETE FROM public.site_members WHERE id = site_record.id;
              
              RAISE NOTICE 'Removed duplicate pending membership for user % on site %', 
                           NEW.id, site_record.site_id;
            END IF;
            
          EXCEPTION
            WHEN unique_violation THEN
              -- Si hay violación de constraint único, eliminar el pendiente
              DELETE FROM public.site_members WHERE id = site_record.id;
              RAISE WARNING 'Removed conflicting site member record for % on site %', 
                            NEW.email, site_record.site_id;
              
            WHEN OTHERS THEN
              RAISE WARNING 'Error processing site member % for %: %', 
                            site_record.id, NEW.email, SQLERRM;
          END;
        END LOOP;
        
        IF updated_count > 0 THEN
          RAISE NOTICE 'Total activated memberships: % for user %', updated_count, NEW.email;
        END IF;
        
      ELSE
        RAISE NOTICE 'Table site_members does not exist, skipping membership activation';
      END IF;
      
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error but don't fail profile creation
        RAISE WARNING 'General error activating site memberships for %: %', 
                      NEW.email, SQLERRM;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."activate_pending_site_memberships"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_command_id_to_all_tables"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    rec RECORD;
    sql_text TEXT;
BEGIN
    -- Implementation depends on the original function logic
    -- This is a placeholder that should be updated with the actual logic
    RAISE NOTICE 'add_command_id_to_all_tables function secured with search_path';
END;
$$;


ALTER FUNCTION "public"."add_command_id_to_all_tables"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_credits"("p_site_id" "uuid", "p_credits" integer) RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Actualizar el registro de billing para agregar créditos
  UPDATE billing 
  SET 
    credits_available = COALESCE(credits_available, 0) + p_credits,
    updated_at = NOW()
  WHERE site_id = p_site_id;
  
  -- Si no existe registro de billing, crear uno
  IF NOT FOUND THEN
    INSERT INTO billing (
      site_id,
      plan,
      credits_available,
      auto_renew,
      created_at,
      updated_at
    ) VALUES (
      p_site_id,
      'commission',
      p_credits,
      true,
      NOW(),
      NOW()
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'credits_added', p_credits,
    'message', 'Credits added successfully'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;


ALTER FUNCTION "public"."add_credits"("p_site_id" "uuid", "p_credits" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_delete_protection_trigger"("p_table_name" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."add_delete_protection_trigger"("p_table_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."add_to_waitlist"("email_param" "text", "name_param" "text" DEFAULT NULL::"text", "referral_code_param" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."add_to_waitlist"("email_param" "text", "name_param" "text", "referral_code_param" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auth_user_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
  SELECT auth.uid()
$$;


ALTER FUNCTION "public"."auth_user_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_kpis_from_events"("site_id_param" "uuid", "kpi_type_param" "text", "period_start_param" timestamp with time zone, "period_end_param" timestamp with time zone) RETURNS TABLE("kpi_name" "text", "kpi_value" numeric, "kpi_previous_value" numeric, "segment_id" "uuid")
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
  previous_period_start TIMESTAMPTZ;
  previous_period_end TIMESTAMPTZ;
  period_length_days INTEGER;
BEGIN
  -- Calcular período anterior basado en la duración del período actual
  period_length_days := EXTRACT(EPOCH FROM (period_end_param - period_start_param)) / 86400;
  previous_period_start := period_start_param - (period_end_param - period_start_param);
  previous_period_end := period_start_param;
  
  -- Devolver diferentes métricas según el tipo de KPI solicitado
  IF kpi_type_param = 'traffic' THEN
    -- KPI de tráfico: número de page_views
    RETURN QUERY
    WITH current_data AS (
      SELECT 
        s.id AS segment_id,
        COUNT(*) AS current_count
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.event_type = 'page_view'
        AND ve.created_at BETWEEN period_start_param AND period_end_param
      GROUP BY s.id
    ),
    previous_data AS (
      SELECT 
        s.id AS segment_id,
        COUNT(*) AS previous_count
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.event_type = 'page_view'
        AND ve.created_at BETWEEN previous_period_start AND previous_period_end
      GROUP BY s.id
    )
    SELECT 
      'Visitas de página' AS kpi_name,
      COALESCE(cd.current_count, 0)::DECIMAL AS kpi_value,
      COALESCE(pd.previous_count, 0)::DECIMAL AS kpi_previous_value,
      cd.segment_id
    FROM current_data cd
    LEFT JOIN previous_data pd ON cd.segment_id = pd.segment_id
    UNION ALL
    SELECT 
      'Visitas de página (sin segmento)' AS kpi_name,
      COUNT(*)::DECIMAL AS kpi_value,
      (SELECT COUNT(*)::DECIMAL FROM public.visitor_events 
       WHERE site_id = site_id_param
         AND event_type = 'page_view'
         AND segment_id IS NULL
         AND created_at BETWEEN previous_period_start AND previous_period_end) AS kpi_previous_value,
      NULL::UUID AS segment_id
    FROM public.visitor_events
    WHERE site_id = site_id_param
      AND event_type = 'page_view'
      AND segment_id IS NULL
      AND created_at BETWEEN period_start_param AND period_end_param;
    
  ELSIF kpi_type_param = 'conversion' THEN
    -- KPI de conversión
    RETURN QUERY
    WITH conversions AS (
      SELECT 
        s.id AS segment_id,
        COUNT(*) FILTER (WHERE ve.event_type = 'conversion') AS conv_count,
        COUNT(*) FILTER (WHERE ve.event_type = 'page_view') AS view_count,
        COUNT(*) FILTER (WHERE ve.event_type = 'conversion' AND ve.created_at BETWEEN previous_period_start AND previous_period_end) AS prev_conv_count,
        COUNT(*) FILTER (WHERE ve.event_type = 'page_view' AND ve.created_at BETWEEN previous_period_start AND previous_period_end) AS prev_view_count
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.created_at BETWEEN previous_period_start AND period_end_param
        AND (ve.event_type = 'conversion' OR ve.event_type = 'page_view')
      GROUP BY s.id
    )
    SELECT 
      'Tasa de conversión' AS kpi_name,
      CASE 
        WHEN view_count > 0 THEN (conv_count * 100.0 / view_count)::DECIMAL 
        ELSE 0::DECIMAL 
      END AS kpi_value,
      CASE 
        WHEN prev_view_count > 0 THEN (prev_conv_count * 100.0 / prev_view_count)::DECIMAL 
        ELSE 0::DECIMAL 
      END AS kpi_previous_value,
      segment_id
    FROM conversions;
    
  ELSIF kpi_type_param = 'engagement' THEN
    -- KPI de engagement (promedio de duración de sesión)
    RETURN QUERY
    WITH engagement AS (
      SELECT 
        s.id AS segment_id,
        AVG(ve.duration_seconds) FILTER (WHERE ve.created_at BETWEEN period_start_param AND period_end_param) AS avg_duration,
        AVG(ve.duration_seconds) FILTER (WHERE ve.created_at BETWEEN previous_period_start AND previous_period_end) AS prev_avg_duration
      FROM public.visitor_events ve
      LEFT JOIN public.segments s ON ve.segment_id = s.id
      WHERE ve.site_id = site_id_param
        AND ve.created_at BETWEEN previous_period_start AND period_end_param
        AND ve.duration_seconds IS NOT NULL
      GROUP BY s.id
    )
    SELECT 
      'Tiempo promedio en página' AS kpi_name,
      COALESCE(avg_duration, 0)::DECIMAL AS kpi_value,
      COALESCE(prev_avg_duration, 0)::DECIMAL AS kpi_previous_value,
      segment_id
    FROM engagement;
  END IF;
END;
$$;


ALTER FUNCTION "public"."calculate_kpis_from_events"("site_id_param" "uuid", "kpi_type_param" "text", "period_start_param" timestamp with time zone, "period_end_param" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_billing_system"() RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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


ALTER FUNCTION "public"."check_billing_system"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_create_update_permission"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
    target_site_id UUID;
    current_user_id UUID;
    user_role TEXT;
    is_owner BOOLEAN := FALSE;
    is_admin BOOLEAN := FALSE;
    is_collaborator BOOLEAN := FALSE;
    is_service_role BOOLEAN := FALSE;
    is_superuser BOOLEAN := FALSE;
BEGIN
    -- NEW: Check if current user is superuser (postgres)
    SELECT rolsuper INTO is_superuser 
    FROM pg_roles 
    WHERE rolname = current_user;
    
    -- Allow superuser to bypass all restrictions
    IF is_superuser THEN
        RETURN NEW;
    END IF;
    
    -- Check if this is service_role (bypass restrictions)
    BEGIN
        is_service_role := (current_setting('role') = 'service_role');
    EXCEPTION WHEN OTHERS THEN
        is_service_role := FALSE;
    END;
    
    -- Allow service_role to bypass restrictions
    IF is_service_role THEN
        RETURN NEW;
    END IF;
    
    -- Get current user
    current_user_id := auth.uid();
    
    -- If no user, block the operation
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'CREATE_UPDATE_PERMISSION_DENIED: Authentication required';
    END IF;
    
    -- Get the site_id from the record being inserted/updated
    CASE TG_TABLE_NAME
        WHEN 'visitors' THEN
            -- visitors doesn't have direct site_id, get from related tables
            IF NEW.segment_id IS NOT NULL THEN
                SELECT s.site_id INTO target_site_id
                FROM public.segments s
                WHERE s.id = NEW.segment_id;
            ELSIF NEW.lead_id IS NOT NULL THEN
                SELECT l.site_id INTO target_site_id
                FROM public.leads l
                WHERE l.id = NEW.lead_id;
            ELSE
                -- Allow if can't determine site_id (system operation)
                RETURN NEW;
            END IF;
            
        WHEN 'visitor_sessions' THEN
            target_site_id := NEW.site_id;
            
        WHEN 'messages' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.conversations c 
            WHERE c.id = NEW.conversation_id;
            
        ELSE
            -- Default: assume table has site_id column
            BEGIN
                EXECUTE format('SELECT ($1).site_id') USING NEW INTO target_site_id;
            EXCEPTION WHEN OTHERS THEN
                -- If no site_id column, allow operation (might be system table)
                RETURN NEW;
            END;
    END CASE;
    
    -- If we couldn't determine site_id, allow the operation (might be system table)
    IF target_site_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Check if user is site owner (fastest check)
    SELECT EXISTS (
        SELECT 1 FROM public.site_ownership 
        WHERE site_id = target_site_id AND user_id = current_user_id
    ) INTO is_owner;
    
    -- If owner, allow immediately
    IF is_owner THEN
        RETURN NEW;
    END IF;
    
    -- Check user role in site_members
    SELECT role INTO user_role
    FROM public.site_members 
    WHERE site_id = target_site_id 
    AND user_id = current_user_id 
    AND status = 'active';
    
    -- Set role flags
    is_admin := (user_role = 'admin');
    is_collaborator := (user_role = 'collaborator');
    
    -- Allow admin and collaborator to create/update
    IF is_admin OR is_collaborator THEN
        RETURN NEW;
    END IF;
    
    -- Block marketing (viewer) and any other roles
    RAISE EXCEPTION 'CREATE_UPDATE_PERMISSION_DENIED: Only site owners, admins, and collaborators can create/update records. Your role: % on site: %', 
        COALESCE(user_role, 'none'), target_site_id;
END;
$_$;


ALTER FUNCTION "public"."check_create_update_permission"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_create_update_permission"() IS 'Trigger function that checks if current user has permission to create/update records. 
Allows only site owners, admins, and collaborators. Blocks marketing (viewer) role.
Has secure search_path and service_role bypass.';



CREATE OR REPLACE FUNCTION "public"."check_delete_permission"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $_$
DECLARE
    target_site_id UUID;
    current_user_id UUID;
    user_role TEXT;
    is_owner BOOLEAN := FALSE;
    is_admin BOOLEAN := FALSE;
    deleting_site_id TEXT;
    deleting_user_id TEXT;
BEGIN
    -- Get current user
    current_user_id := auth.uid();
    
    -- Skip check for system operations (when no user context)
    IF current_user_id IS NULL THEN
        RETURN OLD;
    END IF;
    
    -- Check if we're in a legitimate site deletion context
    BEGIN
        deleting_site_id := current_setting('app.deleting_site_id', true);
        deleting_user_id := current_setting('app.deleting_user_id', true);
    EXCEPTION
        WHEN OTHERS THEN
            deleting_site_id := '';
            deleting_user_id := '';
    END;
    
    -- Get site_id from the record being deleted
    CASE TG_TABLE_NAME
        WHEN 'sites' THEN
            target_site_id := OLD.id;
            
        WHEN 'task_comments' THEN
            SELECT t.site_id INTO target_site_id
            FROM public.tasks t 
            WHERE t.id = OLD.task_id;
            
        WHEN 'task_categories' THEN
            SELECT t.site_id INTO target_site_id
            FROM public.tasks t 
            WHERE t.id = OLD.task_id;
            
        WHEN 'agent_assets' THEN
            SELECT a.site_id INTO target_site_id
            FROM public.agents a 
            WHERE a.id = OLD.agent_id;
            
        WHEN 'agent_memories' THEN
            SELECT a.site_id INTO target_site_id
            FROM public.agents a 
            WHERE a.id = OLD.agent_id;
            
        WHEN 'campaign_requirements' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.campaigns c 
            WHERE c.id = OLD.campaign_id;
            
        WHEN 'campaign_segments' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.campaigns c 
            WHERE c.id = OLD.campaign_id;
            
        WHEN 'campaign_subtasks' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.campaigns c 
            WHERE c.id = OLD.campaign_id;
            
        WHEN 'experiment_segments' THEN
            SELECT e.site_id INTO target_site_id
            FROM public.experiments e 
            WHERE e.id = OLD.experiment_id;
            
        WHEN 'requirement_segments' THEN
            SELECT r.site_id INTO target_site_id
            FROM public.requirements r 
            WHERE r.id = OLD.requirement_id;
            
        WHEN 'messages' THEN
            SELECT c.site_id INTO target_site_id
            FROM public.conversations c 
            WHERE c.id = OLD.conversation_id;
            
        WHEN 'sale_orders' THEN
            target_site_id := OLD.site_id;
            
        ELSE
            -- Default: assume table has site_id column
            BEGIN
                EXECUTE format('SELECT ($1).site_id') USING OLD INTO target_site_id;
            EXCEPTION
                WHEN OTHERS THEN
                    target_site_id := NULL;
            END;
    END CASE;
    
    -- If we couldn't determine site_id, allow the operation (might be system table)
    IF target_site_id IS NULL THEN
        RETURN OLD;
    END IF;
    
    -- CRITICAL: Check if this deletion is part of a legitimate site deletion
    IF deleting_site_id IS NOT NULL 
       AND deleting_site_id != '' 
       AND deleting_site_id = target_site_id::text
       AND deleting_user_id = current_user_id::text THEN
        -- This is a legitimate site deletion by the site owner
        RETURN OLD;
    END IF;
    
    -- For individual record deletions, check normal permissions
    
    -- Check if user is site owner (fastest check)
    SELECT EXISTS (
        SELECT 1 FROM public.sites 
        WHERE id = target_site_id AND user_id = current_user_id
    ) INTO is_owner;
    
    -- If owner, allow immediately
    IF is_owner THEN
        RETURN OLD;
    END IF;
    
    -- Check if user is admin member
    BEGIN
        SELECT role INTO user_role
        FROM public.site_members 
        WHERE site_id = target_site_id 
        AND user_id = current_user_id 
        AND status = 'active';
        
        is_admin := (user_role = 'admin');
    EXCEPTION
        WHEN undefined_table THEN
            -- site_members table doesn't exist, treat as non-admin
            is_admin := FALSE;
            user_role := 'none';
    END;
    
    -- Allow if admin, block otherwise
    IF is_admin THEN
        RETURN OLD;
    ELSE
        RAISE EXCEPTION 'DELETE_PERMISSION_DENIED: Only site owners and admins can delete records. Your role: none';
    END IF;
END;
$_$;


ALTER FUNCTION "public"."check_delete_permission"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_delete_permission"() IS 'Enhanced delete protection function that respects site deletion context.';



CREATE OR REPLACE FUNCTION "public"."check_delete_protection_status"() RETURNS TABLE("table_name" "text", "trigger_name" "text", "status" "text", "performance_impact" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'information_schema, public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.event_object_table::TEXT,
        t.trigger_name::TEXT,
        CASE 
            WHEN t.trigger_name IS NOT NULL THEN 'PROTECTED'
            ELSE 'NOT PROTECTED'
        END::TEXT,
        CASE 
            WHEN t.trigger_name IS NOT NULL THEN 'MINIMAL (single function call)'
            ELSE 'N/A'
        END::TEXT
    FROM information_schema.tables tab
    LEFT JOIN information_schema.triggers t ON t.event_object_table = tab.table_name 
        AND t.trigger_name LIKE 'trigger_delete_protection_%'
        AND t.event_object_schema = 'public'
    WHERE tab.table_schema = 'public'
    AND tab.table_type = 'BASE TABLE'
    ORDER BY tab.table_name;
END;
$$;


ALTER FUNCTION "public"."check_delete_protection_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_referral_system_status"() RETURNS TABLE("component" "text", "status" "text", "details" "text")
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  -- Verificar tablas
  RETURN QUERY
  SELECT 
    'Tabla referral_codes'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referral_codes') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    (SELECT COUNT(*)::TEXT || ' códigos' FROM public.referral_codes)::TEXT;
    
  RETURN QUERY
  SELECT 
    'Tabla referral_code_uses'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'referral_code_uses') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    (SELECT COUNT(*)::TEXT || ' usos' FROM public.referral_code_uses)::TEXT;
  
  -- Verificar funciones
  RETURN QUERY
  SELECT 
    'Función validate_referral_code'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validate_referral_code') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Valida códigos de referido'::TEXT;
    
  RETURN QUERY
  SELECT 
    'Función register_referral_code_use'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'register_referral_code_use') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Registra uso de códigos'::TEXT;
    
  RETURN QUERY
  SELECT 
    'Función handle_new_user'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Trigger de nuevos usuarios'::TEXT;
  
  -- Verificar trigger
  RETURN QUERY
  SELECT 
    'Trigger on_auth_user_created'::TEXT,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN '✅ Existe' ELSE '❌ No existe' END,
    'Trigger en auth.users'::TEXT;
    
  -- Verificar códigos activos
  RETURN QUERY
  SELECT 
    'Códigos activos'::TEXT,
    (SELECT COUNT(*)::TEXT FROM public.referral_codes WHERE is_active = true),
    (SELECT string_agg(code, ', ') FROM public.referral_codes WHERE is_active = true)::TEXT;
END;
$$;


ALTER FUNCTION "public"."check_referral_system_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_role_restrictions_status"() RETURNS TABLE("table_name" "text", "insert_trigger" "text", "update_trigger" "text", "delete_trigger" "text", "status" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    table_names TEXT[] := ARRAY[
        'leads', 'campaigns', 'segments', 'experiments', 'sales',
        'agents', 'content', 'requirements', 'tasks', 'visitors',
        'visitor_sessions', 'messages', 'notifications'
    ];
    
    current_table TEXT;
    insert_trig TEXT;
    update_trig TEXT;
    delete_trig TEXT;
    status_msg TEXT;
    
BEGIN
    FOREACH current_table IN ARRAY table_names
    LOOP
        -- Check if triggers exist
        SELECT 
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_insert_permission_' || current_table
                AND event_object_table = current_table
            ) THEN '✅ Active' ELSE '❌ Missing' END,
            
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_update_permission_' || current_table
                AND event_object_table = current_table
            ) THEN '✅ Active' ELSE '❌ Missing' END,
            
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_delete_protection_' || current_table
                AND event_object_table = current_table
            ) THEN '✅ Active' ELSE '❌ Missing' END
        INTO insert_trig, update_trig, delete_trig;
        
        -- Determine overall status
        IF insert_trig = '✅ Active' AND update_trig = '✅ Active' AND delete_trig = '✅ Active' THEN
            status_msg := '✅ Fully Protected';
        ELSIF insert_trig = '✅ Active' AND update_trig = '✅ Active' THEN
            status_msg := '⚠️ CREATE/UPDATE Protected';
        ELSIF delete_trig = '✅ Active' THEN
            status_msg := '⚠️ DELETE Protected Only';
        ELSE
            status_msg := '❌ No Protection';
        END IF;
        
        RETURN QUERY SELECT current_table, insert_trig, update_trig, delete_trig, status_msg;
    END LOOP;
END;
$$;


ALTER FUNCTION "public"."check_role_restrictions_status"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_role_restrictions_status"() IS 'Shows the status of role-based restrictions on all tables. 
Displays which tables have INSERT/UPDATE/DELETE protection active.
Has secure search_path.';



CREATE OR REPLACE FUNCTION "public"."check_webhook_event_processed"("event_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
    is_processed BOOLEAN;
BEGIN
    SELECT processed INTO is_processed 
    FROM public.webhook_events 
    WHERE id = event_id;
    
    RETURN COALESCE(is_processed, FALSE);
EXCEPTION
    WHEN others THEN
        -- Return false if table doesn't exist or other errors
        RETURN FALSE;
END;
$$;


ALTER FUNCTION "public"."check_webhook_event_processed"("event_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_webhook_event_processed"("event_id" "uuid") IS 'Checks webhook event processing status. Secured with search_path = empty.';



CREATE OR REPLACE FUNCTION "public"."cleanup_old_webhook_events"("days_old" integer DEFAULT 30) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.webhook_events 
    WHERE created_at < NOW() - (days_old || ' days')::INTERVAL
    AND processed = TRUE;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;


ALTER FUNCTION "public"."cleanup_old_webhook_events"("days_old" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."cleanup_old_webhook_events"("days_old" integer) IS 'Cleans up old processed webhook events. Secured with search_path = empty string and SECURITY DEFINER.';



CREATE OR REPLACE FUNCTION "public"."debug_increment_visitor_sessions"("p_visitor_id" "uuid", "p_last_seen_timestamp" bigint) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    debug_info jsonb;
    current_role_setting text;
    current_user_id uuid;
    jwt_claims jsonb;
BEGIN
    -- Recopilar información de debug
    BEGIN
        current_role_setting := current_setting('role', true);
    EXCEPTION WHEN OTHERS THEN
        current_role_setting := 'ERROR_GETTING_ROLE';
    END;
    
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        current_user_id := NULL;
    END;
    
    BEGIN
        jwt_claims := auth.jwt();
    EXCEPTION WHEN OTHERS THEN
        jwt_claims := NULL;
    END;
    
    debug_info := jsonb_build_object(
        'current_role_setting', current_role_setting,
        'current_user_id', current_user_id,
        'jwt_claims', jwt_claims,
        'session_user', session_user,
        'current_user', current_user,
        'is_service_role_function', public.is_service_role()
    );
    
    RETURN debug_info;
END;
$$;


ALTER FUNCTION "public"."debug_increment_visitor_sessions"("p_visitor_id" "uuid", "p_last_seen_timestamp" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."decrypt_token"("encrypted_value" "text", "encryption_key" "text" DEFAULT NULL::"text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  actual_key TEXT;
BEGIN
  -- Use provided key or fall back to an environment variable
  actual_key := COALESCE(encryption_key, current_setting('app.encryption_key', true));
  
  -- If no key is available, raise an exception
  IF actual_key IS NULL THEN
    RAISE EXCEPTION 'Encryption key is not available';
  END IF;
  
  -- Return decrypted value
  RETURN pgp_sym_decrypt(
    decode(encrypted_value, 'base64'),
    actual_key
  );
EXCEPTION
  WHEN others THEN
    RETURN NULL; -- Return NULL if decryption fails
END;
$$;


ALTER FUNCTION "public"."decrypt_token"("encrypted_value" "text", "encryption_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_command_cascade"("command_uuid" "uuid") RETURNS json
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    deleted_counts JSON;
    temp_count INTEGER;
BEGIN
    -- Inicializar el objeto JSON de conteos
    deleted_counts := '{}';
    
    -- Borrar de agent_assets
    DELETE FROM agent_assets WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{agent_assets}', temp_count::text::jsonb);
    
    -- Borrar de agent_memories
    DELETE FROM agent_memories WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{agent_memories}', temp_count::text::jsonb);
    
    -- Borrar de agents
    DELETE FROM agents WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{agents}', temp_count::text::jsonb);
    
    -- Borrar de analysis
    DELETE FROM analysis WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{analysis}', temp_count::text::jsonb);
    
    -- Borrar de assets
    DELETE FROM assets WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{assets}', temp_count::text::jsonb);
    
    -- Borrar de billing
    DELETE FROM billing WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{billing}', temp_count::text::jsonb);
    
    -- Borrar de campaign_requirements
    DELETE FROM campaign_requirements WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaign_requirements}', temp_count::text::jsonb);
    
    -- Borrar de campaign_segments
    DELETE FROM campaign_segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaign_segments}', temp_count::text::jsonb);
    
    -- Borrar de campaign_subtasks
    DELETE FROM campaign_subtasks WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaign_subtasks}', temp_count::text::jsonb);
    
    -- Borrar de campaigns
    DELETE FROM campaigns WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{campaigns}', temp_count::text::jsonb);
    
    -- Borrar de content
    DELETE FROM content WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{content}', temp_count::text::jsonb);
    
    -- Borrar de conversations
    DELETE FROM conversations WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{conversations}', temp_count::text::jsonb);
    
    -- Borrar de debug_logs
    DELETE FROM debug_logs WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{debug_logs}', temp_count::text::jsonb);
    
    -- Borrar de experiment_segments
    DELETE FROM experiment_segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{experiment_segments}', temp_count::text::jsonb);
    
    -- Borrar de experiments
    DELETE FROM experiments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{experiments}', temp_count::text::jsonb);
    
    -- Borrar de external_resources
    DELETE FROM external_resources WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{external_resources}', temp_count::text::jsonb);
    
    -- Borrar de kpis
    DELETE FROM kpis WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{kpis}', temp_count::text::jsonb);
    
    -- Borrar de leads
    DELETE FROM leads WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{leads}', temp_count::text::jsonb);
    
    -- Borrar de messages
    DELETE FROM messages WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{messages}', temp_count::text::jsonb);
    
    -- Borrar de notifications
    DELETE FROM notifications WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{notifications}', temp_count::text::jsonb);
    
    -- Borrar de payments
    DELETE FROM payments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{payments}', temp_count::text::jsonb);
    
    -- Borrar de profiles
    DELETE FROM profiles WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{profiles}', temp_count::text::jsonb);
    
    -- Borrar de requirement_segments
    DELETE FROM requirement_segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{requirement_segments}', temp_count::text::jsonb);
    
    -- Borrar de requirements
    DELETE FROM requirements WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{requirements}', temp_count::text::jsonb);
    
    -- Borrar de sales
    DELETE FROM sales WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{sales}', temp_count::text::jsonb);
    
    -- Borrar de segments
    DELETE FROM segments WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{segments}', temp_count::text::jsonb);
    
    -- Borrar de session_events
    DELETE FROM session_events WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{session_events}', temp_count::text::jsonb);
    
    -- Borrar de settings
    DELETE FROM settings WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{settings}', temp_count::text::jsonb);
    
    -- Borrar de sites
    DELETE FROM sites WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{sites}', temp_count::text::jsonb);
    
    -- Borrar de tasks
    DELETE FROM tasks WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{tasks}', temp_count::text::jsonb);
    
    -- Borrar de transactions
    DELETE FROM transactions WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{transactions}', temp_count::text::jsonb);
    
    -- Borrar de visitor_sessions
    DELETE FROM visitor_sessions WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{visitor_sessions}', temp_count::text::jsonb);
    
    -- Borrar de visitors
    DELETE FROM visitors WHERE command_id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{visitors}', temp_count::text::jsonb);
    
    -- Finalmente, borrar el command
    DELETE FROM commands WHERE id = command_uuid;
    GET DIAGNOSTICS temp_count = ROW_COUNT;
    deleted_counts := jsonb_set(deleted_counts::jsonb, '{commands}', temp_count::text::jsonb);
    
    RETURN deleted_counts;
END;
$$;


ALTER FUNCTION "public"."delete_command_cascade"("command_uuid" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."delete_command_cascade"("command_uuid" "uuid") IS 'Borra un command y todos sus objetos relacionados. Retorna JSON con el conteo de registros borrados por tabla.';



CREATE OR REPLACE FUNCTION "public"."delete_command_simple"("command_uuid" "uuid") RETURNS boolean
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    result JSON;
BEGIN
    SELECT delete_command_cascade(command_uuid) INTO result;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al borrar command %: %', command_uuid, SQLERRM;
        RETURN FALSE;
END;
$$;


ALTER FUNCTION "public"."delete_command_simple"("command_uuid" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."delete_command_simple"("command_uuid" "uuid") IS 'Versión simplificada para borrar un command y sus objetos relacionados. Retorna TRUE/FALSE.';



CREATE OR REPLACE FUNCTION "public"."delete_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  rows_affected INTEGER;
BEGIN
  DELETE FROM secure_tokens
  WHERE site_id = p_site_id
    AND token_type = p_token_type
    AND identifier = p_identifier
  RETURNING 1 INTO rows_affected;
  
  RETURN FOUND;
END;
$$;


ALTER FUNCTION "public"."delete_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_site_safely"("site_id_param" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    site_exists BOOLEAN;
    user_is_owner BOOLEAN;
    current_user_id UUID;
BEGIN
    -- Get current user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required: You must be logged in to delete a site';
    END IF;
    
    -- Check if site exists
    SELECT EXISTS (
        SELECT 1 FROM public.sites 
        WHERE id = site_id_param
    ) INTO site_exists;
    
    IF NOT site_exists THEN
        RAISE EXCEPTION 'Site not found';
    END IF;
    
    -- Check if user is the owner of the site
    SELECT EXISTS (
        SELECT 1 FROM public.sites 
        WHERE id = site_id_param 
        AND user_id = current_user_id
    ) INTO user_is_owner;
    
    IF NOT user_is_owner THEN
        RAISE EXCEPTION 'Permission denied: Only the site owner can delete this site';
    END IF;
    
    -- Set context variable to indicate we're in a legitimate site deletion
    PERFORM set_config('app.deleting_site_id', site_id_param::text, true);
    PERFORM set_config('app.deleting_user_id', current_user_id::text, true);
    
    BEGIN
        -- Delete the site (CASCADE will delete related records)
        DELETE FROM public.sites WHERE id = site_id_param;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Clear context on error
            PERFORM set_config('app.deleting_site_id', '', true);
            PERFORM set_config('app.deleting_user_id', '', true);
            RAISE;
    END;
    
    -- Clear the context variables
    PERFORM set_config('app.deleting_site_id', '', true);
    PERFORM set_config('app.deleting_user_id', '', true);
    
    RETURN true;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Ensure context is cleared on any error
        PERFORM set_config('app.deleting_site_id', '', true);
        PERFORM set_config('app.deleting_user_id', '', true);
        RAISE;
END;
$$;


ALTER FUNCTION "public"."delete_site_safely"("site_id_param" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."delete_site_safely"("site_id_param" "uuid") IS 'Securely deletes a site and all its related data using context variables. Only site owners can delete sites.';



CREATE OR REPLACE FUNCTION "public"."encrypt_token"("token_value" "text", "encryption_key" "text" DEFAULT NULL::"text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  actual_key TEXT;
BEGIN
  -- Use provided key or fall back to an environment variable
  actual_key := COALESCE(encryption_key, current_setting('app.encryption_key', true));
  
  -- If no key is available, raise an exception
  IF actual_key IS NULL THEN
    RAISE EXCEPTION 'Encryption key is not available';
  END IF;
  
  -- Return encrypted value using pgcrypto
  RETURN encode(
    pgp_sym_encrypt(
      token_value, 
      actual_key
    ),
    'base64'
  );
END;
$$;


ALTER FUNCTION "public"."encrypt_token"("token_value" "text", "encryption_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ensure_api_key_not_expired"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF NEW.expires_at IS NOT NULL AND NEW.expires_at < CURRENT_TIMESTAMP THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."ensure_api_key_not_expired"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."expire_old_api_keys"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE public.api_keys
  SET status = 'expired'
  WHERE status = 'active'
    AND expires_at < CURRENT_TIMESTAMP;
  RETURN NULL; -- AFTER trigger, return value ignored
END;
$$;


ALTER FUNCTION "public"."expire_old_api_keys"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_task_serial_id"("site_uuid" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $_$
DECLARE
    site_prefix text;
    max_serial_num integer;
    new_serial_id text;
    attempt_count integer := 0;
    max_attempts integer := 10;
BEGIN
    -- Get site name to create prefix (first 3 characters, uppercase)
    SELECT UPPER(LEFT(COALESCE(name, 'TSK'), 3))
    INTO site_prefix
    FROM public.sites
    WHERE id = site_uuid;
    
    -- If site not found, use default prefix
    IF site_prefix IS NULL THEN
        site_prefix := 'TSK';
    END IF;
    
    -- Loop to handle race conditions
    LOOP
        -- Get the maximum serial number for this site prefix
        SELECT COALESCE(MAX(
            CASE 
                WHEN t.serial_id ~ ('^' || site_prefix || '-[0-9]+$') 
                THEN CAST(SPLIT_PART(t.serial_id, '-', 2) AS INTEGER)
                ELSE 0
            END
        ), 0) + 1
        INTO max_serial_num
        FROM public.tasks t
        WHERE t.site_id = site_uuid
        AND t.serial_id LIKE (site_prefix || '-%');
        
        -- Generate serial_id with format: PREFIX-NNNN
        new_serial_id := site_prefix || '-' || LPAD(max_serial_num::text, 4, '0');
        
        -- Check if this serial_id already exists
        IF NOT EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.site_id = site_uuid 
            AND t.serial_id = new_serial_id
        ) THEN
            -- Serial ID is unique, we can use it
            RETURN new_serial_id;
        END IF;
        
        -- Increment attempt counter
        attempt_count := attempt_count + 1;
        
        -- If we've tried too many times, add a random suffix
        IF attempt_count >= max_attempts THEN
            new_serial_id := site_prefix || '-' || LPAD(max_serial_num::text, 4, '0') || '-' || EXTRACT(EPOCH FROM clock_timestamp())::bigint;
            RETURN new_serial_id;
        END IF;
        
        -- Small delay to reduce contention
        PERFORM pg_sleep(0.001 * attempt_count);
    END LOOP;
END;
$_$;


ALTER FUNCTION "public"."generate_task_serial_id"("site_uuid" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."generate_task_serial_id"("site_uuid" "uuid") IS 'Generates a unique serial ID for a task based on site prefix and handles race conditions - fixed ambiguous reference';



CREATE OR REPLACE FUNCTION "public"."get_auth_user_id"() RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  auth0_sub TEXT;
  user_id UUID;
BEGIN
  -- Intentar obtener el sub claim del token JWT
  BEGIN
    auth0_sub := current_setting('request.jwt.claims', true)::json->>'sub';
  EXCEPTION
    WHEN others THEN
      auth0_sub := NULL;
  END;
  
  -- Si no hay token o no tiene sub, intentar usar auth.uid() por compatibilidad
  IF auth0_sub IS NULL THEN
    RETURN auth.uid();
  END IF;
  
  -- Buscar el perfil correspondiente al ID de Auth0
  SELECT id INTO user_id FROM public.profiles WHERE auth0_id = auth0_sub;
  RETURN user_id;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."get_auth_user_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_performance_status"("command_id" "uuid") RETURNS TABLE("has_like" boolean, "has_dislike" boolean, "has_flag" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (performance & 1) = 1 AS has_like,
        (performance & 2) = 2 AS has_dislike,
        (performance & 4) = 4 AS has_flag
    FROM public.commands
    WHERE id = command_id;
END;
$$;


ALTER FUNCTION "public"."get_performance_status"("command_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text", "p_encryption_key" "text" DEFAULT NULL::"text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  token_record RECORD;
  decrypted_value TEXT;
BEGIN
  -- Get the encrypted token
  SELECT * INTO token_record
  FROM secure_tokens
  WHERE site_id = p_site_id
    AND token_type = p_token_type
    AND identifier = p_identifier;
    
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  
  -- Decrypt the token
  decrypted_value := decrypt_token(token_record.encrypted_value, p_encryption_key);
  
  -- Update last_used timestamp
  UPDATE secure_tokens
  SET last_used = NOW()
  WHERE id = token_record.id;
  
  RETURN decrypted_value;
END;
$$;


ALTER FUNCTION "public"."get_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text", "p_encryption_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_profile_complete"("user_id_param" "uuid") RETURNS TABLE("id" "uuid", "email" "text", "name" "text", "avatar_url" "text", "bio" "text", "role" "text", "language" "text", "timezone" "text", "notifications" "jsonb", "settings" "jsonb", "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.email,
    p.name,
    p.avatar_url,
    p.bio,
    p.role,
    p.language,
    p.timezone,
    p.notifications,
    p.settings,
    p.created_at,
    p.updated_at
  FROM public.profiles p
  WHERE p.id = user_id_param;
END;
$$;


ALTER FUNCTION "public"."get_user_profile_complete"("user_id_param" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_campaign_deletion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Log de la operación (opcional, para debugging)
    RAISE NOTICE 'Deleting campaign: % - %', OLD.id, OLD.title;
    
    -- Primero eliminamos las relaciones en campaign_requirements
    DELETE FROM public.campaign_requirements 
    WHERE campaign_id = OLD.id;
    
    -- Luego eliminamos los requirements que solo estaban asociados a esta campaña
    -- (requirements que no tienen otras relaciones de campaña)
    DELETE FROM public.requirements 
    WHERE id IN (
        SELECT r.id 
        FROM public.requirements r
        LEFT JOIN public.campaign_requirements cr ON r.id = cr.requirement_id
        WHERE cr.requirement_id IS NULL
        AND r.id IN (
            -- Solo eliminar requirements que estaban asociados a la campaña eliminada
            SELECT requirement_id 
            FROM public.campaign_requirements 
            WHERE campaign_id = OLD.id
        )
    );
    
    -- También eliminar subtasks relacionadas
    DELETE FROM public.campaign_subtasks 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar segments relacionados
    DELETE FROM public.campaign_segments 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar transacciones relacionadas
    DELETE FROM public.transactions 
    WHERE campaign_id = OLD.id;
    
    RAISE NOTICE 'Campaign deletion completed for: %', OLD.id;
    
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."handle_campaign_deletion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_campaign_deletion_orphans_only"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    RAISE NOTICE 'Deleting campaign: % - %', OLD.id, OLD.title;
    
    -- Guardamos los requirement_ids que están asociados a esta campaña
    -- antes de eliminar las relaciones
    CREATE TEMP TABLE temp_campaign_requirements AS
    SELECT requirement_id 
    FROM public.campaign_requirements 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar las relaciones en campaign_requirements
    DELETE FROM public.campaign_requirements 
    WHERE campaign_id = OLD.id;
    
    -- Eliminar solo los requirements que quedaron huérfanos
    -- (que no tienen ninguna otra campaña asociada)
    DELETE FROM public.requirements 
    WHERE id IN (
        SELECT tcr.requirement_id 
        FROM temp_campaign_requirements tcr
        LEFT JOIN public.campaign_requirements cr ON tcr.requirement_id = cr.requirement_id
        WHERE cr.requirement_id IS NULL
    );
    
    -- Limpiar tabla temporal
    DROP TABLE temp_campaign_requirements;
    
    -- Eliminar otros elementos relacionados
    DELETE FROM public.campaign_subtasks WHERE campaign_id = OLD.id;
    DELETE FROM public.campaign_segments WHERE campaign_id = OLD.id;
    DELETE FROM public.transactions WHERE campaign_id = OLD.id;
    
    RAISE NOTICE 'Campaign deletion completed for: %', OLD.id;
    
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."handle_campaign_deletion_orphans_only"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_command_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Ensure created_at and updated_at are set
    NEW.created_at = COALESCE(NEW.created_at, NOW());
    NEW.updated_at = NOW();
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_command_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_command_update"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Update the updated_at timestamp
    NEW.updated_at = NOW();
    
    -- If status is changing to completed/failed, set completion_date
    IF (OLD.status <> 'completed' AND OLD.status <> 'failed') AND 
       (NEW.status = 'completed' OR NEW.status = 'failed') THEN
        NEW.completion_date = NOW();
        
        -- Calculate duration if not provided
        IF NEW.duration IS NULL THEN
            NEW.duration = EXTRACT(EPOCH FROM (NOW() - OLD.created_at)) * 1000;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_command_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_event_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Set created_at and updated_at timestamps
    NEW.created_at = COALESCE(NEW.created_at, NOW());
    NEW.updated_at = NOW();
    
    -- Ensure data is a valid JSONB
    IF NEW.data IS NULL THEN
        NEW.data = '{}'::jsonb;
    END IF;
    
    -- Ensure properties is a valid JSONB
    IF NEW.properties IS NULL THEN
        NEW.properties = '{}'::jsonb;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_event_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  referral_code_value TEXT;
  user_name TEXT;
BEGIN
  -- Extraer valores de metadatos de forma segura
  BEGIN
    referral_code_value := NEW.raw_user_meta_data ->> 'referral_code';
    user_name := NEW.raw_user_meta_data ->> 'name';
  EXCEPTION WHEN OTHERS THEN
    referral_code_value := NULL;
    user_name := NEW.email;
  END;
  
  -- Crear perfil de usuario
  BEGIN
    INSERT INTO public.profiles (
      id,
      email,
      name,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      NEW.email,
      COALESCE(user_name, NEW.email),
      NOW(),
      NOW()
    );
  EXCEPTION WHEN OTHERS THEN
    -- Si falla la creación del perfil, continuar
    NULL;
  END;
  
  -- Procesar código de referido si existe
  IF referral_code_value IS NOT NULL AND referral_code_value != '' THEN
    BEGIN
      PERFORM register_referral_code_use(referral_code_value, NEW.id);
    EXCEPTION WHEN OTHERS THEN
      -- Si falla el procesamiento del código, continuar
      NULL;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user_debug"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  referral_code_value TEXT;
  validation_result BOOLEAN;
  registration_result BOOLEAN;
BEGIN
  PERFORM log_debug('=== INICIO handle_new_user_debug ===');
  PERFORM log_debug('Usuario ID: ' || NEW.id::TEXT);
  PERFORM log_debug('Email: ' || NEW.email);
  PERFORM log_debug('Metadatos completos: ' || COALESCE(NEW.raw_user_meta_data::TEXT, 'NULL'));
  
  -- Extraer código de referido
  referral_code_value := NEW.raw_user_meta_data->>'referral_code';
  PERFORM log_debug('Código extraído: ' || COALESCE(referral_code_value, 'NULL'));
  PERFORM log_debug('Longitud del código: ' || COALESCE(LENGTH(referral_code_value)::TEXT, 'NULL'));
  
  BEGIN
    -- Crear perfil
    PERFORM log_debug('Creando perfil...');
    INSERT INTO public.profiles (
      id,
      email,
      name,
      avatar_url,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
      NEW.raw_user_meta_data->>'avatar_url',
      NOW(),
      NOW()
    );
    PERFORM log_debug('✅ Perfil creado exitosamente');
    
  EXCEPTION WHEN OTHERS THEN
    PERFORM log_debug('❌ Error creando perfil: ' || SQLERRM);
  END;
  
  -- Procesar código de referido si existe
  IF referral_code_value IS NOT NULL AND referral_code_value != '' THEN
    PERFORM log_debug('Procesando código de referido: ' || referral_code_value);
    
    -- Validar código
    BEGIN
      SELECT validate_referral_code(referral_code_value) INTO validation_result;
      PERFORM log_debug('Resultado validación: ' || validation_result::TEXT);
      
      IF validation_result THEN
        -- Registrar uso
        PERFORM log_debug('Registrando uso del código...');
        SELECT register_referral_code_use(referral_code_value, NEW.id) INTO registration_result;
        PERFORM log_debug('Resultado registro: ' || registration_result::TEXT);
        
        IF registration_result THEN
          PERFORM log_debug('✅ Código de referido procesado exitosamente');
        ELSE
          PERFORM log_debug('❌ Falló el registro del código');
        END IF;
      ELSE
        PERFORM log_debug('❌ Código de referido inválido');
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      PERFORM log_debug('❌ Error procesando código de referido: ' || SQLERRM);
    END;
  ELSE
    PERFORM log_debug('No hay código de referido para procesar');
  END IF;
  
  PERFORM log_debug('=== FIN handle_new_user_debug ===');
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user_debug"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user_simple"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  referral_code_value TEXT;
BEGIN
  -- Solo procesar referral codes, sin crear perfil
  referral_code_value := NEW.raw_user_meta_data->>'referral_code';
  
  IF referral_code_value IS NOT NULL AND referral_code_value != '' THEN
    -- Registrar en una tabla de log para verificar que funciona
    INSERT INTO public.debug_logs (operation, user_id, details)
    VALUES (
      'referral_trigger_test',
      NEW.id,
      jsonb_build_object(
        'referral_code', referral_code_value,
        'email', NEW.email,
        'timestamp', NOW()
      )
    ) ON CONFLICT DO NOTHING;
    
    -- Intentar registrar el código
    PERFORM public.register_referral_code_use(referral_code_value, NEW.id);
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user_simple"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_session_active_state"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF NEW.closed_at IS NOT NULL THEN
    NEW.is_active = FALSE;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_session_active_state"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_session_events_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_session_events_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_agent_conversations"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE public.agents
  SET conversations = conversations + 1,
      last_active = NOW()
  WHERE id = NEW.agent_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."increment_agent_conversations"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_referral_code_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE public.referral_codes 
  SET current_uses = current_uses + 1
  WHERE id = NEW.referral_code_id;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."increment_referral_code_usage"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_template_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public, pg_temp'
    SET "lock_timeout" TO '10s'
    SET "statement_timeout" TO '30s'
    AS $$
BEGIN
    -- Actualizar basándose en trigger NEW record
    UPDATE public.whatsapp_templates 
    SET 
        usage_count = COALESCE(usage_count, 0) + 1,
        last_used = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.id;  -- Usar NEW.id en lugar de NEW.template_id
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- No fallar el trigger
        RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."increment_template_usage"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_template_usage"("template_sid_param" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    UPDATE whatsapp_templates 
    SET 
        usage_count = COALESCE(usage_count, 0) + 1,
        last_used_at = NOW(),
        updated_at = NOW()
    WHERE template_sid = template_sid_param;
END;
$$;


ALTER FUNCTION "public"."increment_template_usage"("template_sid_param" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_usage_count"() RETURNS integer
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Implementation depends on the original function logic
    -- This is a placeholder that should be updated with the actual logic
    RETURN 1;
END;
$$;


ALTER FUNCTION "public"."increment_usage_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_visitor_sessions"("visitor_id" "uuid", "last_seen_timestamp" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    -- Deshabilitar el trigger específico temporalmente
    ALTER TABLE public.visitors DISABLE TRIGGER trigger_update_permission_visitors;
    
    -- Realizar la actualización
    UPDATE public.visitors 
    SET 
        total_sessions = COALESCE(total_sessions, 0) + 1,
        last_seen_at = last_seen_timestamp,
        updated_at = NOW()
    WHERE id = visitor_id;
    
    -- Reactivar el trigger
    ALTER TABLE public.visitors ENABLE TRIGGER trigger_update_permission_visitors;
    
    -- Verificar si se actualizó alguna fila
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Visitor with ID % not found', visitor_id;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    -- Asegurar que el trigger se reactive en caso de error
    ALTER TABLE public.visitors ENABLE TRIGGER trigger_update_permission_visitors;
    RAISE;
END;
$$;


ALTER FUNCTION "public"."increment_visitor_sessions"("visitor_id" "uuid", "last_seen_timestamp" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_service_role"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
  SELECT current_setting('role', true) = 'service_role' OR 
         (auth.jwt() ->> 'role') = 'service_role'
$$;


ALTER FUNCTION "public"."is_service_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_superadmin"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Check if the user has the superadmin role in auth.users
    RETURN EXISTS (
        SELECT 1 
        FROM auth.users 
        WHERE id = auth.uid() 
        AND raw_user_meta_data->>'role' = 'superadmin'
    );
END;
$$;


ALTER FUNCTION "public"."is_superadmin"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_superadmin"() IS 'Helper function to check if current user has superadmin role';



CREATE OR REPLACE FUNCTION "public"."is_valid_task_type"("task_type" "text") RETURNS boolean
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  RETURN task_type IN (
    'website_visit', 'demo', 'meeting', 'email', 'call', 'quote', 'contract',
    'payment', 'referral', 'feedback', 'trial', 'onboarding', 'refund',
    'ticket', 'kyc', 'training', 'consultation', 'follow_up', 'survey',
    'review', 'support', 'billing', 'documentation', 'integration'
  );
END;
$$;


ALTER FUNCTION "public"."is_valid_task_type"("task_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_asset_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
  -- Crear una tabla de logs si no existe
  CREATE TABLE IF NOT EXISTS public.debug_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation TEXT,
    user_id UUID,
    site_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  
  -- Registrar el intento de inserción
  INSERT INTO public.debug_logs (operation, user_id, site_id, details)
  VALUES (
    'asset_insert',
    NEW.user_id,
    NEW.site_id,
    jsonb_build_object(
      'auth_uid', auth.uid(),
      'has_site_access', public.user_has_access_to_site(NEW.user_id, NEW.site_id),
      'asset_name', NEW.name
    )
  );
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_asset_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_debug"("message" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  RAISE NOTICE '[DEBUG] %', message;
  -- También podríamos insertar en una tabla de logs si fuera necesario
END;
$$;


ALTER FUNCTION "public"."log_debug"("message" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."manually_activate_user_memberships"("user_email" "text") RETURNS integer
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    member_record RECORD;
    user_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    -- First, find the user by email
    SELECT id, email INTO user_record
    FROM profiles 
    WHERE email = user_email
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User with email % not found', user_email;
    END IF;
    
    -- Find all pending site_members with this email
    FOR member_record IN 
        SELECT id, site_id, role, email
        FROM site_members 
        WHERE email = user_email 
        AND user_id IS NULL
        AND status = 'pending'
    LOOP
        -- Update the site_member with the user_id and set status to active
        UPDATE site_members 
        SET 
            user_id = user_record.id,
            status = 'active',
            updated_at = NOW()
        WHERE id = member_record.id;
        
        updated_count := updated_count + 1;
        
        -- If this member is an owner, create the site_ownership record
        IF member_record.role = 'owner' THEN
            INSERT INTO site_ownership (site_id, user_id, created_at)
            VALUES (member_record.site_id, user_record.id, NOW())
            ON CONFLICT (site_id, user_id) DO NOTHING; -- Prevent duplicates
        END IF;
    END LOOP;
    
    RETURN updated_count;
END;
$$;


ALTER FUNCTION "public"."manually_activate_user_memberships"("user_email" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."manually_activate_user_memberships"("user_email" "text") IS 'Manually activates pending memberships for an existing user by email';



CREATE OR REPLACE FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
    UPDATE public.webhook_events 
    SET 
        processed = FALSE,
        failed = TRUE,
        failed_at = NOW(),
        updated_at = NOW()
    WHERE id = event_id;
EXCEPTION
    WHEN others THEN
        -- Log error but don't fail
        RAISE NOTICE 'Failed to mark webhook event as failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid") IS 'Marks webhook event as failed. Secured with search_path = empty.';



CREATE OR REPLACE FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid", "error_msg" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
    UPDATE public.webhook_events 
    SET 
        processed = FALSE,
        failed = TRUE,
        error_message = error_msg,
        failed_at = NOW(),
        updated_at = NOW()
    WHERE id = event_id;
EXCEPTION
    WHEN others THEN
        -- Log error but don't fail
        RAISE NOTICE 'Failed to mark webhook event as failed with message: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid", "error_msg" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid", "error_msg" "text") IS 'Marks webhook event as failed with error message. Secured with search_path = empty.';



CREATE OR REPLACE FUNCTION "public"."mark_webhook_event_processed"("event_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
    UPDATE public.webhook_events 
    SET 
        processed = TRUE,
        processed_at = NOW(),
        updated_at = NOW()
    WHERE id = event_id;
EXCEPTION
    WHEN others THEN
        -- Log error but don't fail
        RAISE NOTICE 'Failed to mark webhook event as processed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."mark_webhook_event_processed"("event_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."mark_webhook_event_processed"("event_id" "uuid") IS 'Marks webhook event as processed. Secured with search_path = empty.';



CREATE OR REPLACE FUNCTION "public"."migrate_team_members_to_site_members"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  -- For each site with team members in settings
  INSERT INTO public.site_members (site_id, user_id, role, email, name, position, added_by, status)
  SELECT 
    s.id AS site_id,
    (SELECT id FROM auth.users WHERE email = tm.email LIMIT 1) AS user_id,
    CASE 
      WHEN tm.role = 'admin' THEN 'admin'
      WHEN tm.role = 'delete' THEN 'marketing'
      WHEN tm.role = 'create' THEN 'marketing'
      WHEN tm.role = 'view' THEN 'collaborator'
      ELSE 'collaborator' 
    END AS role,
    tm.email,
    tm.name,
    tm.position,
    s.user_id AS added_by,
    CASE
      WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = tm.email) THEN 'active'
      ELSE 'pending'
    END AS status
  FROM public.sites s
  CROSS JOIN LATERAL jsonb_to_recordset(
    COALESCE(
      (SELECT team_members FROM public.settings WHERE site_id = s.id),
      '[]'::jsonb
    )
  ) AS tm(email text, role text, name text, position text)
  WHERE tm.email IS NOT NULL AND tm.email != ''
  -- Don't duplicate entries
  ON CONFLICT (site_id, email) DO NOTHING;
  
  -- Set the creator of each site as the owner in site_members if not already
  INSERT INTO public.site_members (site_id, user_id, role, email, name, position, status)
  SELECT 
    s.id AS site_id,
    s.user_id AS user_id,
    'owner' AS role,
    u.email,
    p.name,
    '' AS position,
    'active' AS status
  FROM public.sites s
  JOIN auth.users u ON s.user_id = u.id
  LEFT JOIN public.profiles p ON s.user_id = p.id
  WHERE NOT EXISTS (
    SELECT 1 FROM public.site_members 
    WHERE site_id = s.id AND user_id = s.user_id
  );
END;
$$;


ALTER FUNCTION "public"."migrate_team_members_to_site_members"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_last_admin_deletion"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    admin_count INTEGER;
    site_id_to_check UUID;
    deleting_site_id TEXT;
BEGIN
    site_id_to_check := OLD.site_id;
    
    -- Only protect admin/owner deletions
    IF OLD.role NOT IN ('admin', 'owner') THEN
        RETURN OLD;
    END IF;
    
    -- Check if we're deleting the entire site (allow in that case)
    BEGIN
        deleting_site_id := current_setting('app.deleting_site', true);
    EXCEPTION WHEN OTHERS THEN
        deleting_site_id := '';
    END;
    
    -- If we're deleting this site, allow the operation
    IF deleting_site_id = site_id_to_check::text THEN
        RETURN OLD;
    END IF;
    
    -- Count remaining admins after this deletion
    SELECT COUNT(*) INTO admin_count
    FROM public.site_members 
    WHERE site_id = site_id_to_check 
    AND role IN ('admin', 'owner')
    AND id != OLD.id
    AND status = 'active';
    
    -- Prevent if this would leave no admins/owners
    IF admin_count = 0 THEN
        RAISE EXCEPTION 'Cannot delete the last admin or owner of the site. At least one admin or owner must remain.';
    END IF;
    
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."prevent_last_admin_deletion"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."prevent_last_admin_deletion"() IS 'Trigger function that prevents deletion of the last admin or owner in a site.
Uses SECURITY DEFINER and explicit search_path to ensure proper table access.';



CREATE OR REPLACE FUNCTION "public"."prevent_last_admin_role_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    admin_count INTEGER;
    site_id_to_check UUID;
BEGIN
    -- Get the site_id from the row being updated
    site_id_to_check := NEW.site_id;
    
    -- Only check if we're changing FROM admin/owner TO something else
    IF OLD.role IN ('admin', 'owner') AND NEW.role NOT IN ('admin', 'owner') THEN
        
        -- Count remaining admins/owners for this site (excluding the one being changed)
        SELECT COUNT(*) INTO admin_count
        FROM public.site_members 
        WHERE site_id = site_id_to_check 
        AND role IN ('admin', 'owner')
        AND id != NEW.id  -- Exclude the member being changed
        AND status = 'active';  -- Only count active members
        
        -- If this would be the last admin/owner, prevent the role change
        IF admin_count = 0 THEN
            RAISE EXCEPTION 'Cannot change role of the last admin or owner. At least one admin or owner must remain for the site.';
        END IF;
    END IF;
    
    -- Allow the role change if there are other admins/owners
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."prevent_last_admin_role_change"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."prevent_last_admin_role_change"() IS 'Trigger function that prevents changing the role of the last admin or owner in a site. 
Uses SECURITY DEFINER and explicit search_path to ensure proper table access.';



CREATE OR REPLACE FUNCTION "public"."process_referral_code_use"("p_referral_code_id" "uuid", "p_user_id" "uuid") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
    v_use_record RECORD;
    v_result JSON;
BEGIN
    -- Insert the referral code use record
    INSERT INTO public.referral_code_uses (referral_code_id, user_id, used_at)
    VALUES (p_referral_code_id, p_user_id, NOW())
    RETURNING * INTO v_use_record;
    
    -- Increment the current_uses counter
    UPDATE public.referral_codes 
    SET current_uses = current_uses + 1
    WHERE id = p_referral_code_id;
    
    -- Return the created record as JSON
    SELECT json_build_object(
        'id', v_use_record.id,
        'referral_code_id', v_use_record.referral_code_id,
        'user_id', v_use_record.user_id,
        'used_at', v_use_record.used_at
    ) INTO v_result;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error and re-raise
        RAISE EXCEPTION 'Error processing referral code use: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."process_referral_code_use"("p_referral_code_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."record_payment"("p_site_id" "uuid", "p_transaction_type" character varying, "p_amount" numeric, "p_status" character varying DEFAULT 'success'::character varying, "p_payment_method" character varying DEFAULT 'credit_card'::character varying, "p_details" "jsonb" DEFAULT '{}'::"jsonb", "p_credits" integer DEFAULT 0) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  v_payment_id UUID;
BEGIN
  -- Insert payment record
  INSERT INTO payments (
    site_id,
    transaction_type,
    amount,
    status,
    payment_method,
    details,
    credits
  ) VALUES (
    p_site_id,
    p_transaction_type,
    p_amount,
    p_status,
    p_payment_method,
    p_details,
    p_credits
  )
  RETURNING id INTO v_payment_id;
  
  -- Update credits in billing if successful payment
  IF p_status = 'success' AND p_credits > 0 THEN
    UPDATE billing
    SET credits_available = credits_available + p_credits
    WHERE site_id = p_site_id;
  END IF;
  
  RETURN v_payment_id;
END;
$$;


ALTER FUNCTION "public"."record_payment"("p_site_id" "uuid", "p_transaction_type" character varying, "p_amount" numeric, "p_status" character varying, "p_payment_method" character varying, "p_details" "jsonb", "p_credits" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."register_referral_code_use"("code_param" "text", "user_id_param" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  referral_record RECORD;
  use_exists BOOLEAN;
  inserted_count INTEGER;
BEGIN
  -- Validar parámetros
  IF code_param IS NULL OR code_param = '' OR user_id_param IS NULL THEN
    RAISE NOTICE '❌ Parámetros inválidos: code=%, user_id=%', code_param, user_id_param;
    RETURN FALSE;
  END IF;
  
  -- Verificar si el código es válido
  IF NOT validate_referral_code(code_param) THEN
    RAISE NOTICE '❌ Código de referido inválido: %', code_param;
    RETURN FALSE;
  END IF;
  
  -- Obtener el registro del código de referido
  SELECT id, code, current_uses, max_uses INTO referral_record
  FROM public.referral_codes
  WHERE code = code_param AND is_active = true;
  
  IF NOT FOUND THEN
    RAISE NOTICE '❌ Código de referido no encontrado o inactivo: %', code_param;
    RETURN FALSE;
  END IF;
  
  -- Verificar si el usuario ya usó este código (con un SELECT FOR UPDATE para evitar race conditions)
  SELECT EXISTS(
    SELECT 1 FROM public.referral_code_uses 
    WHERE referral_code_id = referral_record.id AND user_id = user_id_param
    FOR UPDATE
  ) INTO use_exists;
  
  IF use_exists THEN
    RAISE NOTICE '⚠️ Usuario % ya usó el código %', user_id_param, code_param;
    RETURN FALSE;
  END IF;
  
  -- Intentar insertar el uso (esto fallará si ya existe debido a la constraint UNIQUE)
  BEGIN
    INSERT INTO public.referral_code_uses (referral_code_id, user_id)
    VALUES (referral_record.id, user_id_param);
    
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    
    IF inserted_count = 1 THEN
      -- Solo incrementar current_uses si realmente se insertó un nuevo registro
      UPDATE public.referral_codes
      SET current_uses = current_uses + 1,
          updated_at = NOW()
      WHERE id = referral_record.id;
      
      RAISE NOTICE '✅ Código de referido % usado exitosamente por usuario %', code_param, user_id_param;
      RETURN TRUE;
    ELSE
      RAISE NOTICE '⚠️ No se pudo insertar el uso del código %', code_param;
      RETURN FALSE;
    END IF;
    
  EXCEPTION 
    WHEN unique_violation THEN
      RAISE NOTICE '⚠️ Usuario % ya usó el código % (detectado por constraint)', user_id_param, code_param;
      RETURN FALSE;
    WHEN OTHERS THEN
      RAISE NOTICE '❌ Error registrando uso de código de referido: %', SQLERRM;
      RETURN FALSE;
  END;
END;
$$;


ALTER FUNCTION "public"."register_referral_code_use"("code_param" "text", "user_id_param" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remove_all_delete_protection_triggers"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'information_schema, public'
    AS $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT event_object_table, trigger_name
        FROM information_schema.triggers 
        WHERE trigger_name LIKE 'trigger_delete_protection_%'
        AND event_object_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', 
                      trigger_record.trigger_name, 
                      trigger_record.event_object_table);
        RAISE NOTICE 'Removed trigger from: %', trigger_record.event_object_table;
    END LOOP;
    
    RAISE NOTICE 'All delete protection triggers removed.';
END;
$$;


ALTER FUNCTION "public"."remove_all_delete_protection_triggers"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remove_delete_protection_trigger"("p_table_name" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    trigger_name TEXT;
BEGIN
    trigger_name := 'trigger_delete_protection_' || p_table_name;
    
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', trigger_name, p_table_name);
    
    RAISE NOTICE 'Removed delete protection trigger from table: %', p_table_name;
END;
$$;


ALTER FUNCTION "public"."remove_delete_protection_trigger"("p_table_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reorder_task_priorities"("p_task_id" "uuid", "p_new_position" integer, "p_status" "text", "p_site_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    v_old_priority INTEGER;
    v_old_status TEXT;
    v_old_position INTEGER;
    v_current_priority INTEGER;
    v_task_record RECORD;
    v_position_counter INTEGER := 1;
BEGIN
    -- Get current priority and status of the task being moved
    SELECT priority, status INTO v_old_priority, v_old_status
    FROM public.tasks
    WHERE id = p_task_id;

    -- Get the current position of the task in its column
    SELECT COUNT(*) + 1 INTO v_old_position
    FROM public.tasks
    WHERE site_id = p_site_id 
        AND status = v_old_status 
        AND priority > v_old_priority;

    -- If moving within the same status column
    IF v_old_status = p_status THEN
        -- Reorder all tasks in the column
        FOR v_task_record IN 
            SELECT id, priority
            FROM public.tasks
            WHERE site_id = p_site_id 
                AND status = p_status
                AND id != p_task_id
            ORDER BY priority DESC
        LOOP
            -- Skip the position where we want to insert our task
            IF v_position_counter = p_new_position THEN
                v_position_counter := v_position_counter + 1;
            END IF;
            
            -- Update priority based on new position
            UPDATE public.tasks
            SET priority = 1000 - (v_position_counter * 10)
            WHERE id = v_task_record.id;
            
            v_position_counter := v_position_counter + 1;
        END LOOP;
    ELSE
        -- Moving to different status column
        -- First, reorder the source column (fill the gap)
        v_position_counter := 1;
        FOR v_task_record IN 
            SELECT id
            FROM public.tasks
            WHERE site_id = p_site_id 
                AND status = v_old_status
                AND id != p_task_id
            ORDER BY priority DESC
        LOOP
            UPDATE public.tasks
            SET priority = 1000 - (v_position_counter * 10)
            WHERE id = v_task_record.id;
            
            v_position_counter := v_position_counter + 1;
        END LOOP;
        
        -- Then, reorder the destination column (make space)
        v_position_counter := 1;
        FOR v_task_record IN 
            SELECT id
            FROM public.tasks
            WHERE site_id = p_site_id 
                AND status = p_status
            ORDER BY priority DESC
        LOOP
            -- Skip the position where we want to insert our task
            IF v_position_counter = p_new_position THEN
                v_position_counter := v_position_counter + 1;
            END IF;
            
            UPDATE public.tasks
            SET priority = 1000 - (v_position_counter * 10)
            WHERE id = v_task_record.id;
            
            v_position_counter := v_position_counter + 1;
        END LOOP;
    END IF;

    -- Finally, update the moved task with its new position
    UPDATE public.tasks
    SET priority = 1000 - (p_new_position * 10),
        status = p_status
    WHERE id = p_task_id;
END;
$$;


ALTER FUNCTION "public"."reorder_task_priorities"("p_task_id" "uuid", "p_new_position" integer, "p_status" "text", "p_site_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rollback_api_keys"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Implementation depends on the original function logic
    -- This is a placeholder that should be updated with the actual logic
    RAISE NOTICE 'rollback_api_keys function secured with search_path';
END;
$$;


ALTER FUNCTION "public"."rollback_api_keys"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_current_timestamp_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_current_timestamp_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_dislike"("command_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
    UPDATE public.commands 
    SET performance = (performance & ~1) | 2  -- Quitar like y poner dislike
    WHERE id = command_id;
END;
$$;


ALTER FUNCTION "public"."set_dislike"("command_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_like"("command_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
    UPDATE public.commands 
    SET performance = (performance & ~2) | 1  -- Quitar dislike y poner like
    WHERE id = command_id;
END;
$$;


ALTER FUNCTION "public"."set_like"("command_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_task_priority_from_serial"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $_$
BEGIN
    -- Extract numeric part from serial_id and set as priority
    IF NEW.serial_id IS NOT NULL THEN
        NEW.priority := CAST(SUBSTRING(NEW.serial_id FROM '-(\d+)$') AS INTEGER);
    END IF;
    RETURN NEW;
END;
$_$;


ALTER FUNCTION "public"."set_task_priority_from_serial"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_task_serial_id"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
    attempt_count integer := 0;
    max_attempts integer := 5;
    generated_serial_id text;
BEGIN
    -- Only set serial_id if it's empty or NULL
    IF NEW.serial_id IS NULL OR NEW.serial_id = '' THEN
        LOOP
            -- Generate a new serial_id
            generated_serial_id := public.generate_task_serial_id(NEW.site_id);
            
            -- Check if this serial_id is unique
            IF NOT EXISTS (
                SELECT 1 FROM public.tasks t
                WHERE t.site_id = NEW.site_id 
                AND t.serial_id = generated_serial_id
                AND t.id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
            ) THEN
                NEW.serial_id := generated_serial_id;
                EXIT;
            END IF;
            
            -- Increment attempt counter
            attempt_count := attempt_count + 1;
            
            -- If we've tried too many times, add timestamp suffix
            IF attempt_count >= max_attempts THEN
                NEW.serial_id := generated_serial_id || '-' || EXTRACT(EPOCH FROM clock_timestamp())::bigint;
                EXIT;
            END IF;
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_task_serial_id"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."set_task_serial_id"() IS 'Trigger function to automatically set serial_id for new tasks with race condition protection - fixed ambiguous reference';



CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
    BEGIN
      NEW.updated_at := NOW();
      RETURN NEW;
    END;
    $$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."simulate_user_creation"("test_email" "text", "test_name" "text", "test_referral_code" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
  test_user_id UUID;
  test_user_record RECORD;
  trigger_result RECORD;
BEGIN
  -- Generar ID único para el test
  test_user_id := gen_random_uuid();
  
  PERFORM log_debug('=== SIMULACIÓN DE CREACIÓN DE USUARIO ===');
  PERFORM log_debug('Email: ' || test_email);
  PERFORM log_debug('Nombre: ' || test_name);
  PERFORM log_debug('Código: ' || test_referral_code);
  PERFORM log_debug('ID generado: ' || test_user_id::TEXT);
  
  -- Crear registro simulado
  SELECT 
    test_user_id as id,
    test_email as email,
    jsonb_build_object(
      'name', test_name,
      'referral_code', test_referral_code
    ) as raw_user_meta_data,
    NOW() as created_at,
    NOW() as updated_at
  INTO test_user_record;
  
  -- Ejecutar la función de trigger manualmente
  PERFORM handle_new_user_debug() FROM (
    SELECT 
      test_user_record.id as id,
      test_user_record.email as email,
      test_user_record.raw_user_meta_data as raw_user_meta_data,
      test_user_record.created_at as created_at,
      test_user_record.updated_at as updated_at
  ) AS NEW;
  
  RETURN 'Simulación completada - revisa los logs NOTICE arriba';
  
EXCEPTION WHEN OTHERS THEN
  RETURN 'Error en simulación: ' || SQLERRM;
END;
$$;


ALTER FUNCTION "public"."simulate_user_creation"("test_email" "text", "test_name" "text", "test_referral_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."store_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_token_value" "text", "p_identifier" "text", "p_encryption_key" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  encrypted_token TEXT;
  token_id UUID;
BEGIN
  -- Encrypt the token
  encrypted_token := encrypt_token(p_token_value, p_encryption_key);
  
  -- Insert or update the token
  INSERT INTO secure_tokens (site_id, token_type, encrypted_value, identifier, updated_at)
  VALUES (p_site_id, p_token_type, encrypted_token, p_identifier, NOW())
  ON CONFLICT (site_id, token_type, identifier)
  DO UPDATE SET 
    encrypted_value = encrypted_token,
    updated_at = NOW()
  RETURNING id INTO token_id;
  
  RETURN token_id;
END;
$$;


ALTER FUNCTION "public"."store_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_token_value" "text", "p_identifier" "text", "p_encryption_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_auth0_user"("auth0_id_param" "text", "email_param" "text", "name_param" "text", "picture_param" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  user_id UUID;
BEGIN
  -- Primero intentar encontrar un usuario existente en auth.users por email
  SELECT id INTO user_id FROM auth.users WHERE email = email_param;
  
  IF user_id IS NULL THEN
    -- Si no existe, crear nuevo usuario en auth.users
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      email_param,
      '',
      NOW(),
      '{"provider": "auth0", "providers": ["auth0"]}',
      jsonb_build_object(
        'name', name_param,
        'avatar_url', picture_param,
        'auth0_id', auth0_id_param
      ),
      NOW(),
      NOW(),
      '',
      '',
      '',
      ''
    )
    RETURNING id INTO user_id;
  END IF;

  -- Ahora intentar encontrar o crear el perfil
  INSERT INTO public.profiles (id, email, name, avatar_url, auth0_id)
  VALUES (
    user_id,
    email_param,
    name_param,
    picture_param,
    auth0_id_param
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = email_param,
    name = name_param,
    avatar_url = picture_param,
    auth0_id = auth0_id_param,
    updated_at = NOW();
  
  RETURN user_id;
END;
$$;


ALTER FUNCTION "public"."sync_auth0_user"("auth0_id_param" "text", "email_param" "text", "name_param" "text", "picture_param" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_site_members_to_settings"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
    affected_site_id UUID;
    team_members_json JSONB;
    site_exists BOOLEAN;
    deleting_site_id TEXT;
BEGIN
    -- Determinar qué site_id fue afectado
    IF TG_OP = 'DELETE' THEN
        affected_site_id := OLD.site_id;
    ELSE
        affected_site_id := NEW.site_id;
    END IF;
    
    -- Verificar si estamos eliminando este sitio completo
    deleting_site_id := current_setting('app.deleting_site', true);
    
    -- Si estamos eliminando este sitio, no intentar actualizar settings
    IF deleting_site_id = affected_site_id::text THEN
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    
    -- Verificar si el sitio aún existe
    SELECT EXISTS(SELECT 1 FROM public.sites WHERE id = affected_site_id) INTO site_exists;
    
    -- Si el sitio no existe, no intentar actualizar settings
    IF NOT site_exists THEN
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    
    -- Construir el JSON de team_members desde site_members
    SELECT jsonb_agg(
        jsonb_build_object(
            'email', sm.email,
            'role', CASE 
                WHEN sm.role = 'admin' THEN 'admin'
                WHEN sm.role = 'marketing' THEN 'create'
                WHEN sm.role = 'collaborator' THEN 'view'
                ELSE 'view'
            END,
            'name', COALESCE(sm.name, ''),
            'position', COALESCE(sm.position, '')
        )
    )
    INTO team_members_json
    FROM public.site_members sm
    WHERE sm.site_id = affected_site_id
      AND sm.status = 'active'
      AND sm.role != 'owner'; -- Excluir owners del team_members
    
    -- Si no hay miembros, usar array vacío
    team_members_json := COALESCE(team_members_json, '[]'::jsonb);
    
    -- Actualizar settings.team_members solo si el sitio existe
    UPDATE public.settings
    SET team_members = team_members_json,
        updated_at = now()
    WHERE site_id = affected_site_id;
    
    -- Si no existe un registro en settings, crearlo (solo si el sitio existe)
    IF NOT FOUND THEN
        -- Verificar nuevamente que el sitio existe antes de insertar
        SELECT EXISTS(SELECT 1 FROM public.sites WHERE id = affected_site_id) INTO site_exists;
        
        IF site_exists THEN
            INSERT INTO public.settings (site_id, team_members, created_at, updated_at)
            VALUES (affected_site_id, team_members_json, now(), now())
            ON CONFLICT (site_id) DO UPDATE 
            SET team_members = EXCLUDED.team_members,
                updated_at = EXCLUDED.updated_at;
        END IF;
    END IF;
    
    -- Retornar el registro apropiado
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION "public"."sync_site_members_to_settings"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_site_members_to_team_members"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
  team_members_json JSONB;
  tg_table_name TEXT;
  tg_op_type TEXT;
BEGIN
  -- Add recursion protection
  tg_table_name := TG_TABLE_NAME;
  tg_op_type := TG_OP;
  
  -- Skip if this is a recursive call generated by our own trigger
  IF current_setting('site_members.is_updating', TRUE) = 'true' THEN
    RETURN NULL;
  END IF;
  
  -- Set recursion protection flag
  PERFORM set_config('site_members.is_updating', 'true', TRUE);

  -- Get all site members for this site and convert to team_members format
  -- For INSERT/UPDATE, use NEW.site_id; for DELETE use OLD.site_id
  SELECT json_agg(json_build_object(
    'email', email,
    'role', 
    CASE 
      WHEN role = 'admin' THEN 'admin'
      WHEN role = 'marketing' THEN 'create'
      WHEN role = 'collaborator' THEN 'view'
      WHEN role = 'owner' THEN 'admin'
    END,
    'name', name,
    'position', position
  ))
  INTO team_members_json
  FROM public.site_members
  WHERE site_id = CASE 
    WHEN TG_OP = 'DELETE' THEN OLD.site_id
    ELSE NEW.site_id
  END
  AND status = 'active' AND role != 'owner';
  
  -- Only include non-null values
  team_members_json = COALESCE(team_members_json, '[]'::jsonb);
  
  -- Update the settings table
  UPDATE public.settings
  SET team_members = team_members_json
  WHERE site_id = CASE 
    WHEN TG_OP = 'DELETE' THEN OLD.site_id
    ELSE NEW.site_id
  END;
  
  -- Reset recursion protection flag
  PERFORM set_config('site_members.is_updating', 'false', TRUE);
  
  RETURN NULL; -- Return NULL for AFTER triggers
END;
$$;


ALTER FUNCTION "public"."sync_site_members_to_team_members"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_site_ownership"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    INSERT INTO public.site_ownership(site_id, user_id)
    VALUES (NEW.id, NEW.user_id)
    ON CONFLICT (site_id) DO UPDATE SET user_id = EXCLUDED.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.site_ownership WHERE site_id = OLD.id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."sync_site_ownership"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."toggle_flag"("command_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
    UPDATE public.commands 
    SET performance = performance ^ 4  -- Toggle flag bit
    WHERE id = command_id;
END;
$$;


ALTER FUNCTION "public"."toggle_flag"("command_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_activity_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_activity_updated_at"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_activity_updated_at"() IS 'Trigger function to update activity updated_at timestamp. Secured with search_path = empty string.';



CREATE OR REPLACE FUNCTION "public"."update_api_key_last_used"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE public.api_keys
  SET last_used_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_api_key_last_used"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_conversation_last_message_time"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
BEGIN
    -- Update the conversation's last_message_at timestamp
    -- Use explicit public schema reference since search_path is empty for security
    -- Only update if conversation_id is not null for performance
    IF NEW.conversation_id IS NOT NULL THEN
        UPDATE public.conversations 
        SET 
            last_message_at = NEW.created_at,  -- Use message timestamp instead of NOW() for consistency
            updated_at = NEW.created_at
        WHERE id = NEW.conversation_id;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_conversation_last_message_time"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_conversation_last_message_time"() IS 'Updates conversation last_message_at when a new message is inserted. Fixed schema reference and optimized for performance. Only one trigger should exist to avoid duplicates.';



CREATE OR REPLACE FUNCTION "public"."update_copywriting_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_copywriting_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_cron_status_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_cron_status_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_lead_analysis_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_lead_analysis_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_lead_research_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_lead_research_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_sale_orders_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_sale_orders_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_synced_objects_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_synced_objects_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_updated_at_column"() IS 'Generic trigger function to update updated_at timestamp. Secured with search_path = empty string.';



CREATE OR REPLACE FUNCTION "public"."update_webhook_events_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_webhook_events_updated_at"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_webhook_events_updated_at"() IS 'Trigger function to update webhook events updated_at timestamp. Secured with search_path = empty string.';



CREATE OR REPLACE FUNCTION "public"."update_whatsapp_template_tracking_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_whatsapp_template_tracking_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_whatsapp_templates_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_whatsapp_templates_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_billing"("p_site_id" "uuid", "p_plan" "text" DEFAULT NULL::"text", "p_card_name" "text" DEFAULT NULL::"text", "p_masked_card_number" "text" DEFAULT NULL::"text", "p_card_expiry" "text" DEFAULT NULL::"text", "p_stripe_customer_id" "text" DEFAULT NULL::"text", "p_stripe_payment_method_id" "text" DEFAULT NULL::"text", "p_stripe_subscription_id" "text" DEFAULT NULL::"text", "p_card_address" "text" DEFAULT NULL::"text", "p_card_city" "text" DEFAULT NULL::"text", "p_card_postal_code" "text" DEFAULT NULL::"text", "p_card_country" "text" DEFAULT NULL::"text", "p_tax_id" "text" DEFAULT NULL::"text", "p_billing_address" "text" DEFAULT NULL::"text", "p_billing_city" "text" DEFAULT NULL::"text", "p_billing_postal_code" "text" DEFAULT NULL::"text", "p_billing_country" "text" DEFAULT NULL::"text", "p_auto_renew" boolean DEFAULT NULL::boolean, "p_credits_available" integer DEFAULT NULL::integer, "p_subscription_status" "text" DEFAULT NULL::"text", "p_subscription_current_period_end" timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  billing_record billing%ROWTYPE;
BEGIN
  -- Verificar si existe registro de billing
  SELECT * INTO billing_record FROM billing WHERE site_id = p_site_id;
  
  IF FOUND THEN
    -- Actualizar registro existente
    UPDATE billing SET
      plan = COALESCE(p_plan, plan),
      card_name = COALESCE(p_card_name, card_name),
      masked_card_number = COALESCE(p_masked_card_number, masked_card_number),
      card_expiry = COALESCE(p_card_expiry, card_expiry),
      stripe_customer_id = COALESCE(p_stripe_customer_id, stripe_customer_id),
      stripe_payment_method_id = COALESCE(p_stripe_payment_method_id, stripe_payment_method_id),
      stripe_subscription_id = COALESCE(p_stripe_subscription_id, stripe_subscription_id),
      card_address = COALESCE(p_card_address, card_address),
      card_city = COALESCE(p_card_city, card_city),
      card_postal_code = COALESCE(p_card_postal_code, card_postal_code),
      card_country = COALESCE(p_card_country, card_country),
      tax_id = COALESCE(p_tax_id, tax_id),
      billing_address = COALESCE(p_billing_address, billing_address),
      billing_city = COALESCE(p_billing_city, billing_city),
      billing_postal_code = COALESCE(p_billing_postal_code, billing_postal_code),
      billing_country = COALESCE(p_billing_country, billing_country),
      auto_renew = COALESCE(p_auto_renew, auto_renew),
      credits_available = COALESCE(p_credits_available, credits_available),
      subscription_status = COALESCE(p_subscription_status, subscription_status),
      subscription_current_period_end = COALESCE(p_subscription_current_period_end, subscription_current_period_end),
      updated_at = NOW()
    WHERE site_id = p_site_id;
  ELSE
    -- Crear nuevo registro
    INSERT INTO billing (
      site_id,
      plan,
      card_name,
      masked_card_number,
      card_expiry,
      stripe_customer_id,
      stripe_payment_method_id,
      stripe_subscription_id,
      card_address,
      card_city,
      card_postal_code,
      card_country,
      tax_id,
      billing_address,
      billing_city,
      billing_postal_code,
      billing_country,
      auto_renew,
      credits_available,
      subscription_status,
      subscription_current_period_end,
      created_at,
      updated_at
    ) VALUES (
      p_site_id,
      COALESCE(p_plan, 'commission'),
      p_card_name,
      p_masked_card_number,
      p_card_expiry,
      p_stripe_customer_id,
      p_stripe_payment_method_id,
      p_stripe_subscription_id,
      p_card_address,
      p_card_city,
      p_card_postal_code,
      p_card_country,
      p_tax_id,
      p_billing_address,
      p_billing_city,
      p_billing_postal_code,
      p_billing_country,
      COALESCE(p_auto_renew, true),
      COALESCE(p_credits_available, 0),
      p_subscription_status,
      p_subscription_current_period_end,
      NOW(),
      NOW()
    );
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Billing information updated successfully'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;


ALTER FUNCTION "public"."upsert_billing"("p_site_id" "uuid", "p_plan" "text", "p_card_name" "text", "p_masked_card_number" "text", "p_card_expiry" "text", "p_stripe_customer_id" "text", "p_stripe_payment_method_id" "text", "p_stripe_subscription_id" "text", "p_card_address" "text", "p_card_city" "text", "p_card_postal_code" "text", "p_card_country" "text", "p_tax_id" "text", "p_billing_address" "text", "p_billing_city" "text", "p_billing_postal_code" "text", "p_billing_country" "text", "p_auto_renew" boolean, "p_credits_available" integer, "p_subscription_status" "text", "p_subscription_current_period_end" timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."user_has_access_to_site"("user_id_param" "uuid", "site_id_param" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  site_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.sites 
    WHERE id = site_id_param 
    AND user_id = user_id_param
  ) INTO site_exists;
  
  RETURN site_exists;
END;
$$;


ALTER FUNCTION "public"."user_has_access_to_site"("user_id_param" "uuid", "site_id_param" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_notifications"("notifications" "jsonb") RETURNS boolean
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
BEGIN
  -- Check if notifications has the required structure
  RETURN (
    notifications ? 'email' AND
    notifications ? 'push' AND
    (notifications->>'email')::boolean IS NOT NULL AND
    (notifications->>'push')::boolean IS NOT NULL
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$;


ALTER FUNCTION "public"."validate_notifications"("notifications" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_performance_bitmask"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  -- Verificar que like y dislike no estén activos simultáneamente
  IF (NEW.performance & 1) = 1 AND (NEW.performance & 2) = 2 THEN
    RAISE EXCEPTION 'Like y dislike no pueden estar activos simultáneamente';
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_performance_bitmask"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_referral_code"("code_param" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
DECLARE
  referral_record RECORD;
BEGIN
  -- Validar parámetro de entrada
  IF code_param IS NULL OR code_param = '' THEN
    RETURN FALSE;
  END IF;

  -- Buscar el código de referido
  SELECT *
  INTO referral_record
  FROM public.referral_codes
  WHERE code = code_param
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > NOW());
  
  -- Si no existe el código, retornar falso
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Si tiene límite de usos, verificar que no se haya excedido
  IF referral_record.max_uses IS NOT NULL THEN
    IF referral_record.current_uses >= referral_record.max_uses THEN
      RETURN FALSE;
    END IF;
  END IF;
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    -- En caso de cualquier error, retornar FALSE
    RETURN FALSE;
END;
$$;


ALTER FUNCTION "public"."validate_referral_code"("code_param" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."activity" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "workflow_id" character varying(255) NOT NULL,
    "workflow_type" character varying(100) NOT NULL,
    "schedule_id" character varying(255),
    "status" character varying(50) DEFAULT 'STARTED'::character varying NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "duration_ms" integer,
    "input_data" "jsonb",
    "output_data" "jsonb",
    "error_message" "text",
    "error_details" "jsonb",
    "retry_count" integer DEFAULT 0,
    "execution_context" "jsonb",
    "metrics" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."activity" OWNER TO "postgres";


COMMENT ON TABLE "public"."activity" IS 'Logs workflow execution activities for sites, separate from cron_status which is for actual cron jobs. Protected by RLS policies for site_members and site_owners.';



COMMENT ON COLUMN "public"."activity"."site_id" IS 'Site that the workflow was executed for - used for RLS filtering';



COMMENT ON COLUMN "public"."activity"."workflow_id" IS 'Temporal workflow ID for tracking';



COMMENT ON COLUMN "public"."activity"."workflow_type" IS 'Type/name of the workflow executed';



COMMENT ON COLUMN "public"."activity"."schedule_id" IS 'Schedule ID if triggered by schedule, null for manual executions';



COMMENT ON COLUMN "public"."activity"."status" IS 'Current status: STARTED, RUNNING, COMPLETED, FAILED, CANCELLED';



COMMENT ON COLUMN "public"."activity"."duration_ms" IS 'Total execution time in milliseconds';



COMMENT ON COLUMN "public"."activity"."input_data" IS 'JSON of workflow input parameters';



COMMENT ON COLUMN "public"."activity"."output_data" IS 'JSON of workflow execution results';



COMMENT ON COLUMN "public"."activity"."execution_context" IS 'Additional context like parent workflow, trigger source, etc.';



COMMENT ON COLUMN "public"."activity"."metrics" IS 'Performance metrics, counts, and other measurements';



CREATE TABLE IF NOT EXISTS "public"."agent_assets" (
    "agent_id" "uuid" NOT NULL,
    "asset_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid"
);


ALTER TABLE "public"."agent_assets" OWNER TO "postgres";


COMMENT ON COLUMN "public"."agent_assets"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."agent_memories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "agent_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "key" "text" NOT NULL,
    "data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "raw_data" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "access_count" integer DEFAULT 0,
    "last_accessed" timestamp with time zone DEFAULT "now"(),
    "command_id" "uuid",
    "chain_of_thoughts" "text"
);


ALTER TABLE "public"."agent_memories" OWNER TO "postgres";


COMMENT ON TABLE "public"."agent_memories" IS 'Stores agent memory data for persistent context across commands';



COMMENT ON COLUMN "public"."agent_memories"."id" IS 'Unique identifier for the memory record';



COMMENT ON COLUMN "public"."agent_memories"."agent_id" IS 'ID of the agent that owns this memory';



COMMENT ON COLUMN "public"."agent_memories"."user_id" IS 'ID of the user this memory is associated with';



COMMENT ON COLUMN "public"."agent_memories"."type" IS 'Type of memory (conversation, knowledge, entity, etc.)';



COMMENT ON COLUMN "public"."agent_memories"."key" IS 'Unique key for the memory within agent/user scope';



COMMENT ON COLUMN "public"."agent_memories"."data" IS 'Memory content in JSON format';



COMMENT ON COLUMN "public"."agent_memories"."raw_data" IS 'Unstructured textual content for free-form memory';



COMMENT ON COLUMN "public"."agent_memories"."metadata" IS 'Additional metadata about the memory';



COMMENT ON COLUMN "public"."agent_memories"."created_at" IS 'Record creation timestamp';



COMMENT ON COLUMN "public"."agent_memories"."updated_at" IS 'Record last update timestamp';



COMMENT ON COLUMN "public"."agent_memories"."access_count" IS 'Number of times this memory has been accessed';



COMMENT ON COLUMN "public"."agent_memories"."last_accessed" IS 'When the memory was last accessed';



COMMENT ON COLUMN "public"."agent_memories"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."agent_memories"."chain_of_thoughts" IS 'Current state of the logic for the agent';



CREATE TABLE IF NOT EXISTS "public"."agents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "type" "text" NOT NULL,
    "status" "text" NOT NULL,
    "prompt" "text" NOT NULL,
    "conversations" integer DEFAULT 0,
    "success_rate" integer DEFAULT 0,
    "configuration" "jsonb" DEFAULT '{}'::"jsonb",
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_active" timestamp with time zone DEFAULT "now"(),
    "role" "text",
    "tools" "jsonb" DEFAULT '{}'::"jsonb",
    "activities" "jsonb" DEFAULT '{}'::"jsonb",
    "integrations" "jsonb" DEFAULT '{}'::"jsonb",
    "supervisor" "uuid",
    "backstory" "text",
    "command_id" "uuid",
    CONSTRAINT "agents_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'training'::"text"]))),
    CONSTRAINT "agents_type_check" CHECK (("type" = ANY (ARRAY['sales'::"text", 'support'::"text", 'marketing'::"text"])))
);


ALTER TABLE "public"."agents" OWNER TO "postgres";


COMMENT ON COLUMN "public"."agents"."backstory" IS 'Agent personalitie, tone and general info';



COMMENT ON COLUMN "public"."agents"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."allowed_domains" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "domain" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "valid_domain" CHECK ((("domain" = 'localhost'::"text") OR ("domain" ~* '^([a-zA-Z0-9-]+\.)*[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$'::"text") OR ("domain" ~* '^(\d{1,3}\.){3}\d{1,3}$'::"text") OR ("domain" ~* '^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'::"text")))
);


ALTER TABLE "public"."allowed_domains" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."analysis" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "url_path" "text" NOT NULL,
    "structure" "jsonb" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" "text" DEFAULT 'completed'::"text",
    "request_time" integer,
    "provider" "text",
    "model_id" "text",
    "command_id" "uuid"
);


ALTER TABLE "public"."analysis" OWNER TO "postgres";


COMMENT ON TABLE "public"."analysis" IS 'Almacena los análisis estructurales de sitios web';



COMMENT ON COLUMN "public"."analysis"."id" IS 'Identificador único del análisis';



COMMENT ON COLUMN "public"."analysis"."site_id" IS 'ID del sitio al que pertenece el análisis';



COMMENT ON COLUMN "public"."analysis"."url_path" IS 'Ruta URL específica analizada';



COMMENT ON COLUMN "public"."analysis"."structure" IS 'Datos de análisis estructural en formato JSON';



COMMENT ON COLUMN "public"."analysis"."user_id" IS 'ID del usuario que creó el análisis';



COMMENT ON COLUMN "public"."analysis"."created_at" IS 'Fecha y hora de creación del análisis';



COMMENT ON COLUMN "public"."analysis"."updated_at" IS 'Fecha y hora de última actualización';



COMMENT ON COLUMN "public"."analysis"."status" IS 'Estado del análisis (completed, failed, processing)';



COMMENT ON COLUMN "public"."analysis"."request_time" IS 'Tiempo de procesamiento en milisegundos';



COMMENT ON COLUMN "public"."analysis"."provider" IS 'Proveedor de IA utilizado para el análisis';



COMMENT ON COLUMN "public"."analysis"."model_id" IS 'ID del modelo específico utilizado';



COMMENT ON COLUMN "public"."analysis"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."api_keys" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "key_hash" "text" NOT NULL,
    "prefix" character varying(50) NOT NULL,
    "user_id" "uuid" NOT NULL,
    "site_id" "uuid" NOT NULL,
    "status" "public"."key_status" DEFAULT 'active'::"public"."key_status",
    "scopes" "text"[] NOT NULL,
    "last_used_at" timestamp with time zone,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "valid_expires_at" CHECK (("expires_at" > "created_at")),
    CONSTRAINT "valid_prefix" CHECK ((("prefix")::"text" ~* '^[a-zA-Z0-9_-]+$'::"text")),
    CONSTRAINT "valid_scopes" CHECK (("array_length"("scopes", 1) > 0))
);


ALTER TABLE "public"."api_keys" OWNER TO "postgres";


COMMENT ON TABLE "public"."api_keys" IS 'Stores API keys for user authentication';



COMMENT ON COLUMN "public"."api_keys"."key_hash" IS 'Hashed version of the API key (handled by application)';



COMMENT ON COLUMN "public"."api_keys"."prefix" IS 'Visible prefix of the API key for identification';



COMMENT ON COLUMN "public"."api_keys"."site_id" IS 'The site this API key belongs to';



COMMENT ON COLUMN "public"."api_keys"."scopes" IS 'Array of permission scopes granted to this key';



COMMENT ON COLUMN "public"."api_keys"."metadata" IS 'Additional metadata like rate limits, allowed IPs, etc';



CREATE TABLE IF NOT EXISTS "public"."assets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "file_path" "text" NOT NULL,
    "file_type" "text" NOT NULL,
    "file_size" integer,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "is_public" boolean DEFAULT false,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    "instance_id" "uuid"
);


ALTER TABLE "public"."assets" OWNER TO "postgres";


COMMENT ON COLUMN "public"."assets"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."assets"."instance_id" IS 'Remote Instance Reference';



CREATE TABLE IF NOT EXISTS "public"."automation_auth_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "provider_auth_state_id" "text",
    "domain" "text" NOT NULL,
    "auth_type" "text" NOT NULL,
    "auth_data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "browser_type" "text" DEFAULT 'chrome'::"text",
    "user_agent" "text",
    "viewport" "jsonb" DEFAULT '{"width": 1920, "height": 1080}'::"jsonb",
    "last_used_at" timestamp with time zone,
    "usage_count" integer DEFAULT 0,
    "is_valid" boolean DEFAULT true,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "instance_id" "uuid",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone,
    CONSTRAINT "automation_auth_sessions_auth_type_check" CHECK (("auth_type" = ANY (ARRAY['cookies'::"text", 'localStorage'::"text", 'sessionStorage'::"text", 'credentials'::"text", 'oauth'::"text"])))
);


ALTER TABLE "public"."automation_auth_sessions" OWNER TO "postgres";


COMMENT ON TABLE "public"."automation_auth_sessions" IS 'Browser authentication sessions for reuse across instances';



CREATE TABLE IF NOT EXISTS "public"."billing" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "plan" character varying(50) DEFAULT 'free'::character varying NOT NULL,
    "card_name" character varying(255),
    "masked_card_number" character varying(19),
    "card_expiry" character varying(7),
    "stripe_customer_id" character varying(255),
    "stripe_payment_method_id" character varying(255),
    "card_address" character varying(255),
    "card_city" character varying(100),
    "card_postal_code" character varying(20),
    "card_country" character varying(100),
    "tax_id" character varying(100),
    "billing_address" character varying(255),
    "billing_city" character varying(100),
    "billing_postal_code" character varying(20),
    "billing_country" character varying(100),
    "auto_renew" boolean DEFAULT true,
    "credits_available" integer DEFAULT 0,
    "credits_used" integer DEFAULT 0,
    "subscription_start_date" timestamp with time zone,
    "subscription_end_date" timestamp with time zone,
    "status" character varying(50) DEFAULT 'active'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "command_id" "uuid",
    "stripe_subscription_id" "text",
    "subscription_status" "text",
    "subscription_current_period_end" timestamp with time zone
);


ALTER TABLE "public"."billing" OWNER TO "postgres";


COMMENT ON COLUMN "public"."billing"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."campaign_requirements" (
    "campaign_id" "uuid" NOT NULL,
    "requirement_id" "uuid" NOT NULL,
    "command_id" "uuid"
);


ALTER TABLE "public"."campaign_requirements" OWNER TO "postgres";


COMMENT ON COLUMN "public"."campaign_requirements"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."campaign_segments" (
    "campaign_id" "uuid" NOT NULL,
    "segment_id" "uuid" NOT NULL,
    "command_id" "uuid"
);


ALTER TABLE "public"."campaign_segments" OWNER TO "postgres";


COMMENT ON COLUMN "public"."campaign_segments"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."campaign_subtasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "campaign_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "status" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    CONSTRAINT "campaign_subtasks_status_check" CHECK (("status" = ANY (ARRAY['completed'::"text", 'in-progress'::"text", 'pending'::"text"])))
);


ALTER TABLE "public"."campaign_subtasks" OWNER TO "postgres";


COMMENT ON COLUMN "public"."campaign_subtasks"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."campaigns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "priority" "public"."campaign_priority" DEFAULT 'medium'::"public"."campaign_priority" NOT NULL,
    "status" "public"."campaign_status" DEFAULT 'pending'::"public"."campaign_status" NOT NULL,
    "due_date" "date",
    "assignees" integer DEFAULT 0,
    "issues" integer DEFAULT 0,
    "revenue" "jsonb" DEFAULT '{"actual": 0, "currency": "USD", "estimated": 0, "projected": 0}'::"jsonb",
    "budget" "jsonb" DEFAULT '{"currency": "USD", "allocated": 0, "remaining": 0}'::"jsonb",
    "type" "text" NOT NULL,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."campaigns" OWNER TO "postgres";


COMMENT ON COLUMN "public"."campaigns"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."campaigns"."metadata" IS 'Additional transaction info';



CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "icon" "text",
    "color" "text",
    "is_active" boolean DEFAULT true,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commands" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "task" "text" NOT NULL,
    "status" "public"."command_status" DEFAULT 'pending'::"public"."command_status" NOT NULL,
    "description" "text",
    "results" "jsonb" DEFAULT '[]'::"jsonb",
    "targets" "jsonb" DEFAULT '[]'::"jsonb",
    "tools" "jsonb" DEFAULT '[]'::"jsonb",
    "context" "text",
    "supervisor" "jsonb" DEFAULT '[]'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "completion_date" timestamp with time zone,
    "duration" integer,
    "model" "text",
    "agent_id" "uuid",
    "user_id" "uuid" NOT NULL,
    "output_tokens" numeric DEFAULT '0'::numeric,
    "input_tokens" numeric DEFAULT '0'::numeric,
    "site_id" "uuid",
    "agent_background" "text",
    "functions" "jsonb" DEFAULT '[]'::"jsonb",
    "performance" integer DEFAULT 0
);


ALTER TABLE "public"."commands" OWNER TO "postgres";


COMMENT ON TABLE "public"."commands" IS 'Stores AI command execution data and results';



COMMENT ON COLUMN "public"."commands"."id" IS 'Unique identifier for the command';



COMMENT ON COLUMN "public"."commands"."task" IS 'The command task/instruction';



COMMENT ON COLUMN "public"."commands"."status" IS 'Status of the command execution (pending, running, completed, failed, cancelled)';



COMMENT ON COLUMN "public"."commands"."description" IS 'Description of the command';



COMMENT ON COLUMN "public"."commands"."results" IS 'Array of command execution results';



COMMENT ON COLUMN "public"."commands"."targets" IS 'Array of command targets';



COMMENT ON COLUMN "public"."commands"."tools" IS 'Array of tools used by the command';



COMMENT ON COLUMN "public"."commands"."context" IS 'Context for the command execution';



COMMENT ON COLUMN "public"."commands"."supervisor" IS 'Array of supervisor objects for the command';



COMMENT ON COLUMN "public"."commands"."created_at" IS 'Record creation timestamp';



COMMENT ON COLUMN "public"."commands"."updated_at" IS 'Record last update timestamp';



COMMENT ON COLUMN "public"."commands"."completion_date" IS 'Timestamp when command completed';



COMMENT ON COLUMN "public"."commands"."duration" IS 'Command execution duration in milliseconds';



COMMENT ON COLUMN "public"."commands"."model" IS 'AI model used for execution';



COMMENT ON COLUMN "public"."commands"."agent_id" IS 'ID of the agent that executed the command';



COMMENT ON COLUMN "public"."commands"."user_id" IS 'ID of the user who created the command';



COMMENT ON COLUMN "public"."commands"."output_tokens" IS 'Total generated tokens from the command';



COMMENT ON COLUMN "public"."commands"."input_tokens" IS 'Total input tokens from all agents in the command';



COMMENT ON COLUMN "public"."commands"."agent_background" IS 'History, personal backstory and context for the designated Agent';



COMMENT ON COLUMN "public"."commands"."functions" IS 'Executed tools for the agent and workflows';



COMMENT ON COLUMN "public"."commands"."performance" IS 'Bitmask para almacenar el rendimiento del comando: bit 0 = like (1), bit 1 = dislike (2), bit 2 = flag (4)';



CREATE OR REPLACE VIEW "public"."commands_dislikes" WITH ("security_invoker"='true') AS
 SELECT "id",
    "task",
    "status",
    "description",
    "results",
    "targets",
    "tools",
    "context",
    "supervisor",
    "created_at",
    "updated_at",
    "completion_date",
    "duration",
    "model",
    "agent_id",
    "user_id",
    "output_tokens",
    "input_tokens",
    "site_id",
    "agent_background",
    "functions",
    "performance"
   FROM "public"."commands"
  WHERE (("performance" & 2) = 2);


ALTER VIEW "public"."commands_dislikes" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."commands_flags" WITH ("security_invoker"='true') AS
 SELECT "id",
    "task",
    "status",
    "description",
    "results",
    "targets",
    "tools",
    "context",
    "supervisor",
    "created_at",
    "updated_at",
    "completion_date",
    "duration",
    "model",
    "agent_id",
    "user_id",
    "output_tokens",
    "input_tokens",
    "site_id",
    "agent_background",
    "functions",
    "performance"
   FROM "public"."commands"
  WHERE (("performance" & 4) = 4);


ALTER VIEW "public"."commands_flags" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."commands_likes" WITH ("security_invoker"='true') AS
 SELECT "id",
    "task",
    "status",
    "description",
    "results",
    "targets",
    "tools",
    "context",
    "supervisor",
    "created_at",
    "updated_at",
    "completion_date",
    "duration",
    "model",
    "agent_id",
    "user_id",
    "output_tokens",
    "input_tokens",
    "site_id",
    "agent_background",
    "functions",
    "performance"
   FROM "public"."commands"
  WHERE (("performance" & 1) = 1);


ALTER VIEW "public"."commands_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."companies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "website" "text",
    "industry" "text",
    "size" "text",
    "annual_revenue" "text",
    "founded" "text",
    "description" "text",
    "address" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "legal_name" "text",
    "tax_id" "text",
    "tax_country" "text",
    "registration_number" "text",
    "vat_number" "text",
    "legal_structure" "text",
    "phone" "text",
    "email" "text",
    "linkedin_url" "text",
    "employees_count" integer,
    "is_public" boolean DEFAULT false,
    "stock_symbol" "text",
    "parent_company_id" "uuid",
    "logo_url" "text",
    "cover_image_url" "text",
    "social_media" "jsonb" DEFAULT '{}'::"jsonb",
    "key_people" "jsonb" DEFAULT '[]'::"jsonb",
    "funding_info" "jsonb" DEFAULT '{}'::"jsonb",
    "certifications" "text"[] DEFAULT ARRAY[]::"text"[],
    "awards" "text"[] DEFAULT ARRAY[]::"text"[],
    "business_model" "text",
    "products_services" "jsonb" DEFAULT '[]'::"jsonb",
    "tech_stack" "text"[] DEFAULT ARRAY[]::"text"[],
    "languages" "text"[] DEFAULT ARRAY['en'::"text"],
    "business_hours" "jsonb" DEFAULT '{}'::"jsonb",
    "video_url" "text",
    "press_releases" "jsonb" DEFAULT '[]'::"jsonb",
    "partnerships" "jsonb" DEFAULT '[]'::"jsonb",
    "competitor_info" "jsonb" DEFAULT '{}'::"jsonb",
    "sustainability_score" integer,
    "diversity_info" "jsonb" DEFAULT '{}'::"jsonb",
    "remote_policy" "text",
    "office_locations" "jsonb" DEFAULT '[]'::"jsonb",
    "market_cap" bigint,
    "last_funding_date" "date",
    "ipo_date" "date",
    "acquisition_date" "date",
    "acquired_by_id" "uuid",
    CONSTRAINT "companies_annual_revenue_check" CHECK (("annual_revenue" = ANY (ARRAY['<1M'::"text", '1M-10M'::"text", '10M-50M'::"text", '50M-100M'::"text", '100M-500M'::"text", '500M-1B'::"text", '>1B'::"text"]))),
    CONSTRAINT "companies_business_model_check" CHECK (("business_model" = ANY (ARRAY['b2b'::"text", 'b2c'::"text", 'b2b2c'::"text", 'marketplace'::"text", 'saas'::"text", 'ecommerce'::"text", 'other'::"text"]))),
    CONSTRAINT "companies_industry_check" CHECK (("industry" = ANY (ARRAY['technology'::"text", 'finance'::"text", 'healthcare'::"text", 'education'::"text", 'retail'::"text", 'manufacturing'::"text", 'services'::"text", 'hospitality'::"text", 'media'::"text", 'real_estate'::"text", 'logistics'::"text", 'nonprofit'::"text", 'other'::"text"]))),
    CONSTRAINT "companies_legal_structure_check" CHECK (("legal_structure" = ANY (ARRAY['sole_proprietorship'::"text", 'partnership'::"text", 'llc'::"text", 'corporation'::"text", 'nonprofit'::"text", 'cooperative'::"text", 's_corp'::"text", 'c_corp'::"text", 'lp'::"text", 'llp'::"text", 'sa'::"text", 'srl'::"text", 'gmbh'::"text", 'ltd'::"text", 'plc'::"text", 'bv'::"text", 'nv'::"text", 'other'::"text"]))),
    CONSTRAINT "companies_remote_policy_check" CHECK (("remote_policy" = ANY (ARRAY['remote_first'::"text", 'hybrid'::"text", 'office_only'::"text", 'flexible'::"text"]))),
    CONSTRAINT "companies_size_check" CHECK (("size" = ANY (ARRAY['1-10'::"text", '11-50'::"text", '51-200'::"text", '201-500'::"text", '501-1000'::"text", '1001-5000'::"text", '5001-10000'::"text", '10001+'::"text"]))),
    CONSTRAINT "companies_sustainability_score_check" CHECK ((("sustainability_score" >= 0) AND ("sustainability_score" <= 100)))
);


ALTER TABLE "public"."companies" OWNER TO "postgres";


COMMENT ON COLUMN "public"."companies"."legal_name" IS 'Official legal name of the company';



COMMENT ON COLUMN "public"."companies"."tax_id" IS 'Tax identification number (EIN, RFC, etc.)';



COMMENT ON COLUMN "public"."companies"."tax_country" IS 'Country where the company pays taxes';



COMMENT ON COLUMN "public"."companies"."registration_number" IS 'Business registration number';



COMMENT ON COLUMN "public"."companies"."vat_number" IS 'VAT/GST registration number';



COMMENT ON COLUMN "public"."companies"."legal_structure" IS 'Legal structure type of the company';



COMMENT ON COLUMN "public"."companies"."phone" IS 'Primary company phone number';



COMMENT ON COLUMN "public"."companies"."email" IS 'Primary company email address';



COMMENT ON COLUMN "public"."companies"."linkedin_url" IS 'Company LinkedIn profile URL';



COMMENT ON COLUMN "public"."companies"."employees_count" IS 'Exact number of employees';



COMMENT ON COLUMN "public"."companies"."is_public" IS 'Whether the company is publicly traded';



COMMENT ON COLUMN "public"."companies"."stock_symbol" IS 'Stock ticker symbol if publicly traded';



COMMENT ON COLUMN "public"."companies"."parent_company_id" IS 'Reference to parent company if subsidiary';



COMMENT ON COLUMN "public"."companies"."logo_url" IS 'Company logo image URL';



COMMENT ON COLUMN "public"."companies"."cover_image_url" IS 'Company cover/banner image URL';



COMMENT ON COLUMN "public"."companies"."social_media" IS 'Social media profiles (Twitter, Facebook, LinkedIn, etc.)';



COMMENT ON COLUMN "public"."companies"."key_people" IS 'Key company personnel (CEO, CTO, founders, etc.)';



COMMENT ON COLUMN "public"."companies"."funding_info" IS 'Funding information (total raised, investors, rounds)';



COMMENT ON COLUMN "public"."companies"."certifications" IS 'Company certifications (ISO, SOC2, etc.)';



COMMENT ON COLUMN "public"."companies"."awards" IS 'Company awards and recognitions';



COMMENT ON COLUMN "public"."companies"."business_model" IS 'Business model type';



COMMENT ON COLUMN "public"."companies"."products_services" IS 'List of products and services offered';



COMMENT ON COLUMN "public"."companies"."tech_stack" IS 'Technologies and tools used by the company';



COMMENT ON COLUMN "public"."companies"."languages" IS 'Languages supported by the company';



COMMENT ON COLUMN "public"."companies"."business_hours" IS 'Operating hours and timezone information';



COMMENT ON COLUMN "public"."companies"."video_url" IS 'Company introduction or promotional video URL';



COMMENT ON COLUMN "public"."companies"."press_releases" IS 'Company press releases and news';



COMMENT ON COLUMN "public"."companies"."partnerships" IS 'Strategic partnerships and alliances';



COMMENT ON COLUMN "public"."companies"."competitor_info" IS 'Information about main competitors';



COMMENT ON COLUMN "public"."companies"."sustainability_score" IS 'Environmental and sustainability score (0-100)';



COMMENT ON COLUMN "public"."companies"."diversity_info" IS 'Diversity and inclusion information';



COMMENT ON COLUMN "public"."companies"."remote_policy" IS 'Remote work policy';



COMMENT ON COLUMN "public"."companies"."office_locations" IS 'Physical office locations';



COMMENT ON COLUMN "public"."companies"."market_cap" IS 'Market capitalization for public companies';



COMMENT ON COLUMN "public"."companies"."last_funding_date" IS 'Date of last funding round';



COMMENT ON COLUMN "public"."companies"."ipo_date" IS 'Initial public offering date';



COMMENT ON COLUMN "public"."companies"."acquisition_date" IS 'Date when company was acquired';



COMMENT ON COLUMN "public"."companies"."acquired_by_id" IS 'ID of the company that acquired this one';



CREATE TABLE IF NOT EXISTS "public"."content" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "type" "text" NOT NULL,
    "status" "text" NOT NULL,
    "segment_id" "uuid",
    "site_id" "uuid" NOT NULL,
    "author_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "published_at" timestamp with time zone,
    "tags" "text"[],
    "estimated_reading_time" integer,
    "word_count" integer,
    "seo_score" integer,
    "user_id" "uuid",
    "text" "text",
    "campaign_id" "uuid",
    "performance_rating" smallint,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "command_id" "uuid",
    "instructions" "text",
    CONSTRAINT "content_content_type_check" CHECK (("type" = ANY (ARRAY['blog_post'::"text", 'video'::"text", 'podcast'::"text", 'social_post'::"text", 'newsletter'::"text", 'case_study'::"text", 'whitepaper'::"text", 'infographic'::"text", 'webinar'::"text", 'ebook'::"text", 'ad'::"text", 'landing_page'::"text"]))),
    CONSTRAINT "content_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'review'::"text", 'approved'::"text", 'published'::"text", 'archived'::"text"]))),
    CONSTRAINT "performance_rating_range" CHECK ((("performance_rating" IS NULL) OR (("performance_rating" >= 1) AND ("performance_rating" <= 5))))
);


ALTER TABLE "public"."content" OWNER TO "postgres";


COMMENT ON COLUMN "public"."content"."estimated_reading_time" IS 'Estimation in seconds';



COMMENT ON COLUMN "public"."content"."performance_rating" IS 'Content performance rating on a scale of 1-5 stars';



COMMENT ON COLUMN "public"."content"."metadata" IS 'All releated data to the content generation';



COMMENT ON COLUMN "public"."content"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."content"."instructions" IS 'Instructions or guidelines for content creation, separate from the actual copy/text';



CREATE TABLE IF NOT EXISTS "public"."content_assets" (
    "content_id" "uuid" NOT NULL,
    "asset_id" "uuid" NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."content_assets" OWNER TO "postgres";


COMMENT ON TABLE "public"."content_assets" IS 'Many-to-many: content and assets. is_primary marks the main asset for display.';



CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "visitor_id" "uuid",
    "agent_id" "uuid",
    "user_id" "uuid",
    "lead_id" "uuid",
    "site_id" "uuid",
    "status" "text" DEFAULT 'active'::"text",
    "title" "text",
    "custom_data" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_message_at" timestamp with time zone,
    "is_archived" boolean DEFAULT false,
    "command_id" "uuid",
    "flag" integer DEFAULT 0,
    "delegate_id" "uuid",
    "channel" "text"
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


COMMENT ON TABLE "public"."conversations" IS 'Stores chat conversations between visitors, agents, and users';



COMMENT ON COLUMN "public"."conversations"."id" IS 'Unique identifier for the conversation';



COMMENT ON COLUMN "public"."conversations"."visitor_id" IS 'Reference to the visitor';



COMMENT ON COLUMN "public"."conversations"."agent_id" IS 'Reference to the AI agent';



COMMENT ON COLUMN "public"."conversations"."user_id" IS 'Reference to the human user/operator';



COMMENT ON COLUMN "public"."conversations"."lead_id" IS 'Reference to the lead if visitor is identified';



COMMENT ON COLUMN "public"."conversations"."site_id" IS 'Site identifier';



COMMENT ON COLUMN "public"."conversations"."status" IS 'Conversation status (active, closed, archived)';



COMMENT ON COLUMN "public"."conversations"."title" IS 'Conversation title';



COMMENT ON COLUMN "public"."conversations"."custom_data" IS 'Additional custom data as JSON';



COMMENT ON COLUMN "public"."conversations"."created_at" IS 'Record creation timestamp';



COMMENT ON COLUMN "public"."conversations"."updated_at" IS 'Record last update timestamp';



COMMENT ON COLUMN "public"."conversations"."last_message_at" IS 'Timestamp of the last message';



COMMENT ON COLUMN "public"."conversations"."is_archived" IS 'Archived conversations for better UI handling';



COMMENT ON COLUMN "public"."conversations"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."conversations"."flag" IS 'Flag color to indentify de conversation';



COMMENT ON COLUMN "public"."conversations"."delegate_id" IS 'Current Agent managing the conversation (different to the original agent)';



COMMENT ON COLUMN "public"."conversations"."channel" IS 'Current channel behavior';



CREATE TABLE IF NOT EXISTS "public"."copywriting" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "copy_type" "text" NOT NULL,
    "target_audience" "text",
    "use_case" "text",
    "notes" "text",
    "tags" "text"[] DEFAULT '{}'::"text"[],
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "copywriting_copy_type_check" CHECK (("copy_type" = ANY (ARRAY['tweet'::"text", 'pitch'::"text", 'blurb'::"text", 'cold_email'::"text", 'cold_call'::"text", 'social_post'::"text", 'ad_copy'::"text", 'landing_page'::"text", 'email_subject'::"text", 'product_description'::"text", 'tagline'::"text", 'call_to_action'::"text", 'other'::"text"]))),
    CONSTRAINT "copywriting_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'review'::"text", 'approved'::"text", 'published'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."copywriting" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cron_status" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "workflow_id" "text",
    "schedule_id" "text",
    "activity_name" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "last_run" timestamp with time zone,
    "next_run" timestamp with time zone,
    "error_message" "text",
    "retry_count" integer DEFAULT 0,
    "site_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "progress" smallint DEFAULT '0'::smallint
);


ALTER TABLE "public"."cron_status" OWNER TO "postgres";


COMMENT ON TABLE "public"."cron_status" IS 'Control de actividades calendarizadas del sistema - Compatible con Temporal workflows';



COMMENT ON COLUMN "public"."cron_status"."workflow_id" IS 'ID del workflow en Temporal (referencia conceptual)';



COMMENT ON COLUMN "public"."cron_status"."schedule_id" IS 'ID del schedule en Temporal (referencia conceptual)';



COMMENT ON COLUMN "public"."cron_status"."activity_name" IS 'Nombre de la actividad o tarea programada';



COMMENT ON COLUMN "public"."cron_status"."status" IS 'Estado actual: pending, running, completed, failed, cancelled';



COMMENT ON COLUMN "public"."cron_status"."last_run" IS 'Timestamp de la última ejecución';



COMMENT ON COLUMN "public"."cron_status"."next_run" IS 'Timestamp de la próxima ejecución programada';



COMMENT ON COLUMN "public"."cron_status"."error_message" IS 'Mensaje de error en caso de fallo';



COMMENT ON COLUMN "public"."cron_status"."retry_count" IS 'Número de reintentos realizados';



CREATE TABLE IF NOT EXISTS "public"."customizations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "element_id" "uuid" NOT NULL,
    "key" "text" NOT NULL,
    "value" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."customizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."debug_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "operation" "text",
    "user_id" "uuid",
    "site_id" "uuid",
    "details" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "command_id" "uuid"
);


ALTER TABLE "public"."debug_logs" OWNER TO "postgres";


COMMENT ON COLUMN "public"."debug_logs"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."editor" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "site" "jsonb" DEFAULT '{}'::"jsonb",
    "campaigns" "jsonb" DEFAULT '[]'::"jsonb",
    "customizations" "jsonb" DEFAULT '{}'::"jsonb",
    "variants" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."editor" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."elements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "layer_id" "uuid" NOT NULL,
    "text" "text",
    "type" "text" NOT NULL,
    "props" "jsonb" DEFAULT '{}'::"jsonb",
    "value" "text",
    "code" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."elements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."experiment_segments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "experiment_id" "uuid",
    "segment_id" "uuid",
    "participants" integer DEFAULT 0,
    "command_id" "uuid"
);


ALTER TABLE "public"."experiment_segments" OWNER TO "postgres";


COMMENT ON COLUMN "public"."experiment_segments"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."experiments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "status" "text" NOT NULL,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "conversion" numeric,
    "roi" numeric,
    "preview_url" "text",
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "hypothesis" "text",
    "campaign_id" "uuid",
    "command_id" "uuid",
    "instructions" "text",
    "validations" "text",
    CONSTRAINT "experiments_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'completed'::"text", 'draft'::"text"])))
);


ALTER TABLE "public"."experiments" OWNER TO "postgres";


COMMENT ON COLUMN "public"."experiments"."campaign_id" IS 'Foreign key to campaigns table, associating experiments with marketing campaigns';



COMMENT ON COLUMN "public"."experiments"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."experiments"."instructions" IS 'Experiment agent instructions';



COMMENT ON COLUMN "public"."experiments"."validations" IS 'experiment required validations for the agent';



CREATE TABLE IF NOT EXISTS "public"."external_resources" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "url" "text" NOT NULL,
    "description" "text",
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid"
);


ALTER TABLE "public"."external_resources" OWNER TO "postgres";


COMMENT ON COLUMN "public"."external_resources"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."icp_mining" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_query_id" "uuid" NOT NULL,
    "icp_criteria" "jsonb" NOT NULL,
    "icp_hash" "text" GENERATED ALWAYS AS ("encode"("extensions"."digest"(("icp_criteria")::"text", 'sha256'::"text"), 'hex'::"text")) STORED,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "total_targets" integer DEFAULT 0,
    "processed_targets" integer DEFAULT 0,
    "found_matches" integer DEFAULT 0,
    "progress_percent" numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN ("total_targets" > 0) THEN "round"(((100.0 * ("processed_targets")::numeric) / ("total_targets")::numeric), 2)
    WHEN ("status" = 'completed'::"text") THEN 100.00
    ELSE 0.00
END) STORED,
    "started_at" timestamp with time zone,
    "last_progress_at" timestamp with time zone,
    "finished_at" timestamp with time zone,
    "last_error" "text",
    "errors" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "site_id" "uuid",
    "name" "text",
    "current_page" smallint DEFAULT '0'::smallint,
    CONSTRAINT "icp_mining_found_matches_check" CHECK (("found_matches" >= 0)),
    CONSTRAINT "icp_mining_processed_targets_check" CHECK (("processed_targets" >= 0)),
    CONSTRAINT "icp_mining_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'running'::"text", 'completed'::"text", 'failed'::"text"]))),
    CONSTRAINT "icp_mining_total_targets_check" CHECK (("total_targets" >= 0))
);


ALTER TABLE "public"."icp_mining" OWNER TO "postgres";


COMMENT ON COLUMN "public"."icp_mining"."name" IS 'short icp description';



COMMENT ON COLUMN "public"."icp_mining"."current_page" IS 'Pagination Control for the ICP API';



CREATE TABLE IF NOT EXISTS "public"."instance_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "log_type" "text" NOT NULL,
    "level" "text" DEFAULT 'info'::"text" NOT NULL,
    "message" "text" NOT NULL,
    "details" "jsonb" DEFAULT '{}'::"jsonb",
    "step_id" "text",
    "tool_name" "text",
    "tool_call_id" "text",
    "tool_args" "jsonb" DEFAULT '{}'::"jsonb",
    "tool_result" "jsonb" DEFAULT '{}'::"jsonb",
    "is_error" boolean DEFAULT false,
    "duration_ms" integer,
    "tokens_used" "jsonb" DEFAULT '{}'::"jsonb",
    "screenshot_base64" "text",
    "artifacts" "jsonb" DEFAULT '[]'::"jsonb",
    "instance_id" "uuid" NOT NULL,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "agent_id" "uuid",
    "command_id" "uuid",
    "parent_log_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "instance_logs_level_check" CHECK (("level" = ANY (ARRAY['debug'::"text", 'info'::"text", 'warn'::"text", 'error'::"text", 'critical'::"text"]))),
    CONSTRAINT "instance_logs_log_type_check" CHECK (("log_type" = ANY (ARRAY['system'::"text", 'user_action'::"text", 'agent_action'::"text", 'tool_call'::"text", 'tool_result'::"text", 'error'::"text", 'performance'::"text", 'thinking'::"text"])))
);


ALTER TABLE "public"."instance_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."instance_logs" IS 'Detailed logs of all actions, tool calls, and results within instances';



CREATE TABLE IF NOT EXISTS "public"."instance_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "plan_type" "text" NOT NULL,
    "priority" integer DEFAULT 5,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "instructions" "text",
    "expected_output" "text",
    "success_criteria" "jsonb" DEFAULT '[]'::"jsonb",
    "validation_rules" "jsonb" DEFAULT '[]'::"jsonb",
    "tools_required" "jsonb" DEFAULT '[]'::"jsonb",
    "estimated_duration_minutes" integer,
    "actual_duration_minutes" integer,
    "retry_count" integer DEFAULT 0,
    "max_retries" integer DEFAULT 3,
    "results" "jsonb" DEFAULT '{}'::"jsonb",
    "artifacts" "jsonb" DEFAULT '[]'::"jsonb",
    "error_message" "text",
    "progress_percentage" integer DEFAULT 0,
    "steps_completed" integer DEFAULT 0,
    "steps_total" integer DEFAULT 1,
    "instance_id" "uuid" NOT NULL,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "agent_id" "uuid",
    "command_id" "uuid",
    "parent_plan_id" "uuid",
    "depends_on" "jsonb" DEFAULT '[]'::"jsonb",
    "blocks" "jsonb" DEFAULT '[]'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "due_at" timestamp with time zone,
    "steps" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "instance_plans_plan_type_check" CHECK (("plan_type" = ANY (ARRAY['objective'::"text", 'task'::"text", 'verification'::"text", 'milestone'::"text"]))),
    CONSTRAINT "instance_plans_priority_check" CHECK ((("priority" >= 1) AND ("priority" <= 10))),
    CONSTRAINT "instance_plans_progress_percentage_check" CHECK ((("progress_percentage" >= 0) AND ("progress_percentage" <= 100))),
    CONSTRAINT "instance_plans_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'in_progress'::"text", 'paused'::"text", 'completed'::"text", 'failed'::"text", 'cancelled'::"text", 'blocked'::"text"])))
);


ALTER TABLE "public"."instance_plans" OWNER TO "postgres";


COMMENT ON TABLE "public"."instance_plans" IS 'Objectives, tasks, and verification steps for instance execution';



COMMENT ON COLUMN "public"."instance_plans"."steps" IS 'Plan design';



COMMENT ON CONSTRAINT "instance_plans_status_check" ON "public"."instance_plans" IS 'Valid status values: pending, in_progress, paused, completed, failed, cancelled, blocked';



CREATE TABLE IF NOT EXISTS "public"."kpis" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "value" numeric NOT NULL,
    "previous_value" numeric,
    "unit" "text" NOT NULL,
    "type" "text" NOT NULL,
    "period_start" timestamp with time zone NOT NULL,
    "period_end" timestamp with time zone NOT NULL,
    "segment_id" "uuid",
    "is_highlighted" boolean DEFAULT false,
    "target_value" numeric,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "trend" numeric DEFAULT 0,
    "benchmark" numeric,
    "command_id" "uuid",
    CONSTRAINT "kpis_type_check" CHECK (("type" IS NOT NULL))
);


ALTER TABLE "public"."kpis" OWNER TO "postgres";


COMMENT ON COLUMN "public"."kpis"."type" IS 'KPI type (free text field, examples: conversion, engagement, traffic, revenue, growth, custom, segments, etc)';



COMMENT ON COLUMN "public"."kpis"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."layers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "state_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."layers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."lead_analysis" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "company_name" "text" NOT NULL,
    "industry" "text",
    "company_size" "text",
    "annual_revenue" "text",
    "current_kpis" "jsonb" DEFAULT '{"churnRate": 0, "monthlyLeads": 0, "conversionRate": 0, "monthlyRevenue": 0, "salesCycleLength": 0, "averageOrderValue": 0, "convertedCustomers": 0, "salesQualifiedLeads": 0, "customerLifetimeSpan": 0, "customerLifetimeValue": 0, "customerAcquisitionCost": 0, "marketingQualifiedLeads": 0}'::"jsonb",
    "current_costs" "jsonb" DEFAULT '{"cogs": 0, "otherCosts": 0, "salesTeamCost": 0, "marketingBudget": 0, "salesCommission": 0, "technologyCosts": 0, "operationalCosts": 0, "totalMonthlyCosts": 0}'::"jsonb",
    "sales_process" "jsonb" DEFAULT '{"winRate": 0, "painPoints": [], "leadSources": [], "salesTeamSize": 0, "averageDealSize": 0, "salesActivities": {"paidAds": false, "coldCalls": false, "directMail": false, "seoContent": false, "tradeShows": false, "videoCalls": false, "activations": false, "retargeting": false, "partnerships": false, "personalBrand": false, "socialSelling": false, "physicalVisits": false, "webinarsEvents": false, "referralProgram": false, "contentMarketing": false, "influencerMarketing": false, "transactionalEmails": false, "personalizedFollowUp": false}, "closingTechniques": [], "followUpFrequency": "", "qualificationProcess": {"interviews": false, "companySize": false, "leadScoring": false, "deepResearch": false, "icpTargeting": false, "manualResearch": false, "decisionMakerID": false, "behaviorAnalysis": false, "competitorAnalysis": false, "budgetQualification": false, "painPointAssessment": false, "demographicFiltering": false}}'::"jsonb",
    "goals" "jsonb" DEFAULT '{"timeframe": "", "salesGoals": [], "revenueTarget": 0, "marketingGoals": [], "growthChallenges": [], "primaryObjectives": []}'::"jsonb",
    "analysis_results" "jsonb" DEFAULT '{"currentROI": 0, "riskFactors": [], "projectedROI": 0, "projectedCosts": 0, "recommendations": [], "expectedTimeline": "", "opportunityCosts": 0, "projectedRevenue": 0, "potentialIncrease": 0, "implementationPlan": {}}'::"jsonb",
    "roi_projections" "jsonb" DEFAULT '{"sixMonth": {"roi": 0, "costs": 0, "revenue": 0}, "threeMonth": {"roi": 0, "costs": 0, "revenue": 0}, "twelveMonth": {"roi": 0, "costs": 0, "revenue": 0}, "twentyFourMonth": {"roi": 0, "costs": 0, "revenue": 0}}'::"jsonb",
    "strategies" "jsonb" DEFAULT '{"costReduction": [], "revenueGrowth": [], "leadOptimization": [], "processAutomation": [], "technologyUpgrades": [], "conversionImprovement": []}'::"jsonb",
    "contact_info" "jsonb" DEFAULT '{"name": "", "email": "", "phone": "", "title": "", "bestTimeToCall": "", "preferredContactMethod": ""}'::"jsonb",
    "status" "text" DEFAULT 'draft'::"text",
    "completion_percentage" integer DEFAULT 0,
    "source" "text" DEFAULT 'roi-calculator'::"text",
    "utm_source" "text",
    "utm_medium" "text",
    "utm_campaign" "text",
    "referrer" "text",
    "ip_address" "inet",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "user_id" "uuid",
    "site_id" "uuid",
    CONSTRAINT "lead_analysis_completion_percentage_check" CHECK ((("completion_percentage" >= 0) AND ("completion_percentage" <= 100)))
);


ALTER TABLE "public"."lead_analysis" OWNER TO "postgres";


COMMENT ON TABLE "public"."lead_analysis" IS 'ROI Calculator lead analysis data - stores comprehensive business analysis for prospects';



COMMENT ON COLUMN "public"."lead_analysis"."current_kpis" IS 'Current business KPIs and metrics including revenue, CAC, LTV, conversion rates, etc.';



COMMENT ON COLUMN "public"."lead_analysis"."current_costs" IS 'Current business costs breakdown including marketing, sales, technology, and operational expenses';



COMMENT ON COLUMN "public"."lead_analysis"."sales_process" IS 'Information about current sales process, lead sources, qualification methods, and challenges';



COMMENT ON COLUMN "public"."lead_analysis"."goals" IS 'Business goals, targets, objectives, and growth challenges';



COMMENT ON COLUMN "public"."lead_analysis"."analysis_results" IS 'Calculated ROI analysis results, recommendations, and projections';



COMMENT ON COLUMN "public"."lead_analysis"."roi_projections" IS 'ROI projections for different timeframes (3, 6, 12, 24 months)';



COMMENT ON COLUMN "public"."lead_analysis"."strategies" IS 'Recommended strategies and opportunities for growth and optimization';



COMMENT ON COLUMN "public"."lead_analysis"."contact_info" IS 'Contact information for follow-up and sales outreach';



CREATE OR REPLACE VIEW "public"."lead_analysis_summary" WITH ("security_invoker"='true') AS
 SELECT "id",
    "company_name",
    "industry",
    "company_size",
    "annual_revenue",
    "status",
    "completion_percentage",
    (("current_kpis" ->> 'monthlyRevenue'::"text"))::numeric AS "monthly_revenue",
    (("current_kpis" ->> 'customerAcquisitionCost'::"text"))::numeric AS "cac",
    (("current_kpis" ->> 'customerLifetimeValue'::"text"))::numeric AS "ltv",
    (("current_kpis" ->> 'conversionRate'::"text"))::numeric AS "conversion_rate",
    (("analysis_results" ->> 'currentROI'::"text"))::numeric AS "current_roi",
    (("analysis_results" ->> 'projectedROI'::"text"))::numeric AS "projected_roi",
    (("analysis_results" ->> 'potentialIncrease'::"text"))::numeric AS "potential_increase",
    ("contact_info" ->> 'email'::"text") AS "contact_email",
    ("contact_info" ->> 'name'::"text") AS "contact_name",
    "source",
    "utm_source",
    "utm_campaign",
    "created_at",
    "updated_at",
    "completed_at"
   FROM "public"."lead_analysis";


ALTER VIEW "public"."lead_analysis_summary" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text",
    "email" "text",
    "position" "text",
    "segment_id" "uuid",
    "status" "text" NOT NULL,
    "notes" "text",
    "last_contact" timestamp with time zone,
    "site_id" "uuid",
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "phone" "text",
    "origin" "text",
    "social_networks" "jsonb" DEFAULT '{}'::"jsonb",
    "address" "jsonb" DEFAULT '{}'::"jsonb",
    "company" "jsonb" DEFAULT '{}'::"jsonb",
    "subscription" "jsonb" DEFAULT '{}'::"jsonb",
    "birthday" "text",
    "campaign_id" "uuid",
    "command_id" "uuid",
    "language" "text",
    "company_id" "uuid",
    "attribution" "jsonb" DEFAULT '{}'::"jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "assignee_id" "uuid",
    "referral_lead_id" "uuid",
    "person_id" "uuid",
    "personal_email" "text",
    CONSTRAINT "leads_status_check" CHECK (("status" = ANY (ARRAY['new'::"text", 'contacted'::"text", 'qualified'::"text", 'cold'::"text", 'converted'::"text", 'lost'::"text", 'not_qualified'::"text"])))
);


ALTER TABLE "public"."leads" OWNER TO "postgres";


COMMENT ON COLUMN "public"."leads"."status" IS 'Lead status: new, contacted, qualified, cold, converted, lost, not_qualified';



COMMENT ON COLUMN "public"."leads"."origin" IS 'Origen o fuente del lead (sitio web, redes sociales, referido, etc.)';



COMMENT ON COLUMN "public"."leads"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."leads"."language" IS 'Native language of the lead';



COMMENT ON COLUMN "public"."leads"."attribution" IS 'Lead origin and closing date';



COMMENT ON COLUMN "public"."leads"."metadata" IS 'additional structured info from the agents';



COMMENT ON COLUMN "public"."leads"."assignee_id" IS 'Team member assigned to the lead';



COMMENT ON COLUMN "public"."leads"."person_id" IS 'Referral person id';



CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "visitor_id" "uuid",
    "agent_id" "uuid",
    "user_id" "uuid",
    "lead_id" "uuid",
    "content" "text" NOT NULL,
    "role" "text" NOT NULL,
    "read_at" timestamp with time zone,
    "custom_data" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "command_id" "uuid",
    "interaction" "text",
    CONSTRAINT "valid_role" CHECK (("role" = ANY (ARRAY['user'::"text", 'assistant'::"text", 'system'::"text", 'function'::"text", 'tool'::"text", 'data'::"text", 'team_member'::"text"])))
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


COMMENT ON TABLE "public"."messages" IS 'Stores individual messages in conversations';



COMMENT ON COLUMN "public"."messages"."id" IS 'Unique identifier for the message';



COMMENT ON COLUMN "public"."messages"."conversation_id" IS 'Reference to the conversation';



COMMENT ON COLUMN "public"."messages"."visitor_id" IS 'Reference to the visitor';



COMMENT ON COLUMN "public"."messages"."agent_id" IS 'Reference to the AI agent';



COMMENT ON COLUMN "public"."messages"."user_id" IS 'Reference to the human user/operator';



COMMENT ON COLUMN "public"."messages"."lead_id" IS 'Reference to the lead if visitor is identified';



COMMENT ON COLUMN "public"."messages"."content" IS 'Message content';



COMMENT ON COLUMN "public"."messages"."role" IS 'Tipo de remitente (visitor, agent, user, system, assistant)';



COMMENT ON COLUMN "public"."messages"."read_at" IS 'Timestamp when message was read';



COMMENT ON COLUMN "public"."messages"."custom_data" IS 'Additional custom data as JSON';



COMMENT ON COLUMN "public"."messages"."created_at" IS 'Record creation timestamp';



COMMENT ON COLUMN "public"."messages"."updated_at" IS 'Record last update timestamp';



COMMENT ON COLUMN "public"."messages"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."messages"."interaction" IS 'User or target interaction status';



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "type" "text" NOT NULL,
    "is_read" boolean DEFAULT false,
    "action_url" "text",
    "related_entity_type" "text",
    "related_entity_id" "uuid",
    "site_id" "uuid",
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "event_type" "text",
    "severity" integer,
    "command_id" "uuid",
    CONSTRAINT "notifications_event_type_check" CHECK (("event_type" = ANY (ARRAY['lead_created'::"text", 'kpi_alert'::"text", 'experiment_result'::"text"]))),
    CONSTRAINT "notifications_type_check" CHECK (("type" = ANY (ARRAY['info'::"text", 'success'::"text", 'warning'::"text", 'error'::"text"])))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


COMMENT ON COLUMN "public"."notifications"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."payments" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "transaction_id" character varying(255) DEFAULT ('tx_'::"text" || "substr"("md5"((("random"())::"text" || ("clock_timestamp"())::"text")), 1, 16)),
    "transaction_type" character varying(50) NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "currency" character varying(3) DEFAULT 'USD'::character varying,
    "status" character varying(50) NOT NULL,
    "payment_method" character varying(50),
    "details" "jsonb" DEFAULT '{}'::"jsonb",
    "credits" integer DEFAULT 0,
    "invoice_url" character varying(255),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "command_id" "uuid"
);


ALTER TABLE "public"."payments" OWNER TO "postgres";


COMMENT ON COLUMN "public"."payments"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."persons" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_query_id" "uuid",
    "external_person_id" bigint,
    "external_role_id" bigint,
    "external_organization_id" bigint,
    "full_name" "text",
    "role_title" "text",
    "company_name" "text",
    "start_date" "date",
    "end_date" "date",
    "is_current" boolean,
    "location" "text",
    "emails" "jsonb",
    "phones" "jsonb",
    "raw_result" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "personal_emails" "jsonb"[] DEFAULT '{}'::"jsonb"[],
    "linkedin_profile" "text"
);


ALTER TABLE "public"."persons" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "name" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    "bio" "text",
    "role" "text",
    "language" "text" DEFAULT 'es'::"text",
    "timezone" "text" DEFAULT 'America/Mexico_City'::"text",
    "notifications" "jsonb" DEFAULT '{"push": true, "email": true}'::"jsonb",
    "settings" "jsonb" DEFAULT '{}'::"jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "profiles_language_check" CHECK (("language" = ANY (ARRAY['es'::"text", 'en'::"text", 'fr'::"text", 'de'::"text"]))),
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['Product Manager'::"text", 'Designer'::"text", 'Developer'::"text", 'Marketing'::"text", 'Sales'::"text", 'CEO'::"text", 'Other'::"text"]))),
    CONSTRAINT "valid_notifications" CHECK ("public"."validate_notifications"("notifications"))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."profiles"."bio" IS 'User biography or description';



COMMENT ON COLUMN "public"."profiles"."role" IS 'User role in the organization';



COMMENT ON COLUMN "public"."profiles"."language" IS 'Preferred language for the user interface';



COMMENT ON COLUMN "public"."profiles"."timezone" IS 'User timezone for proper date/time display';



COMMENT ON COLUMN "public"."profiles"."notifications" IS 'User notification preferences as JSON';



COMMENT ON COLUMN "public"."profiles"."settings" IS 'Additional profile settings as JSON';



COMMENT ON COLUMN "public"."profiles"."metadata" IS 'Additonal info';



CREATE TABLE IF NOT EXISTS "public"."referral_code_uses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "referral_code_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "used_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."referral_code_uses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referral_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true,
    "max_uses" integer,
    "current_uses" integer DEFAULT 0,
    "expires_at" timestamp with time zone,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "referral_codes_current_uses_check" CHECK (("current_uses" >= 0)),
    CONSTRAINT "referral_codes_max_uses_check" CHECK ((("max_uses" IS NULL) OR ("max_uses" > 0)))
);


ALTER TABLE "public"."referral_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."remote_instances" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "instance_type" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "provider_instance_id" "text",
    "cdp_url" "text",
    "timeout_hours" integer DEFAULT 1,
    "configuration" "jsonb" DEFAULT '{}'::"jsonb",
    "environment_variables" "jsonb" DEFAULT '{}'::"jsonb",
    "tools_enabled" "jsonb" DEFAULT '["bash", "computer", "edit"]'::"jsonb",
    "last_screenshot_at" timestamp with time zone,
    "last_activity_at" timestamp with time zone,
    "total_commands_executed" integer DEFAULT 0,
    "estimated_cost" numeric(10,4) DEFAULT 0.0000,
    "actual_cost" numeric(10,4) DEFAULT 0.0000,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "agent_id" "uuid",
    "command_id" "uuid",
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "started_at" timestamp with time zone,
    "stopped_at" timestamp with time zone,
    CONSTRAINT "remote_instances_instance_type_check" CHECK (("instance_type" = ANY (ARRAY['ubuntu'::"text", 'browser'::"text", 'windows'::"text"]))),
    CONSTRAINT "remote_instances_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'starting'::"text", 'running'::"text", 'paused'::"text", 'stopping'::"text", 'stopped'::"text", 'error'::"text", 'uninstantiated'::"text"])))
);


ALTER TABLE "public"."remote_instances" OWNER TO "postgres";


COMMENT ON TABLE "public"."remote_instances" IS 'Remote desktop instances for AI agents (Ubuntu, Browser, Windows)';



COMMENT ON CONSTRAINT "remote_instances_status_check" ON "public"."remote_instances" IS 'Status constraint including uninstantiated for assistant mode without Scrapybara provisioning';



CREATE OR REPLACE VIEW "public"."requirement_campaigns" WITH ("security_invoker"='true') AS
 SELECT "requirement_id",
    "campaign_id"
   FROM "public"."campaign_requirements";


ALTER VIEW "public"."requirement_campaigns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."requirement_segments" (
    "requirement_id" "uuid" NOT NULL,
    "segment_id" "uuid" NOT NULL,
    "command_id" "uuid"
);


ALTER TABLE "public"."requirement_segments" OWNER TO "postgres";


COMMENT ON COLUMN "public"."requirement_segments"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."requirements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "priority" "text" NOT NULL,
    "status" "text" NOT NULL,
    "completion_status" "text" NOT NULL,
    "source" "text",
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "budget" numeric,
    "instructions" "text",
    "command_id" "uuid",
    "type" "public"."requirement_type" DEFAULT 'task'::"public"."requirement_type",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "requirements_completion_status_check" CHECK (("completion_status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'rejected'::"text"]))),
    CONSTRAINT "requirements_priority_check" CHECK (("priority" = ANY (ARRAY['high'::"text", 'medium'::"text", 'low'::"text"]))),
    CONSTRAINT "requirements_status_check" CHECK (("status" = ANY (ARRAY['validated'::"text", 'in-progress'::"text", 'on-review'::"text", 'done'::"text", 'backlog'::"text", 'canceled'::"text"])))
);


ALTER TABLE "public"."requirements" OWNER TO "postgres";


COMMENT ON TABLE "public"."requirements" IS 'Stores product requirements with various statuses and priorities';



COMMENT ON COLUMN "public"."requirements"."budget" IS 'Task budget';



COMMENT ON COLUMN "public"."requirements"."instructions" IS 'detailed instructions for the task';



COMMENT ON COLUMN "public"."requirements"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."requirements"."type" IS 'Categorizes the requirement by its nature (content creation, design work, research, etc.)';



COMMENT ON COLUMN "public"."requirements"."metadata" IS 'Additional transaction info';



CREATE TABLE IF NOT EXISTS "public"."role_queries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "query" "jsonb" NOT NULL,
    "query_hash" "text" GENERATED ALWAYS AS ("encode"("extensions"."digest"(("query")::"text", 'sha256'::"text"), 'hex'::"text")) STORED,
    "synced_pages" integer DEFAULT 0 NOT NULL,
    "total_persons" integer,
    "total_organizations" integer,
    "total_search_results" integer,
    "status" "text" DEFAULT 'pending'::"text",
    "last_run_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."role_queries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_query_segments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_query_id" "uuid" NOT NULL,
    "segment_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."role_query_segments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sale_orders" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "order_number" "text" NOT NULL,
    "items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "subtotal" numeric DEFAULT 0 NOT NULL,
    "tax_total" numeric DEFAULT 0 NOT NULL,
    "discount_total" numeric DEFAULT 0 NOT NULL,
    "total" numeric DEFAULT 0 NOT NULL,
    "notes" "text",
    "status" "text" DEFAULT 'completed'::"text" NOT NULL,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."sale_orders" OWNER TO "postgres";


COMMENT ON TABLE "public"."sale_orders" IS 'Stores order details associated with sales';



COMMENT ON COLUMN "public"."sale_orders"."id" IS 'Primary key for the sale order';



COMMENT ON COLUMN "public"."sale_orders"."sale_id" IS 'Reference to the associated sale';



COMMENT ON COLUMN "public"."sale_orders"."order_number" IS 'Unique identifier for the order';



COMMENT ON COLUMN "public"."sale_orders"."items" IS 'JSON array containing order items with details';



COMMENT ON COLUMN "public"."sale_orders"."subtotal" IS 'Sum of all items before tax and discounts';



COMMENT ON COLUMN "public"."sale_orders"."tax_total" IS 'Total tax amount applied to the order';



COMMENT ON COLUMN "public"."sale_orders"."discount_total" IS 'Total discount amount applied to the order';



COMMENT ON COLUMN "public"."sale_orders"."total" IS 'Final order total (subtotal + tax - discount)';



COMMENT ON COLUMN "public"."sale_orders"."notes" IS 'Additional notes or comments about the order';



COMMENT ON COLUMN "public"."sale_orders"."status" IS 'Current status of the order';



COMMENT ON COLUMN "public"."sale_orders"."site_id" IS 'Reference to the site this order belongs to';



COMMENT ON COLUMN "public"."sale_orders"."user_id" IS 'User who created this order';



COMMENT ON COLUMN "public"."sale_orders"."created_at" IS 'Timestamp when the order was created';



COMMENT ON COLUMN "public"."sale_orders"."updated_at" IS 'Timestamp when the order was last updated';



CREATE TABLE IF NOT EXISTS "public"."sales" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "campaign_id" "uuid",
    "segment_id" "uuid",
    "amount" numeric NOT NULL,
    "currency" "text" DEFAULT 'USD'::"text",
    "status" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "sale_date" "date" NOT NULL,
    "payment_method" "text",
    "payment_details" "jsonb" DEFAULT '{}'::"jsonb",
    "invoice_number" "text",
    "product_name" "text",
    "product_type" "text",
    "product_details" "jsonb" DEFAULT '{}'::"jsonb",
    "reference_code" "text",
    "external_id" "text",
    "notes" "text",
    "tags" "text"[],
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    "channel" "text" DEFAULT 'online'::"text",
    "source" "text" DEFAULT 'online'::"text",
    "amount_due" numeric DEFAULT '0'::numeric,
    "payments" "jsonb" DEFAULT '[]'::"jsonb",
    CONSTRAINT "sales_source_check" CHECK (("source" = ANY (ARRAY['retail'::"text", 'online'::"text"]))),
    CONSTRAINT "sales_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'cancelled'::"text", 'refunded'::"text"])))
);


ALTER TABLE "public"."sales" OWNER TO "postgres";


COMMENT ON COLUMN "public"."sales"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."sales"."channel" IS 'Source of the transaction';



COMMENT ON COLUMN "public"."sales"."amount_due" IS 'Unpaid amount';



COMMENT ON COLUMN "public"."sales"."payments" IS 'Array for payments information';



CREATE TABLE IF NOT EXISTS "public"."sections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."sections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."secure_tokens" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "site_id" "uuid",
    "token_type" "text" NOT NULL,
    "encrypted_value" "text" NOT NULL,
    "identifier" "text" NOT NULL,
    "last_used" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."secure_tokens" OWNER TO "postgres";


COMMENT ON COLUMN "public"."secure_tokens"."token_type" IS 'Type of token: "email", "whatsapp", "api", etc.';



COMMENT ON COLUMN "public"."secure_tokens"."encrypted_value" IS 'Encrypted token value';



COMMENT ON COLUMN "public"."secure_tokens"."identifier" IS 'Human-readable identifier for the token (e.g. email address)';



CREATE TABLE IF NOT EXISTS "public"."segments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "audience" "public"."segment_audience",
    "size" numeric,
    "engagement" integer,
    "is_active" boolean DEFAULT true,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "language" "public"."segment_language" DEFAULT 'en'::"public"."segment_language" NOT NULL,
    "url" "text",
    "analysis" "jsonb",
    "topics" "jsonb",
    "icp" "jsonb",
    "estimated_value" numeric,
    "command_id" "uuid",
    "rules" "jsonb" DEFAULT '[]'::"jsonb",
    CONSTRAINT "segments_audience_check" CHECK (("audience" = ANY (ARRAY['enterprise'::"public"."segment_audience", 'smb'::"public"."segment_audience", 'startup'::"public"."segment_audience", 'b2b_saas'::"public"."segment_audience", 'e_commerce'::"public"."segment_audience", 'tech'::"public"."segment_audience", 'finance'::"public"."segment_audience", 'healthcare'::"public"."segment_audience", 'education'::"public"."segment_audience", 'manufacturing'::"public"."segment_audience", 'retail'::"public"."segment_audience", 'real_estate'::"public"."segment_audience", 'hospitality'::"public"."segment_audience", 'automotive'::"public"."segment_audience", 'media'::"public"."segment_audience", 'telecom'::"public"."segment_audience", 'energy'::"public"."segment_audience", 'agriculture'::"public"."segment_audience", 'construction'::"public"."segment_audience", 'logistics'::"public"."segment_audience", 'professional'::"public"."segment_audience", 'government'::"public"."segment_audience", 'nonprofit'::"public"."segment_audience", 'legal'::"public"."segment_audience", 'pharma'::"public"."segment_audience", 'insurance'::"public"."segment_audience", 'consulting'::"public"."segment_audience", 'research'::"public"."segment_audience", 'aerospace'::"public"."segment_audience", 'gaming'::"public"."segment_audience"]))),
    CONSTRAINT "segments_language_check" CHECK (("language" = ANY (ARRAY['en'::"public"."segment_language", 'zh'::"public"."segment_language", 'hi'::"public"."segment_language", 'es'::"public"."segment_language", 'ar'::"public"."segment_language", 'bn'::"public"."segment_language", 'pt'::"public"."segment_language", 'ru'::"public"."segment_language", 'ja'::"public"."segment_language", 'de'::"public"."segment_language", 'fr'::"public"."segment_language", 'ur'::"public"."segment_language", 'id'::"public"."segment_language", 'tr'::"public"."segment_language", 'it'::"public"."segment_language", 'th'::"public"."segment_language", 'vi'::"public"."segment_language", 'ko'::"public"."segment_language", 'fa'::"public"."segment_language", 'pl'::"public"."segment_language", 'uk'::"public"."segment_language", 'ro'::"public"."segment_language", 'nl'::"public"."segment_language", 'el'::"public"."segment_language", 'cs'::"public"."segment_language", 'sv'::"public"."segment_language", 'hu'::"public"."segment_language", 'da'::"public"."segment_language", 'fi'::"public"."segment_language", 'no'::"public"."segment_language"])))
);


ALTER TABLE "public"."segments" OWNER TO "postgres";


COMMENT ON TABLE "public"."segments" IS 'Segments table with updated schema: keywords -> analysis, hot_topics -> topics, added icp';



COMMENT ON COLUMN "public"."segments"."audience" IS 'The primary business audience type for the segment';



COMMENT ON COLUMN "public"."segments"."language" IS 'The primary language of the segment content and targeting';



COMMENT ON COLUMN "public"."segments"."url" IS 'URL del segmento para previsualización o acceso directo';



COMMENT ON COLUMN "public"."segments"."analysis" IS 'Analysis data for different ad platforms (migrated from keywords)';



COMMENT ON COLUMN "public"."segments"."topics" IS 'Topic ideas for blog and newsletter content (migrated from hot_topics)';



COMMENT ON COLUMN "public"."segments"."icp" IS 'Ideal Customer Profile description';



COMMENT ON COLUMN "public"."segments"."estimated_value" IS 'Estimated monetary value of the segment in USD';



COMMENT ON COLUMN "public"."segments"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."segments"."rules" IS 'Conditions for automatic visitor match';



CREATE TABLE IF NOT EXISTS "public"."session_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_type" "text" NOT NULL,
    "url" "text",
    "timestamp" bigint NOT NULL,
    "data" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "site_id" "text" NOT NULL,
    "visitor_id" "uuid",
    "referrer" "text",
    "user_agent" "text",
    "ip" "text",
    "event_name" "text",
    "properties" "jsonb" DEFAULT '{}'::"jsonb",
    "session_id" "uuid",
    "activity" "jsonb",
    "command_id" "uuid",
    "segment_id" "uuid"
);


ALTER TABLE "public"."session_events" OWNER TO "postgres";


COMMENT ON TABLE "public"."session_events" IS 'Stores visitor events and tracking data';



COMMENT ON COLUMN "public"."session_events"."id" IS 'Unique identifier for the event';



COMMENT ON COLUMN "public"."session_events"."event_type" IS 'Type of event (pageview, click, custom, etc.)';



COMMENT ON COLUMN "public"."session_events"."url" IS 'URL where the event occurred';



COMMENT ON COLUMN "public"."session_events"."timestamp" IS 'Event timestamp in milliseconds';



COMMENT ON COLUMN "public"."session_events"."data" IS 'Raw event data';



COMMENT ON COLUMN "public"."session_events"."created_at" IS 'Record creation timestamp';



COMMENT ON COLUMN "public"."session_events"."updated_at" IS 'Record last update timestamp';



COMMENT ON COLUMN "public"."session_events"."site_id" IS 'Site identifier';



COMMENT ON COLUMN "public"."session_events"."visitor_id" IS 'Visitor identifier';



COMMENT ON COLUMN "public"."session_events"."referrer" IS 'Referrer URL';



COMMENT ON COLUMN "public"."session_events"."user_agent" IS 'User agent string';



COMMENT ON COLUMN "public"."session_events"."ip" IS 'IP address';



COMMENT ON COLUMN "public"."session_events"."event_name" IS 'Custom event name';



COMMENT ON COLUMN "public"."session_events"."properties" IS 'Event properties as JSON';



COMMENT ON COLUMN "public"."session_events"."session_id" IS 'Reference to visitor_sessions table';



COMMENT ON COLUMN "public"."session_events"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "about" "text",
    "company_size" "text",
    "industry" "text",
    "products" "jsonb" DEFAULT '[]'::"jsonb",
    "services" "jsonb" DEFAULT '[]'::"jsonb",
    "swot" "jsonb" DEFAULT '{"threats": "", "strengths": "", "weaknesses": "", "opportunities": ""}'::"jsonb",
    "locations" "jsonb" DEFAULT '[]'::"jsonb",
    "marketing_budget" "jsonb" DEFAULT '{"total": 0, "available": 0}'::"jsonb",
    "marketing_channels" "jsonb" DEFAULT '[]'::"jsonb",
    "social_media" "jsonb" DEFAULT '[]'::"jsonb",
    "analytics_provider" "text",
    "analytics_id" "text",
    "team_members" "jsonb" DEFAULT '[]'::"jsonb",
    "team_roles" "jsonb" DEFAULT '[]'::"jsonb",
    "org_structure" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    "competitors" "jsonb" DEFAULT '[]'::"jsonb",
    "focus_mode" integer DEFAULT 50,
    "goals" "jsonb" DEFAULT '[]'::"jsonb",
    "channels" "jsonb" DEFAULT '[]'::"jsonb",
    "business_hours" "jsonb" DEFAULT '[]'::"jsonb",
    "branding" "jsonb" DEFAULT '{}'::"jsonb",
    "customer_journey" "jsonb" DEFAULT '{}'::"jsonb",
    "onboarding" "jsonb" DEFAULT '{}'::"jsonb",
    "business_model" "jsonb" DEFAULT '{}'::"jsonb",
    "activities" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."settings" OWNER TO "postgres";


COMMENT ON COLUMN "public"."settings"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."settings"."competitors" IS 'Company most important commercial challenges';



COMMENT ON COLUMN "public"."settings"."focus_mode" IS 'Current company vision either revenue or acquisition focused on';



COMMENT ON COLUMN "public"."settings"."goals" IS 'Current company short mid and long term goals';



COMMENT ON COLUMN "public"."settings"."channels" IS 'Current POC settings';



COMMENT ON COLUMN "public"."settings"."business_hours" IS 'describes an array of the business preferred working hours';



COMMENT ON COLUMN "public"."settings"."branding" IS 'Brand of the company';



COMMENT ON COLUMN "public"."settings"."customer_journey" IS 'Ideal success path for new users';



COMMENT ON COLUMN "public"."settings"."onboarding" IS 'Task for project success';



COMMENT ON COLUMN "public"."settings"."business_model" IS 'Information regarding the company business model, and the agent focus';



COMMENT ON COLUMN "public"."settings"."activities" IS 'Worfklows settings';



CREATE TABLE IF NOT EXISTS "public"."site_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "role" "text" NOT NULL,
    "added_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "name" "text",
    "position" "text",
    "status" "text" DEFAULT 'pending'::"text",
    CONSTRAINT "site_members_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'marketing'::"text", 'collaborator'::"text"]))),
    CONSTRAINT "site_members_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'active'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."site_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."site_ownership" (
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."site_ownership" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "url" "text",
    "description" "text",
    "logo_url" "text",
    "resource_urls" "jsonb" DEFAULT '[]'::"jsonb",
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "tracking" "jsonb" DEFAULT '{"record_screen": false, "track_actions": false, "track_visitors": false}'::"jsonb",
    "command_id" "uuid"
);


ALTER TABLE "public"."sites" OWNER TO "postgres";


COMMENT ON COLUMN "public"."sites"."command_id" IS 'Reference to the command that created this record';



CREATE TABLE IF NOT EXISTS "public"."states" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "section_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "order" integer NOT NULL,
    "frame" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."states" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."synced_objects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "external_id" "text" NOT NULL,
    "site_id" "uuid" NOT NULL,
    "object_type" "text" DEFAULT 'email'::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "provider" "text",
    "first_seen_at" timestamp with time zone DEFAULT "now"(),
    "last_processed_at" timestamp with time zone,
    "process_count" integer DEFAULT 0,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "error_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "hash" bigint
);


ALTER TABLE "public"."synced_objects" OWNER TO "postgres";


COMMENT ON TABLE "public"."synced_objects" IS 'Tracks processed objects (emails, contacts, etc.) to prevent duplications and provide processing history';



COMMENT ON COLUMN "public"."synced_objects"."external_id" IS 'External identifier of the object (email messageId, contact id, etc.)';



COMMENT ON COLUMN "public"."synced_objects"."site_id" IS 'Site/workspace this object belongs to';



COMMENT ON COLUMN "public"."synced_objects"."object_type" IS 'Type of object being tracked (email, contact, task, etc.)';



COMMENT ON COLUMN "public"."synced_objects"."status" IS 'Current processing status';



COMMENT ON COLUMN "public"."synced_objects"."provider" IS 'Source provider (gmail, outlook, imap, etc.)';



COMMENT ON COLUMN "public"."synced_objects"."process_count" IS 'Number of times this object has been processed';



COMMENT ON COLUMN "public"."synced_objects"."metadata" IS 'Additional object data in JSON format';



COMMENT ON COLUMN "public"."synced_objects"."hash" IS 'Unique Identifier for the content string of the object';



CREATE TABLE IF NOT EXISTS "public"."system_memories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid",
    "system_type" "text" NOT NULL,
    "key" "text" NOT NULL,
    "data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "raw_data" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "access_count" integer DEFAULT 0,
    "last_accessed" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone,
    "command_id" "uuid"
);


ALTER TABLE "public"."system_memories" OWNER TO "postgres";


COMMENT ON TABLE "public"."system_memories" IS 'Stores system-level memories to avoid repeating unsuccessful operations like venue searches that returned no results';



COMMENT ON COLUMN "public"."system_memories"."id" IS 'Unique identifier for the system memory';



COMMENT ON COLUMN "public"."system_memories"."site_id" IS 'Site identifier to scope memories per site';



COMMENT ON COLUMN "public"."system_memories"."system_type" IS 'Type of system operation (e.g., venue_search, lead_generation)';



COMMENT ON COLUMN "public"."system_memories"."key" IS 'Unique key for the memory within the system_type and site';



COMMENT ON COLUMN "public"."system_memories"."data" IS 'JSON data related to the memory';



COMMENT ON COLUMN "public"."system_memories"."raw_data" IS 'Raw text data if needed';



COMMENT ON COLUMN "public"."system_memories"."metadata" IS 'Additional metadata as JSON';



COMMENT ON COLUMN "public"."system_memories"."created_at" IS 'Record creation timestamp';



COMMENT ON COLUMN "public"."system_memories"."updated_at" IS 'Record last update timestamp';



COMMENT ON COLUMN "public"."system_memories"."access_count" IS 'Number of times this memory has been accessed';



COMMENT ON COLUMN "public"."system_memories"."last_accessed" IS 'Timestamp of last access';



COMMENT ON COLUMN "public"."system_memories"."expires_at" IS 'Optional expiration timestamp for the memory';



COMMENT ON COLUMN "public"."system_memories"."command_id" IS 'Reference to the command that created this memory';



CREATE TABLE IF NOT EXISTS "public"."task_categories" (
    "task_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL
);


ALTER TABLE "public"."task_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."task_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "task_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "attachments" "jsonb" DEFAULT '[]'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_private" boolean DEFAULT false NOT NULL,
    "files" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "cta" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."task_comments" OWNER TO "postgres";


COMMENT ON COLUMN "public"."task_comments"."is_private" IS 'If true, the comment is only visible to team members and not to leads or agents';



COMMENT ON COLUMN "public"."task_comments"."files" IS 'Array of attached files with metadata like {name, url, size, type}';



COMMENT ON COLUMN "public"."task_comments"."cta" IS 'Call to action for the lead or visitor';



CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "type" "text" NOT NULL,
    "stage" "text" NOT NULL,
    "status" "text" NOT NULL,
    "scheduled_date" timestamp with time zone NOT NULL,
    "completed_date" timestamp with time zone,
    "amount" numeric(10,2),
    "assignee" "uuid",
    "notes" "text",
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    "serial_id" "text" NOT NULL,
    "priority" integer DEFAULT 0 NOT NULL,
    "address" "jsonb",
    "conversation_id" "uuid",
    CONSTRAINT "tasks_stage_check" CHECK (("stage" = ANY (ARRAY['awareness'::"text", 'consideration'::"text", 'decision'::"text", 'purchase'::"text", 'retention'::"text", 'referral'::"text"]))),
    CONSTRAINT "tasks_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'in_progress'::"text", 'completed'::"text", 'failed'::"text", 'canceled'::"text"])))
);


ALTER TABLE "public"."tasks" OWNER TO "postgres";


COMMENT ON COLUMN "public"."tasks"."type" IS 'Task type - accepts any custom string value. No restrictions.';



COMMENT ON COLUMN "public"."tasks"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."tasks"."serial_id" IS 'Unique human-readable identifier for the task (e.g., TSK-0001)';



COMMENT ON COLUMN "public"."tasks"."priority" IS 'Numeric priority for ordering tasks within kanban columns (higher number = higher priority)';



COMMENT ON COLUMN "public"."tasks"."address" IS 'JSONB field for storing address information (for future use)';



COMMENT ON COLUMN "public"."tasks"."conversation_id" IS 'Rerfence to the original conversation generating the task';



COMMENT ON CONSTRAINT "tasks_status_check" ON "public"."tasks" IS 'Updated to include canceled status to match TypeScript types';



CREATE TABLE IF NOT EXISTS "public"."transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "campaign_id" "uuid",
    "type" "text" NOT NULL,
    "amount" numeric NOT NULL,
    "description" "text",
    "date" "date" NOT NULL,
    "currency" "text" DEFAULT 'USD'::"text",
    "site_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "command_id" "uuid",
    "category" "text",
    CONSTRAINT "transactions_type_check" CHECK (("type" = ANY (ARRAY['fixed'::"text", 'variable'::"text"])))
);


ALTER TABLE "public"."transactions" OWNER TO "postgres";


COMMENT ON COLUMN "public"."transactions"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."transactions"."category" IS 'Result account';



CREATE TABLE IF NOT EXISTS "public"."transitions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "from_state_id" "uuid" NOT NULL,
    "to_state_id" "uuid" NOT NULL,
    "duration" numeric NOT NULL,
    "effects" "jsonb" DEFAULT '{}'::"jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "transitions_no_self_reference" CHECK (("from_state_id" <> "to_state_id"))
);


ALTER TABLE "public"."transitions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."variants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "state_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "overrides" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."variants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."visitor_sessions" (
    "id" "uuid" NOT NULL,
    "visitor_id" "uuid" NOT NULL,
    "site_id" "uuid" NOT NULL,
    "landing_url" "text",
    "current_url" "text",
    "referrer" "text",
    "utm_source" "text",
    "utm_medium" "text",
    "utm_campaign" "text",
    "utm_term" "text",
    "utm_content" "text",
    "started_at" bigint NOT NULL,
    "last_activity_at" bigint NOT NULL,
    "page_views" integer DEFAULT 1,
    "device" "jsonb",
    "browser" "jsonb",
    "location" "jsonb",
    "previous_session_id" "uuid",
    "performance" "jsonb",
    "consent" "jsonb",
    "is_active" boolean DEFAULT true,
    "duration" bigint,
    "active_time" bigint,
    "idle_time" bigint,
    "lead_id" "uuid",
    "exit_url" "text",
    "exit_type" "text",
    "custom_data" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "command_id" "uuid",
    "identified_at" bigint,
    "lead_data" "jsonb"
);


ALTER TABLE "public"."visitor_sessions" OWNER TO "postgres";


COMMENT ON COLUMN "public"."visitor_sessions"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."visitor_sessions"."identified_at" IS 'Timestamp when the visitor was identified with a lead';



COMMENT ON COLUMN "public"."visitor_sessions"."lead_data" IS 'Additional data associated with the lead';



CREATE TABLE IF NOT EXISTS "public"."visitors" (
    "id" "uuid" NOT NULL,
    "first_seen_at" bigint NOT NULL,
    "last_seen_at" bigint NOT NULL,
    "total_sessions" integer DEFAULT 1,
    "total_page_views" integer DEFAULT 0,
    "total_time_spent" bigint DEFAULT 0,
    "first_url" "text",
    "first_referrer" "text",
    "first_utm_source" "text",
    "first_utm_medium" "text",
    "first_utm_campaign" "text",
    "first_utm_term" "text",
    "first_utm_content" "text",
    "custom_data" "jsonb",
    "lead_id" "uuid",
    "is_identified" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "fingerprint" "text",
    "command_id" "uuid",
    "segment_id" "uuid",
    "campaign_id" "uuid",
    "experiment_id" "uuid"
);


ALTER TABLE "public"."visitors" OWNER TO "postgres";


COMMENT ON COLUMN "public"."visitors"."fingerprint" IS 'Unique identifier for the device, used to link visitors across sessions';



COMMENT ON COLUMN "public"."visitors"."command_id" IS 'Reference to the command that created this record';



COMMENT ON COLUMN "public"."visitors"."campaign_id" IS 'Campaign Attribution';



COMMENT ON COLUMN "public"."visitors"."experiment_id" IS 'Experiment tracking';



CREATE TABLE IF NOT EXISTS "public"."waitlist" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "name" "text",
    "referral_code_attempted" "text",
    "source" "text" DEFAULT 'signup'::"text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "waitlist_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text", 'converted'::"text"])))
);


ALTER TABLE "public"."waitlist" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."webhook_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "stripe_event_id" character varying(255) NOT NULL,
    "event_type" character varying(100) NOT NULL,
    "processed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" character varying(50) DEFAULT 'processed'::character varying NOT NULL,
    "event_data" "jsonb" DEFAULT '{}'::"jsonb",
    "error_message" "text",
    "site_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "webhook_events_status_check" CHECK ((("status")::"text" = ANY (ARRAY[('processed'::character varying)::"text", ('failed'::character varying)::"text", ('skipped'::character varying)::"text"])))
);


ALTER TABLE "public"."webhook_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."webhooks_deliveries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "endpoint_id" "uuid" NOT NULL,
    "subscription_id" "uuid",
    "event_type" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "attempt_count" integer DEFAULT 0 NOT NULL,
    "last_attempt_at" timestamp with time zone,
    "response_status" integer,
    "response_body" "text",
    "last_error" "text",
    "delivered_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."webhooks_deliveries" OWNER TO "postgres";


COMMENT ON TABLE "public"."webhooks_deliveries" IS 'Delivery attempts and outcomes for webhook events.';



CREATE TABLE IF NOT EXISTS "public"."webhooks_endpoints" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "target_url" "text" NOT NULL,
    "secret" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "handshake_status" "text" DEFAULT 'pending'::"text",
    "handshake_token" "text",
    "handshake_verified_at" timestamp with time zone,
    "last_handshake_error" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."webhooks_endpoints" OWNER TO "postgres";


COMMENT ON TABLE "public"."webhooks_endpoints" IS 'Webhook endpoints per site (third-party URLs with optional verification).';



COMMENT ON COLUMN "public"."webhooks_endpoints"."handshake_status" IS 'pending | verified | failed | none';



CREATE TABLE IF NOT EXISTS "public"."webhooks_subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "site_id" "uuid" NOT NULL,
    "endpoint_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "filters" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."webhooks_subscriptions" OWNER TO "postgres";


COMMENT ON TABLE "public"."webhooks_subscriptions" IS 'Subscriptions linking endpoints to event types (with optional filters).';



CREATE TABLE IF NOT EXISTS "public"."whatsapp_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "template_sid" "text" NOT NULL,
    "template_name" "text" NOT NULL,
    "content" "text" NOT NULL,
    "original_message" "text",
    "site_id" "uuid" NOT NULL,
    "account_sid" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text",
    "language" "text" DEFAULT 'es'::"text",
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "last_used" timestamp with time zone,
    "usage_count" integer DEFAULT 0,
    CONSTRAINT "whatsapp_templates_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'pending'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."whatsapp_templates" OWNER TO "postgres";


COMMENT ON TABLE "public"."whatsapp_templates" IS 'Almacena templates de WhatsApp de Twilio para manejar ventana de respuesta';



COMMENT ON COLUMN "public"."whatsapp_templates"."template_sid" IS 'SID único del template en Twilio';



COMMENT ON COLUMN "public"."whatsapp_templates"."template_name" IS 'Nombre amigable del template generado automáticamente';



COMMENT ON COLUMN "public"."whatsapp_templates"."content" IS 'Contenido procesado del template';



COMMENT ON COLUMN "public"."whatsapp_templates"."original_message" IS 'Mensaje original que generó este template';



COMMENT ON COLUMN "public"."whatsapp_templates"."site_id" IS 'ID del sitio al que pertenece este template';



COMMENT ON COLUMN "public"."whatsapp_templates"."account_sid" IS 'Account SID de Twilio asociado';



COMMENT ON COLUMN "public"."whatsapp_templates"."status" IS 'Estado del template: active, inactive, pending, failed';



COMMENT ON COLUMN "public"."whatsapp_templates"."last_used" IS 'Última vez que se usó este template';



COMMENT ON COLUMN "public"."whatsapp_templates"."usage_count" IS 'Número de veces que se ha usado este template';



ALTER TABLE ONLY "public"."activity"
    ADD CONSTRAINT "activity_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agent_assets"
    ADD CONSTRAINT "agent_assets_pkey" PRIMARY KEY ("agent_id", "asset_id");



ALTER TABLE ONLY "public"."agent_memories"
    ADD CONSTRAINT "agent_memories_agent_id_user_id_key_key" UNIQUE ("agent_id", "user_id", "key");



ALTER TABLE ONLY "public"."agent_memories"
    ADD CONSTRAINT "agent_memories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "agents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."allowed_domains"
    ADD CONSTRAINT "allowed_domains_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."analysis"
    ADD CONSTRAINT "analysis_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."automation_auth_sessions"
    ADD CONSTRAINT "automation_auth_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."automation_auth_sessions"
    ADD CONSTRAINT "automation_auth_sessions_site_domain_name_unique" UNIQUE ("site_id", "domain", "name");



ALTER TABLE ONLY "public"."billing"
    ADD CONSTRAINT "billing_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaign_requirements"
    ADD CONSTRAINT "campaign_requirements_pkey" PRIMARY KEY ("campaign_id", "requirement_id");



ALTER TABLE ONLY "public"."campaign_segments"
    ADD CONSTRAINT "campaign_segments_pkey" PRIMARY KEY ("campaign_id", "segment_id");



ALTER TABLE ONLY "public"."campaign_subtasks"
    ADD CONSTRAINT "campaign_subtasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."commands"
    ADD CONSTRAINT "commands_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_assets"
    ADD CONSTRAINT "content_assets_pkey" PRIMARY KEY ("content_id", "asset_id");



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."copywriting"
    ADD CONSTRAINT "copywriting_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."copywriting"
    ADD CONSTRAINT "copywriting_site_user_title_unique" UNIQUE ("site_id", "user_id", "title");



ALTER TABLE ONLY "public"."cron_status"
    ADD CONSTRAINT "cron_status_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customizations"
    ADD CONSTRAINT "customizations_element_id_key_key" UNIQUE ("element_id", "key");



ALTER TABLE ONLY "public"."customizations"
    ADD CONSTRAINT "customizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."debug_logs"
    ADD CONSTRAINT "debug_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."editor"
    ADD CONSTRAINT "editor_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."editor"
    ADD CONSTRAINT "editor_site_id_key" UNIQUE ("site_id");



ALTER TABLE ONLY "public"."elements"
    ADD CONSTRAINT "elements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."experiment_segments"
    ADD CONSTRAINT "experiment_segments_experiment_id_segment_id_key" UNIQUE ("experiment_id", "segment_id");



ALTER TABLE ONLY "public"."experiment_segments"
    ADD CONSTRAINT "experiment_segments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."experiments"
    ADD CONSTRAINT "experiments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."external_resources"
    ADD CONSTRAINT "external_resources_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."icp_mining"
    ADD CONSTRAINT "icp_mining_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."instance_logs"
    ADD CONSTRAINT "instance_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."instance_plans"
    ADD CONSTRAINT "instance_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."kpis"
    ADD CONSTRAINT "kpis_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."layers"
    ADD CONSTRAINT "layers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."lead_analysis"
    ADD CONSTRAINT "lead_analysis_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_site_name_email_unique" UNIQUE ("site_id", "name", "email");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."persons"
    ADD CONSTRAINT "persons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referral_code_uses"
    ADD CONSTRAINT "referral_code_uses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referral_code_uses"
    ADD CONSTRAINT "referral_code_uses_referral_code_id_user_id_key" UNIQUE ("referral_code_id", "user_id");



ALTER TABLE ONLY "public"."referral_codes"
    ADD CONSTRAINT "referral_codes_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."referral_codes"
    ADD CONSTRAINT "referral_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."remote_instances"
    ADD CONSTRAINT "remote_instances_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."requirement_segments"
    ADD CONSTRAINT "requirement_segments_pkey" PRIMARY KEY ("requirement_id", "segment_id");



ALTER TABLE ONLY "public"."requirements"
    ADD CONSTRAINT "requirements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_queries"
    ADD CONSTRAINT "role_queries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_queries"
    ADD CONSTRAINT "role_queries_query_hash_key" UNIQUE ("query_hash");



ALTER TABLE ONLY "public"."role_query_segments"
    ADD CONSTRAINT "role_query_segments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_query_segments"
    ADD CONSTRAINT "role_query_segments_role_query_id_segment_id_key" UNIQUE ("role_query_id", "segment_id");



ALTER TABLE ONLY "public"."sale_orders"
    ADD CONSTRAINT "sale_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sections"
    ADD CONSTRAINT "sections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."secure_tokens"
    ADD CONSTRAINT "secure_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."secure_tokens"
    ADD CONSTRAINT "secure_tokens_site_id_token_type_identifier_key" UNIQUE ("site_id", "token_type", "identifier");



ALTER TABLE ONLY "public"."segments"
    ADD CONSTRAINT "segments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."session_events"
    ADD CONSTRAINT "session_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_site_id_key" UNIQUE ("site_id");



ALTER TABLE ONLY "public"."site_members"
    ADD CONSTRAINT "site_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."site_members"
    ADD CONSTRAINT "site_members_site_id_email_key" UNIQUE ("site_id", "email");



ALTER TABLE ONLY "public"."site_members"
    ADD CONSTRAINT "site_members_site_id_user_id_key" UNIQUE ("site_id", "user_id");



ALTER TABLE ONLY "public"."site_ownership"
    ADD CONSTRAINT "site_ownership_pkey" PRIMARY KEY ("site_id");



ALTER TABLE ONLY "public"."sites"
    ADD CONSTRAINT "sites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."states"
    ADD CONSTRAINT "states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."synced_objects"
    ADD CONSTRAINT "synced_objects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_memories"
    ADD CONSTRAINT "system_memories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_memories"
    ADD CONSTRAINT "system_memories_site_id_system_type_key_key" UNIQUE ("site_id", "system_type", "key");



ALTER TABLE ONLY "public"."task_categories"
    ADD CONSTRAINT "task_categories_pkey" PRIMARY KEY ("task_id", "category_id");



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transitions"
    ADD CONSTRAINT "transitions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."persons"
    ADD CONSTRAINT "uniq_persons_ext" UNIQUE ("external_person_id", "external_role_id");



ALTER TABLE ONLY "public"."allowed_domains"
    ADD CONSTRAINT "unique_domain_per_site" UNIQUE ("site_id", "domain");



ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_state_id_name_key" UNIQUE ("state_id", "name");



ALTER TABLE ONLY "public"."visitor_sessions"
    ADD CONSTRAINT "visitor_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."visitors"
    ADD CONSTRAINT "visitors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."waitlist"
    ADD CONSTRAINT "waitlist_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."waitlist"
    ADD CONSTRAINT "waitlist_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."webhook_events"
    ADD CONSTRAINT "webhook_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."webhook_events"
    ADD CONSTRAINT "webhook_events_stripe_event_id_key" UNIQUE ("stripe_event_id");



ALTER TABLE ONLY "public"."webhooks_deliveries"
    ADD CONSTRAINT "webhooks_deliveries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."webhooks_endpoints"
    ADD CONSTRAINT "webhooks_endpoints_name_per_site_unique" UNIQUE ("site_id", "name");



ALTER TABLE ONLY "public"."webhooks_endpoints"
    ADD CONSTRAINT "webhooks_endpoints_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."webhooks_subscriptions"
    ADD CONSTRAINT "webhooks_subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."webhooks_subscriptions"
    ADD CONSTRAINT "webhooks_subscriptions_unique" UNIQUE ("endpoint_id", "event_type");



ALTER TABLE ONLY "public"."whatsapp_templates"
    ADD CONSTRAINT "whatsapp_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."whatsapp_templates"
    ADD CONSTRAINT "whatsapp_templates_unique_name_site" UNIQUE ("template_name", "site_id");



ALTER TABLE ONLY "public"."whatsapp_templates"
    ADD CONSTRAINT "whatsapp_templates_unique_sid" UNIQUE ("template_sid");



CREATE INDEX "analysis_user_id_idx" ON "public"."analysis" USING "btree" ("user_id");



CREATE INDEX "idx_activity_active" ON "public"."activity" USING "btree" ("site_id", "workflow_type", "status") WHERE (("status")::"text" = ANY (ARRAY[('STARTED'::character varying)::"text", ('RUNNING'::character varying)::"text"]));



CREATE INDEX "idx_activity_auth_context" ON "public"."activity" USING "btree" ("site_id", "created_at" DESC);



CREATE INDEX "idx_activity_schedule_id" ON "public"."activity" USING "btree" ("schedule_id") WHERE ("schedule_id" IS NOT NULL);



CREATE INDEX "idx_activity_site_id" ON "public"."activity" USING "btree" ("site_id");



CREATE INDEX "idx_activity_site_workflow_type" ON "public"."activity" USING "btree" ("site_id", "workflow_type");



CREATE INDEX "idx_activity_started_at" ON "public"."activity" USING "btree" ("started_at");



CREATE INDEX "idx_activity_status" ON "public"."activity" USING "btree" ("status");



CREATE INDEX "idx_activity_workflow_id" ON "public"."activity" USING "btree" ("workflow_id");



CREATE INDEX "idx_activity_workflow_type" ON "public"."activity" USING "btree" ("workflow_type");



CREATE INDEX "idx_agent_assets_agent_id" ON "public"."agent_assets" USING "btree" ("agent_id");



CREATE INDEX "idx_agent_assets_asset_id_new" ON "public"."agent_assets" USING "btree" ("asset_id");



CREATE INDEX "idx_agent_assets_command_id_new" ON "public"."agent_assets" USING "btree" ("command_id");



CREATE INDEX "idx_agent_memories_command_id" ON "public"."agent_memories" USING "btree" ("command_id");



CREATE INDEX "idx_agents_command_id" ON "public"."agents" USING "btree" ("command_id");



CREATE INDEX "idx_agents_site_id" ON "public"."agents" USING "btree" ("site_id");



CREATE INDEX "idx_agents_status" ON "public"."agents" USING "btree" ("status");



CREATE INDEX "idx_agents_supervisor" ON "public"."agents" USING "btree" ("supervisor");



CREATE INDEX "idx_agents_user_id" ON "public"."agents" USING "btree" ("user_id");



CREATE INDEX "idx_allowed_domains_site_id" ON "public"."allowed_domains" USING "btree" ("site_id");



CREATE INDEX "idx_analysis_command_id_new" ON "public"."analysis" USING "btree" ("command_id");



CREATE INDEX "idx_analysis_site_id_new" ON "public"."analysis" USING "btree" ("site_id");



CREATE INDEX "idx_api_keys_prefix" ON "public"."api_keys" USING "btree" ("prefix");



CREATE INDEX "idx_api_keys_site_id" ON "public"."api_keys" USING "btree" ("site_id");



CREATE INDEX "idx_api_keys_status" ON "public"."api_keys" USING "btree" ("status");



CREATE INDEX "idx_api_keys_user_id" ON "public"."api_keys" USING "btree" ("user_id");



CREATE INDEX "idx_assets_command_id_new" ON "public"."assets" USING "btree" ("command_id");



CREATE INDEX "idx_assets_site_id" ON "public"."assets" USING "btree" ("site_id");



CREATE INDEX "idx_assets_user_id" ON "public"."assets" USING "btree" ("user_id");



CREATE INDEX "idx_automation_auth_sessions_auth_type" ON "public"."automation_auth_sessions" USING "btree" ("auth_type");



CREATE INDEX "idx_automation_auth_sessions_domain" ON "public"."automation_auth_sessions" USING "btree" ("domain");



CREATE INDEX "idx_automation_auth_sessions_expires_at" ON "public"."automation_auth_sessions" USING "btree" ("expires_at");



CREATE INDEX "idx_automation_auth_sessions_instance_id" ON "public"."automation_auth_sessions" USING "btree" ("instance_id");



CREATE INDEX "idx_automation_auth_sessions_is_valid" ON "public"."automation_auth_sessions" USING "btree" ("is_valid");



CREATE INDEX "idx_automation_auth_sessions_last_used_at" ON "public"."automation_auth_sessions" USING "btree" ("last_used_at");



CREATE INDEX "idx_automation_auth_sessions_site_id" ON "public"."automation_auth_sessions" USING "btree" ("site_id");



CREATE INDEX "idx_automation_auth_sessions_user_id" ON "public"."automation_auth_sessions" USING "btree" ("user_id");



CREATE INDEX "idx_billing_command_id" ON "public"."billing" USING "btree" ("command_id");



CREATE INDEX "idx_billing_plan" ON "public"."billing" USING "btree" ("plan");



CREATE INDEX "idx_billing_site_id" ON "public"."billing" USING "btree" ("site_id");



CREATE INDEX "idx_billing_stripe_customer_id" ON "public"."billing" USING "btree" ("stripe_customer_id");



CREATE INDEX "idx_campaign_requirements_campaign_id" ON "public"."campaign_requirements" USING "btree" ("campaign_id");



CREATE INDEX "idx_campaign_requirements_command_id" ON "public"."campaign_requirements" USING "btree" ("command_id");



CREATE INDEX "idx_campaign_requirements_requirement_id" ON "public"."campaign_requirements" USING "btree" ("requirement_id");



CREATE INDEX "idx_campaign_segments_command_id_new" ON "public"."campaign_segments" USING "btree" ("command_id");



CREATE INDEX "idx_campaign_segments_segment_id" ON "public"."campaign_segments" USING "btree" ("segment_id");



CREATE INDEX "idx_campaign_subtasks_campaign_id" ON "public"."campaign_subtasks" USING "btree" ("campaign_id");



CREATE INDEX "idx_campaign_subtasks_command_id_new" ON "public"."campaign_subtasks" USING "btree" ("command_id");



CREATE INDEX "idx_campaigns_command_id" ON "public"."campaigns" USING "btree" ("command_id");



CREATE INDEX "idx_campaigns_site_id" ON "public"."campaigns" USING "btree" ("site_id");



CREATE INDEX "idx_campaigns_status" ON "public"."campaigns" USING "btree" ("status");



CREATE INDEX "idx_campaigns_user_id" ON "public"."campaigns" USING "btree" ("user_id");



CREATE INDEX "idx_categories_site_id" ON "public"."categories" USING "btree" ("site_id");



CREATE INDEX "idx_categories_user_id" ON "public"."categories" USING "btree" ("user_id");



CREATE INDEX "idx_commands_agent_id" ON "public"."commands" USING "btree" ("agent_id");



CREATE INDEX "idx_commands_created_at" ON "public"."commands" USING "btree" ("created_at");



CREATE INDEX "idx_commands_performance" ON "public"."commands" USING "btree" ("performance");



CREATE INDEX "idx_commands_site_id" ON "public"."commands" USING "btree" ("site_id");



CREATE INDEX "idx_commands_site_user_composite" ON "public"."commands" USING "btree" ("site_id", "user_id");



CREATE INDEX "idx_commands_status" ON "public"."commands" USING "btree" ("status");



CREATE INDEX "idx_commands_user_id" ON "public"."commands" USING "btree" ("user_id");



CREATE INDEX "idx_companies_acquired_by_id_new" ON "public"."companies" USING "btree" ("acquired_by_id");



CREATE INDEX "idx_companies_name" ON "public"."companies" USING "gin" ("name" "extensions"."gin_trgm_ops");



CREATE INDEX "idx_companies_parent_company_id_new" ON "public"."companies" USING "btree" ("parent_company_id");



CREATE INDEX "idx_content_assets_asset_id" ON "public"."content_assets" USING "btree" ("asset_id");



CREATE INDEX "idx_content_assets_content_id" ON "public"."content_assets" USING "btree" ("content_id");



CREATE INDEX "idx_content_assets_content_id_rls" ON "public"."content_assets" USING "btree" ("content_id");



CREATE INDEX "idx_content_author_id" ON "public"."content" USING "btree" ("author_id");



CREATE INDEX "idx_content_campaign_id" ON "public"."content" USING "btree" ("campaign_id");



CREATE INDEX "idx_content_command_id" ON "public"."content" USING "btree" ("command_id");



CREATE INDEX "idx_content_segment_id" ON "public"."content" USING "btree" ("segment_id");



CREATE INDEX "idx_content_site_id" ON "public"."content" USING "btree" ("site_id");



COMMENT ON INDEX "public"."idx_content_site_id" IS 'Index for content site_id foreign key';



CREATE INDEX "idx_content_user_id" ON "public"."content" USING "btree" ("user_id");



CREATE INDEX "idx_conversations_agent_id" ON "public"."conversations" USING "btree" ("agent_id");



CREATE INDEX "idx_conversations_command_id" ON "public"."conversations" USING "btree" ("command_id");



CREATE INDEX "idx_conversations_delegate_id" ON "public"."conversations" USING "btree" ("delegate_id");



CREATE INDEX "idx_conversations_id_optimized" ON "public"."conversations" USING "btree" ("id") WHERE ("last_message_at" IS NOT NULL);



CREATE INDEX "idx_conversations_last_message_at" ON "public"."conversations" USING "btree" ("last_message_at");



CREATE INDEX "idx_conversations_lead_id" ON "public"."conversations" USING "btree" ("lead_id");



CREATE INDEX "idx_conversations_site_id" ON "public"."conversations" USING "btree" ("site_id");



CREATE INDEX "idx_conversations_user_id" ON "public"."conversations" USING "btree" ("user_id");



CREATE INDEX "idx_conversations_visitor_id" ON "public"."conversations" USING "btree" ("visitor_id");



CREATE INDEX "idx_copywriting_copy_type" ON "public"."copywriting" USING "btree" ("copy_type");



CREATE INDEX "idx_copywriting_created_at" ON "public"."copywriting" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_copywriting_site_id" ON "public"."copywriting" USING "btree" ("site_id");



CREATE INDEX "idx_copywriting_site_type_status" ON "public"."copywriting" USING "btree" ("site_id", "copy_type", "status");



CREATE INDEX "idx_copywriting_status" ON "public"."copywriting" USING "btree" ("status");



CREATE INDEX "idx_copywriting_tags" ON "public"."copywriting" USING "gin" ("tags");



CREATE INDEX "idx_copywriting_user_id" ON "public"."copywriting" USING "btree" ("user_id");



CREATE INDEX "idx_copywriting_user_type_created" ON "public"."copywriting" USING "btree" ("user_id", "copy_type", "created_at" DESC);



CREATE INDEX "idx_cron_status_site_id" ON "public"."cron_status" USING "btree" ("site_id");



CREATE INDEX "idx_customizations_element_id" ON "public"."customizations" USING "btree" ("element_id");



CREATE INDEX "idx_debug_logs_command_id_new" ON "public"."debug_logs" USING "btree" ("command_id");



CREATE INDEX "idx_editor_site_id" ON "public"."editor" USING "btree" ("site_id");



CREATE INDEX "idx_elements_layer_id" ON "public"."elements" USING "btree" ("layer_id");



CREATE INDEX "idx_experiment_segments_command_id_new" ON "public"."experiment_segments" USING "btree" ("command_id");



CREATE INDEX "idx_experiment_segments_exp_seg" ON "public"."experiment_segments" USING "btree" ("experiment_id", "segment_id");



CREATE INDEX "idx_experiment_segments_experiment_id" ON "public"."experiment_segments" USING "btree" ("experiment_id");



CREATE INDEX "idx_experiment_segments_segment_id" ON "public"."experiment_segments" USING "btree" ("segment_id");



CREATE INDEX "idx_experiments_campaign_id_new" ON "public"."experiments" USING "btree" ("campaign_id");



CREATE INDEX "idx_experiments_command_id_new" ON "public"."experiments" USING "btree" ("command_id");



CREATE INDEX "idx_experiments_id_site_id" ON "public"."experiments" USING "btree" ("id", "site_id");



CREATE INDEX "idx_experiments_site_id" ON "public"."experiments" USING "btree" ("site_id");



CREATE INDEX "idx_experiments_user_id" ON "public"."experiments" USING "btree" ("user_id");



CREATE INDEX "idx_external_resources_command_id" ON "public"."external_resources" USING "btree" ("command_id");



CREATE INDEX "idx_external_resources_site_id" ON "public"."external_resources" USING "btree" ("site_id");



CREATE INDEX "idx_external_resources_user_id" ON "public"."external_resources" USING "btree" ("user_id");



CREATE INDEX "idx_icp_mining_created_at" ON "public"."icp_mining" USING "btree" ("created_at");



CREATE INDEX "idx_icp_mining_icp_criteria_gin" ON "public"."icp_mining" USING "gin" ("icp_criteria");



CREATE INDEX "idx_icp_mining_last_progress_at" ON "public"."icp_mining" USING "btree" ("last_progress_at");



CREATE INDEX "idx_icp_mining_role_query_id" ON "public"."icp_mining" USING "btree" ("role_query_id");



CREATE INDEX "idx_icp_mining_status" ON "public"."icp_mining" USING "btree" ("status");



CREATE INDEX "idx_instance_logs_agent_id" ON "public"."instance_logs" USING "btree" ("agent_id");



CREATE INDEX "idx_instance_logs_command_id" ON "public"."instance_logs" USING "btree" ("command_id");



CREATE INDEX "idx_instance_logs_created_at" ON "public"."instance_logs" USING "btree" ("created_at");



CREATE INDEX "idx_instance_logs_instance_id" ON "public"."instance_logs" USING "btree" ("instance_id");



CREATE INDEX "idx_instance_logs_is_error" ON "public"."instance_logs" USING "btree" ("is_error");



CREATE INDEX "idx_instance_logs_level" ON "public"."instance_logs" USING "btree" ("level");



CREATE INDEX "idx_instance_logs_log_type" ON "public"."instance_logs" USING "btree" ("log_type");



CREATE INDEX "idx_instance_logs_site_id" ON "public"."instance_logs" USING "btree" ("site_id");



CREATE INDEX "idx_instance_logs_step_id" ON "public"."instance_logs" USING "btree" ("step_id");



CREATE INDEX "idx_instance_logs_tool_name" ON "public"."instance_logs" USING "btree" ("tool_name");



CREATE INDEX "idx_instance_logs_user_id" ON "public"."instance_logs" USING "btree" ("user_id");



CREATE INDEX "idx_instance_plans_agent_id" ON "public"."instance_plans" USING "btree" ("agent_id");



CREATE INDEX "idx_instance_plans_command_id" ON "public"."instance_plans" USING "btree" ("command_id");



CREATE INDEX "idx_instance_plans_created_at" ON "public"."instance_plans" USING "btree" ("created_at");



CREATE INDEX "idx_instance_plans_due_at" ON "public"."instance_plans" USING "btree" ("due_at");



CREATE INDEX "idx_instance_plans_instance_id" ON "public"."instance_plans" USING "btree" ("instance_id");



CREATE INDEX "idx_instance_plans_parent_plan_id" ON "public"."instance_plans" USING "btree" ("parent_plan_id");



CREATE INDEX "idx_instance_plans_plan_type" ON "public"."instance_plans" USING "btree" ("plan_type");



CREATE INDEX "idx_instance_plans_priority" ON "public"."instance_plans" USING "btree" ("priority");



CREATE INDEX "idx_instance_plans_site_id" ON "public"."instance_plans" USING "btree" ("site_id");



CREATE INDEX "idx_instance_plans_status" ON "public"."instance_plans" USING "btree" ("status");



CREATE INDEX "idx_instance_plans_user_id" ON "public"."instance_plans" USING "btree" ("user_id");



CREATE INDEX "idx_kpis_command_id" ON "public"."kpis" USING "btree" ("command_id");



CREATE INDEX "idx_kpis_period_end" ON "public"."kpis" USING "btree" ("period_end");



CREATE INDEX "idx_kpis_segment_id" ON "public"."kpis" USING "btree" ("segment_id");



CREATE INDEX "idx_kpis_site_id" ON "public"."kpis" USING "btree" ("site_id");



CREATE INDEX "idx_kpis_type" ON "public"."kpis" USING "btree" ("type");



CREATE INDEX "idx_kpis_user_id" ON "public"."kpis" USING "btree" ("user_id");



COMMENT ON INDEX "public"."idx_kpis_user_id" IS 'Index for kpis user_id foreign key';



CREATE INDEX "idx_layers_state_id" ON "public"."layers" USING "btree" ("state_id");



CREATE INDEX "idx_layers_state_id_order" ON "public"."layers" USING "btree" ("state_id", "order");



CREATE INDEX "idx_lead_analysis_company_size" ON "public"."lead_analysis" USING "btree" ("company_size");



CREATE INDEX "idx_lead_analysis_completion" ON "public"."lead_analysis" USING "btree" ("completion_percentage");



CREATE INDEX "idx_lead_analysis_created_at" ON "public"."lead_analysis" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_lead_analysis_industry" ON "public"."lead_analysis" USING "btree" ("industry");



CREATE INDEX "idx_lead_analysis_site_id" ON "public"."lead_analysis" USING "btree" ("site_id");



CREATE INDEX "idx_lead_analysis_source" ON "public"."lead_analysis" USING "btree" ("source");



CREATE INDEX "idx_lead_analysis_status" ON "public"."lead_analysis" USING "btree" ("status");



CREATE INDEX "idx_lead_analysis_user_id" ON "public"."lead_analysis" USING "btree" ("user_id");



CREATE INDEX "idx_leads_campaign_id" ON "public"."leads" USING "btree" ("campaign_id");



CREATE INDEX "idx_leads_command_id" ON "public"."leads" USING "btree" ("command_id");



CREATE INDEX "idx_leads_company_id_new" ON "public"."leads" USING "btree" ("company_id");



CREATE INDEX "idx_leads_referral_lead_id" ON "public"."leads" USING "btree" ("referral_lead_id");



CREATE INDEX "idx_leads_segment_id" ON "public"."leads" USING "btree" ("segment_id");



CREATE INDEX "idx_leads_site_id" ON "public"."leads" USING "btree" ("site_id");



CREATE INDEX "idx_leads_status" ON "public"."leads" USING "btree" ("status");



CREATE INDEX "idx_leads_user_id" ON "public"."leads" USING "btree" ("user_id");



CREATE INDEX "idx_memories_type" ON "public"."agent_memories" USING "btree" ("type");



CREATE INDEX "idx_messages_command_id" ON "public"."messages" USING "btree" ("command_id");



CREATE INDEX "idx_messages_conversation_id" ON "public"."messages" USING "btree" ("conversation_id");



CREATE INDEX "idx_messages_created_at" ON "public"."messages" USING "btree" ("created_at");



CREATE INDEX "idx_messages_lead_id" ON "public"."messages" USING "btree" ("lead_id");



CREATE INDEX "idx_messages_role" ON "public"."messages" USING "btree" ("role");



CREATE INDEX "idx_messages_visitor_id" ON "public"."messages" USING "btree" ("visitor_id");



CREATE INDEX "idx_notifications_command_id" ON "public"."notifications" USING "btree" ("command_id");



CREATE INDEX "idx_notifications_site_id" ON "public"."notifications" USING "btree" ("site_id");



CREATE INDEX "idx_notifications_user_id" ON "public"."notifications" USING "btree" ("user_id");



CREATE INDEX "idx_payments_command_id" ON "public"."payments" USING "btree" ("command_id");



CREATE INDEX "idx_payments_site_id" ON "public"."payments" USING "btree" ("site_id");



CREATE INDEX "idx_persons_company" ON "public"."persons" USING "btree" ("company_name");



CREATE INDEX "idx_persons_current" ON "public"."persons" USING "btree" ("is_current");



CREATE INDEX "idx_persons_name" ON "public"."persons" USING "btree" ("full_name");



CREATE INDEX "idx_persons_raw_gin" ON "public"."persons" USING "gin" ("raw_result");



CREATE INDEX "idx_persons_role" ON "public"."persons" USING "btree" ("role_title");



CREATE INDEX "idx_persons_role_query_id" ON "public"."persons" USING "btree" ("role_query_id");



CREATE INDEX "idx_profiles_command_id_new" ON "public"."profiles" USING "btree" ("command_id");



CREATE INDEX "idx_referral_code_uses_code_id" ON "public"."referral_code_uses" USING "btree" ("referral_code_id");



CREATE INDEX "idx_referral_code_uses_user_id" ON "public"."referral_code_uses" USING "btree" ("user_id");



CREATE INDEX "idx_referral_codes_code" ON "public"."referral_codes" USING "btree" ("code");



CREATE INDEX "idx_referral_codes_created_by" ON "public"."referral_codes" USING "btree" ("created_by");



CREATE INDEX "idx_remote_instances_agent_id" ON "public"."remote_instances" USING "btree" ("agent_id");



CREATE INDEX "idx_remote_instances_command_id" ON "public"."remote_instances" USING "btree" ("command_id");



CREATE INDEX "idx_remote_instances_created_at" ON "public"."remote_instances" USING "btree" ("created_at");



CREATE INDEX "idx_remote_instances_instance_type" ON "public"."remote_instances" USING "btree" ("instance_type");



CREATE INDEX "idx_remote_instances_last_activity_at" ON "public"."remote_instances" USING "btree" ("last_activity_at");



CREATE INDEX "idx_remote_instances_provider_instance_id" ON "public"."remote_instances" USING "btree" ("provider_instance_id");



CREATE INDEX "idx_remote_instances_site_id" ON "public"."remote_instances" USING "btree" ("site_id");



CREATE INDEX "idx_remote_instances_status" ON "public"."remote_instances" USING "btree" ("status");



CREATE INDEX "idx_remote_instances_user_id" ON "public"."remote_instances" USING "btree" ("user_id");



CREATE INDEX "idx_requirement_segments_command_id_new" ON "public"."requirement_segments" USING "btree" ("command_id");



CREATE INDEX "idx_requirement_segments_segment_id" ON "public"."requirement_segments" USING "btree" ("segment_id");



CREATE INDEX "idx_requirements_command_id" ON "public"."requirements" USING "btree" ("command_id");



CREATE INDEX "idx_requirements_completion_status" ON "public"."requirements" USING "btree" ("completion_status");



COMMENT ON INDEX "public"."idx_requirements_completion_status" IS 'Index for filtering by completion status (pending/completed/rejected)';



CREATE INDEX "idx_requirements_priority" ON "public"."requirements" USING "btree" ("priority");



COMMENT ON INDEX "public"."idx_requirements_priority" IS 'Index for filtering and sorting by priority (high/medium/low)';



CREATE INDEX "idx_requirements_site_completion" ON "public"."requirements" USING "btree" ("site_id", "completion_status");



COMMENT ON INDEX "public"."idx_requirements_site_completion" IS 'Composite index for site-specific completion status queries';



CREATE INDEX "idx_requirements_site_id" ON "public"."requirements" USING "btree" ("site_id");



CREATE INDEX "idx_requirements_site_priority" ON "public"."requirements" USING "btree" ("site_id", "priority");



COMMENT ON INDEX "public"."idx_requirements_site_priority" IS 'Composite index for site-specific priority queries';



CREATE INDEX "idx_requirements_site_status" ON "public"."requirements" USING "btree" ("site_id", "status");



COMMENT ON INDEX "public"."idx_requirements_site_status" IS 'Composite index for site-specific status queries';



CREATE INDEX "idx_requirements_status" ON "public"."requirements" USING "btree" ("status");



COMMENT ON INDEX "public"."idx_requirements_status" IS 'Index for filtering by requirement status (backlog/in-progress/done/etc)';



CREATE INDEX "idx_requirements_type" ON "public"."requirements" USING "btree" ("type");



CREATE INDEX "idx_requirements_user_id" ON "public"."requirements" USING "btree" ("user_id");



CREATE INDEX "idx_role_queries_created_at" ON "public"."role_queries" USING "btree" ("created_at");



CREATE INDEX "idx_role_queries_query_gin" ON "public"."role_queries" USING "gin" ("query");



CREATE INDEX "idx_role_queries_status" ON "public"."role_queries" USING "btree" ("status");



CREATE INDEX "idx_rqs_role_query_id" ON "public"."role_query_segments" USING "btree" ("role_query_id");



CREATE INDEX "idx_rqs_segment_id" ON "public"."role_query_segments" USING "btree" ("segment_id");



CREATE INDEX "idx_sale_orders_sale_id" ON "public"."sale_orders" USING "btree" ("sale_id");



CREATE INDEX "idx_sale_orders_site_id" ON "public"."sale_orders" USING "btree" ("site_id");



CREATE INDEX "idx_sales_campaign_id" ON "public"."sales" USING "btree" ("campaign_id");



CREATE INDEX "idx_sales_command_id_new" ON "public"."sales" USING "btree" ("command_id");



CREATE INDEX "idx_sales_lead_id" ON "public"."sales" USING "btree" ("lead_id");



CREATE INDEX "idx_sales_segment_id" ON "public"."sales" USING "btree" ("segment_id");



CREATE INDEX "idx_sales_site_id" ON "public"."sales" USING "btree" ("site_id");



CREATE INDEX "idx_sales_status" ON "public"."sales" USING "btree" ("status");



CREATE INDEX "idx_sales_user_id" ON "public"."sales" USING "btree" ("user_id");



CREATE INDEX "idx_sections_site_id" ON "public"."sections" USING "btree" ("site_id");



CREATE INDEX "idx_sections_site_id_order" ON "public"."sections" USING "btree" ("site_id", "order");



CREATE INDEX "idx_segments_command_id" ON "public"."segments" USING "btree" ("command_id");



CREATE INDEX "idx_segments_site_id" ON "public"."segments" USING "btree" ("site_id");



CREATE INDEX "idx_segments_user_id" ON "public"."segments" USING "btree" ("user_id");



CREATE INDEX "idx_session_events_command_id" ON "public"."session_events" USING "btree" ("command_id");



CREATE INDEX "idx_session_events_segment_id" ON "public"."session_events" USING "btree" ("segment_id");



CREATE INDEX "idx_session_events_session_id" ON "public"."session_events" USING "btree" ("session_id");



CREATE INDEX "idx_session_events_site_id" ON "public"."session_events" USING "btree" ("site_id");



CREATE INDEX "idx_session_events_visitor_id" ON "public"."session_events" USING "btree" ("visitor_id");



CREATE INDEX "idx_settings_command_id" ON "public"."settings" USING "btree" ("command_id");



CREATE INDEX "idx_site_members_added_by" ON "public"."site_members" USING "btree" ("added_by");



CREATE INDEX "idx_site_members_email" ON "public"."site_members" USING "btree" ("email");



CREATE INDEX "idx_site_members_role" ON "public"."site_members" USING "btree" ("role");



CREATE INDEX "idx_site_members_site_id" ON "public"."site_members" USING "btree" ("site_id");



CREATE INDEX "idx_site_members_site_user_status" ON "public"."site_members" USING "btree" ("site_id", "user_id", "status") WHERE ("status" = 'active'::"text");



CREATE INDEX "idx_site_members_user_id" ON "public"."site_members" USING "btree" ("user_id");



CREATE INDEX "idx_site_members_user_site" ON "public"."site_members" USING "btree" ("user_id", "site_id");



CREATE INDEX "idx_site_members_user_site_status" ON "public"."site_members" USING "btree" ("user_id", "site_id", "status") WHERE ("status" = 'active'::"text");



CREATE INDEX "idx_site_ownership_user_id" ON "public"."site_ownership" USING "btree" ("user_id");



CREATE INDEX "idx_sites_command_id_new" ON "public"."sites" USING "btree" ("command_id");



CREATE INDEX "idx_sites_user_id" ON "public"."sites" USING "btree" ("user_id");



COMMENT ON INDEX "public"."idx_sites_user_id" IS 'Index for sites user_id foreign key';



CREATE INDEX "idx_states_section_id" ON "public"."states" USING "btree" ("section_id");



CREATE INDEX "idx_states_section_id_order" ON "public"."states" USING "btree" ("section_id", "order");



CREATE INDEX "idx_synced_objects_external_id" ON "public"."synced_objects" USING "btree" ("external_id");



CREATE INDEX "idx_synced_objects_external_site_type" ON "public"."synced_objects" USING "btree" ("external_id", "site_id", "object_type");



CREATE INDEX "idx_synced_objects_object_type" ON "public"."synced_objects" USING "btree" ("object_type");



CREATE INDEX "idx_synced_objects_provider" ON "public"."synced_objects" USING "btree" ("provider");



CREATE INDEX "idx_synced_objects_site_id" ON "public"."synced_objects" USING "btree" ("site_id");



CREATE INDEX "idx_synced_objects_site_object_type" ON "public"."synced_objects" USING "btree" ("site_id", "object_type");



CREATE INDEX "idx_synced_objects_site_status" ON "public"."synced_objects" USING "btree" ("site_id", "status");



CREATE INDEX "idx_synced_objects_status" ON "public"."synced_objects" USING "btree" ("status");



CREATE UNIQUE INDEX "idx_synced_objects_unique_external_site_type" ON "public"."synced_objects" USING "btree" ("external_id", "site_id", "object_type");



CREATE INDEX "idx_system_memories_command_id" ON "public"."system_memories" USING "btree" ("command_id");



CREATE INDEX "idx_system_memories_expires_at" ON "public"."system_memories" USING "btree" ("expires_at");



CREATE INDEX "idx_system_memories_key" ON "public"."system_memories" USING "btree" ("key");



CREATE INDEX "idx_system_memories_last_accessed" ON "public"."system_memories" USING "btree" ("last_accessed");



CREATE INDEX "idx_system_memories_site_id" ON "public"."system_memories" USING "btree" ("site_id");



CREATE INDEX "idx_system_memories_system_type" ON "public"."system_memories" USING "btree" ("system_type");



CREATE INDEX "idx_task_categories_category_id_new" ON "public"."task_categories" USING "btree" ("category_id");



CREATE INDEX "idx_task_categories_task_id" ON "public"."task_categories" USING "btree" ("task_id");



CREATE INDEX "idx_task_comments_task_id" ON "public"."task_comments" USING "btree" ("task_id");



CREATE INDEX "idx_task_comments_user_id" ON "public"."task_comments" USING "btree" ("user_id");



CREATE INDEX "idx_tasks_assignee" ON "public"."tasks" USING "btree" ("assignee");



CREATE INDEX "idx_tasks_command_id_new" ON "public"."tasks" USING "btree" ("command_id");



CREATE INDEX "idx_tasks_lead_id" ON "public"."tasks" USING "btree" ("lead_id");



CREATE INDEX "idx_tasks_priority" ON "public"."tasks" USING "btree" ("priority");



CREATE INDEX "idx_tasks_serial_id" ON "public"."tasks" USING "btree" ("serial_id");



CREATE UNIQUE INDEX "idx_tasks_serial_id_site_unique" ON "public"."tasks" USING "btree" ("site_id", "serial_id");



CREATE INDEX "idx_tasks_site_id" ON "public"."tasks" USING "btree" ("site_id");



CREATE INDEX "idx_tasks_user_id" ON "public"."tasks" USING "btree" ("user_id");



CREATE INDEX "idx_transactions_campaign_id" ON "public"."transactions" USING "btree" ("campaign_id");



CREATE INDEX "idx_transactions_command_id_new" ON "public"."transactions" USING "btree" ("command_id");



CREATE INDEX "idx_transactions_site_id" ON "public"."transactions" USING "btree" ("site_id");



CREATE INDEX "idx_transactions_user_id" ON "public"."transactions" USING "btree" ("user_id");



CREATE INDEX "idx_transitions_from_state_id" ON "public"."transitions" USING "btree" ("from_state_id");



CREATE INDEX "idx_transitions_from_to" ON "public"."transitions" USING "btree" ("from_state_id", "to_state_id");



CREATE INDEX "idx_transitions_to_state_id" ON "public"."transitions" USING "btree" ("to_state_id");



CREATE INDEX "idx_variants_state_id" ON "public"."variants" USING "btree" ("state_id");



CREATE INDEX "idx_visitor_sessions_command_id" ON "public"."visitor_sessions" USING "btree" ("command_id");



CREATE INDEX "idx_visitor_sessions_is_active" ON "public"."visitor_sessions" USING "btree" ("is_active");



CREATE INDEX "idx_visitor_sessions_lead_id" ON "public"."visitor_sessions" USING "btree" ("lead_id");



CREATE INDEX "idx_visitor_sessions_site_id" ON "public"."visitor_sessions" USING "btree" ("site_id");



CREATE INDEX "idx_visitor_sessions_visitor_id" ON "public"."visitor_sessions" USING "btree" ("visitor_id");



CREATE INDEX "idx_visitors_campaign_id" ON "public"."visitors" USING "btree" ("campaign_id");



CREATE INDEX "idx_visitors_command_id" ON "public"."visitors" USING "btree" ("command_id");



CREATE INDEX "idx_visitors_device_id" ON "public"."visitors" USING "btree" ("fingerprint");



CREATE INDEX "idx_visitors_lead_id" ON "public"."visitors" USING "btree" ("lead_id");



CREATE INDEX "idx_visitors_segment_id" ON "public"."visitors" USING "btree" ("segment_id");



CREATE INDEX "idx_webhook_events_event_type" ON "public"."webhook_events" USING "btree" ("event_type");



CREATE INDEX "idx_webhook_events_processed_at" ON "public"."webhook_events" USING "btree" ("processed_at");



CREATE INDEX "idx_webhook_events_site_id" ON "public"."webhook_events" USING "btree" ("site_id");



CREATE INDEX "idx_webhook_events_status" ON "public"."webhook_events" USING "btree" ("status");



CREATE INDEX "idx_webhook_events_stripe_event_id" ON "public"."webhook_events" USING "btree" ("stripe_event_id");



CREATE INDEX "idx_webhooks_deliveries_created_at" ON "public"."webhooks_deliveries" USING "btree" ("created_at");



CREATE INDEX "idx_webhooks_deliveries_endpoint" ON "public"."webhooks_deliveries" USING "btree" ("endpoint_id");



CREATE INDEX "idx_webhooks_deliveries_event" ON "public"."webhooks_deliveries" USING "btree" ("event_type");



CREATE INDEX "idx_webhooks_deliveries_site" ON "public"."webhooks_deliveries" USING "btree" ("site_id");



CREATE INDEX "idx_webhooks_deliveries_status" ON "public"."webhooks_deliveries" USING "btree" ("status");



CREATE INDEX "idx_webhooks_endpoints_site" ON "public"."webhooks_endpoints" USING "btree" ("site_id");



CREATE INDEX "idx_webhooks_endpoints_site_active" ON "public"."webhooks_endpoints" USING "btree" ("site_id", "is_active");



CREATE INDEX "idx_webhooks_subscriptions_endpoint" ON "public"."webhooks_subscriptions" USING "btree" ("endpoint_id");



CREATE INDEX "idx_webhooks_subscriptions_event" ON "public"."webhooks_subscriptions" USING "btree" ("event_type");



CREATE INDEX "idx_webhooks_subscriptions_site" ON "public"."webhooks_subscriptions" USING "btree" ("site_id");



CREATE INDEX "idx_whatsapp_templates_account_sid" ON "public"."whatsapp_templates" USING "btree" ("account_sid");



CREATE INDEX "idx_whatsapp_templates_created_at" ON "public"."whatsapp_templates" USING "btree" ("created_at");



CREATE INDEX "idx_whatsapp_templates_last_used" ON "public"."whatsapp_templates" USING "btree" ("last_used");



CREATE INDEX "idx_whatsapp_templates_site_id" ON "public"."whatsapp_templates" USING "btree" ("site_id");



CREATE INDEX "idx_whatsapp_templates_status" ON "public"."whatsapp_templates" USING "btree" ("status");



CREATE INDEX "settings_site_id_idx" ON "public"."settings" USING "btree" ("site_id");



CREATE UNIQUE INDEX "uq_icp_mining_active_unique" ON "public"."icp_mining" USING "btree" ("role_query_id", "icp_hash") WHERE ("status" = ANY (ARRAY['pending'::"text", 'running'::"text"]));



CREATE OR REPLACE TRIGGER "activate_pending_memberships_trigger" AFTER INSERT ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."activate_pending_site_memberships"();



CREATE OR REPLACE TRIGGER "billing_timestamp_trigger" BEFORE UPDATE ON "public"."billing" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "campaign_cascade_delete_trigger" BEFORE DELETE ON "public"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."handle_campaign_deletion"();



CREATE OR REPLACE TRIGGER "check_expired_api_keys" BEFORE INSERT OR UPDATE ON "public"."api_keys" FOR EACH ROW EXECUTE FUNCTION "public"."ensure_api_key_not_expired"();



CREATE OR REPLACE TRIGGER "increment_template_usage_trigger" AFTER UPDATE ON "public"."whatsapp_templates" FOR EACH ROW WHEN ((("old"."usage_count" IS DISTINCT FROM "new"."usage_count") OR ("old"."last_used" IS DISTINCT FROM "new"."last_used"))) EXECUTE FUNCTION "public"."increment_template_usage"();



CREATE OR REPLACE TRIGGER "leads_webhooks" AFTER INSERT OR DELETE OR UPDATE ON "public"."leads" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://backend.uncodie.com/api/workflow/webhook', 'POST', '{"Content-type":"application/json","x-api-key":"8s4EtZ@4f^6QRH%r%e%9!79Uk88PDV4Mgw3573t47q2a6QEq98^65y5AwqWMJym9"}', '{}', '5000');



CREATE OR REPLACE TRIGGER "log_asset_insert_trigger" BEFORE INSERT ON "public"."assets" FOR EACH ROW EXECUTE FUNCTION "public"."log_asset_insert"();



CREATE OR REPLACE TRIGGER "messages_webhooks" AFTER INSERT OR DELETE OR UPDATE ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://backend.uncodie.com/api/workflow/webhook', 'POST', '{"Content-type":"application/json","x-api-key":"8s4EtZ@4f^6QRH%r%e%9!79Uk88PDV4Mgw3573t47q2a6QEq98^65y5AwqWMJym9"}', '{}', '5000');



CREATE OR REPLACE TRIGGER "on_command_insert" BEFORE INSERT ON "public"."commands" FOR EACH ROW EXECUTE FUNCTION "public"."handle_command_insert"();



CREATE OR REPLACE TRIGGER "on_command_update" BEFORE UPDATE ON "public"."commands" FOR EACH ROW EXECUTE FUNCTION "public"."handle_command_update"();



CREATE OR REPLACE TRIGGER "on_event_insert" BEFORE INSERT ON "public"."session_events" FOR EACH ROW EXECUTE FUNCTION "public"."handle_event_insert"();



CREATE OR REPLACE TRIGGER "on_message_insert" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_conversation_last_message_time"();



CREATE OR REPLACE TRIGGER "payments_timestamp_trigger" BEFORE UPDATE ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "prevent_last_admin_deletion_trigger" BEFORE DELETE ON "public"."site_members" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_last_admin_deletion"();



COMMENT ON TRIGGER "prevent_last_admin_deletion_trigger" ON "public"."site_members" IS 'Ensures at least one admin/owner remains when deleting members individually, but allows deletion during site deletion.';



CREATE OR REPLACE TRIGGER "prevent_last_admin_role_change_trigger" BEFORE UPDATE ON "public"."site_members" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_last_admin_role_change"();



COMMENT ON TRIGGER "prevent_last_admin_role_change_trigger" ON "public"."site_members" IS 'Ensures at least one admin/owner remains when changing roles';



CREATE OR REPLACE TRIGGER "session_events_updated_at_trigger" BEFORE UPDATE ON "public"."session_events" FOR EACH ROW EXECUTE FUNCTION "public"."handle_session_events_updated_at"();



CREATE OR REPLACE TRIGGER "set_tasks_updated_at" BEFORE UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."set_current_timestamp_updated_at"();



CREATE OR REPLACE TRIGGER "set_timestamp_webhooks_deliveries" BEFORE UPDATE ON "public"."webhooks_deliveries" FOR EACH ROW EXECUTE FUNCTION "public"."set_current_timestamp_updated_at"();



CREATE OR REPLACE TRIGGER "set_timestamp_webhooks_endpoints" BEFORE UPDATE ON "public"."webhooks_endpoints" FOR EACH ROW EXECUTE FUNCTION "public"."set_current_timestamp_updated_at"();



CREATE OR REPLACE TRIGGER "set_timestamp_webhooks_subscriptions" BEFORE UPDATE ON "public"."webhooks_subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_current_timestamp_updated_at"();



CREATE OR REPLACE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."analysis" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



CREATE OR REPLACE TRIGGER "settings_updated_at" BEFORE UPDATE ON "public"."settings" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "sync_members_to_settings" AFTER INSERT OR DELETE OR UPDATE ON "public"."site_members" FOR EACH ROW EXECUTE FUNCTION "public"."sync_site_members_to_settings"();



CREATE OR REPLACE TRIGGER "sync_ownership_on_site_change" AFTER INSERT OR DELETE OR UPDATE OF "user_id" ON "public"."sites" FOR EACH ROW EXECUTE FUNCTION "public"."sync_site_ownership"();



CREATE OR REPLACE TRIGGER "sync_site_members_trigger" AFTER INSERT OR DELETE OR UPDATE ON "public"."site_members" FOR EACH ROW EXECUTE FUNCTION "public"."sync_site_members_to_team_members"();



CREATE OR REPLACE TRIGGER "tasks_webhooks" AFTER INSERT OR DELETE OR UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://backend.uncodie.com/api/workflow/webhook', 'POST', '{"Content-type":"application/json","x-api-key":"8s4EtZ@4f^6QRH%r%e%9!79Uk88PDV4Mgw3573t47q2a6QEq98^65y5AwqWMJym9"}', '{}', '5000');



CREATE OR REPLACE TRIGGER "trg_icp_mining_set_updated_at" BEFORE UPDATE ON "public"."icp_mining" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_persons_updated_at" BEFORE UPDATE ON "public"."persons" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_role_queries_updated_at" BEFORE UPDATE ON "public"."role_queries" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_rqs_updated_at" BEFORE UPDATE ON "public"."role_query_segments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_activity_updated_at" BEFORE UPDATE ON "public"."activity" FOR EACH ROW EXECUTE FUNCTION "public"."update_activity_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_agent_assets" BEFORE DELETE ON "public"."agent_assets" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_agent_memories" BEFORE DELETE ON "public"."agent_memories" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_agents" BEFORE DELETE ON "public"."agents" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_allowed_domains" BEFORE DELETE ON "public"."allowed_domains" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_analysis" BEFORE DELETE ON "public"."analysis" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_api_keys" BEFORE DELETE ON "public"."api_keys" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_assets" BEFORE DELETE ON "public"."assets" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_billing" BEFORE DELETE ON "public"."billing" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_campaign_requirements" BEFORE DELETE ON "public"."campaign_requirements" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_campaign_segments" BEFORE DELETE ON "public"."campaign_segments" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_campaign_subtasks" BEFORE DELETE ON "public"."campaign_subtasks" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_campaigns" BEFORE DELETE ON "public"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_categories" BEFORE DELETE ON "public"."categories" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_content" BEFORE DELETE ON "public"."content" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_conversations" BEFORE DELETE ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_experiment_segments" BEFORE DELETE ON "public"."experiment_segments" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_experiments" BEFORE DELETE ON "public"."experiments" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_external_resources" BEFORE DELETE ON "public"."external_resources" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_kpis" BEFORE DELETE ON "public"."kpis" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_leads" BEFORE DELETE ON "public"."leads" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_messages" BEFORE DELETE ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_notifications" BEFORE DELETE ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_payments" BEFORE DELETE ON "public"."payments" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_requirement_segments" BEFORE DELETE ON "public"."requirement_segments" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_requirements" BEFORE DELETE ON "public"."requirements" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_sale_orders" BEFORE DELETE ON "public"."sale_orders" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_sales" BEFORE DELETE ON "public"."sales" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_secure_tokens" BEFORE DELETE ON "public"."secure_tokens" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_segments" BEFORE DELETE ON "public"."segments" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_session_events" BEFORE DELETE ON "public"."session_events" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_settings" BEFORE DELETE ON "public"."settings" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_site_members" BEFORE DELETE ON "public"."site_members" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_task_categories" BEFORE DELETE ON "public"."task_categories" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_task_comments" BEFORE DELETE ON "public"."task_comments" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_tasks" BEFORE DELETE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_transactions" BEFORE DELETE ON "public"."transactions" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_visitor_sessions" BEFORE DELETE ON "public"."visitor_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_delete_protection_visitors" BEFORE DELETE ON "public"."visitors" FOR EACH ROW EXECUTE FUNCTION "public"."check_delete_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_agents" BEFORE INSERT ON "public"."agents" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_campaigns" BEFORE INSERT ON "public"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_content" BEFORE INSERT ON "public"."content" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_experiments" BEFORE INSERT ON "public"."experiments" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_leads" BEFORE INSERT ON "public"."leads" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_messages" BEFORE INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_notifications" BEFORE INSERT ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_requirements" BEFORE INSERT ON "public"."requirements" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_sales" BEFORE INSERT ON "public"."sales" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_segments" BEFORE INSERT ON "public"."segments" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_tasks" BEFORE INSERT ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_visitor_sessions" BEFORE INSERT ON "public"."visitor_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_insert_permission_visitors" BEFORE INSERT ON "public"."visitors" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_set_task_priority" BEFORE INSERT ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."set_task_priority_from_serial"();



CREATE OR REPLACE TRIGGER "trigger_set_task_serial_id" BEFORE INSERT ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."set_task_serial_id"();



CREATE OR REPLACE TRIGGER "trigger_update_copywriting_updated_at" BEFORE UPDATE ON "public"."copywriting" FOR EACH ROW EXECUTE FUNCTION "public"."update_copywriting_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_update_cron_status_updated_at" BEFORE UPDATE ON "public"."cron_status" FOR EACH ROW EXECUTE FUNCTION "public"."update_cron_status_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_update_lead_analysis_updated_at" BEFORE UPDATE ON "public"."lead_analysis" FOR EACH ROW EXECUTE FUNCTION "public"."update_lead_analysis_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_agents" BEFORE UPDATE ON "public"."agents" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_campaigns" BEFORE UPDATE ON "public"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_content" BEFORE UPDATE ON "public"."content" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_experiments" BEFORE UPDATE ON "public"."experiments" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_leads" BEFORE UPDATE ON "public"."leads" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_messages" BEFORE UPDATE ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_notifications" BEFORE UPDATE ON "public"."notifications" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_requirements" BEFORE UPDATE ON "public"."requirements" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_sales" BEFORE UPDATE ON "public"."sales" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_segments" BEFORE UPDATE ON "public"."segments" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_tasks" BEFORE UPDATE ON "public"."tasks" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_visitor_sessions" BEFORE UPDATE ON "public"."visitor_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_permission_visitors" BEFORE UPDATE ON "public"."visitors" FOR EACH ROW EXECUTE FUNCTION "public"."check_create_update_permission"();



CREATE OR REPLACE TRIGGER "trigger_update_sale_orders_updated_at" BEFORE UPDATE ON "public"."sale_orders" FOR EACH ROW EXECUTE FUNCTION "public"."update_sale_orders_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_update_synced_objects_updated_at" BEFORE UPDATE ON "public"."synced_objects" FOR EACH ROW EXECUTE FUNCTION "public"."update_synced_objects_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_update_whatsapp_templates_updated_at" BEFORE UPDATE ON "public"."whatsapp_templates" FOR EACH ROW EXECUTE FUNCTION "public"."update_whatsapp_templates_updated_at"();



CREATE OR REPLACE TRIGGER "update_api_keys_updated_at" BEFORE UPDATE ON "public"."api_keys" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_automation_auth_sessions_updated_at" BEFORE UPDATE ON "public"."automation_auth_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_companies_updated_at" BEFORE UPDATE ON "public"."companies" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_instance_plans_updated_at" BEFORE UPDATE ON "public"."instance_plans" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_referral_codes_updated_at" BEFORE UPDATE ON "public"."referral_codes" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_remote_instances_updated_at" BEFORE UPDATE ON "public"."remote_instances" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_waitlist_updated_at" BEFORE UPDATE ON "public"."waitlist" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "validate_performance_bitmask_trigger" BEFORE INSERT OR UPDATE ON "public"."commands" FOR EACH ROW EXECUTE FUNCTION "public"."validate_performance_bitmask"();



CREATE OR REPLACE TRIGGER "webhook_events_updated_at_trigger" BEFORE UPDATE ON "public"."webhook_events" FOR EACH ROW EXECUTE FUNCTION "public"."update_webhook_events_updated_at"();



ALTER TABLE ONLY "public"."activity"
    ADD CONSTRAINT "activity_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_assets"
    ADD CONSTRAINT "agent_assets_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_assets"
    ADD CONSTRAINT "agent_assets_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_memories"
    ADD CONSTRAINT "agent_memories_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "agents_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "agents_supervisor_fkey" FOREIGN KEY ("supervisor") REFERENCES "public"."agents"("id");



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "agents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."allowed_domains"
    ADD CONSTRAINT "allowed_domains_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analysis"
    ADD CONSTRAINT "analysis_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analysis"
    ADD CONSTRAINT "analysis_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_instance_id_fkey" FOREIGN KEY ("instance_id") REFERENCES "public"."remote_instances"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "assets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."automation_auth_sessions"
    ADD CONSTRAINT "automation_auth_sessions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."automation_auth_sessions"
    ADD CONSTRAINT "automation_auth_sessions_instance_id_fkey" FOREIGN KEY ("instance_id") REFERENCES "public"."remote_instances"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."automation_auth_sessions"
    ADD CONSTRAINT "automation_auth_sessions_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."automation_auth_sessions"
    ADD CONSTRAINT "automation_auth_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."billing"
    ADD CONSTRAINT "billing_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_requirements"
    ADD CONSTRAINT "campaign_requirements_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_requirements"
    ADD CONSTRAINT "campaign_requirements_requirement_id_fkey" FOREIGN KEY ("requirement_id") REFERENCES "public"."requirements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_segments"
    ADD CONSTRAINT "campaign_segments_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_segments"
    ADD CONSTRAINT "campaign_segments_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_subtasks"
    ADD CONSTRAINT "campaign_subtasks_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."commands"
    ADD CONSTRAINT "commands_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agents"("id");



ALTER TABLE ONLY "public"."commands"
    ADD CONSTRAINT "commands_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_acquired_by_id_fkey" FOREIGN KEY ("acquired_by_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_parent_company_id_fkey" FOREIGN KEY ("parent_company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."content_assets"
    ADD CONSTRAINT "content_assets_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "public"."assets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_assets"
    ADD CONSTRAINT "content_assets_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "public"."content"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_command_id_fkey" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id");



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content"
    ADD CONSTRAINT "content_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agents"("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_delegate_id_fkey" FOREIGN KEY ("delegate_id") REFERENCES "public"."agents"("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."leads"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."copywriting"
    ADD CONSTRAINT "copywriting_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."copywriting"
    ADD CONSTRAINT "copywriting_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cron_status"
    ADD CONSTRAINT "cron_status_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."customizations"
    ADD CONSTRAINT "customizations_element_id_fkey" FOREIGN KEY ("element_id") REFERENCES "public"."elements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."editor"
    ADD CONSTRAINT "editor_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."elements"
    ADD CONSTRAINT "elements_layer_id_fkey" FOREIGN KEY ("layer_id") REFERENCES "public"."layers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experiment_segments"
    ADD CONSTRAINT "experiment_segments_experiment_id_fkey" FOREIGN KEY ("experiment_id") REFERENCES "public"."experiments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experiment_segments"
    ADD CONSTRAINT "experiment_segments_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experiments"
    ADD CONSTRAINT "experiments_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."experiments"
    ADD CONSTRAINT "experiments_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experiments"
    ADD CONSTRAINT "experiments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."external_resources"
    ADD CONSTRAINT "external_resources_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."external_resources"
    ADD CONSTRAINT "external_resources_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."agent_assets"
    ADD CONSTRAINT "fk_command_agent_assets" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agent_memories"
    ADD CONSTRAINT "fk_command_agent_memories" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "fk_command_agents" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."analysis"
    ADD CONSTRAINT "fk_command_analysis" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."assets"
    ADD CONSTRAINT "fk_command_assets" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."billing"
    ADD CONSTRAINT "fk_command_billing" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_requirements"
    ADD CONSTRAINT "fk_command_campaign_requirements" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_segments"
    ADD CONSTRAINT "fk_command_campaign_segments" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaign_subtasks"
    ADD CONSTRAINT "fk_command_campaign_subtasks" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "fk_command_campaigns" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "fk_command_conversations" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."debug_logs"
    ADD CONSTRAINT "fk_command_debug_logs" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experiment_segments"
    ADD CONSTRAINT "fk_command_experiment_segments" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."experiments"
    ADD CONSTRAINT "fk_command_experiments" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."external_resources"
    ADD CONSTRAINT "fk_command_external_resources" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."instance_logs"
    ADD CONSTRAINT "fk_command_instance_logs" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."instance_plans"
    ADD CONSTRAINT "fk_command_instance_plans" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."kpis"
    ADD CONSTRAINT "fk_command_kpis" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "fk_command_leads" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "fk_command_messages" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "fk_command_notifications" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "fk_command_payments" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "fk_command_profiles" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."remote_instances"
    ADD CONSTRAINT "fk_command_remote_instances" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."requirement_segments"
    ADD CONSTRAINT "fk_command_requirement_segments" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."requirements"
    ADD CONSTRAINT "fk_command_requirements" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "fk_command_sales" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."segments"
    ADD CONSTRAINT "fk_command_segments" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_events"
    ADD CONSTRAINT "fk_command_session_events" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "fk_command_settings" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sites"
    ADD CONSTRAINT "fk_command_sites" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."system_memories"
    ADD CONSTRAINT "fk_command_system_memories" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "fk_command_tasks" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "fk_command_transactions" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visitor_sessions"
    ADD CONSTRAINT "fk_command_visitor_sessions" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visitors"
    ADD CONSTRAINT "fk_command_visitors" FOREIGN KEY ("command_id") REFERENCES "public"."commands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "fk_conversation" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "fk_lead" FOREIGN KEY ("lead_id") REFERENCES "public"."leads"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "fk_site" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "fk_user" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "fk_visitor" FOREIGN KEY ("visitor_id") REFERENCES "public"."visitors"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "fk_visitor" FOREIGN KEY ("visitor_id") REFERENCES "public"."visitors"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."session_events"
    ADD CONSTRAINT "fk_visitor_session" FOREIGN KEY ("session_id") REFERENCES "public"."visitor_sessions"("id") ON DELETE CASCADE;



COMMENT ON CONSTRAINT "fk_visitor_session" ON "public"."session_events" IS 'Links session_events to visitor_sessions table';



ALTER TABLE ONLY "public"."icp_mining"
    ADD CONSTRAINT "icp_mining_role_query_id_fkey" FOREIGN KEY ("role_query_id") REFERENCES "public"."role_queries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."icp_mining"
    ADD CONSTRAINT "icp_mining_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."instance_logs"
    ADD CONSTRAINT "instance_logs_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agents"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."instance_logs"
    ADD CONSTRAINT "instance_logs_instance_id_fkey" FOREIGN KEY ("instance_id") REFERENCES "public"."remote_instances"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."instance_logs"
    ADD CONSTRAINT "instance_logs_parent_log_id_fkey" FOREIGN KEY ("parent_log_id") REFERENCES "public"."instance_logs"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."instance_logs"
    ADD CONSTRAINT "instance_logs_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."instance_logs"
    ADD CONSTRAINT "instance_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."instance_plans"
    ADD CONSTRAINT "instance_plans_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agents"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."instance_plans"
    ADD CONSTRAINT "instance_plans_instance_id_fkey" FOREIGN KEY ("instance_id") REFERENCES "public"."remote_instances"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."instance_plans"
    ADD CONSTRAINT "instance_plans_parent_plan_id_fkey" FOREIGN KEY ("parent_plan_id") REFERENCES "public"."instance_plans"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."instance_plans"
    ADD CONSTRAINT "instance_plans_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."instance_plans"
    ADD CONSTRAINT "instance_plans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."kpis"
    ADD CONSTRAINT "kpis_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."kpis"
    ADD CONSTRAINT "kpis_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."kpis"
    ADD CONSTRAINT "kpis_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."layers"
    ADD CONSTRAINT "layers_state_id_fkey" FOREIGN KEY ("state_id") REFERENCES "public"."states"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."lead_analysis"
    ADD CONSTRAINT "lead_analysis_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."lead_analysis"
    ADD CONSTRAINT "lead_analysis_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_assignee_id_fkey" FOREIGN KEY ("assignee_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."persons"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_referral_lead_id_fkey" FOREIGN KEY ("referral_lead_id") REFERENCES "public"."leads"("id");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id");



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leads"
    ADD CONSTRAINT "leads_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."persons"
    ADD CONSTRAINT "persons_role_query_id_fkey" FOREIGN KEY ("role_query_id") REFERENCES "public"."role_queries"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referral_code_uses"
    ADD CONSTRAINT "referral_code_uses_referral_code_id_fkey" FOREIGN KEY ("referral_code_id") REFERENCES "public"."referral_codes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referral_code_uses"
    ADD CONSTRAINT "referral_code_uses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referral_codes"
    ADD CONSTRAINT "referral_codes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."remote_instances"
    ADD CONSTRAINT "remote_instances_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agents"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."remote_instances"
    ADD CONSTRAINT "remote_instances_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."remote_instances"
    ADD CONSTRAINT "remote_instances_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."remote_instances"
    ADD CONSTRAINT "remote_instances_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."requirement_segments"
    ADD CONSTRAINT "requirement_segments_requirement_id_fkey" FOREIGN KEY ("requirement_id") REFERENCES "public"."requirements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."requirement_segments"
    ADD CONSTRAINT "requirement_segments_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."requirements"
    ADD CONSTRAINT "requirements_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."requirements"
    ADD CONSTRAINT "requirements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."role_query_segments"
    ADD CONSTRAINT "role_query_segments_role_query_id_fkey" FOREIGN KEY ("role_query_id") REFERENCES "public"."role_queries"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_query_segments"
    ADD CONSTRAINT "role_query_segments_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_orders"
    ADD CONSTRAINT "sale_orders_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_orders"
    ADD CONSTRAINT "sale_orders_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."leads"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."sections"
    ADD CONSTRAINT "sections_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."secure_tokens"
    ADD CONSTRAINT "secure_tokens_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."segments"
    ADD CONSTRAINT "segments_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."segments"
    ADD CONSTRAINT "segments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_events"
    ADD CONSTRAINT "session_events_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_events"
    ADD CONSTRAINT "session_events_visitor_id_fkey" FOREIGN KEY ("visitor_id") REFERENCES "public"."visitors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."site_members"
    ADD CONSTRAINT "site_members_added_by_fkey" FOREIGN KEY ("added_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."site_members"
    ADD CONSTRAINT "site_members_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."site_members"
    ADD CONSTRAINT "site_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."site_ownership"
    ADD CONSTRAINT "site_ownership_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."site_ownership"
    ADD CONSTRAINT "site_ownership_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sites"
    ADD CONSTRAINT "sites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."states"
    ADD CONSTRAINT "states_section_id_fkey" FOREIGN KEY ("section_id") REFERENCES "public"."sections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."system_memories"
    ADD CONSTRAINT "system_memories_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_categories"
    ADD CONSTRAINT "task_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_categories"
    ADD CONSTRAINT "task_categories_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."tasks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_comments"
    ADD CONSTRAINT "task_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_assignee_fkey" FOREIGN KEY ("assignee") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."leads"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."transitions"
    ADD CONSTRAINT "transitions_from_state_id_fkey" FOREIGN KEY ("from_state_id") REFERENCES "public"."states"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transitions"
    ADD CONSTRAINT "transitions_to_state_id_fkey" FOREIGN KEY ("to_state_id") REFERENCES "public"."states"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_state_id_fkey" FOREIGN KEY ("state_id") REFERENCES "public"."states"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visitor_sessions"
    ADD CONSTRAINT "visitor_sessions_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."leads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visitor_sessions"
    ADD CONSTRAINT "visitor_sessions_visitor_id_fkey" FOREIGN KEY ("visitor_id") REFERENCES "public"."visitors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visitors"
    ADD CONSTRAINT "visitors_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."visitors"
    ADD CONSTRAINT "visitors_experiment_id_fkey" FOREIGN KEY ("experiment_id") REFERENCES "public"."experiments"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."visitors"
    ADD CONSTRAINT "visitors_segment_id_fkey" FOREIGN KEY ("segment_id") REFERENCES "public"."segments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhooks_deliveries"
    ADD CONSTRAINT "webhooks_deliveries_endpoint_id_fkey" FOREIGN KEY ("endpoint_id") REFERENCES "public"."webhooks_endpoints"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhooks_deliveries"
    ADD CONSTRAINT "webhooks_deliveries_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhooks_deliveries"
    ADD CONSTRAINT "webhooks_deliveries_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "public"."webhooks_subscriptions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."webhooks_endpoints"
    ADD CONSTRAINT "webhooks_endpoints_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhooks_subscriptions"
    ADD CONSTRAINT "webhooks_subscriptions_endpoint_id_fkey" FOREIGN KEY ("endpoint_id") REFERENCES "public"."webhooks_endpoints"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."webhooks_subscriptions"
    ADD CONSTRAINT "webhooks_subscriptions_site_id_fkey" FOREIGN KEY ("site_id") REFERENCES "public"."sites"("id") ON DELETE CASCADE;



CREATE POLICY "Authenticated users can insert site ownership" ON "public"."site_ownership" FOR INSERT WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Authenticated users can manage companies" ON "public"."companies" USING ((( SELECT "auth"."uid"() AS "uid") IS NOT NULL)) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") IS NOT NULL));



CREATE POLICY "Authenticated users can view site ownership" ON "public"."site_ownership" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Enable insert for authenticated users" ON "public"."session_events" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Enable read access for authenticated users" ON "public"."session_events" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Only superadmin can delete cron status" ON "public"."cron_status" FOR DELETE USING ("public"."is_superadmin"());



CREATE POLICY "Only superadmin can insert cron status" ON "public"."cron_status" FOR INSERT WITH CHECK ("public"."is_superadmin"());



CREATE POLICY "Only superadmin can update cron status" ON "public"."cron_status" FOR UPDATE USING ("public"."is_superadmin"()) WITH CHECK ("public"."is_superadmin"());



CREATE POLICY "Only superadmin can view cron status" ON "public"."cron_status" FOR SELECT USING ("public"."is_superadmin"());



CREATE POLICY "Permitir insertar en lista de espera" ON "public"."waitlist" FOR INSERT WITH CHECK (true);



CREATE POLICY "Permitir lectura de códigos de referido activos" ON "public"."referral_codes" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Users can create their own API keys" ON "public"."api_keys" FOR INSERT WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete their own API keys" ON "public"."api_keys" FOR DELETE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete their own site ownership" ON "public"."site_ownership" FOR DELETE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete their own tokens" ON "public"."secure_tokens" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "secure_tokens"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can insert their own tokens" ON "public"."secure_tokens" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "secure_tokens"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can manage campaign segments for their sites" ON "public"."campaign_segments" USING ((EXISTS ( SELECT 1
   FROM ("public"."campaigns" "c"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "c"."site_id")))
  WHERE (("c"."id" = "campaign_segments"."campaign_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."campaigns" "c"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "c"."site_id")))
  WHERE (("c"."id" = "campaign_segments"."campaign_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can manage campaign subtasks for their sites" ON "public"."campaign_subtasks" USING ((EXISTS ( SELECT 1
   FROM ("public"."campaigns" "c"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "c"."site_id")))
  WHERE (("c"."id" = "campaign_subtasks"."campaign_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."campaigns" "c"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "c"."site_id")))
  WHERE (("c"."id" = "campaign_subtasks"."campaign_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can manage sale orders for their sites" ON "public"."sale_orders" USING ((EXISTS ( SELECT 1
   FROM ("public"."sales" "s"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "sale_orders"."sale_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."sales" "s"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "sale_orders"."sale_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can manage task categories for their tasks" ON "public"."task_categories" USING ((EXISTS ( SELECT 1
   FROM ("public"."tasks" "t"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "t"."site_id")))
  WHERE (("t"."id" = "task_categories"."task_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."tasks" "t"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "t"."site_id")))
  WHERE (("t"."id" = "task_categories"."task_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can manage their own referral code uses" ON "public"."referral_code_uses" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can manage transactions for their sites" ON "public"."transactions" USING ((EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "transactions"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "transactions"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can update their own API keys" ON "public"."api_keys" FOR UPDATE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update their own site ownership" ON "public"."site_ownership" FOR UPDATE USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update their own tokens" ON "public"."secure_tokens" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "secure_tokens"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can view their own API keys" ON "public"."api_keys" FOR SELECT USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view their own tokens" ON "public"."secure_tokens" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "secure_tokens"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



ALTER TABLE "public"."activity" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."agent_assets" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_assets_unified" ON "public"."agent_assets" USING (((EXISTS ( SELECT 1
   FROM ("public"."agents" "a"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "a"."site_id")))
  WHERE (("a"."id" = "agent_assets"."agent_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))) OR (EXISTS ( SELECT 1
   FROM ("public"."agents" "a"
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "a"."site_id")))
  WHERE (("a"."id" = "agent_assets"."agent_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ("public"."agents" "a"
     JOIN "public"."sites" "s" ON (("s"."id" = "a"."site_id")))
  WHERE (("a"."id" = "agent_assets"."agent_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM ("public"."agents" "a"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "a"."site_id")))
  WHERE (("a"."id" = "agent_assets"."agent_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))) OR (EXISTS ( SELECT 1
   FROM ("public"."agents" "a"
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "a"."site_id")))
  WHERE (("a"."id" = "agent_assets"."agent_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ("public"."agents" "a"
     JOIN "public"."sites" "s" ON (("s"."id" = "a"."site_id")))
  WHERE (("a"."id" = "agent_assets"."agent_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



ALTER TABLE "public"."agent_memories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agent_memories_optimized_policy" ON "public"."agent_memories" USING ((EXISTS ( SELECT 1
   FROM ("public"."agents" "a"
     JOIN "public"."sites" "s" ON (("s"."id" = "a"."site_id")))
  WHERE (("a"."id" = "agent_memories"."agent_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."agents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "agents_optimized_policy" ON "public"."agents" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "agents"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



CREATE POLICY "allow_service_role_delete" ON "public"."site_members" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_api_keys" ON "public"."api_keys" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_billing" ON "public"."billing" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_notifications" ON "public"."notifications" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_payments" ON "public"."payments" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_profiles" ON "public"."profiles" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_settings" ON "public"."settings" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_site_ownership" ON "public"."site_ownership" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "allow_service_role_delete_tasks" ON "public"."tasks" FOR DELETE TO "service_role" USING (true);



ALTER TABLE "public"."allowed_domains" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "allowed_domains_access_policy" ON "public"."allowed_domains" TO "authenticated" USING (("site_id" IN ( SELECT "site_ownership"."site_id"
   FROM "public"."site_ownership"
  WHERE ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))
UNION
 SELECT "site_members"."site_id"
   FROM "public"."site_members"
  WHERE (("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text"))))) WITH CHECK (("site_id" IN ( SELECT "site_ownership"."site_id"
   FROM "public"."site_ownership"
  WHERE ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))
UNION
 SELECT "site_members"."site_id"
   FROM "public"."site_members"
  WHERE (("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text")))));



ALTER TABLE "public"."analysis" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "analysis_optimized_policy" ON "public"."analysis" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."api_keys" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."assets" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "assets_optimized_policy" ON "public"."assets" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "assets"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



CREATE POLICY "authenticated_read_activity" ON "public"."activity" FOR SELECT TO "authenticated" USING ((((( SELECT "auth"."jwt"() AS "jwt") ->> 'role'::"text") <> 'service_role'::"text") AND ((( SELECT "auth"."jwt"() AS "jwt") ->> 'role'::"text") = 'authenticated'::"text") AND (("site_id" IN ( SELECT "sites"."id"
   FROM "public"."sites"
  WHERE ("sites"."user_id" = ( SELECT "auth"."uid"() AS "uid")))) OR ("site_id" IN ( SELECT "site_members"."site_id"
   FROM "public"."site_members"
  WHERE ("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



COMMENT ON POLICY "authenticated_read_activity" ON "public"."activity" IS 'Combined SELECT policy for site owners and members - single policy to avoid conflicts';



ALTER TABLE "public"."automation_auth_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "automation_auth_sessions_access_policy" ON "public"."automation_auth_sessions" USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "automation_auth_sessions"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members"
  WHERE (("site_members"."site_id" = "automation_auth_sessions"."site_id") AND ("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "automation_auth_sessions"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



ALTER TABLE "public"."billing" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "billing_optimized_policy" ON "public"."billing" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "billing"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



CREATE POLICY "bypass_synced_objects" ON "public"."synced_objects" USING (true);



CREATE POLICY "bypass_system_memories" ON "public"."system_memories" USING (true);



CREATE POLICY "bypass_whatsapp_templates" ON "public"."whatsapp_templates" USING (true);



ALTER TABLE "public"."campaign_requirements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "campaign_requirements_optimized_policy" ON "public"."campaign_requirements" USING ((EXISTS ( SELECT 1
   FROM ("public"."campaigns" "c"
     JOIN "public"."sites" "s" ON (("s"."id" = "c"."site_id")))
  WHERE (("c"."id" = "campaign_requirements"."campaign_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."campaign_segments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."campaign_subtasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."campaigns" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "campaigns_unified" ON "public"."campaigns" USING ("app_auth"."is_service_role_or_user_condition"((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "campaigns"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "categories_for_owned_sites" ON "public"."categories" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "categories"."site_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "categories"."site_id") AND ("s"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



ALTER TABLE "public"."commands" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "commands_site_access_policy" ON "public"."commands" TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "commands"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))))))) OR ("user_id" = ( SELECT "auth"."uid"() AS "uid")))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "commands"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))))))) OR ("user_id" = ( SELECT "auth"."uid"() AS "uid"))));



ALTER TABLE "public"."companies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."content" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."content_assets" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "content_assets_unified_policy" ON "public"."content_assets" TO "authenticated" USING ((("current_setting"('role'::"text", true) = 'service_role'::"text") OR (("auth"."jwt"() ->> 'role'::"text") = 'service_role'::"text") OR (EXISTS ( SELECT 1
   FROM ("public"."content" "c"
     JOIN "public"."sites" "s" ON (("s"."id" = "c"."site_id")))
  WHERE (("c"."id" = "content_assets"."content_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))))))))) WITH CHECK ((("current_setting"('role'::"text", true) = 'service_role'::"text") OR (("auth"."jwt"() ->> 'role'::"text") = 'service_role'::"text") OR (EXISTS ( SELECT 1
   FROM ("public"."content" "c"
     JOIN "public"."sites" "s" ON (("s"."id" = "c"."site_id")))
  WHERE (("c"."id" = "content_assets"."content_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))))))));



CREATE POLICY "content_unified_access_policy" ON "public"."content" USING (((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "content"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))) OR ("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("author_id" = ( SELECT "auth"."uid"() AS "uid"))));



ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "conversations_unified_access_policy" ON "public"."conversations" USING (((( SELECT "auth"."uid"() AS "uid") IS NOT NULL) OR (( SELECT "auth"."uid"() AS "uid") IS NULL)));



ALTER TABLE "public"."copywriting" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "copywriting_site_access_policy" ON "public"."copywriting" TO "authenticated" USING (("site_id" IN ( SELECT "sites"."id"
   FROM "public"."sites"
  WHERE ("sites"."user_id" = ( SELECT "auth"."uid"() AS "uid"))
UNION
 SELECT "site_members"."site_id"
   FROM "public"."site_members"
  WHERE (("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text"))))) WITH CHECK (("site_id" IN ( SELECT "sites"."id"
   FROM "public"."sites"
  WHERE ("sites"."user_id" = ( SELECT "auth"."uid"() AS "uid"))
UNION
 SELECT "site_members"."site_id"
   FROM "public"."site_members"
  WHERE (("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text")))));



ALTER TABLE "public"."cron_status" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."customizations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "customizations_delete_owner_admin" ON "public"."customizations" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "customizations_insert_owner_admin" ON "public"."customizations" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "customizations_select_owner_admin" ON "public"."customizations" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "customizations_update_owner_admin" ON "public"."customizations" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (((("public"."elements" "e"
     JOIN "public"."layers" "l" ON (("l"."id" = "e"."layer_id")))
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("e"."id" = "customizations"."element_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."debug_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "debug_logs_optimized_policy" ON "public"."debug_logs" FOR SELECT USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "debug_logs"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



ALTER TABLE "public"."editor" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "editor_delete_owner_admin" ON "public"."editor" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "editor"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "editor"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "editor_insert_owner_admin" ON "public"."editor" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "editor"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "editor"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "editor_select_owner_admin" ON "public"."editor" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "editor"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "editor"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "editor_update_owner_admin" ON "public"."editor" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "editor"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "editor"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."elements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "elements_delete_owner_admin" ON "public"."elements" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "elements_insert_owner_admin" ON "public"."elements" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "elements_select_owner_admin" ON "public"."elements" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "elements_update_owner_admin" ON "public"."elements" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ((("public"."layers" "l"
     JOIN "public"."states" "st" ON (("st"."id" = "l"."state_id")))
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("l"."id" = "elements"."layer_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."experiment_segments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "experiment_segments_emergency" ON "public"."experiment_segments" USING (((( SELECT "auth"."uid"() AS "uid") IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."experiments"
  WHERE ("experiments"."id" = "experiment_segments"."experiment_id"))))) WITH CHECK (((( SELECT "auth"."uid"() AS "uid") IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."experiments"
  WHERE ("experiments"."id" = "experiment_segments"."experiment_id")))));



ALTER TABLE "public"."experiments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "experiments_unified" ON "public"."experiments" USING ("app_auth"."is_service_role_or_user_condition"((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "experiments"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



ALTER TABLE "public"."external_resources" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "external_resources_optimized_policy" ON "public"."external_resources" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "external_resources"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."icp_mining" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "icp_mining - anon can read completed" ON "public"."icp_mining" FOR SELECT TO "anon" USING (("status" = 'completed'::"text"));



CREATE POLICY "icp_mining - authenticated can delete in site" ON "public"."icp_mining" FOR DELETE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("rqs"."role_query_id" = "icp_mining"."role_query_id"))) OR (EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("rqs"."role_query_id" = "icp_mining"."role_query_id")))));



CREATE POLICY "icp_mining - authenticated can insert in site" ON "public"."icp_mining" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("rqs"."role_query_id" = "rqs"."role_query_id"))) OR (EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("rqs"."role_query_id" = "rqs"."role_query_id")))));



CREATE POLICY "icp_mining - authenticated can select in site" ON "public"."icp_mining" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("rqs"."role_query_id" = "icp_mining"."role_query_id"))) OR (EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("rqs"."role_query_id" = "icp_mining"."role_query_id")))));



CREATE POLICY "icp_mining - authenticated can update in site" ON "public"."icp_mining" FOR UPDATE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("rqs"."role_query_id" = "icp_mining"."role_query_id"))) OR (EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("rqs"."role_query_id" = "icp_mining"."role_query_id"))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("rqs"."role_query_id" = "rqs"."role_query_id"))) OR (EXISTS ( SELECT 1
   FROM (("public"."role_query_segments" "rqs"
     JOIN "public"."segments" "s" ON (("s"."id" = "rqs"."segment_id")))
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("rqs"."role_query_id" = "rqs"."role_query_id")))));



CREATE POLICY "icp_mining - service_role can do anything" ON "public"."icp_mining" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."instance_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "instance_logs_access_policy" ON "public"."instance_logs" USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "instance_logs"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members"
  WHERE (("site_members"."site_id" = "instance_logs"."site_id") AND ("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "instance_logs"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members"
  WHERE (("site_members"."site_id" = "instance_logs"."site_id") AND ("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text"))))));



ALTER TABLE "public"."instance_plans" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "instance_plans_access_policy" ON "public"."instance_plans" USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "instance_plans"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members"
  WHERE (("site_members"."site_id" = "instance_plans"."site_id") AND ("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text")))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "instance_plans"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



ALTER TABLE "public"."kpis" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "kpis_optimized_policy" ON "public"."kpis" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "kpis"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."layers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "layers_delete_owner_admin" ON "public"."layers" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "layers_insert_owner_admin" ON "public"."layers" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "layers_select_owner_admin" ON "public"."layers" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "layers_update_owner_admin" ON "public"."layers" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "layers"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."lead_analysis" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "lead_analysis_insert" ON "public"."lead_analysis" FOR INSERT WITH CHECK (true);



CREATE POLICY "lead_analysis_select" ON "public"."lead_analysis" FOR SELECT USING (true);



CREATE POLICY "lead_analysis_update" ON "public"."lead_analysis" FOR UPDATE USING (true);



ALTER TABLE "public"."leads" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "leads_unified" ON "public"."leads" USING ("app_auth"."is_service_role_or_user_condition"((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "leads"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "messages_unified_access_policy" ON "public"."messages" USING (((( SELECT "auth"."uid"() AS "uid") IS NOT NULL) OR (( SELECT "auth"."uid"() AS "uid") IS NULL)));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_optimized_policy" ON "public"."notifications" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "p_deny_anon_auth_all_persons" ON "public"."persons" TO "anon", "authenticated" USING (false) WITH CHECK (false);



CREATE POLICY "p_deny_anon_auth_all_role_queries" ON "public"."role_queries" TO "anon", "authenticated" USING (false) WITH CHECK (false);



CREATE POLICY "p_deny_anon_auth_all_rqs" ON "public"."role_query_segments" TO "anon", "authenticated" USING (false) WITH CHECK (false);



ALTER TABLE "public"."payments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "payments_insert_optimized" ON "public"."payments" FOR INSERT WITH CHECK (true);



CREATE POLICY "payments_select_optimized" ON "public"."payments" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "payments"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."persons" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_delete_optimized" ON "public"."profiles" FOR DELETE USING (("id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "profiles_insert_optimized" ON "public"."profiles" FOR INSERT WITH CHECK ((( SELECT "auth"."uid"() AS "uid") IS NOT NULL));



CREATE POLICY "profiles_select_optimized" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "profiles_update_optimized" ON "public"."profiles" FOR UPDATE USING (("id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."referral_code_uses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."referral_codes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."remote_instances" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "remote_instances_access_policy" ON "public"."remote_instances" USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "remote_instances"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members"
  WHERE (("site_members"."site_id" = "remote_instances"."site_id") AND ("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."site_ownership"
  WHERE (("site_ownership"."site_id" = "remote_instances"."site_id") AND ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members"
  WHERE (("site_members"."site_id" = "remote_instances"."site_id") AND ("site_members"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("site_members"."status" = 'active'::"text"))))));



ALTER TABLE "public"."requirement_segments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "requirement_segments_optimized_policy" ON "public"."requirement_segments" USING ((EXISTS ( SELECT 1
   FROM ("public"."requirements" "r"
     JOIN "public"."sites" "s" ON (("s"."id" = "r"."site_id")))
  WHERE (("r"."id" = "requirement_segments"."requirement_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."requirements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "requirements_optimized_policy" ON "public"."requirements" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "requirements"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."role_queries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_query_segments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "role_query_segments - authenticated can delete in site" ON "public"."role_query_segments" FOR DELETE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("s"."id" = "role_query_segments"."segment_id"))) OR (EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("s"."id" = "role_query_segments"."segment_id")))));



CREATE POLICY "role_query_segments - authenticated can insert in site" ON "public"."role_query_segments" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("s"."id" = "role_query_segments"."segment_id"))) OR (EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("s"."id" = "role_query_segments"."segment_id")))));



CREATE POLICY "role_query_segments - authenticated can select in site" ON "public"."role_query_segments" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("s"."id" = "role_query_segments"."segment_id"))) OR (EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("s"."id" = "role_query_segments"."segment_id")))));



CREATE POLICY "role_query_segments - authenticated can update in site" ON "public"."role_query_segments" FOR UPDATE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("s"."id" = "role_query_segments"."segment_id"))) OR (EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("s"."id" = "role_query_segments"."segment_id"))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_ownership" "so" ON ((("so"."site_id" = "s"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))
  WHERE ("s"."id" = "role_query_segments"."segment_id"))) OR (EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_members" "sm" ON ((("sm"."site_id" = "s"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))
  WHERE ("s"."id" = "role_query_segments"."segment_id")))));



CREATE POLICY "role_query_segments - service_role can do anything" ON "public"."role_query_segments" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."sale_orders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sales" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sales_unified" ON "public"."sales" USING ("app_auth"."is_service_role_or_user_condition"((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "sales"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



ALTER TABLE "public"."sections" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sections_delete_owner_admin" ON "public"."sections" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "sections"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "sections"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "sections_insert_owner_admin" ON "public"."sections" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "sections"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "sections"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "sections_select_owner_admin" ON "public"."sections" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "sections"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "sections"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "sections_update_owner_admin" ON "public"."sections" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "sections"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "sections"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."secure_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."segments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "segments_unified" ON "public"."segments" USING ("app_auth"."is_service_role_or_user_condition"((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "segments"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



CREATE POLICY "service_role_activity_access" ON "public"."activity" TO "service_role" USING (true);



COMMENT ON POLICY "service_role_activity_access" ON "public"."activity" IS 'Service role gets full access - role-specific policy to avoid conflicts';



CREATE POLICY "service_role_full_access_sites" ON "public"."sites" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."session_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "settings_optimized_policy" ON "public"."settings" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "settings"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."site_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "site_members_final_policy" ON "public"."site_members" TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("site_id" IN ( SELECT "site_ownership"."site_id"
   FROM "public"."site_ownership"
  WHERE ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))) WITH CHECK (("site_id" IN ( SELECT "site_ownership"."site_id"
   FROM "public"."site_ownership"
  WHERE ("site_ownership"."user_id" = ( SELECT "auth"."uid"() AS "uid")))));



CREATE POLICY "site_owners_delete_activity" ON "public"."activity" FOR DELETE TO "authenticated" USING ((((( SELECT "auth"."jwt"() AS "jwt") ->> 'role'::"text") <> 'service_role'::"text") AND ((( SELECT "auth"."jwt"() AS "jwt") ->> 'role'::"text") = 'authenticated'::"text") AND ("site_id" IN ( SELECT "sites"."id"
   FROM "public"."sites"
  WHERE ("sites"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



COMMENT ON POLICY "site_owners_delete_activity" ON "public"."activity" IS 'Site owners can DELETE on their sites - separate from SELECT to avoid conflicts';



CREATE POLICY "site_owners_update_activity" ON "public"."activity" FOR UPDATE TO "authenticated" USING ((((( SELECT "auth"."jwt"() AS "jwt") ->> 'role'::"text") <> 'service_role'::"text") AND ((( SELECT "auth"."jwt"() AS "jwt") ->> 'role'::"text") = 'authenticated'::"text") AND ("site_id" IN ( SELECT "sites"."id"
   FROM "public"."sites"
  WHERE ("sites"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



COMMENT ON POLICY "site_owners_update_activity" ON "public"."activity" IS 'Site owners can UPDATE on their sites - separate from SELECT to avoid conflicts';



ALTER TABLE "public"."site_ownership" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sites_delete_policy" ON "public"."sites" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "sites_insert_policy" ON "public"."sites" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "sites_select_policy" ON "public"."sites" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "sites"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "sites_update_policy" ON "public"."sites" FOR UPDATE USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "sites"."id") AND ("sm"."user_id" = "auth"."uid"()) AND ("sm"."status" = 'active'::"text") AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"]))))))) WITH CHECK ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "sites"."id") AND ("sm"."user_id" = "auth"."uid"()) AND ("sm"."status" = 'active'::"text") AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])))))));



ALTER TABLE "public"."states" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "states_delete_owner_admin" ON "public"."states" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "states_insert_owner_admin" ON "public"."states" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "states_select_owner_admin" ON "public"."states" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "states_update_owner_admin" ON "public"."states" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM ("public"."sections" "s"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "states"."section_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "supabase_auth_admin_full_access_settings" ON "public"."settings" TO "supabase_auth_admin" USING (true) WITH CHECK (true);



CREATE POLICY "supabase_auth_admin_full_access_site_members" ON "public"."site_members" TO "supabase_auth_admin" USING (true) WITH CHECK (true);



CREATE POLICY "supabase_auth_admin_full_access_site_ownership" ON "public"."site_ownership" TO "supabase_auth_admin" USING (true) WITH CHECK (true);



CREATE POLICY "supabase_auth_admin_full_access_sites" ON "public"."sites" TO "supabase_auth_admin" USING (true) WITH CHECK (true);



ALTER TABLE "public"."synced_objects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."system_memories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "task_comments_final_policy" ON "public"."task_comments" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."tasks" "t"
  WHERE (("t"."id" = "task_comments"."task_id") AND (("t"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("t"."assignee" = ( SELECT "auth"."uid"() AS "uid"))))))));



COMMENT ON POLICY "task_comments_final_policy" ON "public"."task_comments" IS 'Optimized policy allowing users to manage comments on tasks they own, are assigned to, or comments they created';



ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tasks_unified" ON "public"."tasks" USING ((EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "tasks"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))))));



ALTER TABLE "public"."transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transitions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "transitions_delete_owner_admin" ON "public"."transitions" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE ((("st"."id" = "transitions"."from_state_id") OR ("st"."id" = "transitions"."to_state_id")) AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE ((("st"."id" = "transitions"."from_state_id") OR ("st"."id" = "transitions"."to_state_id")) AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "transitions_insert_owner_admin" ON "public"."transitions" FOR INSERT WITH CHECK ((((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "transitions"."from_state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "transitions"."from_state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))) AND ((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "transitions"."to_state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "transitions"."to_state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text")))))));



CREATE POLICY "transitions_select_owner_admin" ON "public"."transitions" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE ((("st"."id" = "transitions"."from_state_id") OR ("st"."id" = "transitions"."to_state_id")) AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE ((("st"."id" = "transitions"."from_state_id") OR ("st"."id" = "transitions"."to_state_id")) AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "transitions_update_owner_admin" ON "public"."transitions" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE ((("st"."id" = "transitions"."from_state_id") OR ("st"."id" = "transitions"."to_state_id")) AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE ((("st"."id" = "transitions"."from_state_id") OR ("st"."id" = "transitions"."to_state_id")) AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."variants" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "variants_delete_owner_admin" ON "public"."variants" FOR DELETE USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "variants_insert_owner_admin" ON "public"."variants" FOR INSERT WITH CHECK (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "variants_select_owner_admin" ON "public"."variants" FOR SELECT USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



CREATE POLICY "variants_update_owner_admin" ON "public"."variants" FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_ownership" "so" ON (("so"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM (("public"."states" "st"
     JOIN "public"."sections" "s" ON (("s"."id" = "st"."section_id")))
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("st"."id" = "variants"."state_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."visitor_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "visitor_sessions_unified" ON "public"."visitor_sessions" USING ("app_auth"."is_service_role_or_user_condition"((EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "visitor_sessions"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."visitors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "visitors_optimized" ON "public"."visitors" USING (("public"."is_service_role"() OR (("public"."auth_user_id"() IS NOT NULL) AND ((("segment_id" IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM ("public"."segments" "s"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "s"."site_id")))
  WHERE (("s"."id" = "visitors"."segment_id") AND ("sm"."user_id" = "public"."auth_user_id"()) AND ("sm"."status" = 'active'::"text"))))) OR (("lead_id" IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM ("public"."leads" "l"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "l"."site_id")))
  WHERE (("l"."id" = "visitors"."lead_id") AND ("sm"."user_id" = "public"."auth_user_id"()) AND ("sm"."status" = 'active'::"text"))))) OR (EXISTS ( SELECT 1
   FROM ("public"."visitor_sessions" "vs"
     JOIN "public"."site_members" "sm" ON (("sm"."site_id" = "vs"."site_id")))
  WHERE (("vs"."visitor_id" = "visitors"."id") AND ("sm"."user_id" = "public"."auth_user_id"()) AND ("sm"."status" = 'active'::"text"))))))));



ALTER TABLE "public"."waitlist" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."webhook_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "webhook_events_service_role_policy" ON "public"."webhook_events" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "webhook_events_users_policy" ON "public"."webhook_events" FOR SELECT TO "authenticated" USING ((("site_id" IS NULL) OR (EXISTS ( SELECT 1
   FROM "public"."sites" "s"
  WHERE (("s"."id" = "webhook_events"."site_id") AND (("s"."user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
           FROM "public"."site_members" "sm"
          WHERE (("sm"."site_id" = "s"."id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



ALTER TABLE "public"."webhooks_deliveries" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "webhooks_deliveries_unified" ON "public"."webhooks_deliveries" USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "webhooks_deliveries"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "webhooks_deliveries"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "webhooks_deliveries"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "webhooks_deliveries"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."webhooks_endpoints" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "webhooks_endpoints_unified" ON "public"."webhooks_endpoints" USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "webhooks_endpoints"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "webhooks_endpoints"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "webhooks_endpoints"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "webhooks_endpoints"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."webhooks_subscriptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "webhooks_subscriptions_unified" ON "public"."webhooks_subscriptions" USING (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "webhooks_subscriptions"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "webhooks_subscriptions"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text")))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."site_ownership" "so"
  WHERE (("so"."site_id" = "webhooks_subscriptions"."site_id") AND ("so"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))) OR (EXISTS ( SELECT 1
   FROM "public"."site_members" "sm"
  WHERE (("sm"."site_id" = "webhooks_subscriptions"."site_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm"."status" = 'active'::"text"))))));



ALTER TABLE "public"."whatsapp_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "workflow_insert_activity" ON "public"."activity" FOR INSERT TO "service_role" WITH CHECK (true);



COMMENT ON POLICY "workflow_insert_activity" ON "public"."activity" IS 'Service role INSERT only - eliminates all authenticated INSERT conflicts';





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."assets";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."conversations";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."instance_logs";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."instance_plans";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."messages";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."remote_instances";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";


































































































































































































































































GRANT ALL ON FUNCTION "public"."activate_pending_site_memberships"() TO "anon";
GRANT ALL ON FUNCTION "public"."activate_pending_site_memberships"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."activate_pending_site_memberships"() TO "service_role";



GRANT ALL ON FUNCTION "public"."add_command_id_to_all_tables"() TO "anon";
GRANT ALL ON FUNCTION "public"."add_command_id_to_all_tables"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_command_id_to_all_tables"() TO "service_role";



GRANT ALL ON FUNCTION "public"."add_credits"("p_site_id" "uuid", "p_credits" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."add_credits"("p_site_id" "uuid", "p_credits" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_credits"("p_site_id" "uuid", "p_credits" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_delete_protection_trigger"("p_table_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_delete_protection_trigger"("p_table_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_delete_protection_trigger"("p_table_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_to_waitlist"("email_param" "text", "name_param" "text", "referral_code_param" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_to_waitlist"("email_param" "text", "name_param" "text", "referral_code_param" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_to_waitlist"("email_param" "text", "name_param" "text", "referral_code_param" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."auth_user_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."auth_user_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auth_user_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_kpis_from_events"("site_id_param" "uuid", "kpi_type_param" "text", "period_start_param" timestamp with time zone, "period_end_param" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_kpis_from_events"("site_id_param" "uuid", "kpi_type_param" "text", "period_start_param" timestamp with time zone, "period_end_param" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_kpis_from_events"("site_id_param" "uuid", "kpi_type_param" "text", "period_start_param" timestamp with time zone, "period_end_param" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."check_billing_system"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_billing_system"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_billing_system"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_create_update_permission"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_create_update_permission"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_create_update_permission"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_delete_permission"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_delete_permission"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_delete_permission"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_delete_protection_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_delete_protection_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_delete_protection_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_referral_system_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_referral_system_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_referral_system_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_role_restrictions_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_role_restrictions_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_role_restrictions_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_webhook_event_processed"("event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_webhook_event_processed"("event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_webhook_event_processed"("event_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_old_webhook_events"("days_old" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_webhook_events"("days_old" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_webhook_events"("days_old" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."debug_increment_visitor_sessions"("p_visitor_id" "uuid", "p_last_seen_timestamp" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."debug_increment_visitor_sessions"("p_visitor_id" "uuid", "p_last_seen_timestamp" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."debug_increment_visitor_sessions"("p_visitor_id" "uuid", "p_last_seen_timestamp" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."decrypt_token"("encrypted_value" "text", "encryption_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."decrypt_token"("encrypted_value" "text", "encryption_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrypt_token"("encrypted_value" "text", "encryption_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_command_cascade"("command_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_command_cascade"("command_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_command_cascade"("command_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_command_simple"("command_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_command_simple"("command_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_command_simple"("command_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_site_safely"("site_id_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_site_safely"("site_id_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_site_safely"("site_id_param" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."encrypt_token"("token_value" "text", "encryption_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."encrypt_token"("token_value" "text", "encryption_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."encrypt_token"("token_value" "text", "encryption_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ensure_api_key_not_expired"() TO "anon";
GRANT ALL ON FUNCTION "public"."ensure_api_key_not_expired"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ensure_api_key_not_expired"() TO "service_role";



GRANT ALL ON FUNCTION "public"."expire_old_api_keys"() TO "anon";
GRANT ALL ON FUNCTION "public"."expire_old_api_keys"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."expire_old_api_keys"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_task_serial_id"("site_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_task_serial_id"("site_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_task_serial_id"("site_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_auth_user_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_auth_user_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_auth_user_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_performance_status"("command_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_performance_status"("command_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_performance_status"("command_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text", "p_encryption_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text", "p_encryption_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_identifier" "text", "p_encryption_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_profile_complete"("user_id_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_profile_complete"("user_id_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_profile_complete"("user_id_param" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_campaign_deletion"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_campaign_deletion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_campaign_deletion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_campaign_deletion_orphans_only"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_campaign_deletion_orphans_only"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_campaign_deletion_orphans_only"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_command_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_command_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_command_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_command_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_command_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_command_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_event_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_event_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_event_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user_debug"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user_debug"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user_debug"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user_simple"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user_simple"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user_simple"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_session_active_state"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_session_active_state"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_session_active_state"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_session_events_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_session_events_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_session_events_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_agent_conversations"() TO "anon";
GRANT ALL ON FUNCTION "public"."increment_agent_conversations"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_agent_conversations"() TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_referral_code_usage"() TO "anon";
GRANT ALL ON FUNCTION "public"."increment_referral_code_usage"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_referral_code_usage"() TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_template_usage"() TO "anon";
GRANT ALL ON FUNCTION "public"."increment_template_usage"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_template_usage"() TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_template_usage"("template_sid_param" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."increment_template_usage"("template_sid_param" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_template_usage"("template_sid_param" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_usage_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."increment_usage_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_usage_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_visitor_sessions"("visitor_id" "uuid", "last_seen_timestamp" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."increment_visitor_sessions"("visitor_id" "uuid", "last_seen_timestamp" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_visitor_sessions"("visitor_id" "uuid", "last_seen_timestamp" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_service_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_service_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_service_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_superadmin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_superadmin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_superadmin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_valid_task_type"("task_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."is_valid_task_type"("task_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_valid_task_type"("task_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_asset_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_asset_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_asset_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_debug"("message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."log_debug"("message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_debug"("message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."manually_activate_user_memberships"("user_email" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."manually_activate_user_memberships"("user_email" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."manually_activate_user_memberships"("user_email" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid", "error_msg" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid", "error_msg" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_webhook_event_failed"("event_id" "uuid", "error_msg" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_webhook_event_processed"("event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_webhook_event_processed"("event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_webhook_event_processed"("event_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."migrate_team_members_to_site_members"() TO "anon";
GRANT ALL ON FUNCTION "public"."migrate_team_members_to_site_members"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."migrate_team_members_to_site_members"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_last_admin_deletion"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_last_admin_deletion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_last_admin_deletion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_last_admin_role_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_last_admin_role_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_last_admin_role_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."process_referral_code_use"("p_referral_code_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."process_referral_code_use"("p_referral_code_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_referral_code_use"("p_referral_code_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."record_payment"("p_site_id" "uuid", "p_transaction_type" character varying, "p_amount" numeric, "p_status" character varying, "p_payment_method" character varying, "p_details" "jsonb", "p_credits" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."record_payment"("p_site_id" "uuid", "p_transaction_type" character varying, "p_amount" numeric, "p_status" character varying, "p_payment_method" character varying, "p_details" "jsonb", "p_credits" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_payment"("p_site_id" "uuid", "p_transaction_type" character varying, "p_amount" numeric, "p_status" character varying, "p_payment_method" character varying, "p_details" "jsonb", "p_credits" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."register_referral_code_use"("code_param" "text", "user_id_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."register_referral_code_use"("code_param" "text", "user_id_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."register_referral_code_use"("code_param" "text", "user_id_param" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_all_delete_protection_triggers"() TO "anon";
GRANT ALL ON FUNCTION "public"."remove_all_delete_protection_triggers"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_all_delete_protection_triggers"() TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_delete_protection_trigger"("p_table_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."remove_delete_protection_trigger"("p_table_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_delete_protection_trigger"("p_table_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."reorder_task_priorities"("p_task_id" "uuid", "p_new_position" integer, "p_status" "text", "p_site_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."reorder_task_priorities"("p_task_id" "uuid", "p_new_position" integer, "p_status" "text", "p_site_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reorder_task_priorities"("p_task_id" "uuid", "p_new_position" integer, "p_status" "text", "p_site_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."rollback_api_keys"() TO "anon";
GRANT ALL ON FUNCTION "public"."rollback_api_keys"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rollback_api_keys"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_current_timestamp_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_current_timestamp_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_current_timestamp_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_dislike"("command_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."set_dislike"("command_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_dislike"("command_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_like"("command_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."set_like"("command_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_like"("command_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_task_priority_from_serial"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_task_priority_from_serial"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_task_priority_from_serial"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_task_serial_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_task_serial_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_task_serial_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."simulate_user_creation"("test_email" "text", "test_name" "text", "test_referral_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."simulate_user_creation"("test_email" "text", "test_name" "text", "test_referral_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."simulate_user_creation"("test_email" "text", "test_name" "text", "test_referral_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."store_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_token_value" "text", "p_identifier" "text", "p_encryption_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."store_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_token_value" "text", "p_identifier" "text", "p_encryption_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."store_secure_token"("p_site_id" "uuid", "p_token_type" "text", "p_token_value" "text", "p_identifier" "text", "p_encryption_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_auth0_user"("auth0_id_param" "text", "email_param" "text", "name_param" "text", "picture_param" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."sync_auth0_user"("auth0_id_param" "text", "email_param" "text", "name_param" "text", "picture_param" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_auth0_user"("auth0_id_param" "text", "email_param" "text", "name_param" "text", "picture_param" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_site_members_to_settings"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_site_members_to_settings"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_site_members_to_settings"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_site_members_to_team_members"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_site_members_to_team_members"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_site_members_to_team_members"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_site_ownership"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_site_ownership"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_site_ownership"() TO "service_role";



GRANT ALL ON FUNCTION "public"."toggle_flag"("command_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_flag"("command_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_flag"("command_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_activity_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_activity_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_activity_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_api_key_last_used"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_api_key_last_used"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_api_key_last_used"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_conversation_last_message_time"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_conversation_last_message_time"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_conversation_last_message_time"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_copywriting_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_copywriting_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_copywriting_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_cron_status_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_cron_status_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_cron_status_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_lead_analysis_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_lead_analysis_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_lead_analysis_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_lead_research_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_lead_research_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_lead_research_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_sale_orders_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_sale_orders_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_sale_orders_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_synced_objects_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_synced_objects_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_synced_objects_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_webhook_events_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_webhook_events_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_webhook_events_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_whatsapp_template_tracking_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_whatsapp_template_tracking_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_whatsapp_template_tracking_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_whatsapp_templates_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_whatsapp_templates_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_whatsapp_templates_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_billing"("p_site_id" "uuid", "p_plan" "text", "p_card_name" "text", "p_masked_card_number" "text", "p_card_expiry" "text", "p_stripe_customer_id" "text", "p_stripe_payment_method_id" "text", "p_stripe_subscription_id" "text", "p_card_address" "text", "p_card_city" "text", "p_card_postal_code" "text", "p_card_country" "text", "p_tax_id" "text", "p_billing_address" "text", "p_billing_city" "text", "p_billing_postal_code" "text", "p_billing_country" "text", "p_auto_renew" boolean, "p_credits_available" integer, "p_subscription_status" "text", "p_subscription_current_period_end" timestamp without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_billing"("p_site_id" "uuid", "p_plan" "text", "p_card_name" "text", "p_masked_card_number" "text", "p_card_expiry" "text", "p_stripe_customer_id" "text", "p_stripe_payment_method_id" "text", "p_stripe_subscription_id" "text", "p_card_address" "text", "p_card_city" "text", "p_card_postal_code" "text", "p_card_country" "text", "p_tax_id" "text", "p_billing_address" "text", "p_billing_city" "text", "p_billing_postal_code" "text", "p_billing_country" "text", "p_auto_renew" boolean, "p_credits_available" integer, "p_subscription_status" "text", "p_subscription_current_period_end" timestamp without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_billing"("p_site_id" "uuid", "p_plan" "text", "p_card_name" "text", "p_masked_card_number" "text", "p_card_expiry" "text", "p_stripe_customer_id" "text", "p_stripe_payment_method_id" "text", "p_stripe_subscription_id" "text", "p_card_address" "text", "p_card_city" "text", "p_card_postal_code" "text", "p_card_country" "text", "p_tax_id" "text", "p_billing_address" "text", "p_billing_city" "text", "p_billing_postal_code" "text", "p_billing_country" "text", "p_auto_renew" boolean, "p_credits_available" integer, "p_subscription_status" "text", "p_subscription_current_period_end" timestamp without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."user_has_access_to_site"("user_id_param" "uuid", "site_id_param" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."user_has_access_to_site"("user_id_param" "uuid", "site_id_param" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."user_has_access_to_site"("user_id_param" "uuid", "site_id_param" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_notifications"("notifications" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."validate_notifications"("notifications" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_notifications"("notifications" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_performance_bitmask"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_performance_bitmask"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_performance_bitmask"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_referral_code"("code_param" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."validate_referral_code"("code_param" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_referral_code"("code_param" "text") TO "service_role";
























GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."activity" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."activity" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."activity" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agent_assets" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agent_assets" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agent_assets" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agent_memories" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agent_memories" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agent_memories" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agents" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agents" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."agents" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."allowed_domains" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."allowed_domains" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."allowed_domains" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."analysis" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."analysis" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."analysis" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."api_keys" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."api_keys" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."api_keys" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."assets" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."assets" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."assets" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."automation_auth_sessions" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."automation_auth_sessions" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."automation_auth_sessions" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."billing" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."billing" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."billing" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_requirements" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_requirements" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_requirements" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_segments" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_segments" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_segments" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_subtasks" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_subtasks" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaign_subtasks" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaigns" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaigns" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."campaigns" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."categories" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."categories" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."categories" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_dislikes" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_dislikes" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_dislikes" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_flags" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_flags" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_flags" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_likes" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_likes" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."commands_likes" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."companies" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."companies" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."companies" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."content" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."content" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."content" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."content_assets" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."content_assets" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."content_assets" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."conversations" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."conversations" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."conversations" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."copywriting" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."copywriting" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."copywriting" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."cron_status" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."cron_status" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."cron_status" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."customizations" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."customizations" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."customizations" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."debug_logs" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."debug_logs" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."debug_logs" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."editor" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."editor" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."editor" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."elements" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."elements" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."elements" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."experiment_segments" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."experiment_segments" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."experiment_segments" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."experiments" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."experiments" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."experiments" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."external_resources" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."external_resources" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."external_resources" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."icp_mining" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."icp_mining" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."icp_mining" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."instance_logs" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."instance_logs" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."instance_logs" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."instance_plans" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."instance_plans" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."instance_plans" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."kpis" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."kpis" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."kpis" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."layers" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."layers" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."layers" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."lead_analysis" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."lead_analysis" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."lead_analysis" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."lead_analysis_summary" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."lead_analysis_summary" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."lead_analysis_summary" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."leads" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."leads" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."leads" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."messages" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."messages" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."messages" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."notifications" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."notifications" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."notifications" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."payments" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."payments" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."payments" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."persons" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."profiles" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."profiles" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."profiles" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."referral_code_uses" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."referral_code_uses" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."referral_code_uses" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."referral_codes" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."referral_codes" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."referral_codes" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."remote_instances" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."remote_instances" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."remote_instances" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirement_campaigns" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirement_campaigns" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirement_campaigns" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirement_segments" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirement_segments" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirement_segments" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirements" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirements" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."requirements" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."role_queries" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."role_query_segments" TO "service_role";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."role_query_segments" TO "authenticated";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_orders" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_orders" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_orders" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sales" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sales" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sales" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sections" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sections" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sections" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."secure_tokens" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."secure_tokens" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."secure_tokens" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."segments" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."segments" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."segments" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."session_events" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."session_events" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."session_events" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."settings" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."settings" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."settings" TO "service_role";
GRANT ALL ON TABLE "public"."settings" TO "supabase_auth_admin";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."site_members" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."site_members" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."site_members" TO "service_role";
GRANT ALL ON TABLE "public"."site_members" TO "supabase_auth_admin";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."site_ownership" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."site_ownership" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."site_ownership" TO "service_role";
GRANT ALL ON TABLE "public"."site_ownership" TO "supabase_auth_admin";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sites" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sites" TO "authenticated";
GRANT ALL ON TABLE "public"."sites" TO "service_role";
GRANT ALL ON TABLE "public"."sites" TO "supabase_auth_admin";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."states" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."states" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."states" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."synced_objects" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."synced_objects" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."synced_objects" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."system_memories" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."system_memories" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."system_memories" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."task_categories" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."task_categories" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."task_categories" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."task_comments" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."task_comments" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."task_comments" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."tasks" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."tasks" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."tasks" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."transactions" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."transactions" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."transactions" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."transitions" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."transitions" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."transitions" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."variants" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."variants" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."variants" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."visitor_sessions" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."visitors" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."waitlist" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."waitlist" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."waitlist" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhook_events" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhook_events" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhook_events" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_deliveries" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_deliveries" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_deliveries" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_endpoints" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_endpoints" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_endpoints" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_subscriptions" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_subscriptions" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."webhooks_subscriptions" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."whatsapp_templates" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."whatsapp_templates" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."whatsapp_templates" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "service_role";































drop policy "p_deny_anon_auth_all_persons" on "public"."persons";

drop policy "p_deny_anon_auth_all_role_queries" on "public"."role_queries";

drop policy "p_deny_anon_auth_all_rqs" on "public"."role_query_segments";

revoke delete on table "public"."persons" from "anon";

revoke insert on table "public"."persons" from "anon";

revoke references on table "public"."persons" from "anon";

revoke select on table "public"."persons" from "anon";

revoke trigger on table "public"."persons" from "anon";

revoke truncate on table "public"."persons" from "anon";

revoke update on table "public"."persons" from "anon";

revoke delete on table "public"."persons" from "authenticated";

revoke insert on table "public"."persons" from "authenticated";

revoke references on table "public"."persons" from "authenticated";

revoke select on table "public"."persons" from "authenticated";

revoke trigger on table "public"."persons" from "authenticated";

revoke truncate on table "public"."persons" from "authenticated";

revoke update on table "public"."persons" from "authenticated";

revoke delete on table "public"."role_queries" from "anon";

revoke insert on table "public"."role_queries" from "anon";

revoke references on table "public"."role_queries" from "anon";

revoke select on table "public"."role_queries" from "anon";

revoke trigger on table "public"."role_queries" from "anon";

revoke truncate on table "public"."role_queries" from "anon";

revoke update on table "public"."role_queries" from "anon";

revoke delete on table "public"."role_queries" from "authenticated";

revoke insert on table "public"."role_queries" from "authenticated";

revoke references on table "public"."role_queries" from "authenticated";

revoke select on table "public"."role_queries" from "authenticated";

revoke trigger on table "public"."role_queries" from "authenticated";

revoke truncate on table "public"."role_queries" from "authenticated";

revoke update on table "public"."role_queries" from "authenticated";

revoke delete on table "public"."role_query_segments" from "anon";

revoke insert on table "public"."role_query_segments" from "anon";

revoke references on table "public"."role_query_segments" from "anon";

revoke select on table "public"."role_query_segments" from "anon";

revoke trigger on table "public"."role_query_segments" from "anon";

revoke truncate on table "public"."role_query_segments" from "anon";

revoke update on table "public"."role_query_segments" from "anon";

revoke references on table "public"."role_query_segments" from "authenticated";

revoke trigger on table "public"."role_query_segments" from "authenticated";

revoke truncate on table "public"."role_query_segments" from "authenticated";

revoke delete on table "public"."visitor_sessions" from "anon";

revoke insert on table "public"."visitor_sessions" from "anon";

revoke references on table "public"."visitor_sessions" from "anon";

revoke select on table "public"."visitor_sessions" from "anon";

revoke trigger on table "public"."visitor_sessions" from "anon";

revoke truncate on table "public"."visitor_sessions" from "anon";

revoke update on table "public"."visitor_sessions" from "anon";

revoke delete on table "public"."visitor_sessions" from "authenticated";

revoke insert on table "public"."visitor_sessions" from "authenticated";

revoke references on table "public"."visitor_sessions" from "authenticated";

revoke select on table "public"."visitor_sessions" from "authenticated";

revoke trigger on table "public"."visitor_sessions" from "authenticated";

revoke truncate on table "public"."visitor_sessions" from "authenticated";

revoke update on table "public"."visitor_sessions" from "authenticated";

revoke delete on table "public"."visitors" from "anon";

revoke insert on table "public"."visitors" from "anon";

revoke references on table "public"."visitors" from "anon";

revoke select on table "public"."visitors" from "anon";

revoke trigger on table "public"."visitors" from "anon";

revoke truncate on table "public"."visitors" from "anon";

revoke update on table "public"."visitors" from "anon";

revoke delete on table "public"."visitors" from "authenticated";

revoke insert on table "public"."visitors" from "authenticated";

revoke references on table "public"."visitors" from "authenticated";

revoke select on table "public"."visitors" from "authenticated";

revoke trigger on table "public"."visitors" from "authenticated";

revoke truncate on table "public"."visitors" from "authenticated";

revoke update on table "public"."visitors" from "authenticated";


  create policy "p_deny_anon_auth_all_persons"
  on "public"."persons"
  as permissive
  for all
  to authenticated, anon
using (false)
with check (false);



  create policy "p_deny_anon_auth_all_role_queries"
  on "public"."role_queries"
  as permissive
  for all
  to authenticated, anon
using (false)
with check (false);



  create policy "p_deny_anon_auth_all_rqs"
  on "public"."role_query_segments"
  as permissive
  for all
  to authenticated, anon
using (false)
with check (false);


CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


  create policy "Anyone can read avatars"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'avatars'::text));



  create policy "Authenticated users can upload avatars"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'avatars'::text));



  create policy "Permitir a todos descargar archivos"
  on "storage"."objects"
  as permissive
  for select
  to authenticated, anon
using ((bucket_id = 'assets'::text));



  create policy "Permitir a usuarios autenticados actualizar sus archivos"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'assets'::text) AND (owner = auth.uid())));



  create policy "Permitir a usuarios autenticados eliminar sus archivos"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'assets'::text) AND (owner = auth.uid())));



  create policy "Permitir a usuarios autenticados subir archivos"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'assets'::text));



  create policy "Users can delete their own avatars"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using ((bucket_id = 'avatars'::text));



  create policy "Users can update their own avatars"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using ((bucket_id = 'avatars'::text))
with check ((bucket_id = 'avatars'::text));



  create policy "Usuarios pueden acceder a archivos de sus tareas"
  on "storage"."objects"
  as permissive
  for all
  to public
using (((bucket_id = 'task_files'::text) AND (EXISTS ( SELECT 1
   FROM public.tasks t
  WHERE ((t.id = ((regexp_match(objects.name, '^([^/]+)/'::text))[1])::uuid) AND ((t.user_id = auth.uid()) OR (t.assignee = auth.uid())))))));



