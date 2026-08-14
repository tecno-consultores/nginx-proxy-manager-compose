#!/usr/bin/env bash
# Made by Sinfallas <sinfallas@yahoo.com>
# Licence: GPL-2

if [ "$#" -ne 3 ]; then
    echo "Uso: $0 <usuario> <contrasena> <codigo_2fa>"
    echo "Ejemplo: $0 miusuario clave. 123456"
    exit 1
fi

USER=$1
PASSWORD=$2
CODE_2FA=$3

# URLs de la API
API_URL="http://192.168.1.1:81/api/tokens"
API_URL_2FA="http://192.168.1.1:81/api/tokens/2fa" # <- Endpoint correcto para 2FA

echo "[1/2] Autenticando usuario..."

# 1. JSON para obtener el challenge token inicial
JSON_PAYLOAD_1=$(python3 -c 'import json, sys; print(json.dumps({"identity": sys.argv[1], "secret": sys.argv[2]}))' "$USER" "$PASSWORD")

# Paso 1: Petición inicial
RESPONSE=$(curl -s -k -L -X POST "$API_URL" \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD_1")

# Extraer el 'challenge_token'
CHALLENGE_TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('challenge_token', ''))" 2>/dev/null)

if [ -z "$CHALLENGE_TOKEN" ] || [ "$CHALLENGE_TOKEN" == "None" ]; then
    echo "Error en Paso 1. Respuesta del servidor:"
    echo "$RESPONSE"
    exit 1
fi

echo "[2/2] Challenge Token recibido con éxito. Validando código 2FA..."

# 2. JSON exacto según el esquema que exige la API de Nginx Proxy Manager
JSON_PAYLOAD_2=$(python3 -c 'import json, sys; print(json.dumps({"challenge_token": sys.argv[1], "code": sys.argv[2]}))' "$CHALLENGE_TOKEN" "$CODE_2FA")

# Paso 2: Petición enviando challenge_token y code al endpoint de 2FA
FINAL_RESPONSE=$(curl -s -k -L -X POST "$API_URL_2FA" \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD_2")

# Extraer el Token de Acceso definitivo (JWT)
ACCESS_TOKEN=$(echo "$FINAL_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))" 2>/dev/null)

echo ""
echo "=== Resultado ==="
if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "None" ]; then
    echo "¡Autenticación Exitosa!"
    echo "Token de Acceso:"
    echo "$ACCESS_TOKEN"
else
    echo "Respuesta del Servidor:"
    echo "$FINAL_RESPONSE"
fi
