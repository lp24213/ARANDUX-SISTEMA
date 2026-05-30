#!/bin/bash
# Script para configurar secrets no Cloudflare Workers

echo "🔐 Configurando secrets no Cloudflare Workers..."

# DATABASE_URL
echo ""
echo "📊 Configure DATABASE_URL (MySQL):"
echo "Formato: mysql://usuario:senha@host:porta/database"
read -p "Digite a DATABASE_URL: " db_url
if [ ! -z "$db_url" ]; then
    echo "$db_url" | wrangler secret put DATABASE_URL --env production
    echo "✅ DATABASE_URL configurado!"
fi

# JWT_ACCESS_SECRET
echo ""
echo "🔑 Configure JWT_ACCESS_SECRET:"
read -p "Digite o JWT_ACCESS_SECRET (ou pressione Enter para gerar): " jwt_secret
if [ -z "$jwt_secret" ]; then
    jwt_secret=$(openssl rand -hex 32)
    echo "Secret gerado: $jwt_secret"
fi
echo "$jwt_secret" | wrangler secret put JWT_ACCESS_SECRET --env production
echo "✅ JWT_ACCESS_SECRET configurado!"

# JWT_REFRESH_SECRET
echo ""
echo "🔑 Configure JWT_REFRESH_SECRET:"
read -p "Digite o JWT_REFRESH_SECRET (ou pressione Enter para gerar): " jwt_refresh
if [ -z "$jwt_refresh" ]; then
    jwt_refresh=$(openssl rand -hex 32)
    echo "Secret gerado: $jwt_refresh"
fi
echo "$jwt_refresh" | wrangler secret put JWT_REFRESH_SECRET --env production
echo "✅ JWT_REFRESH_SECRET configurado!"

echo ""
echo "✅ Todos os secrets foram configurados!"

