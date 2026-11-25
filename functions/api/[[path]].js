import { handleWaptiaUpdates } from '../../edge/updates_core.js';

export function onRequest(context) {
  return handleWaptiaUpdates(context.request, context.env);
}
