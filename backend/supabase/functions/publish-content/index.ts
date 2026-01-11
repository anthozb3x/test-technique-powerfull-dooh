import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { z } from "https://deno.land/x/zod@v3.21.4/index.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const schema = z.object({
  title: z.string().min(1, "Le titre est requis"),
  mediaUrl: z.string().url().optional(),
  startAt: z.string().datetime(),
  endAt: z.string().datetime(),
}).refine(data => new Date(data.endAt) > new Date(data.startAt), {
  message: "La date de fin doit être après le début"
});

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Non autorisé" }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const json = await req.json()
    const validation = schema.safeParse(json)
    
    if (!validation.success) {
      return new Response(JSON.stringify({ error: validation.error.issues }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
    
    const input = validation.data


    const { data: profile } = await supabase
      .from('profiles')
      .select('site_id')
      .eq('id', user.id)
      .single()

    if (!profile?.site_id) {
       return new Response(JSON.stringify({ error: "Aucun site associé à ce profil" }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { data: newContent, error: dbError } = await supabase
      .from('contents')
      .insert({
        title: input.title,
        media_url: input.mediaUrl,
        start_at: input.startAt,
        end_at: input.endAt,
        site_id: profile.site_id,
        created_by: user.id
      })
      .select()
      .single()

    if (dbError) throw dbError

    return new Response(JSON.stringify({ success: true, data: newContent }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 201,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})