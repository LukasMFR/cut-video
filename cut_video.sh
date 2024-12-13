#!/bin/bash

# Vérifie si FFmpeg est installé
if ! command -v ffmpeg &> /dev/null
then
    echo "FFmpeg n'est pas installé. Installe-le d'abord."
    exit 1
fi

# Variables
INPUT_VIDEO=$1   # Vidéo source (chemin)
OUTPUT_VIDEO=$2  # Vidéo finale (chemin)
KEEP_AUDIO=$3    # "true" pour garder l'audio, "false" pour le couper
shift 3          # On enlève les trois premiers arguments pour traiter les timestamps restants
TIMESTAMPS=("$@")  # Récupère tous les timestamps restants

# Vérifie les paramètres obligatoires
if [ -z "$INPUT_VIDEO" ] || [ -z "$OUTPUT_VIDEO" ] || [ ${#TIMESTAMPS[@]} -eq 0 ]; then
    echo "Usage: $0 <input_video> <output_video> <keep_audio (true/false)> <timestamp1_start> <timestamp1_end> [timestamp2_start timestamp2_end ...]"
    exit 1
fi

# Dossier temporaire pour les segments
TEMP_DIR=$(mktemp -d)
SEGMENT_LIST="$TEMP_DIR/segments.txt"

# Découpe les segments
echo "Découpage des segments..."
for ((i=0; i<${#TIMESTAMPS[@]}; i+=2)); do
    START=${TIMESTAMPS[i]}
    END=${TIMESTAMPS[i+1]}
    SEGMENT_FILE="$TEMP_DIR/segment_$((i/2)).mp4"
    if [ "$KEEP_AUDIO" = "true" ]; then
        ffmpeg -i "$INPUT_VIDEO" -ss "$START" -to "$END" -c:v libx264 -preset fast -c:a aac "$SEGMENT_FILE" -y
    else
        ffmpeg -i "$INPUT_VIDEO" -ss "$START" -to "$END" -c:v libx264 -preset fast -an "$SEGMENT_FILE" -y
    fi
    echo "file '$SEGMENT_FILE'" >> "$SEGMENT_LIST"
done

# Assemble les segments
echo "Assemblage des segments..."
ffmpeg -f concat -safe 0 -i "$SEGMENT_LIST" -c:v libx264 -preset fast -c:a aac "$OUTPUT_VIDEO" -y

# Nettoie les fichiers temporaires
rm -r "$TEMP_DIR"

echo "Vidéo finale créée : $OUTPUT_VIDEO"
