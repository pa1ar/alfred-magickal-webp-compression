#!/bin/zsh

function handle_error {
  source ./notificator --title "🚨 Error" --message "An error occurred! Exiting script.." --sound "$sound"
  exit 1
}

trap "handle_error" ERR

(source ./notificator --title "⏳ Please wait..." --message "The workflow is generating images" --sound "$sound") &

echo "🔍 Depth of the search : Level ${level}\n"

LINKS=(${(s/	/)_links_list}) # split by tab
IMAGES=()
IFS=$'\n'

# Get color profile path from Alfred workflow variables
COLOR_PROFILE="$color_profile"

for LINK in "${LINKS[@]}"; do
  if [ -d "$LINK" ]; then
    IMAGES+=($(find -E "$LINK" -maxdepth "$level" -iregex '.*\.(png|jpg|jpeg|tif|tiff|webp)'))
  else
    IMAGES+=("$LINK")
  fi
done

for IMAGE in "${IMAGES[@]}"; do
  if [ -z "$COLOR_PROFILE" ] || ! echo "$COLOR_PROFILE" | grep -qE '\.icm$|\.icc$'; then
    # No valid color profile defined, directly use cwebp
    cwebp $_the_preset "$IMAGE" -o "${IMAGE%.*}.webp"
  else
    if [ ! -f "$COLOR_PROFILE" ]; then
      source ./notificator --title "🚨 Error" --message "Color profile file not found at $COLOR_PROFILE" --sound "$sound"
      exit 1
    fi
    TEMP_IMAGE="${IMAGE%.*}_temp.png"
    # Embed color profile using ImageMagick
    magick "$IMAGE" -profile "$COLOR_PROFILE" "$TEMP_IMAGE"
    # Convert to WebP using cwebp
    cwebp $_the_preset "$TEMP_IMAGE" -o "${IMAGE%.*}.webp"
    # Remove temporary image
    rm "$TEMP_IMAGE"
  fi
done

if [[ $workflow_action = "_notif" ]]; then
  sleep 0.5
  source ./notificator --title "⌛ Finished" --message "Process completed. You can check the log file" --sound "$sound"
fi
