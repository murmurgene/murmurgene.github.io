WITH table_ddl AS (
  SELECT 
    t.tablename,
    'CREATE TABLE IF NOT EXISTS public.' || quote_ident(t.tablename) || ' (' || chr(10) ||
    (
      SELECT string_agg(
        '  ' || quote_ident(column_name) || ' ' || data_type || 
        CASE WHEN character_maximum_length IS NOT NULL THEN '(' || character_maximum_length || ')' ELSE '' END ||
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
        CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default ELSE '' END,
        ',' || chr(10)
      )
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = t.tablename
    ) || chr(10) || ');' as table_sql
  FROM pg_tables t
  WHERE schemaname = 'public'
),
policy_ddl AS (
  SELECT 
    tablename,
    'ALTER TABLE public.' || quote_ident(tablename) || ' ENABLE ROW LEVEL SECURITY;' || chr(10) ||
    string_agg(
      format('CREATE POLICY %I ON public.%I FOR %s TO %s %s %s;',
        policyname, tablename, cmd, array_to_string(roles, ','), 
        CASE WHEN qual IS NOT NULL THEN 'USING (' || qual || ')' ELSE '' END,
        CASE WHEN with_check IS NOT NULL THEN 'WITH CHECK (' || with_check || ')' ELSE '' END
      ), chr(10)
    ) as policy_sql
  FROM pg_policies 
  WHERE schemaname = 'public'
  GROUP BY tablename
)
SELECT 
  '-- Table: ' || t.tablename || chr(10) ||
  t.table_sql || chr(10) ||
  COALESCE(p.policy_sql, '') as full_sql
FROM table_ddl t
LEFT JOIN policy_ddl p ON t.tablename = p.tablename;

-- Table: ReplacedRns
CREATE TABLE IF NOT EXISTS public."ReplacedRns" (
  id bigint NOT NULL,
  substance_id bigint NOT NULL,
  replaced_rn character varying(12)
);
ALTER TABLE public."ReplacedRns" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write ReplacedRns_delete" ON public."ReplacedRns" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read ReplacedRns" ON public."ReplacedRns" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write ReplacedRns_update" ON public."ReplacedRns" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write ReplacedRns_insert" ON public."ReplacedRns" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: Substance
CREATE TABLE IF NOT EXISTS public."Substance" (
  id bigint NOT NULL,
  cas_rn character varying(12) NOT NULL,
  substance_name text,
  uri character varying(255),
  inchi text,
  inchikey character varying(255),
  smile text,
  molecular_formula text,
  molecular_mass real,
  has_molfile boolean,
  svg_image text,
  created_at timestamp with time zone DEFAULT now(),
  chem_name_kor text,
  en_no text,
  ke_no text,
  un_no text,
  kosha_chem_id text,
  last_msds_check timestamp with time zone,
  canonical_smiles text,
  school_hazardous_chemical_standard text,
  special_health_checkup_hazardous_factor_standard text,
  toxic_substance_standard text,
  permitted_substance_standard text,
  restricted_substance_standard text,
  prohibited_substance_standard text,
  school_accident_precaution_chemical_standard text,
  cas_mod text,
  chem_name_kor_mod text,
  substance_name_mod text,
  molecular_formula_mod text
);
ALTER TABLE public."Substance" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write Substance_delete" ON public."Substance" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read Substance" ON public."Substance" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write Substance_insert" ON public."Substance" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write Substance_update" ON public."Substance" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: tools
CREATE TABLE IF NOT EXISTS public.tools (
  id bigint NOT NULL,
  user_id uuid DEFAULT auth.uid(),
  tools_name text NOT NULL,
  tools_category text NOT NULL,
  stock integer NOT NULL DEFAULT 0,
  purchase_date date,
  location jsonb,
  image_url text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  tools_section text DEFAULT '교구'::text,
  tools_no integer,
  stock_period text DEFAULT '과학(2025)'::text,
  tools_code text,
  specification text,
  using_class text DEFAULT '전학년'::text,
  standard_amount text,
  requirement integer DEFAULT 0,
  proportion double precision,
  recommended text DEFAULT '필수'::text,
  out_of_standard text DEFAULT '기준내'::text
);
ALTER TABLE public.tools ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write tools_update" ON public.tools FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read tools" ON public.tools FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write tools_delete" ON public.tools FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write tools_insert" ON public.tools FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: safety_content
CREATE TABLE IF NOT EXISTS public.safety_content (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  category text NOT NULL,
  title text NOT NULL,
  content_type text NOT NULL,
  external_id text NOT NULL,
  display_order integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.safety_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read safety_content" ON public.safety_content FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write safety_content_delete" ON public.safety_content FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write safety_content_insert" ON public.safety_content FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write safety_content_update" ON public.safety_content FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: lab_rooms
CREATE TABLE IF NOT EXISTS public.lab_rooms (
  id bigint NOT NULL,
  room_name text NOT NULL,
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  user_id uuid
);
ALTER TABLE public.lab_rooms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write lab_rooms_delete" ON public.lab_rooms FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write lab_rooms_insert" ON public.lab_rooms FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_rooms_update" ON public.lab_rooms FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read lab_rooms" ON public.lab_rooms FOR SELECT TO public USING (true) ;

-- Table: lab_class_counts
CREATE TABLE IF NOT EXISTS public.lab_class_counts (
  id bigint NOT NULL,
  semester_id bigint,
  grade integer NOT NULL,
  class_count integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.lab_class_counts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write lab_class_counts_update" ON public.lab_class_counts FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read lab_class_counts" ON public.lab_class_counts FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write lab_class_counts_delete" ON public.lab_class_counts FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write lab_class_counts_insert" ON public.lab_class_counts FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: lab_teachers
CREATE TABLE IF NOT EXISTS public.lab_teachers (
  id bigint NOT NULL,
  semester_id bigint,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.lab_teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write lab_teachers_insert" ON public.lab_teachers FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_teachers_update" ON public.lab_teachers FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read lab_teachers" ON public.lab_teachers FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write lab_teachers_delete" ON public.lab_teachers FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;

-- Table: lab_usage_log
CREATE TABLE IF NOT EXISTS public.lab_usage_log (
  id bigint NOT NULL,
  lab_room_id bigint,
  usage_date date NOT NULL,
  period text NOT NULL,
  activity_type text NOT NULL,
  subject_id bigint,
  grade text,
  class_number integer,
  teacher_id bigint,
  club_id bigint,
  content text,
  safety_education text DEFAULT '실시'::text,
  remarks text,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  applicant_name text,
  phone_number text,
  participant_count integer,
  semester_id bigint
);
ALTER TABLE public.lab_usage_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read lab_usage_log" ON public.lab_usage_log FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write lab_usage_log_update" ON public.lab_usage_log FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_usage_log_delete" ON public.lab_usage_log FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write lab_usage_log_insert" ON public.lab_usage_log FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: HazardList
CREATE TABLE IF NOT EXISTS public."HazardList" (
  id bigint NOT NULL,
  cas_nos text,
  chem_name text,
  school_hazardous_standard text,
  school_accident_precaution_standard text,
  special_health_standard text,
  toxic_standard text,
  permitted_standard text,
  restricted_standard text,
  prohibited_standard text,
  hazard_class text
);
ALTER TABLE public."HazardList" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write HazardList_delete" ON public."HazardList" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write HazardList_insert" ON public."HazardList" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write HazardList_update" ON public."HazardList" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read HazardList" ON public."HazardList" FOR SELECT TO public USING (true) ;

-- Table: Inventory
CREATE TABLE IF NOT EXISTS public."Inventory" (
  id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  substance_id bigint NOT NULL,
  bottle_identifier character varying(255),
  lot_number character varying(255),
  supplier character varying(255),
  initial_amount numeric,
  current_amount numeric,
  unit character varying(10) DEFAULT NULL::character varying,
  purchase_date date,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  classification character varying(50),
  state character varying(50),
  concentration_value numeric,
  concentration_unit character varying(10),
  manufacturer character varying(255),
  bottle_type text,
  cabinet_id bigint,
  door_vertical character varying(10),
  door_horizontal character varying(10),
  internal_shelf_level integer,
  storage_column integer,
  photo_url_320 text,
  photo_url_160 text,
  updated_at timestamp with time zone,
  user_id uuid,
  status text DEFAULT '사용중'::text,
  msds_pdf_url text,
  msds_pdf_hash text,
  converted_concentration_value_1 double precision,
  converted_concentration_unit_1 text,
  converted_concentration_value_2 double precision,
  converted_concentration_unit_2 text,
  school_hazardous_chemical text,
  special_health_checkup_hazardous_factor text,
  toxic_substance text,
  permitted_substance text,
  restricted_substance text,
  prohibited_substance text,
  school_accident_precaution_chemical text,
  bottle_mass numeric,
  valence integer DEFAULT 1,
  edited_name_kor text
);
ALTER TABLE public."Inventory" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read Inventory" ON public."Inventory" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write Inventory_delete" ON public."Inventory" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write Inventory_insert" ON public."Inventory" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write Inventory_update" ON public."Inventory" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: lab_semesters
CREATE TABLE IF NOT EXISTS public.lab_semesters (
  id bigint NOT NULL,
  name text NOT NULL,
  start_date date,
  end_date date,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.lab_semesters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write lab_semesters_update" ON public.lab_semesters FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read lab_semesters" ON public.lab_semesters FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write lab_semesters_insert" ON public.lab_semesters FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_semesters_delete" ON public.lab_semesters FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;

-- Table: tools_usage_log
CREATE TABLE IF NOT EXISTS public.tools_usage_log (
  id bigint NOT NULL,
  tools_id bigint NOT NULL,
  user_id uuid DEFAULT auth.uid(),
  change_amount integer NOT NULL,
  final_quantity integer NOT NULL,
  reason text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.tools_usage_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write tools_usage_log_delete" ON public.tools_usage_log FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write tools_usage_log_insert" ON public.tools_usage_log FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write tools_usage_log_update" ON public.tools_usage_log FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read tools_usage_log" ON public.tools_usage_log FOR SELECT TO public USING (true) ;

-- Table: lab_manual_content
CREATE TABLE IF NOT EXISTS public.lab_manual_content (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  section_title text NOT NULL,
  caption text NOT NULL,
  image_url text NOT NULL,
  display_order integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.lab_manual_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write lab_manual_content_insert" ON public.lab_manual_content FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read lab_manual_content" ON public.lab_manual_content FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write lab_manual_content_update" ON public.lab_manual_content FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_manual_content_delete" ON public.lab_manual_content FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;

-- Table: Citations
CREATE TABLE IF NOT EXISTS public."Citations" (
  id bigint NOT NULL,
  substance_id bigint,
  source text,
  url text,
  source_number integer
);
ALTER TABLE public."Citations" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write Citations_insert" ON public."Citations" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write Citations_delete" ON public."Citations" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read Citations" ON public."Citations" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write Citations_update" ON public."Citations" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: MSDS
CREATE TABLE IF NOT EXISTS public."MSDS" (
  id bigint NOT NULL,
  substance_id bigint NOT NULL,
  section_number integer NOT NULL,
  content text
);
ALTER TABLE public."MSDS" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read MSDS" ON public."MSDS" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write MSDS_delete" ON public."MSDS" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write MSDS_insert" ON public."MSDS" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write MSDS_update" ON public."MSDS" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: HazardClassifications
CREATE TABLE IF NOT EXISTS public."HazardClassifications" (
  id bigint NOT NULL,
  substance_id bigint NOT NULL,
  "sbstnClsfTypeNm" text,
  "unqNo" text,
  "contInfo" text,
  "ancmntInfo" text,
  "ancmntYmd" date
);
ALTER TABLE public."HazardClassifications" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write HazardClassifications_delete" ON public."HazardClassifications" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write HazardClassifications_insert" ON public."HazardClassifications" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write HazardClassifications_update" ON public."HazardClassifications" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read HazardClassifications" ON public."HazardClassifications" FOR SELECT TO public USING (true) ;

-- Table: WasteLog
CREATE TABLE IF NOT EXISTS public."WasteLog" (
  id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  date date NOT NULL,
  classification text NOT NULL,
  amount numeric NOT NULL,
  total_mass_log numeric,
  unit text DEFAULT 'g'::text,
  manager text,
  remarks text,
  disposal_id uuid
);
ALTER TABLE public."WasteLog" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write WasteLog_delete" ON public."WasteLog" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write WasteLog_insert" ON public."WasteLog" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write WasteLog_update" ON public."WasteLog" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read WasteLog" ON public."WasteLog" FOR SELECT TO public USING (true) ;

-- Table: user_kits
CREATE TABLE IF NOT EXISTS public.user_kits (
  id bigint NOT NULL,
  kit_id bigint,
  kit_name text NOT NULL,
  kit_class text,
  quantity integer DEFAULT 1,
  purchase_date date,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  image_url text,
  location text,
  status text,
  kit_person smallint,
  user_id uuid
);
ALTER TABLE public.user_kits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read user_kits" ON public.user_kits FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write user_kits_insert" ON public.user_kits FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write user_kits_update" ON public.user_kits FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write user_kits_delete" ON public.user_kits FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;

-- Table: experiment_kit
CREATE TABLE IF NOT EXISTS public.experiment_kit (
  id bigint NOT NULL,
  kit_name text NOT NULL,
  kit_class text,
  kit_cas text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  kit_person smallint
);
ALTER TABLE public.experiment_kit ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write experiment_kit_delete" ON public.experiment_kit FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read experiment_kit" ON public.experiment_kit FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write experiment_kit_update" ON public.experiment_kit FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write experiment_kit_insert" ON public.experiment_kit FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: SubstanceRef
CREATE TABLE IF NOT EXISTS public."SubstanceRef" (
  id bigint NOT NULL,
  cas_ref text,
  chem_name_kor_ref text,
  substance_name_ref text,
  molecular_formula_ref text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  valence_ref integer,
  molecular_mass_ref numeric
);
ALTER TABLE public."SubstanceRef" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write SubstanceRef_insert" ON public."SubstanceRef" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write SubstanceRef_delete" ON public."SubstanceRef" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read SubstanceRef" ON public."SubstanceRef" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write SubstanceRef_update" ON public."SubstanceRef" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: EquipmentCabinet
CREATE TABLE IF NOT EXISTS public."EquipmentCabinet" (
  id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  area_id bigint,
  cabinet_name text NOT NULL,
  photo_url_320 text,
  photo_url_160 text,
  door_vertical_count integer
);
ALTER TABLE public."EquipmentCabinet" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read EquipmentCabinet" ON public."EquipmentCabinet" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write EquipmentCabinet_delete" ON public."EquipmentCabinet" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write EquipmentCabinet_insert" ON public."EquipmentCabinet" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write EquipmentCabinet_update" ON public."EquipmentCabinet" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: kit_chemicals
CREATE TABLE IF NOT EXISTS public.kit_chemicals (
  id bigint NOT NULL,
  cas_no text NOT NULL,
  name_ko text,
  name_en text,
  formula text,
  molecular_weight text,
  msds_data jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.kit_chemicals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write kit_chemicals_delete" ON public.kit_chemicals FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read kit_chemicals" ON public.kit_chemicals FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write kit_chemicals_update" ON public.kit_chemicals FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write kit_chemicals_insert" ON public.kit_chemicals FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: kit_usage_log
CREATE TABLE IF NOT EXISTS public.kit_usage_log (
  id bigint NOT NULL,
  user_kit_id bigint,
  change_amount integer NOT NULL,
  log_date date NOT NULL DEFAULT CURRENT_DATE,
  log_type text,
  created_at timestamp with time zone DEFAULT now(),
  user_id uuid
);
ALTER TABLE public.kit_usage_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write kit_usage_log_delete" ON public.kit_usage_log FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read kit_usage_log" ON public.kit_usage_log FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write kit_usage_log_insert" ON public.kit_usage_log FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write kit_usage_log_update" ON public.kit_usage_log FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL,
  email text,
  role text DEFAULT 'guest'::text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT TO public USING (true) ;
CREATE POLICY "Admins can update profiles" ON public.profiles FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) = id)) ;

-- Table: Properties
CREATE TABLE IF NOT EXISTS public."Properties" (
  id bigint NOT NULL,
  substance_id bigint,
  name text,
  property text,
  units text,
  type text,
  source_number integer
);
ALTER TABLE public."Properties" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write Properties_delete" ON public."Properties" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read Properties" ON public."Properties" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write Properties_update" ON public."Properties" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write Properties_insert" ON public."Properties" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: Cabinet
CREATE TABLE IF NOT EXISTS public."Cabinet" (
  id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  area_id bigint NOT NULL,
  cabinet_name character varying(255) NOT NULL,
  door_vertical_count integer NOT NULL DEFAULT 1,
  door_horizontal_count integer NOT NULL DEFAULT 1,
  shelf_height integer NOT NULL DEFAULT 3,
  storage_columns integer NOT NULL DEFAULT 6,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  user_id uuid,
  photo_url_320 text,
  photo_url_160 text
);
ALTER TABLE public."Cabinet" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write Cabinet_delete" ON public."Cabinet" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read Cabinet" ON public."Cabinet" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write Cabinet_update" ON public."Cabinet" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write Cabinet_insert" ON public."Cabinet" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: Synonyms
CREATE TABLE IF NOT EXISTS public."Synonyms" (
  id bigint NOT NULL,
  substance_id bigint NOT NULL,
  synonyms_name character varying(255),
  synonyms_eng text
);
ALTER TABLE public."Synonyms" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write Synonyms_delete" ON public."Synonyms" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read Synonyms" ON public."Synonyms" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write Synonyms_update" ON public."Synonyms" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write Synonyms_insert" ON public."Synonyms" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: UsageLog
CREATE TABLE IF NOT EXISTS public."UsageLog" (
  id bigint NOT NULL,
  inventory_id bigint NOT NULL,
  usage_date date NOT NULL DEFAULT CURRENT_DATE,
  subject text NOT NULL,
  period text NOT NULL,
  amount numeric NOT NULL,
  unit text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public."UsageLog" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write UsageLog_update" ON public."UsageLog" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write UsageLog_delete" ON public."UsageLog" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read UsageLog" ON public."UsageLog" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write UsageLog_insert" ON public."UsageLog" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: WasteDisposal
CREATE TABLE IF NOT EXISTS public."WasteDisposal" (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  date date NOT NULL,
  classification text NOT NULL,
  total_amount numeric NOT NULL,
  company_name text,
  manager text
);
ALTER TABLE public."WasteDisposal" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read WasteDisposal" ON public."WasteDisposal" FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write WasteDisposal_delete" ON public."WasteDisposal" FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write WasteDisposal_insert" ON public."WasteDisposal" FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write WasteDisposal_update" ON public."WasteDisposal" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: global_settings
CREATE TABLE IF NOT EXISTS public.global_settings (
  key text NOT NULL,
  value text,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);
ALTER TABLE public.global_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write global_settings_update" ON public.global_settings FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read global_settings" ON public.global_settings FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write global_settings_delete" ON public.global_settings FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write global_settings_insert" ON public.global_settings FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: lab_clubs
CREATE TABLE IF NOT EXISTS public.lab_clubs (
  id bigint NOT NULL,
  semester_id bigint,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.lab_clubs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write lab_clubs_insert" ON public.lab_clubs FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_clubs_delete" ON public.lab_clubs FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Public Read lab_clubs" ON public.lab_clubs FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write lab_clubs_update" ON public.lab_clubs FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: lab_subjects
CREATE TABLE IF NOT EXISTS public.lab_subjects (
  id bigint NOT NULL,
  semester_id bigint,
  name text NOT NULL,
  created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.lab_subjects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read lab_subjects" ON public.lab_subjects FOR SELECT TO public USING (true) ;
CREATE POLICY "Auth Write lab_subjects_update" ON public.lab_subjects FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_subjects_delete" ON public.lab_subjects FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write lab_subjects_insert" ON public.lab_subjects FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));

-- Table: lab_timetables
CREATE TABLE IF NOT EXISTS public.lab_timetables (
  id bigint NOT NULL,
  semester_id bigint,
  teacher_id bigint,
  day_of_week text NOT NULL,
  period integer NOT NULL,
  grade integer,
  class_number integer,
  subject_id bigint,
  valid_from date NOT NULL,
  valid_to date NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  lab_room_id bigint
);
ALTER TABLE public.lab_timetables ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth Write lab_timetables_update" ON public.lab_timetables FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Auth Write lab_timetables_delete" ON public.lab_timetables FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) IS NOT NULL)) ;
CREATE POLICY "Auth Write lab_timetables_insert" ON public.lab_timetables FOR INSERT TO authenticated  WITH CHECK ((( SELECT auth.uid() AS uid) IS NOT NULL));
CREATE POLICY "Public Read lab_timetables" ON public.lab_timetables FOR SELECT TO public USING (true) ;

-- [Storage Buckets ?앹꽦]

INSERT INTO storage.buckets (id, name, public) 
VALUES ('cabinet-photos', 'cabinet-photos', true) 
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('kit-photos', 'kit-photos', true) 
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('msds-pdf', 'msds-pdf', true) 
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('reagent-photos', 'reagent-photos', true) 
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('lab_manual_images', 'lab_manual_images', true) 
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('tools-photo', 'tools-photo', true) 
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('equipment-cabinets', 'equipment-cabinets', true) 
ON CONFLICT (id) DO NOTHING;

-- [Primary Keys]
ALTER TABLE public."ReplacedRns" ADD PRIMARY KEY (id);
ALTER TABLE public."Substance" ADD PRIMARY KEY (id);
ALTER TABLE public.tools ADD PRIMARY KEY (id);
ALTER TABLE public.safety_content ADD PRIMARY KEY (id);
ALTER TABLE public.lab_rooms ADD PRIMARY KEY (id);
ALTER TABLE public.lab_class_counts ADD PRIMARY KEY (id);
ALTER TABLE public.lab_teachers ADD PRIMARY KEY (id);
ALTER TABLE public.lab_usage_log ADD PRIMARY KEY (id);
ALTER TABLE public."HazardList" ADD PRIMARY KEY (id);
ALTER TABLE public."Inventory" ADD PRIMARY KEY (id);
ALTER TABLE public.lab_semesters ADD PRIMARY KEY (id);
ALTER TABLE public.tools_usage_log ADD PRIMARY KEY (id);
ALTER TABLE public.lab_manual_content ADD PRIMARY KEY (id);
ALTER TABLE public."Citations" ADD PRIMARY KEY (id);
ALTER TABLE public."MSDS" ADD PRIMARY KEY (id);
ALTER TABLE public."HazardClassifications" ADD PRIMARY KEY (id);
ALTER TABLE public."WasteLog" ADD PRIMARY KEY (id);
ALTER TABLE public.user_kits ADD PRIMARY KEY (id);
ALTER TABLE public.experiment_kit ADD PRIMARY KEY (id);
ALTER TABLE public."SubstanceRef" ADD PRIMARY KEY (id);
ALTER TABLE public."EquipmentCabinet" ADD PRIMARY KEY (id);
ALTER TABLE public.kit_chemicals ADD PRIMARY KEY (id);
ALTER TABLE public.kit_usage_log ADD PRIMARY KEY (id);
ALTER TABLE public.profiles ADD PRIMARY KEY (id);
ALTER TABLE public."Properties" ADD PRIMARY KEY (id);
ALTER TABLE public."Cabinet" ADD PRIMARY KEY (id);
ALTER TABLE public."Synonyms" ADD PRIMARY KEY (id);
ALTER TABLE public."UsageLog" ADD PRIMARY KEY (id);
ALTER TABLE public."WasteDisposal" ADD PRIMARY KEY (id);
ALTER TABLE public.global_settings ADD PRIMARY KEY (key);
ALTER TABLE public.lab_clubs ADD PRIMARY KEY (id);
ALTER TABLE public.lab_subjects ADD PRIMARY KEY (id);
ALTER TABLE public.lab_timetables ADD PRIMARY KEY (id);


-- [Foreign Keys for Relationships]
-- 1. Inventory Relations
ALTER TABLE public."Inventory" ADD CONSTRAINT "Inventory_substance_id_fkey" FOREIGN KEY (substance_id) REFERENCES public."Substance"(id);
ALTER TABLE public."Inventory" ADD CONSTRAINT "Inventory_cabinet_id_fkey" FOREIGN KEY (cabinet_id) REFERENCES public."Cabinet"(id);

-- 2. Synonyms Relations
ALTER TABLE public."Synonyms" ADD CONSTRAINT "Synonyms_substance_id_fkey" FOREIGN KEY (substance_id) REFERENCES public."Substance"(id);

-- 3. ReplacedRns Relations (Naming matches query hint: ReplacedRns_substance_id_fkey)
ALTER TABLE public."ReplacedRns" ADD CONSTRAINT "ReplacedRns_substance_id_fkey" FOREIGN KEY (substance_id) REFERENCES public."Substance"(id);

-- 4. Cabinet Relations (Naming matches query hint: fk_cabinet_lab_rooms)
ALTER TABLE public."Cabinet" ADD CONSTRAINT "fk_cabinet_lab_rooms" FOREIGN KEY (area_id) REFERENCES public.lab_rooms(id);

-- Additional implied constraints (optional but recommended)
ALTER TABLE public."MSDS" ADD CONSTRAINT "MSDS_substance_id_fkey" FOREIGN KEY (substance_id) REFERENCES public."Substance"(id);
ALTER TABLE public."Properties" ADD CONSTRAINT "Properties_substance_id_fkey" FOREIGN KEY (substance_id) REFERENCES public."Substance"(id);

-- [Storage RLS Policies Reset & Create]
DROP POLICY IF EXISTS "Public Access cabinet-photos" ON storage.objects;
CREATE POLICY "Public Access cabinet-photos" ON storage.objects FOR ALL TO public USING (bucket_id = 'cabinet-photos') WITH CHECK (bucket_id = 'cabinet-photos');

DROP POLICY IF EXISTS "Public Access kit-photos" ON storage.objects;
CREATE POLICY "Public Access kit-photos" ON storage.objects FOR ALL TO public USING (bucket_id = 'kit-photos') WITH CHECK (bucket_id = 'kit-photos');

DROP POLICY IF EXISTS "Public Access msds-pdf" ON storage.objects;
CREATE POLICY "Public Access msds-pdf" ON storage.objects FOR ALL TO public USING (bucket_id = 'msds-pdf') WITH CHECK (bucket_id = 'msds-pdf');

DROP POLICY IF EXISTS "Public Access reagent-photos" ON storage.objects;
CREATE POLICY "Public Access reagent-photos" ON storage.objects FOR ALL TO public USING (bucket_id = 'reagent-photos') WITH CHECK (bucket_id = 'reagent-photos');

DROP POLICY IF EXISTS "Public Access tools-photo" ON storage.objects;
CREATE POLICY "Public Access tools-photo" ON storage.objects FOR ALL TO public USING (bucket_id = 'tools-photo') WITH CHECK (bucket_id = 'tools-photo');

DROP POLICY IF EXISTS "Public Access equipment-cabinets" ON storage.objects;
CREATE POLICY "Public Access equipment-cabinets" ON storage.objects FOR ALL TO public USING (bucket_id = 'equipment-cabinets') WITH CHECK (bucket_id = 'equipment-cabinets');

DROP POLICY IF EXISTS "Public Access lab_manual_images" ON storage.objects;
CREATE POLICY "Public Access lab_manual_images" ON storage.objects FOR ALL TO public USING (bucket_id = 'lab_manual_images') WITH CHECK (bucket_id = 'lab_manual_images');

-- [Grant Permissions used by Supabase]
-- 스키마 초기화 시 기본 권한이 날아가므로, anon/authenticated 역할에 대한 권한을 다시 부여해야 합니다.
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- [Seed Users]
-- 비밀번호는 모두 '12341234'로 설정됩니다.
-- 이 스크립트는 auth.users 테이블에 직접 insert하므로 Supabase SQL Editor에서 실행해야 합니다.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Admin User (admin@goe.sci)
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, 
    confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000', 
    'a0000000-0000-0000-0000-000000000001', 
    'authenticated', 'authenticated', 'admin@goe.sci', 
    crypt('1234567890', gen_salt('bf')), 
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 
    '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 2. Teacher User (teacher@goe.sci)
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, 
    confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000', 
    'a0000000-0000-0000-0000-000000000002', 
    'authenticated', 'authenticated', 'teacher@goe.sci', 
    crypt('1234567890', gen_salt('bf')), 
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 
    '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 3. Student User (student@goe.sci)
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at, 
    confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000', 
    'a0000000-0000-0000-0000-000000000003', 
    'authenticated', 'authenticated', 'student@goe.sci', 
    crypt('1234', gen_salt('bf')), 
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), 
    '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- 4. Public Profiles 연결 (User ID와 매칭)
-- roles: admin / teacher / student (기본값 guest 대신 지정)
INSERT INTO public.profiles (id, email, role)
VALUES 
('a0000000-0000-0000-0000-000000000001', 'admin@goe.sci', 'admin'),
('a0000000-0000-0000-0000-000000000002', 'teacher@goe.sci', 'teacher'),
('a0000000-0000-0000-0000-000000000003', 'student@goe.sci', 'student')
ON CONFLICT (id) DO UPDATE SET 
    role = EXCLUDED.role,
    email = EXCLUDED.email;
