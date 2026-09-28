import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Supabase configuration missing" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create client with user JWT to get their ID
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") || "", {
      global: {
        headers: {
          authorization: authHeader,
        },
      },
    });

    // Get the authenticated user
    const { data: userData, error: userError } =
      await userClient.auth.getUser();
    if (userError || !userData.user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized", details: userError?.message }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const userId = userData.user.id;

    // Create admin client for deleting auth user
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // 1. Delete user's scans
    const { error: scansError } = await adminClient
      .from("scans")
      .delete()
      .eq("user_id", userId);

    if (scansError) {
      console.error("Error deleting scans:", scansError);
      return new Response(
        JSON.stringify({
          error: "Failed to delete scans",
          details: scansError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 2. Delete user's profile
    const { error: profileError } = await adminClient
      .from("profiles")
      .delete()
      .eq("id", userId);

    if (profileError) {
      console.error("Error deleting profile:", profileError);
      return new Response(
        JSON.stringify({
          error: "Failed to delete profile",
          details: profileError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 3. Delete storage (scan photos)
    const { data: storageObjects, error: listError } = await adminClient
      .storage.from("scan-images")
      .list(`${userId}`);

    if (!listError && storageObjects) {
      const filePaths = storageObjects.map((file) => `${userId}/${file.name}`);
      if (filePaths.length > 0) {
        const { error: deleteStorageError } = await adminClient
          .storage.from("scan-images")
          .remove(filePaths);

        if (deleteStorageError) {
          console.error("Error deleting storage:", deleteStorageError);
        }
      }
    }

    // 4. Delete the auth user (irreversible)
    const { error: authError } = await adminClient.auth.admin.deleteUser(
      userId
    );

    if (authError) {
      console.error("Error deleting auth user:", authError);
      return new Response(
        JSON.stringify({
          error: "Failed to delete account",
          details: authError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Account and all associated data deleted successfully",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
