import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 })

  const authorization = request.headers.get('Authorization') ?? ''
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const admin = createClient(supabaseUrl, serviceRoleKey)
  const token = authorization.replace('Bearer ', '')
  const { data, error } = await admin.auth.getUser(token)

  if (error || !data.user) return new Response('Unauthorized', { status: 401 })

  await admin.storage.from('cvs').remove([
    `${data.user.id}/cv.pdf`,
    `${data.user.id}/cv.doc`,
    `${data.user.id}/cv.docx`,
  ])
  const result = await admin.auth.admin.deleteUser(data.user.id)
  if (result.error) return new Response(result.error.message, { status: 500 })
  return Response.json({ deleted: true })
})
