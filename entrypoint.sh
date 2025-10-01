set -e

echo "📦 Instalando dependências do backend..."
pip install --upgrade pip
pip install -r requirements.txt

echo "🚀 Rodando makemigrations de todos os apps..."
python manage.py makemigrations --noinput

echo "🚀 Aplicando migrate..."
python manage.py migrate --noinput

echo "⚙️ Criando grupo e conta admin e vinculando permissões..."
python manage.py shell <<EOF
from django.contrib.auth.models import Group, Permission
from hub_users.models import CustomUser
from django.db import transaction

with transaction.atomic():
    admin_group, created = Group.objects.get_or_create(name="admin")
    if created:
        print("Grupo 'admin' criado")
    else:
        print("Grupo 'admin' já existia")

    perms = Permission.objects.all()
    admin_group.permissions.set(perms)
    admin_group.save()
    print(f"✅ Vinculadas {perms.count()} permissões ao grupo admin")

    user, created = CustomUser.objects.get_or_create(
        email="naoresponda_sistema@restinga.ifrs.edu.br",
        defaults={
            "username": "Admin Sistemas",
            "access_profile": "servidor",
            "is_active": True,
            "is_abstract": True,
            "first_login": False,
        }
    )

    if created:
        print("👤 Usuário 'Admin Sistemas' criado")
    else:
        print("👤 Usuário 'Admin Sistemas' já existia")

    user.groups.add(admin_group)
    print("✅ Usuário vinculado ao grupo admin")
EOF

echo "📊 Rodando script de mapeamento UUID..."
python manage.py map_groups_and_permissions
