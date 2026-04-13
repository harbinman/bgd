import sys
import os
from PIL import Image

def remove_white_background(input_path, output_path, threshold=230):
    """
    Converts a white background to transparent.
    """
    print(f"Opening image: {input_path}")
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    for item in datas:
        # Check if the pixel is close to white
        # item[0]=R, item[1]=G, item[2]=B, item[3]=A
        if item[0] > threshold and item[1] > threshold and item[2] > threshold:
            # Make it transparent
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Saved transparent image to: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python remove_bg.py <input_path> <output_path> [threshold]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    threshold = int(sys.argv[3]) if len(sys.argv) > 3 else 230
    
    remove_white_background(input_file, output_file, threshold)
