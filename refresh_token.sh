#!/bin/bash
# Script para refrescar el token de Gemini cada 50 minutos

CONFIG_FILE="/Users/mayrasciarrillo/projects/test-ai-gateway/AliasDetector/AliasDetector/Config.swift"

while true; do
    NEW_TOKEN=$(gcloud auth print-identity-token)

    # Reemplazar token en Config.swift usando sed
    sed -i '' "s/static var geminiToken = \"[^\"]*\"/static var geminiToken = \"$NEW_TOKEN\"/" "$CONFIG_FILE"

    echo "$(date): Token actualizado"

    # Esperar 50 minutos (3000 segundos)
    sleep 3000
done
