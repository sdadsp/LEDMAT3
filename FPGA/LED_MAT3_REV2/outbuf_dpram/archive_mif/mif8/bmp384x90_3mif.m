%Date: 20180609
%Author: Dmitriy S.
%convert input bmp to the 3 mif files (split Top & Bot)

close all;
clear all;
clf;

% use this string for Octave only:
pkg load image;

% "standard" image dimensions
rows_std = 90;
cols_std = 384;

src_img = imread('input3.bmp');
[rows, cols, rgb] = size(src_img);
%imshow(src_img);

% check if the image has correct size:
if (rows != rows_std) || (cols != cols_std)
  disp('Image has a wrong size. Resizing...')
  src_img_resized = imresize(src_img,[rows_std cols_std]);
  working_image = src_img_resized;
%  return;
else
  disp('Image has a correct size already. Resizing will not be performed.')
  working_image = src_img;
endif

rows3 = uint16(rows_std/3);

%-------------------------------------------------------------------------------
fid = fopen('image3_top.mif','w');

fprintf(fid, '-- %3ux%3u 24bit image color values\n\n', rows3, cols_std);
fprintf(fid, 'WIDTH = 24;\n');
fprintf(fid, 'DEPTH = %4u;\n\n', rows3*cols_std);
fprintf(fid, 'ADDRESS_RADIX = UNS;\n');
fprintf(fid, 'DATA_RADIX = UNS;\n\n');
fprintf(fid, 'CONTENT BEGIN\n');

count = 0;
for r = 1:rows3
    for c = 1:cols_std
        red = uint32(working_image(r,c,1));
        green = uint32(working_image(r,c,2));
        blue = uint32(working_image(r,c,3));
        color = red*(256*256) + green*256 + blue;
        fprintf(fid,'%4u : %4u;\n',count, color);
        count = count + 1;
    end
end
fprintf(fid,'END;');
fclose(fid);

%-------------------------------------------------------------------------------

fid = fopen('image3_mid.mif','w');

fprintf(fid, '-- %3ux%3u 24bit image color values\n\n', rows3, cols_std);
fprintf(fid, 'WIDTH = 24;\n');
fprintf(fid, 'DEPTH = %4u;\n\n', rows3*cols_std);
fprintf(fid, 'ADDRESS_RADIX = UNS;\n');
fprintf(fid, 'DATA_RADIX = UNS;\n\n');
fprintf(fid, 'CONTENT BEGIN\n');

count = 0;
for r = (rows3+1):(rows3+rows3)
    for c = 1:cols_std
        red = uint32(working_image(r,c,1));
        green = uint32(working_image(r,c,2));
        blue = uint32(working_image(r,c,3));
        color = red*(256*256) + green*256 + blue;
        fprintf(fid,'%4u : %4u;\n',count, color);
        count = count + 1;
    end
end
fprintf(fid,'END;');
fclose(fid);

%-------------------------------------------------------------------------------

fid = fopen('image3_bot.mif','w');

fprintf(fid, '-- %3ux%3u 24bit image color values\n\n', rows3, cols_std);
fprintf(fid, 'WIDTH = 24;\n');
fprintf(fid, 'DEPTH = %4u;\n\n', rows3*cols_std);
fprintf(fid, 'ADDRESS_RADIX = UNS;\n');
fprintf(fid, 'DATA_RADIX = UNS;\n\n');
fprintf(fid, 'CONTENT BEGIN\n');

count = 0;
for r = (rows3+rows3+1):(rows3+rows3+rows3)
    for c = 1:cols_std
        red = uint32(working_image(r,c,1));
        green = uint32(working_image(r,c,2));
        blue = uint32(working_image(r,c,3));
        color = red*(256*256) + green*256 + blue;
        fprintf(fid,'%4u : %4u;\n',count, color);
        count = count + 1;
    end
end
fprintf(fid,'END;');
fclose(fid);

disp('Conversion done.')