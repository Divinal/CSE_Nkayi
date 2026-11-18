-- Messages envoyés depuis la page Contact du site public.
-- Un visiteur (non connecté) peut seulement en déposer un : il ne peut ni les
-- lire, ni les modifier. L'administration les consulte dans « Messages du site »
-- et reçoit une notification à chaque nouveau message.

CREATE TABLE IF NOT EXISTS public.contact_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL CHECK (char_length(btrim(name)) BETWEEN 2 AND 120),
  email TEXT CHECK (
    email IS NULL
    OR (char_length(email) <= 200 AND email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
  ),
  phone TEXT CHECK (phone IS NULL OR char_length(btrim(phone)) BETWEEN 6 AND 30),
  subject TEXT NOT NULL DEFAULT 'Renseignement' CHECK (
    subject IN ('Inscription', 'Renseignement', 'Scolarité et frais', 'Vie scolaire', 'Autre')
  ),
  message TEXT NOT NULL CHECK (char_length(btrim(message)) BETWEEN 5 AND 3000),
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), 
  -- Il faut pouvoir répondre : un email ou un téléphone au minimum.
  CONSTRAINT contact_messages_reachable CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_contact_messages_date ON public.contact_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contact_messages_unread ON public.contact_messages(created_at DESC) WHERE NOT is_read;

ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;

-- Dépôt d'un message par n'importe quel visiteur.
DROP POLICY IF EXISTS "Visitors send contact messages" ON public.contact_messages;
CREATE POLICY "Visitors send contact messages" ON public.contact_messages
FOR INSERT TO anon, authenticated
WITH CHECK (is_read = false);

-- Lecture, marquage « lu » et suppression : administration uniquement.
DROP POLICY IF EXISTS "Staff manage contact messages" ON public.contact_messages;
CREATE POLICY "Staff manage contact messages" ON public.contact_messages
FOR ALL TO authenticated
USING (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'academic_admin')
  OR public.has_role(auth.uid(), 'admin_secretaire')
)
WITH CHECK (
  public.has_role(auth.uid(), 'admin') OR public.has_role(auth.uid(), 'academic_admin')
  OR public.has_role(auth.uid(), 'admin_secretaire')
);

-- Un visiteur ne choisit que le contenu du message (pas la date ni le statut).
REVOKE ALL ON public.contact_messages FROM anon, authenticated;
GRANT INSERT (name, email, phone, subject, message) ON public.contact_messages TO anon, authenticated;
GRANT SELECT, DELETE ON public.contact_messages TO authenticated;
GRANT UPDATE (is_read) ON public.contact_messages TO authenticated;

-- Anti-envoi en masse : 3 messages max. par expéditeur et 30 au total par tranche de 10 minutes.
CREATE OR REPLACE FUNCTION public.contact_messages_flood_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  NEW.name := btrim(NEW.name);
  NEW.email := NULLIF(lower(btrim(COALESCE(NEW.email, ''))), '');
  NEW.phone := NULLIF(btrim(COALESCE(NEW.phone, '')), '');
  NEW.message := btrim(NEW.message);

  IF (
    SELECT count(*) FROM public.contact_messages
    WHERE created_at > now() - interval '10 minutes'
      AND ((NEW.email IS NOT NULL AND email = NEW.email) OR (NEW.phone IS NOT NULL AND phone = NEW.phone))
  ) >= 3 THEN
    RAISE EXCEPTION 'Trop de messages envoyés. Merci de patienter quelques minutes.' USING ERRCODE = 'P0001';
  END IF;

  IF (SELECT count(*) FROM public.contact_messages WHERE created_at > now() - interval '10 minutes') >= 30 THEN
    RAISE EXCEPTION 'Le formulaire est momentanément saturé. Merci de réessayer plus tard.' USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS contact_messages_flood_guard ON public.contact_messages;
CREATE TRIGGER contact_messages_flood_guard BEFORE INSERT ON public.contact_messages
FOR EACH ROW EXECUTE FUNCTION public.contact_messages_flood_guard();

-- Nouveau type de notification : un message reçu depuis le site.
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check CHECK (
  type IN ('message', 'payment', 'payslip', 'grade', 'exam', 'announcement', 'schedule', 'followup', 'registration', 'contact')
);

CREATE OR REPLACE FUNCTION public.notify_on_contact_message() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM public.notify_users(
    public.notification_staff(ARRAY['admin', 'academic_admin', 'admin_secretaire']),
    'contact',
    'Nouveau message du site',
    NEW.name || ' — ' || NEW.subject,
    'site-messages'
  );
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notification contact : %', SQLERRM;
  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS notify_on_contact_message ON public.contact_messages;
CREATE TRIGGER notify_on_contact_message AFTER INSERT ON public.contact_messages
FOR EACH ROW EXECUTE FUNCTION public.notify_on_contact_message();

REVOKE ALL ON FUNCTION public.contact_messages_flood_guard() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.notify_on_contact_message() FROM PUBLIC, anon, authenticated;
