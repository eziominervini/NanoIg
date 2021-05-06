#!/usr/bin/python

import sys
import math
import os
import matplotlib
matplotlib.use('pdf')
import matplotlib.pyplot as plt

path = sys.argv[1]

# Config:
images_dir = path+'/PIPE/Clonality'
result_grid_filename = path + '/PIPE/Clonality/grid.jpg'
result_figsize_resolution = 50

images_list =[]

for i in os.listdir(images_dir):
    images_list.append(images_dir+'/'+i+'/barchart.'+i+'.png')

images_list.sort()

print(images_list)

images_count = len(images_list)
print('Images: ', images_list)
print('Images count: ', images_count)

# Calculate the grid size:
grid_size = int(math.ceil(float(images_count)/4.0))
grid_cells=grid_size * 4
empty_cells=grid_cells-images_count


# Create plt plot:
fig, axes = plt.subplots(grid_size, 4, figsize=(result_figsize_resolution, result_figsize_resolution), squeeze=False)

current_file_number = 0
for image_filename in images_list:
    x_position = current_file_number % 4
    y_position = current_file_number // 4
    plt_image = plt.imread(image_filename)
    if grid_size>1:
        axes[y_position, x_position].imshow(plt_image)
        axes[y_position, x_position].axis('off')
    else:
        axes[0, x_position].imshow(plt_image)
        axes[0, x_position].axis('off')
        
    print((current_file_number + 1), '/', images_count, ': ', image_filename)
    current_file_number += 1

empty_x=range((grid_cells-1), (images_count-1), -1)

for i in empty_x:
    fig.delaxes(axes[images_count // 4][i % 4])


plt.subplots_adjust(left=0.0, right=1.0, bottom=0.0, top=1.0, wspace=None, hspace=None)
plt.savefig(result_grid_filename)
