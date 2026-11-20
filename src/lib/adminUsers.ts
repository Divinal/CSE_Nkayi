import { FunctionsFetchError, FunctionsHttpError, FunctionsRelayError } from '@supabase/supabase-js';
import { supabase } from './supabaseClient';
import { t } from '../i18n';

// Appelle la fonction serveur qui gère les comptes de connexion. Les droits y
// sont vérifiés d'après la session de la personne connectée.
export const callAdminUsers = async <T = Record<string, any>>(
  action: string,
  payload: Record<string, unknown> = {},
): Promise<T> => {
  const { data, error } = await supabase.functions.invoke('admin-users', {
    body: { action, ...payload },
  });
  if (!error) return data as T;

  if (error instanceof FunctionsHttpError) {
    // Un message du serveur passe en premier : « Lien d'inscription introuvable » est aussi un 404.
    const body = await error.context.json().catch(() => null);
    if (body?.error) throw new Error(t(body.error));
    if (error.context.status === 404) {
      throw new Error(t("Le service de gestion des comptes n'est pas encore déployé sur le serveur."));
    }
    throw new Error(t("Le serveur a refusé cette action."));
  }
  if (error instanceof FunctionsFetchError || error instanceof FunctionsRelayError) {
    if (await isFunctionMissing()) {
      throw new Error(t("Le service de gestion des comptes n'est pas encore déployé sur le serveur."));
    }
    throw new Error(t("Service de gestion des comptes injoignable. Vérifiez votre connexion et réessayez."));
  }
  throw error;
};

// Fonction absente du serveur : le navigateur ne voit qu'une erreur réseau (le
// 404 ne répond pas au préflight CORS). Une requête « simple » sans préflight
// permet de lire la vraie réponse et d'afficher un message exact.
const isFunctionMissing = async (): Promise<boolean> => {
  try {
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/admin-users`, {
      method: 'POST',
      headers: { 'Content-Type': 'text/plain' },
      body: '{}',
    });
    if (response.status !== 404) return false;
    const body = await response.json().catch(() => null);
    return body?.code === 'NOT_FOUND';
  } catch {
    return false;
  }
};
