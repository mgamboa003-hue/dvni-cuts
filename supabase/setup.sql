-- ============================================================
-- DVNI CUTS · Configuración de Supabase
-- Pega todo este archivo en Supabase → SQL Editor → New query → Run.
-- Se puede ejecutar más de una vez sin romper nada.
-- ============================================================

-- 1) Contenido de la web (un único documento JSON)
create table if not exists public.contenido (
  id int primary key default 1 check (id = 1),
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- 2) Correos que pueden editar la web
create table if not exists public.admins (
  email text primary key
);

-- Función que dice si el usuario conectado es administrador
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where lower(email) = lower(auth.jwt() ->> 'email'));
$$;

-- 3) Reglas de seguridad (RLS)
alter table public.contenido enable row level security;
alter table public.admins enable row level security;

drop policy if exists "contenido lectura publica" on public.contenido;
create policy "contenido lectura publica" on public.contenido
  for select using (true);

drop policy if exists "contenido editan admins" on public.contenido;
create policy "contenido editan admins" on public.contenido
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- 4) Carpeta pública para las fotos
insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', true)
on conflict (id) do update set public = true;

drop policy if exists "fotos suben admins" on storage.objects;
create policy "fotos suben admins" on storage.objects
  for insert to authenticated with check (bucket_id = 'fotos' and public.is_admin());

drop policy if exists "fotos actualizan admins" on storage.objects;
create policy "fotos actualizan admins" on storage.objects
  for update to authenticated using (bucket_id = 'fotos' and public.is_admin());

drop policy if exists "fotos borran admins" on storage.objects;
create policy "fotos borran admins" on storage.objects
  for delete to authenticated using (bucket_id = 'fotos' and public.is_admin());

-- 5) Contenido inicial (solo si la tabla está vacía)
insert into public.contenido (id, data) values (1, $json${
  "negocio": {
    "direccion": "",
    "comuna": "",
    "horario_dias": "Lun a Sáb",
    "horario_horas": "10:00 – 20:00",
    "whatsapp": "",
    "whatsapp_msg": "¡Hola! Quiero reservar una hora en DVNI CUTS 💈",
    "agenda_url": "",
    "instagram": "",
    "tiktok": "",
    "google_resenas_url": "",
    "spotify_playlist": ""
  },
  "hero": {
    "linea1": "Cortes con",
    "linea2": "precisión.",
    "linea3": "Estilo con sello.",
    "bajada": "Fades, barba y perfilado hechos con detalle. Elige tu barbero, reserva en segundos y llega directo a la silla.",
    "fotos": [
      "https://images.unsplash.com/photo-1635273051839-003bf06a8751?auto=format&fit=crop&w=2000&q=70",
      "https://images.unsplash.com/photo-1536520002442-39764a41e987?auto=format&fit=crop&w=2000&q=70",
      "https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=2000&q=70"
    ]
  },
  "fotos": {
    "agenda": "https://images.unsplash.com/photo-1567894340315-735d7c361db0?auto=format&fit=crop&w=1200&q=70",
    "tienda": "https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=1200&q=70",
    "tienda_grande": "https://images.unsplash.com/photo-1621645582931-d1d3e6564943?auto=format&fit=crop&w=1200&q=70",
    "reserva": "https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=1800&q=60"
  },
  "servicios": [
    {
      "cat": "cortes",
      "nombre": "Corte clásico",
      "desc": "Tijera y máquina, terminado y peinado.",
      "precio": 12000,
      "minutos": 45
    },
    {
      "cat": "cortes",
      "nombre": "Fade / degradado",
      "desc": "Degradado limpio con transiciones suaves.",
      "precio": 14000,
      "minutos": 50
    },
    {
      "cat": "cortes",
      "nombre": "Corte niño",
      "desc": "Para los más chicos, con paciencia y buena onda.",
      "precio": 10000,
      "minutos": 40
    },
    {
      "cat": "barba",
      "nombre": "Perfilado de barba",
      "desc": "Definición de líneas y contorno con navaja.",
      "precio": 7000,
      "minutos": 25
    },
    {
      "cat": "barba",
      "nombre": "Barba con toalla caliente",
      "desc": "Ritual completo con toalla caliente y aceite.",
      "precio": 10000,
      "minutos": 35
    },
    {
      "cat": "barba",
      "nombre": "Cejas",
      "desc": "Perfilado de cejas con navaja.",
      "precio": 4000,
      "minutos": 10
    },
    {
      "cat": "combos",
      "nombre": "Corte + barba",
      "desc": "El combo completo para salir impecable.",
      "precio": 20000,
      "minutos": 70
    },
    {
      "cat": "combos",
      "nombre": "Corte + barba + cejas",
      "desc": "Servicio completo con todos los detalles.",
      "precio": 23000,
      "minutos": 80
    }
  ],
  "planes": [
    {
      "nombre": "Plan Básico",
      "cortes": 2,
      "descuento": 5,
      "precio": 22800,
      "destacado": false,
      "beneficios": [
        "Agenda con cualquier barbero",
        "Úsalo dentro de 30 días"
      ]
    },
    {
      "nombre": "Plan Pro",
      "cortes": 3,
      "descuento": 10,
      "precio": 32400,
      "destacado": true,
      "beneficios": [
        "Agenda con cualquier barbero",
        "Úsalo dentro de 30 días",
        "Prioridad en horas de fin de semana"
      ]
    },
    {
      "nombre": "Plan Full",
      "cortes": 4,
      "descuento": 15,
      "precio": 40800,
      "destacado": false,
      "beneficios": [
        "Agenda con cualquier barbero",
        "Úsalo dentro de 30 días",
        "Perfilado de cejas incluido"
      ]
    }
  ],
  "barberos": [
    {
      "nombre": "Barbero 01",
      "rol": "Barbero profesional",
      "lema": "Fade · Líneas · Detalle",
      "especialidades": [
        "Fade",
        "Diseños",
        "Perfilado"
      ],
      "foto": "https://images.unsplash.com/photo-1594751684241-bcef815d5a57?auto=format&fit=crop&w=1000&q=70",
      "instagram": "",
      "agenda_url": ""
    },
    {
      "nombre": "Barbero 02",
      "rol": "Barbero profesional",
      "lema": "Clásico · Tijera · Barba",
      "especialidades": [
        "Tijera",
        "Barba",
        "Toalla caliente"
      ],
      "foto": "https://images.unsplash.com/photo-1617746652908-91e66c07499a?auto=format&fit=crop&w=1000&q=70",
      "instagram": "",
      "agenda_url": ""
    },
    {
      "nombre": "Barbero 03",
      "rol": "Barbero profesional",
      "lema": "Urbano · Texturas · Color",
      "especialidades": [
        "Taper",
        "Texturas",
        "Corte niño"
      ],
      "foto": "https://images.unsplash.com/photo-1587397845856-e6cf49176c70?auto=format&fit=crop&w=1000&q=70",
      "instagram": "",
      "agenda_url": ""
    }
  ],
  "galeria": [
    {
      "foto": "https://images.unsplash.com/photo-1593702275687-f8b402bf1fb5?auto=format&fit=crop&w=1200&q=70",
      "etiqueta": "Fade bajo"
    },
    {
      "foto": "https://images.unsplash.com/photo-1630827020718-3433092696e7?auto=format&fit=crop&w=800&q=70",
      "etiqueta": "Barba"
    },
    {
      "foto": "https://images.unsplash.com/photo-1772442088712-df1780cbb709?auto=format&fit=crop&w=800&q=70",
      "etiqueta": "Taper"
    },
    {
      "foto": "https://images.unsplash.com/photo-1599834562135-b6fc90e642ca?auto=format&fit=crop&w=800&q=70",
      "etiqueta": "Clásico"
    },
    {
      "foto": "https://images.unsplash.com/photo-1761931403667-a6753db21f32?auto=format&fit=crop&w=800&q=70",
      "etiqueta": "Terminación"
    },
    {
      "foto": "https://images.unsplash.com/photo-1647140655214-e4a2d914971f?auto=format&fit=crop&w=1200&q=70",
      "etiqueta": "Tijera"
    }
  ],
  "productos": [
    {
      "nombre": "Cera mate",
      "desc": "Fijación media, sin brillo.",
      "precio": 8990
    },
    {
      "nombre": "Pomada brillo",
      "desc": "Acabado pulido, estilo clásico.",
      "precio": 8990
    },
    {
      "nombre": "Aceite de barba",
      "desc": "Suaviza y da brillo natural.",
      "precio": 9990
    },
    {
      "nombre": "After shave",
      "desc": "Calma la piel después del afeitado.",
      "precio": 7990
    }
  ],
  "ejemplo": true
}$json$::jsonb)
on conflict (id) do nothing;

-- 6) ⚠️ CAMBIA ESTOS CORREOS por el del dueño (y el tuyo, para dar soporte)
insert into public.admins (email) values
  ('correo-del-dueno@ejemplo.cl'),
  ('tu-correo@ejemplo.cl')
on conflict do nothing;
