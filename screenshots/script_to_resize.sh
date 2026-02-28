#!/bin/bash

# Create a folder for the processed images
mkdir -p adjusted_screenshots

for file in *.{png,jpg,jpeg}; do
    # Skip if no files match the pattern
    [ -e "$file" ] || continue

    # Get dimensions in WxH format
    dims=$(identify -format "%wx%h" "$file")

    echo "Checking $file ($dims)..."

    # Check if dimensions are already valid
    if [[ "$dims" == "1242x2688" || "$dims" == "2688x1242" || "$dims" == "1284x2778" || "$dims" == "2778x1284" ]]; then
        echo "  [✓] Dimensions are already correct. Skipping."
    else
        echo "  [!] Incorrect size. Adjusting..."
        
        # Determine if it's Portrait or Landscape to choose the best fit
        width=$(echo $dims | cut -d'x' -f1)
        height=$(echo $dims | cut -d'x' -f2)

        if [ "$width" -lt "$height" ]; then
            # Resize to Portrait (1284x2778)
            convert "$file" -resize 1284x2778^ -gravity center -extent 1284x2778 "adjusted_screenshots/$file"
        else
            # Resize to Landscape (2778x1284)
            convert "$file" -resize 2778x1284^ -gravity center -extent 2778x1284 "adjusted_screenshots/$file"
        fi
        echo "  [+] Saved to adjusted_screenshots/"
    fi
done

echo "Done!"
