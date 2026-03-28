from supabase import create_client, Client
from core.config import settings

# Initialize the Supabase client
# This client will be imported and used by all your routers
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)